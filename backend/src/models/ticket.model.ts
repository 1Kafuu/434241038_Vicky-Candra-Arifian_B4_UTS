import { supabaseAdmin } from '../config/db';

export enum TicketStatus {
  open = 'Open',
  assigned = 'Assigned',
  in_progress = 'In Progress',
  pending = 'Pending',
  resolved = 'Resolved',
  closed = 'Closed'
}

export enum TicketPriority {
  low = 'Low',
  medium = 'Medium',
  high = 'High',
  urgent = 'Urgent'
}

export interface Ticket {
  id: string;
  title: string;
  description: string;
  status: TicketStatus;
  priority: TicketPriority;
  userId: string;
  assignedTo?: string;
  createdAt: string;
  updatedAt?: string;
  resolvedAt?: string;
  attachments: string[];
}

// Shape of the tickets table row in Supabase
export interface TicketRow {
  id: string;
  title: string;
  description: string;
  status: string;
  priority: string;
  user_id: string;
  assigned_to: string | null;
  created_at: string;
  updated_at: string | null;
  resolved_at: string | null;
  attachments: string[];
}

// Request body for POST /api/tickets
export interface CreateTicketRequest {
  title: string;
  description: string;
  priority?: TicketPriority;
}

// Request body for PUT /api/tickets/:id/status
export interface UpdateStatusRequest {
  status: TicketStatus.in_progress | TicketStatus.pending | TicketStatus.open | TicketStatus.resolved;
}

// Request body for POST /api/tickets/:id/assign
export interface AssignTicketRequest {
  assignedTo?: string | null;
}

// Helper — maps Supabase row to Ticket interface
export function mapToTicket(row: TicketRow): Ticket {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    status: row.status as TicketStatus,
    priority: row.priority as TicketPriority,
    userId: row.user_id,
    assignedTo: row.assigned_to ?? undefined,
    createdAt: row.created_at,
    updatedAt: row.updated_at ?? undefined,
    resolvedAt: row.resolved_at ?? undefined,
    attachments: row.attachments ?? [],
  };
}

export const ticketModel = {
  async addAttachment(ticketId: string, url: string): Promise<Ticket> {
    // Get current attachments
    const { data: current, error: fetchError } = await supabaseAdmin
      .from('tickets')
      .select('attachments')
      .eq('id', ticketId)
      .maybeSingle();

    if (fetchError) throw fetchError;
    if (!current) throw new Error('Ticket not found');

    const attachments = current?.attachments || [];
    attachments.push(url);

    const { data, error } = await supabaseAdmin
      .from('tickets')
      .update({ attachments, updated_at: new Date().toISOString() })
      .eq('id', ticketId)
      .select()
      .single();

    if (error) throw error;
    return mapToTicket(data);
  },
};