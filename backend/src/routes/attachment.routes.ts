import { Router } from 'express';
import { attachmentController, uploadMiddleware } from '../controllers/attachment.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();

// All attachment routes require authentication
router.use(authMiddleware);

// POST /api/tickets/:id/attachments - Upload attachment
router.post('/tickets/:id/attachments', uploadMiddleware, attachmentController.upload);

export default router;