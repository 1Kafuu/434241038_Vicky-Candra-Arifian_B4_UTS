import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import {
  getTickets,
  getTicketById,
  createTicket,
  assignTicket,
  updateTicketStatus,
  resolveTicket,
  getTicketHistory,
} from '../controllers/ticket.controller';
import {
  getComments,
  addComment,
  deleteComment,
} from '../controllers/comment.controller';

const router = Router();

// GET /tickets - List tickets (filtered by role)
router.get('/', authMiddleware, getTickets);

// GET /tickets/:id - Get ticket detail
router.get('/:id', authMiddleware, getTicketById);

// POST /tickets - Create new ticket (User only)
router.post('/', authMiddleware, createTicket);

// POST /tickets/:id/assign - Assign helpdesk (Admin only)
router.post('/:id/assign', authMiddleware, assignTicket);

// PUT /tickets/:id/status - Update status (Helpdesk for assigned tickets)
router.put('/:id/status', authMiddleware, updateTicketStatus);

// POST /tickets/:id/resolve - Resolve ticket (Admin only)
router.post('/:id/resolve', authMiddleware, resolveTicket);

// GET /tickets/:id/history - Get ticket history
router.get('/:id/history', authMiddleware, getTicketHistory);

// ─── Comments ─────────────────────────────────────────────────────────────────

// GET /tickets/:id/comments - Get all comments
router.get('/:id/comments', authMiddleware, getComments);

// POST /tickets/:id/comments - Add comment
router.post('/:id/comments', authMiddleware, addComment);

// DELETE /tickets/:id/comments/:commentId - Delete comment
router.delete('/:id/comments/:commentId', authMiddleware, deleteComment);

export default router;