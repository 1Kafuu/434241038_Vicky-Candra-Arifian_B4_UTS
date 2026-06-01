import { Request, Response } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { storageConfig } from '../config/storage';
import { ticketModel } from '../models/ticket.model';

// Konfigurasi multer
const upload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => {
      cb(null, storageConfig.uploadDir);
    },
    filename: (_req, file, cb) => {
      const filename = storageConfig.generateFilename(file.originalname);
      cb(null, filename);
    },
  }),
  limits: {
    fileSize: storageConfig.maxFileSize,
  },
  fileFilter: (_req, file, cb) => {
    if (storageConfig.allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`File type not allowed. Allowed: ${storageConfig.allowedMimeTypes.join(', ')}`));
    }
  },
});

// Middleware untuk upload single file
export const uploadMiddleware = upload.single('file');

export const attachmentController = {
  // POST /api/tickets/:id/attachments - Upload attachment
  async upload(req: Request, res: Response) {
    try {
      const ticketId = req.params.id;
      const file = req.file;

      if (!file) {
        res.status(400).json({ error: 'No file uploaded' });
        return;
      }

      // Build relative path that will be stored in the DB
      const relativePath = `uploads/attachments/${file.filename}`;

      // Store the relative path in tickets.attachments array
      const ticket = await ticketModel.addAttachment(ticketId, relativePath);

      res.status(201).json({
        message: 'File uploaded successfully',
        attachments: ticket.attachments,
      });
    } catch (error: any) {
      console.error('Upload error:', error);
      res.status(500).json({ error: error.message });
    }
  },

  // GET /api/tickets/:id/attachments - Get attachments list
  async listByTicket(req: Request, res: Response) {
    try {
      const ticketId = req.params.id;

      const { data, error } = await (await import('../config/db')).supabase
        .from('tickets')
        .select('attachments')
        .eq('id', ticketId)
        .single();

      if (error) throw error;

      res.json({
        attachments: data?.attachments || [],
      });
    } catch (error: any) {
      console.error('List error:', error);
      res.status(500).json({ error: error.message });
    }
  },

  // DELETE /api/attachments/:id - Delete attachment by URL
  async delete(req: Request, res: Response) {
    try {
      const { ticketId, url } = req.query as { ticketId: string; url: string };

      if (!ticketId || !url) {
        res.status(400).json({ error: 'ticketId and url are required' });
        return;
      }

      // Ambil filename dari URL
      const filename = path.basename(url);
      const filePath = path.join(storageConfig.uploadDir, filename);

      // Hapus file dari disk jika ada
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }

      // Hapus dari array di tickets
      await ticketModel.removeAttachment(ticketId, url);

      res.json({ message: 'Attachment deleted successfully' });
    } catch (error: any) {
      console.error('Delete error:', error);
      res.status(500).json({ error: error.message });
    }
  },
};