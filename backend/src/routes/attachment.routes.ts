import { Router } from 'express';
import { attachmentController, uploadMiddleware } from '../controllers/attachment.controller';

const router = Router();

// POST /api/tickets/:id/attachments - Upload attachment
router.post('/tickets/:id/attachments', uploadMiddleware, attachmentController.upload);

// GET /api/tickets/:id/attachments - Get attachments list
router.get('/tickets/:id/attachments', attachmentController.listByTicket);

// DELETE /api/attachments?ticketId=:id&url=:url - Delete attachment
router.delete('/attachments', attachmentController.delete);

export default router;