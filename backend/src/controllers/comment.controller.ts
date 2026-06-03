import { Request, Response } from 'express';
import { supabaseAdmin } from '../config/db';
import { Comment, mapToComment, CreateCommentRequest } from '../models/comment.model';
import { User } from '../models/user.model';

// GET /tickets/:id/comments - Get all comments for a ticket
export async function getComments(req: Request, res: Response) {
  try {
    const { id: ticketId } = req.params;
    const user = (req as any).user as User;

    // Check ticket exists and user has access
    const { data: ticket, error: ticketError } = await supabaseAdmin
      .from('tickets')
      .select('*')
      .eq('id', ticketId)
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

    // Get comments with user info
    const { data: comments, error } = await supabaseAdmin
      .from('comments')
      .select('*')
      .eq('ticket_id', ticketId)
      .order('timestamp', { ascending: true });

    if (error) throw error;

    // Get all unique sender IDs from comments
    const senderIds = [...new Set(comments.map(c => c.sender_id))];
    
    // Fetch user names
    const { data: profiles } = await supabaseAdmin
      .from('profiles')
      .select('id, name')
      .in('id', senderIds);

    const userNameMap = new Map(profiles?.map(p => [p.id, p.name]) || []);

    const result = comments.map(c => ({
      ...mapToComment(c),
      senderName: userNameMap.get(c.sender_id) || 'Unknown',
    }));
    res.json({ success: true, data: result });
  } catch (error: any) {
    console.error('Error fetching comments:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// POST /tickets/:id/comments - Add comment to ticket
export async function addComment(req: Request, res: Response) {
  try {
    const { id: ticketId } = req.params;
    const user = (req as any).user as User;
    const body = req.body as CreateCommentRequest;

    if (!body.message || body.message.trim() === '') {
      return res.status(400).json({ success: false, message: 'Message is required' });
    }

    // Check ticket exists and user has access
    const { data: ticket, error: ticketError } = await supabaseAdmin
      .from('tickets')
      .select('*')
      .eq('id', ticketId)
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

    // If replying to a comment, verify parent exists
    if (body.parentCommentId) {
      const { data: parentComment } = await supabaseAdmin
        .from('comments')
        .select('id')
        .eq('id', body.parentCommentId)
        .single();

      if (!parentComment) {
        return res.status(400).json({ success: false, message: 'Parent comment not found' });
      }
    }

    // Create comment
    const { data, error } = await supabaseAdmin
      .from('comments')
      .insert({
        ticket_id: ticketId,
        sender_id: user.id,
        sender_name: user.name,
        message: body.message,
        parent_comment_id: body.parentCommentId || null,
      })
      .select()
      .single();

    if (error) throw error;

    const comment = {
      ...mapToComment(data),
      senderName: user.name,
    };
    res.status(201).json({ success: true, data: comment });
  } catch (error: any) {
    console.error('Error adding comment:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}

// DELETE /tickets/:id/comments/:commentId - Delete comment
export async function deleteComment(req: Request, res: Response) {
  try {
    const { id: ticketId, commentId } = req.params;
    const user = (req as any).user as User;

    // Get comment
    const { data: comment, error: fetchError } = await supabaseAdmin
      .from('comments')
      .select('*')
      .eq('id', commentId)
      .eq('ticket_id', ticketId)
      .single();

    if (fetchError) throw fetchError;
    if (!comment) {
      return res.status(404).json({ success: false, message: 'Comment not found' });
    }

    // Check permission: only comment owner or admin can delete
    if (user.role !== 'admin' && comment.sender_id !== user.id) {
      return res.status(403).json({ success: false, message: 'You can only delete your own comments' });
    }

    // Delete comment
    const { error } = await supabaseAdmin
      .from('comments')
      .delete()
      .eq('id', commentId);

    if (error) throw error;

    res.json({ success: true, message: 'Comment deleted' });
  } catch (error: any) {
    console.error('Error deleting comment:', error);
    res.status(500).json({ success: false, message: error.message });
  }
}