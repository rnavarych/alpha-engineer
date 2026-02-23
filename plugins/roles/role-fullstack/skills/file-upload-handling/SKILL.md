---
name: file-upload-handling
description: Implement file upload flows with presigned URLs (S3, GCS, R2), multipart/tus resumable uploads, Sharp image processing, drag-and-drop UI with progress indicators, server-side MIME validation via magic bytes, virus scanning, and CDN serving. Use when adding profile pictures, document attachments, media galleries, or any user-submitted file feature.
allowed-tools: Read, Grep, Glob, Bash
---

# File Upload Handling

## When to use
- Implementing profile picture or avatar upload
- Building document attachment or media gallery features
- Handling bulk file imports or exports
- Adding drag-and-drop upload UX with progress feedback
- Setting up CDN serving for uploaded assets
- Adding virus scanning or strict file type enforcement

## Core principles
1. **Never trust client-reported types** — always validate MIME type server-side by reading magic bytes, not the `Content-Type` header
2. **Presigned URLs over server proxy** — upload directly from client to S3/GCS; never stream file bytes through the application server
3. **Rename to UUIDs** — strip original filenames entirely to prevent path traversal, collisions, and enumeration attacks
4. **Process media asynchronously** — run Sharp resizing and format conversion in BullMQ jobs, not in the request handler
5. **Clean up orphans** — run a periodic job to delete uploads unreferenced in the database; storage costs compound silently

## Reference Files

- `references/upload-strategies.md` — strategy selection table (multipart form vs presigned URL vs tus), presigned URL flow steps, AWS SDK v3 code example, progress indicator with XMLHttpRequest, CDN serving with signed URLs and cache headers
- `references/validation-security.md` — client-side vs server-side validation responsibilities, magic byte MIME checking, ClamAV/cloud malware scanning, Sharp image processing pipeline, react-dropzone UI patterns, common pitfalls
