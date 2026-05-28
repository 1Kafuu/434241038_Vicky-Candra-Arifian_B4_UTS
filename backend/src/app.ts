import express from 'express';
import cors from 'cors';
import * as dotenv from 'dotenv';
import authRoutes from './routes/auth.routes';
import ticketRoutes from './routes/ticket.routes';
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

app.use('/api/auth', authRoutes);
app.use('/api/tickets', ticketRoutes);

// ─── Health Check ─────────────────────────────────────────────────────────────

app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// ─── Global Error Handler ─────────────────────────────────────────────────────

// Must be registered LAST, after all routes
app.use(errorHandler);

export default app;
