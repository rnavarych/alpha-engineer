# Upload Strategies

## When to load
Load when selecting an upload approach, implementing presigned URL flows, or configuring S3/GCS for direct-to-cloud uploads.

## Strategy Selection

| Strategy             | Max Size  | Resumable | Best For                              |
|----------------------|-----------|-----------|---------------------------------------|
| Multipart form       | ~10 MB    | No        | Small files, simple forms             |
| Presigned URL (S3)   | 5 GB      | No        | Direct-to-cloud, large files          |
| Multipart upload (S3)| 5 TB      | Yes       | Very large files, unreliable networks |
| tus protocol         | Unlimited | Yes       | Resumable uploads, poor connectivity  |

## Presigned URL Flow (Recommended)

1. **Client** requests an upload URL from the API with file metadata (name, type, size).
2. **Server** validates metadata (type whitelist, size limit), generates a presigned PUT URL (expires in 15 minutes).
3. **Client** uploads directly to S3/GCS using the presigned URL with `Content-Type` header.
4. **Server** receives a completion callback (S3 Event Notification or client confirmation) and records the file in the database.

```typescript
// Generate presigned URL (AWS SDK v3)
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

async function getUploadUrl(key: string, contentType: string) {
  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET,
    Key: `uploads/${key}`,
    ContentType: contentType,
  });
  return getSignedUrl(s3Client, command, { expiresIn: 900 });
}
```

## Progress Indicators

```typescript
// XMLHttpRequest for progress tracking with presigned URLs
const xhr = new XMLHttpRequest();
xhr.upload.addEventListener('progress', (event) => {
  if (event.lengthComputable) {
    const percent = Math.round((event.loaded / event.total) * 100);
    setProgress(percent);
  }
});
xhr.open('PUT', presignedUrl);
xhr.setRequestHeader('Content-Type', file.type);
xhr.send(file);
```

## CDN Serving

- Serve uploaded files through CloudFront, Cloudflare R2, or imgproxy.
- Use signed URLs for private files with short expiration (1 hour).
- Set `Cache-Control: public, max-age=31536000, immutable` for content-addressed files.
- Use image CDN (Cloudinary, imgix, or self-hosted imgproxy) for on-the-fly transformations.
