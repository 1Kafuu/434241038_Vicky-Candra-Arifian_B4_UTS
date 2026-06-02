import { Request, Response } from 'express';
import { supabase } from '../config/db';
import { Ticket, TicketStatus, TicketPriority, mapToTicket, CreateTicketRequest, UpdateStatusRequest, AssignTicketRequest } from '../models/ticket.model';
import { mapToTicketHistory, TicketHistory } from '../models/ticket_history.model';
import { User } from '../models/user.model';

// GET /tickets - List tickets (filtered by role)
export async function getTickets(req: Request, res: Response) {
  try {
    const user = (req as any).user as User;
    
    let query = supabase
      .from('tickets')
      .select('*')
      .order('created_at', { ascending: false });

    // Filter berdasarkan role
    if (user.role === 'user') {
      // User hanya bisa lihat ticket miliknya
      query = query.eq('user_id', user.id);
    } else if (user.role === 'helpdesk') {
      // Helpdesk bisa lihat ticket yang di-assign ke dia ATAU yang belum di-assign
      query = query.or(`assigned_to.eq.${user.id},assigned_to.is.null`);
    }
    // Admin bisa lihat semua

    const { data, error } = await query;

    if (error) throw error;

    const tickets = data.map(mapToTicket);
    res.json({ success: true, data: tickets });
  } catch (error: any) {
    console.error('Error fetching tickets:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// GET /tickets/:id - Get ticket detail
export async function getTicketById(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const user = (req as any).user as User;

    const { data, error } = await supabase
      .from('tickets')
      .select('*')
      .eq('id', id)
      .single();

    if (error) throw error;
    if (!data) {
      return res.status(404).json({ success: false, message: 'Ticket not found' });
    }

    const ticket = mapToTicket(data);

    // Check access
    if (user.role === 'user' && ticket.userId !== user.id) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }
    if (user.role === 'helpdesk' && ticket.assignedTo !== user.id && ticket.assignedTo) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    res.json({ success: true, data: ticket });
  } catch (error: any) {
    console.error('Error fetching ticket:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// POST /tickets - Create new ticket (User only)
export async function createTicket(req: Request, res: Response) {
  try {
    const user = (req as any).user as User;
    const body = req.body as CreateTicketRequest;

    if (!body.title || !body.description) {
      return res.status(400).json({ success: false, message: 'Title and description are required' });
    }

    const { data, error } = await supabase
      .from('tickets')
      .insert({
        title: body.title,
        description: body.description,
        status: TicketStatus.open,
        priority: body.priority || TicketPriority.medium,
        user_id: user.id,
      })
      .select()
      .single();

    if (error) throw error;

    const ticket = mapToTicket(data);
    res.status(201).json({ success: true, data: ticket });
  } catch (error: any) {
    console.error('Error creating ticket:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// POST /tickets/:id/assign - Assign helpdesk to ticket (Admin only)
export async function assignTicket(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const user = (req as any).user as User;
    const body = req.body as AssignTicketRequest;

    if (user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Only admin can assign tickets' });
    }

    // Get current ticket
    const { data: currentTicket, error: fetchError } = await supabase
      .from('tickets')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError) throw fetchError;
    if (!currentTicket) {
      return res.status(404).json({ success: false, message: 'Ticket not found' });
    }

    const isUnassign = !body.assignedTo;
    const newStatus = isUnassign ? TicketStatus.open : TicketStatus.assigned;

    // Record history
    await supabase.from('ticket_history').insert({
      ticket_id: id,
      changed_by: user.id,
      old_status: currentTicket.status,
      new_status: newStatus,
    });

    // Update ticket
    const updateData: any = {
      assigned_to: isUnassign ? null : body.assignedTo,
      status: newStatus,
      updated_at: new Date().toISOString(),
    };
    if (isUnassign) {
      updateData.resolved_at = null;
    }

    const { data, error } = await supabase
      .from('tickets')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    const ticket = mapToTicket(data);
    res.json({ success: true, data: ticket });
  } catch (error: any) {
    console.error('Error assigning ticket:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// PUT /tickets/:id/status - Update status (Helpdesk only for assigned tickets)
export async function updateTicketStatus(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const user = (req as any).user as User;
    const body = req.body as UpdateStatusRequest;

    // Get current ticket
    const { data: currentTicket, error: fetchError } = await supabase
      .from('tickets')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError) throw fetchError;
    if (!currentTicket) {
      return res.status(404).json({ success: false, message: 'Ticket not found' });
    }

    // Check permission
    if (user.role === 'helpdesk') {
      // Helpdesk hanya bisa update ticket yang di-assign ke dia
      if (currentTicket.assigned_to !== user.id) {
        return res.status(403).json({ success: false, message: 'You can only update tickets assigned to you' });
      }
      // Helpdesk hanya bisa ubah ke in_progress atau pending
      if (body.status !== TicketStatus.in_progress && body.status !== TicketStatus.pending) {
        return res.status(403).json({ success: false, message: 'You can only update to in_progress or pending' });
      }
    } else if (user.role === 'admin') {
      // Admin bisa update in_progress, pending, atau reopen (open)
      // Untuk resolve/close, gunakan /resolve endpoint
      if (body.status !== TicketStatus.in_progress && body.status !== TicketStatus.pending && body.status !== TicketStatus.open) {
        return res.status(403).json({ success: false, message: 'Use /resolve endpoint to close ticket' });
      }
    } else {
      return res.status(403).json({ success: false, message: 'Users cannot update ticket status' });
    }

    // Record history
    await supabase.from('ticket_history').insert({
      ticket_id: id,
      changed_by: user.id,
      old_status: currentTicket.status,
      new_status: body.status,
    });

    // Update ticket — clear resolved_at when reopening
    const updateData: any = {
      status: body.status,
      updated_at: new Date().toISOString(),
    };
    if (body.status === TicketStatus.open) {
      updateData.resolved_at = null;
    }

    const { data, error } = await supabase
      .from('tickets')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    const ticket = mapToTicket(data);
    res.json({ success: true, data: ticket });
  } catch (error: any) {
    console.error('Error updating ticket status:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// POST /tickets/:id/resolve - Resolve/close ticket (Admin only)
export async function resolveTicket(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const user = (req as any).user as User;

    if (user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Only admin can resolve tickets' });
    }

    // Get current ticket
    const { data: currentTicket, error: fetchError } = await supabase
      .from('tickets')
      .select('*')
      .eq('id', id)
      .single();

    if (fetchError) throw fetchError;
    if (!currentTicket) {
      return res.status(404).json({ success: false, message: 'Ticket not found' });
    }

    const now = new Date().toISOString();

    // Record history
    await supabase.from('ticket_history').insert({
      ticket_id: id,
      changed_by: user.id,
      old_status: currentTicket.status,
      new_status: TicketStatus.resolved,
    });

    // Update ticket
    const { data, error } = await supabase
      .from('tickets')
      .update({
        status: TicketStatus.resolved,
        resolved_at: now,
        updated_at: now,
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    const ticket = mapToTicket(data);
    res.json({ success: true, data: ticket });
  } catch (error: any) {
    console.error('Error resolving ticket:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// GET /tickets/:id/history - Get ticket history
export async function getTicketHistory(req: Request, res: Response) {
  try {
    const { id } = req.params;
    const user = (req as any).user as User;

    // Get ticket first to check access
    const { data: ticket, error: ticketError } = await supabase
      .from('tickets')
      .select('*')
      .eq('id', id)
      .single();

    if (ticketError) throw ticketError;
    if (!ticket) {
      return res.status(404).json({ success: false, message: 'Ticket not found' });
    }

    // Check access
    if (user.role === 'user' && ticket.user_id !== user.id) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }
    if (user.role === 'helpdesk' && ticket.assigned_to !== user.id && ticket.assigned_to) {
      return res.status(403).json({ success: false, message: 'Access denied' });
    }

    // Get history
    const { data, error } = await supabase
      .from('ticket_history')
      .select('*')
      .eq('ticket_id', id)
      .order('created_at', { ascending: true });

    if (error) throw error;

    const history = data.map(mapToTicketHistory);
    res.json({ success: true, data: history });
  } catch (error: any) {
    console.error('Error fetching ticket history:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}