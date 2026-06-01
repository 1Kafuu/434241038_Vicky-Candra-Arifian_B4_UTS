import path from 'path';
import fs from 'fs';
import sharp from 'sharp';

// Konfigurasi folder uploads
const UPLOAD_DIR = path.join(process.cwd(), 'uploads', 'attachments');

// Pastikan folder ada
if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

export const storageConfig = {
  // Folder untuk menyimpan file
  uploadDir: UPLOAD_DIR,

  // Base URL untuk akses file (bisa diganti ke CDN/Supabase Storage)
  baseUrl: process.env.BASE_URL || 'http://192.168.49.116:3000/uploads/attachments',

  // Max file size: 10MB
  maxFileSize: 10 * 1024 * 1024,

  // Allowed mime types
  allowedMimeTypes: [
    'image/jpeg',
    'image/png',
    'image/webp',
    'text/plain',
  ],

  // Generate unique filename
  generateFilename(originalName: string): string {
    const ext = path.extname(originalName);
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8);
    return `${timestamp}-${random}${ext}`;
  },

  // Compress image jika needed (untuk jpg/png max 1200px)
  async compressImage(inputPath: string, outputPath: string): Promise<void> {
    const ext = path.extname(inputPath).toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.webp'].includes(ext)) {
      await sharp(inputPath)
        .resize(1200, 1200, {
          fit: 'inside',
          withoutEnlargement: true,
        })
        .jpeg({ quality: 80 })
        .png({ compressionLevel: 9 })
        .toFile(outputPath);
    } else {
      // Bukan image, copy aja
      fs.copyFileSync(inputPath, outputPath);
    }
  },

  // Build URL untuk akses
  getFileUrl(filename: string): string {
    return `${this.baseUrl}/${filename}`;
  },
};