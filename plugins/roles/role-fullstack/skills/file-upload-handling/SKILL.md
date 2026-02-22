---
name: file-upload-handling
description: |
  Implement file upload flows: multipart uploads, presigned URLs (S3, GCS),
  image processing with Sharp, progress indicators, drag-and-drop UI,
  file type validation, size limits, virus scanning, and CDN serving.
allowed-tools: Read, Grep, Glob, Bash
---

# File Upload Handling

## When to Use

Activate when implementing file upload functionality -- profile pictures, document attachments, media galleries, bulk imports, or any feature involving user-submitted files.

## Upload Strategy Selection

| Strategy           | Max Size  | Resumable | Best For                          |
|--------------------|-----------|-----------|-----------------------------------|
| Multipart form     | ~10 MB    | No        | Small files, simple forms         |
| Presigned URL (S3) | 5 GB      | No        | Direct-to-cloud, large files      |
| Multipart upload (S3)| 5 TB    | Yes       | Very large files, unreliable networks |
| tus protocol       | Unlimited | Yes       | Resumable uploads, poor connectivity |

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

## Image Processing (Sharp)

- Resize on upload: generate thumbnails (150x150), medium (800x600), and original.
- Convert to WebP or AVIF for smaller file sizes with quality 80.
- Strip EXIF metadata for privacy (Sharp does this by default on resize).
- Process asynchronously in a background job (Bull/BullMQ) for large batches.

## Drag-and-Drop UI

- Use `react-dropzone` or the native HTML5 Drag and Drop API.
- Show a drop zone with visual feedback (border highlight, icon change).
- Display file previews (image thumbnails, file type icons) before upload.
- Show individual progress bars per file with cancel capability.

## File Validation

### Client-Side (UX only, never trust)
- Check file extension and MIME type against an allowlist.
- Enforce size limits before initiating the upload.
- Show immediate feedback for rejected files.

### Server-Side (Security enforcement)
- Validate MIME type by reading file magic bytes (not the `Content-Type` header).
- Enforce size limits at the API and storage layer.
- Scan for malware using ClamAV or a cloud scanning service.
- Rename files to UUIDs to prevent path traversal and naming collisions.

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

## Common Pitfalls

- Trusting client-reported file types -- always validate server-side with magic bytes.
- Storing files on the application server filesystem -- always use object storage (S3, GCS, R2).
- Not limiting concurrent uploads -- cap at 3-5 parallel uploads to avoid overwhelming the browser.
- Missing cleanup for orphaned uploads -- run a periodic job to delete unreferenced files.
- Forgetting CORS configuration on the storage bucket for presigned URL uploads.
