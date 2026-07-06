import express from 'express';
import cors from 'cors';
import * as dotenv from 'dotenv';
import path from 'path';
import authRoutes from './routes/auth.routes';
import ticketRoutes from './routes/ticket.routes';
import attachmentRoutes from './routes/attachment.routes';
import userRoutes from './routes/user.routes';
import { errorHandler } from './middleware/errorHandler';

dotenv.config();

const app = express();

// ─── Middleware ───────────────────────────────────────────────────────────────

// Parse incoming JSON request bodies
app.use(express.json());

// Allow Flutter app to call this API
app.use(cors({
  origin: '*', // In production, replace with your actual domain
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ─── Routes ───────────────────────────────────────────────────────────────────

// Static files untuk serving uploads
app.use('/uploads', express.static(path.join(process.cwd(), 'uploads')));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/admin', userRoutes);
app.use('/api', attachmentRoutes);

// ─── Health Check ─────────────────────────────────────────────────────────────

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── Config ───────────────────────────────────────────────────────────────────

app.get('/api/config', (_req, res) => {
  res.json({ baseUrl: process.env.API_BASE_URL || `http://localhost:${process.env.PORT || 3000}` });
});

// ─── Global Error Handler ─────────────────────────────────────────────────────

// Must be registered LAST, after all routes
app.use(errorHandler);

export default app;
