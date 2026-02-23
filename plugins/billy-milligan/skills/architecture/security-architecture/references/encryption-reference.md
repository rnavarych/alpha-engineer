# Encryption Reference

## When to load
Load when discussing encryption at-rest, in-transit, field-level encryption, key management, or key rotation strategies.

## Patterns

### Encryption at-rest (AES-256-GCM)
```typescript
import { createCipheriv, createDecipheriv, randomBytes } from 'crypto';

// AES-256-GCM: authenticated encryption (integrity + confidentiality)
function encrypt(plaintext: string, key: Buffer): { ciphertext: string; iv: string; tag: string } {
  const iv = randomBytes(12);  // 96-bit IV for GCM
  const cipher = createCipheriv('aes-256-gcm', key, iv);
  let encrypted = cipher.update(plaintext, 'utf8', 'base64');
  encrypted += cipher.final('base64');
  return {
    ciphertext: encrypted,
    iv: iv.toString('base64'),
    tag: cipher.getAuthTag().toString('base64'),
  };
}

function decrypt(data: { ciphertext: string; iv: string; tag: string }, key: Buffer): string {
  const decipher = createDecipheriv(
    'aes-256-gcm',
    key,
    Buffer.from(data.iv, 'base64')
  );
  decipher.setAuthTag(Buffer.from(data.tag, 'base64'));
  let decrypted = decipher.update(data.ciphertext, 'base64', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

// Key derivation from password (if needed)
import { scrypt } from 'crypto';
const key = await new Promise<Buffer>((resolve, reject) => {
  scrypt(password, salt, 32, (err, derivedKey) => {
    err ? reject(err) : resolve(derivedKey);
  });
});
```

### Encryption in-transit (TLS 1.3)
```typescript
// Node.js HTTPS server with TLS 1.3
import https from 'https';
import { readFileSync } from 'fs';

const server = https.createServer({
  key: readFileSync('/etc/ssl/private/server.key'),
  cert: readFileSync('/etc/ssl/certs/server.crt'),
  ca: readFileSync('/etc/ssl/certs/ca.crt'),
  minVersion: 'TLSv1.2',    // minimum TLS 1.2
  maxVersion: 'TLSv1.3',    // prefer TLS 1.3
  ciphers: [
    'TLS_AES_256_GCM_SHA384',
    'TLS_CHACHA20_POLY1305_SHA256',
    'TLS_AES_128_GCM_SHA256',
  ].join(':'),
}, app);
```

```nginx
# Nginx TLS configuration
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers on;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

# HSTS (force HTTPS)
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;
```

### Field-level encryption
```typescript
// Encrypt specific fields before database storage
interface UserRecord {
  id: string;
  email: string;              // plaintext (indexed)
  ssn_encrypted: string;      // AES-256-GCM encrypted
  ssn_iv: string;
  ssn_tag: string;
  ssn_key_version: number;    // for key rotation
  phone_encrypted: string;    // AES-256-GCM encrypted
  phone_iv: string;
  phone_tag: string;
  phone_key_version: number;
}

// Encrypt sensitive fields in middleware
async function encryptSensitiveFields(user: CreateUserInput): Promise<UserRecord> {
  const currentKey = await kms.getCurrentKey('user-pii');
  return {
    id: user.id,
    email: user.email,
    ...encrypt(user.ssn, currentKey.material),
    ssn_key_version: currentKey.version,
    ...encrypt(user.phone, currentKey.material),
    phone_key_version: currentKey.version,
  };
}
```

### Key management (KMS / Vault)
```typescript
// Envelope encryption pattern
// 1. KMS generates/stores master key (never leaves KMS)
// 2. KMS generates data encryption key (DEK), encrypted by master key
// 3. App uses plaintext DEK to encrypt data
// 4. App stores encrypted DEK alongside data
// 5. To decrypt: send encrypted DEK to KMS, get plaintext DEK, decrypt data

// AWS KMS example
import { KMSClient, GenerateDataKeyCommand, DecryptCommand } from '@aws-sdk/client-kms';

async function getDataKey(kmsKeyId: string) {
  const kms = new KMSClient({});
  const { Plaintext, CiphertextBlob } = await kms.send(
    new GenerateDataKeyCommand({
      KeyId: kmsKeyId,
      KeySpec: 'AES_256',
    })
  );
  return {
    plaintext: Buffer.from(Plaintext!),     // use for encryption, discard after
    encrypted: Buffer.from(CiphertextBlob!), // store alongside encrypted data
  };
}

// HashiCorp Vault transit engine
// vault write transit/encrypt/my-key plaintext=$(base64 <<< "secret data")
// vault write transit/decrypt/my-key ciphertext="vault:v1:..."
```

### Key rotation
```typescript
// Key rotation strategy:
// 1. Generate new key version in KMS
// 2. New writes use new key version
// 3. Background job re-encrypts old data with new key
// 4. Track key_version per record to know which key decrypts it

async function rotateKeys(tableName: string, oldVersion: number, newVersion: number) {
  const oldKey = await kms.getKeyByVersion(oldVersion);
  const newKey = await kms.getKeyByVersion(newVersion);

  // Process in batches
  let cursor = null;
  do {
    const batch = await db.query(
      `SELECT * FROM ${tableName} WHERE key_version = $1 LIMIT 1000`,
      [oldVersion]
    );
    for (const record of batch.rows) {
      const plaintext = decrypt(record, oldKey);
      const reEncrypted = encrypt(plaintext, newKey);
      await db.query(
        `UPDATE ${tableName} SET encrypted_data=$1, iv=$2, tag=$3, key_version=$4 WHERE id=$5`,
        [reEncrypted.ciphertext, reEncrypted.iv, reEncrypted.tag, newVersion, record.id]
      );
    }
    cursor = batch.rows.length === 1000 ? true : null;
  } while (cursor);
}
```

## Anti-patterns
- ECB mode -> patterns visible in ciphertext; always use GCM or CBC with HMAC
- Reusing IV/nonce -> catastrophic for GCM (key recovery possible)
- Storing encryption keys in code or env vars -> use KMS or Vault
- Encrypting everything -> performance cost; encrypt only sensitive data (PII, secrets)
- No key rotation plan -> compromised key means all historical data exposed

## Decision criteria
- **AES-256-GCM**: default choice, authenticated encryption, hardware-accelerated
- **ChaCha20-Poly1305**: mobile/embedded without AES hardware support
- **RSA**: key exchange only, never for bulk data (max ~245 bytes with 2048-bit key)
- **Envelope encryption**: when using KMS, reduces KMS API calls

## Quick reference
```
Algorithm: AES-256-GCM (default), ChaCha20-Poly1305 (mobile)
IV/Nonce: 12 bytes (96-bit) for GCM, NEVER reuse
Key size: 256-bit (32 bytes)
TLS minimum: 1.2, prefer 1.3
HSTS: max-age=63072000 (2 years), includeSubDomains, preload
Key rotation: annual minimum, immediate on suspected compromise
Envelope encryption: KMS master key -> DEK -> data
Password hashing: argon2id (not encryption, one-way hash)
```
