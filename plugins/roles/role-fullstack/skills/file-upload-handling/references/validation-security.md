# File Validation and Security

## When to load
Load when implementing file type validation, enforcing size limits, or adding server-side security checks for uploads.

## Client-Side Validation (UX only — never trust)

- Check file extension and MIME type against an allowlist.
- Enforce size limits before initiating the upload.
- Show immediate feedback for rejected files.

## Server-Side Validation (Security enforcement)

- Validate MIME type by reading file magic bytes (not the `Content-Type` header).
- Enforce size limits at the API and storage layer.
- Scan for malware using ClamAV or a cloud scanning service.
- Rename files to UUIDs to prevent path traversal and naming collisions.

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

## Common Pitfalls

- Trusting client-reported file types — always validate server-side with magic bytes.
- Storing files on the application server filesystem — always use object storage (S3, GCS, R2).
- Not limiting concurrent uploads — cap at 3-5 parallel uploads to avoid overwhelming the browser.
- Missing cleanup for orphaned uploads — run a periodic job to delete unreferenced files.
- Forgetting CORS configuration on the storage bucket for presigned URL uploads.
