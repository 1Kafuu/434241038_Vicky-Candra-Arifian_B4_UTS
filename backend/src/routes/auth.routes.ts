import { Router } from 'express';
import { register, login, me, logout, getHelpdesks } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();

// Public routes — no token needed
router.post('/register', register);
router.post('/login', login);

// Protected routes — token required
router.get('/me', authMiddleware, me);
router.get('/helpdesks', authMiddleware, getHelpdesks);
router.post('/logout', authMiddleware, logout);

export default router;
