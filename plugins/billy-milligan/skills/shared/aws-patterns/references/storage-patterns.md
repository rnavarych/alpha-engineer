# AWS Storage Patterns

## When to load
Load when choosing between S3, EBS, EFS, or designing data storage architecture on AWS.

## Storage Decision Tree

```
What kind of data?
  │
  ├─ Objects (files, images, backups, logs)
  │   → S3
  │     Standard:            Hot data, frequent access
  │     Intelligent-Tiering: Unknown access pattern (auto-moves)
  │     Glacier Instant:     Archive, millisecond retrieval
  │     Glacier Deep:        Compliance archive, 12h retrieval
  │
  ├─ Block storage (database volumes, boot disks)
  │   → EBS
  │     gp3:  General purpose (baseline 3000 IOPS, 125 MB/s)
  │     io2:  High IOPS databases (up to 64K IOPS)
  │     st1:  Throughput-optimized (big data, logs)
  │
  ├─ Shared filesystem (multiple instances need same files)
  │   → EFS (NFS)
  │     Standard:   Multi-AZ, auto-scaling
  │     One Zone:   30% cheaper, single AZ
  │
  └─ High-performance computing
      → FSx for Lustre (HPC, ML training)
```

## S3 Patterns

```typescript
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const s3 = new S3Client({ region: 'us-east-1' });

// Upload with server-side encryption
await s3.send(new PutObjectCommand({
  Bucket: 'my-app-uploads',
  Key: `users/${userId}/avatar.jpg`,
  Body: fileBuffer,
  ContentType: 'image/jpeg',
  ServerSideEncryption: 'aws:kms',
  Metadata: { 'uploaded-by': userId },
}));

// Generate presigned URL for direct upload (bypass server)
const uploadUrl = await getSignedUrl(s3, new PutObjectCommand({
  Bucket: 'my-app-uploads',
  Key: `users/${userId}/document.pdf`,
  ContentType: 'application/pdf',
}), { expiresIn: 300 }); // 5 minutes

// Generate presigned URL for download
const downloadUrl = await getSignedUrl(s3, new GetObjectCommand({
  Bucket: 'my-app-uploads',
  Key: `users/${userId}/avatar.jpg`,
}), { expiresIn: 3600 }); // 1 hour
```

## S3 Lifecycle Rules

```json
{
  "Rules": [
    {
      "ID": "archive-old-logs",
      "Status": "Enabled",
      "Filter": { "Prefix": "logs/" },
      "Transitions": [
        { "Days": 30, "StorageClass": "STANDARD_IA" },
        { "Days": 90, "StorageClass": "GLACIER" },
        { "Days": 365, "StorageClass": "DEEP_ARCHIVE" }
      ],
      "Expiration": { "Days": 2555 }
    },
    {
      "ID": "cleanup-temp",
      "Status": "Enabled",
      "Filter": { "Prefix": "tmp/" },
      "Expiration": { "Days": 7 }
    }
  ]
}
```

## S3 Cost Optimization

```
Storage class pricing (us-east-1, per GB/month):
  Standard:            $0.023
  Intelligent-Tiering: $0.023 (+ $0.0025/1K objects monitoring)
  Standard-IA:         $0.0125 (min 30 days, retrieval fee)
  Glacier Instant:     $0.004  (retrieval fee per GB)
  Glacier Deep:        $0.00099 (12-48h retrieval)

Cost reduction strategies:
  1. Lifecycle rules: auto-transition to cheaper tiers
  2. Intelligent-Tiering: for unpredictable access patterns
  3. S3 Inventory: identify unused objects for deletion
  4. Compression: gzip before upload (logs, JSON)
  5. Multipart upload: >100MB files, resume on failure
```

## DynamoDB vs RDS vs S3

```
| Need | Service | Why |
|------|---------|-----|
| Relational data, joins | RDS (Postgres/MySQL) | ACID, SQL, complex queries |
| Key-value, high scale | DynamoDB | Single-digit ms, auto-scale |
| Document store | DynamoDB or DocumentDB | Schema-flexible |
| File storage | S3 | Unlimited, cheap, durable |
| Cache layer | ElastiCache (Redis) | Sub-ms latency |
| Search | OpenSearch | Full-text, analytics |
| Time series | Timestream | IoT, metrics, auto-partition |
```

## Anti-patterns
- S3 public buckets without intention → data breach risk, use presigned URLs
- EBS without snapshots → no backup, no disaster recovery
- Large EBS volumes "just in case" → pay for provisioned, not used
- EFS for single-instance workloads → more expensive than EBS, unnecessary
- Storing database data on S3 → use RDS/DynamoDB for transactional data

## Quick reference
```
S3: objects, unlimited, 11x9 durability, lifecycle rules
EBS gp3: block storage, single instance, 3000 IOPS baseline
EFS: shared NFS, multi-AZ, auto-scaling, multiple instances
DynamoDB: key-value, single-digit ms, auto-scale, serverless
Presigned URLs: direct upload/download without server proxy
Lifecycle: auto-transition Standard → IA → Glacier → Deep Archive
Encryption: SSE-S3 (default), SSE-KMS (audit), or client-side
Versioning: enable on S3 for accidental deletion protection
```
