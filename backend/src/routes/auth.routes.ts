import { Router } from 'express';
import { register, login, me, logout } from '../controllers/auth.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();

// Public routes — no token needed
router.post('/register', register);
router.post('/login', login);

// Protected routes — token required
router.get('/me', authMiddleware, me);
router.post('/logout', authMiddleware, logout);

export default router;
