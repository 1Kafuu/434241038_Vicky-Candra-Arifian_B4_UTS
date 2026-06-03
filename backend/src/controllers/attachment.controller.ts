import { Request, Response } from 'express';
import multer from 'multer';
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

};