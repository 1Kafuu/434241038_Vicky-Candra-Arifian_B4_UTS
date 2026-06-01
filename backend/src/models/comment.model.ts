export interface Comment {
  id: string;
  ticketId: string;
  senderId: string;
  senderName?: string;
  message: string;
  parentCommentId?: string;
  createdAt: string;
}

// Shape of the comments table row in Supabase
export interface CommentRow {
  id: string;
  ticket_id: string;
  sender_id: string;
  sender_name: string;
  message: string;
  parent_comment_id: string | null;
  timestamp: string;
}

// Request body for POST /api/tickets/:id/comments
export interface CreateCommentRequest {
  message: string;
  parentCommentId?: string;
}

// Helper — maps Supabase row to Comment interface
export function mapToComment(row: CommentRow): Comment {
  return {
    id: row.id,
    ticketId: row.ticket_id,
    senderId: row.sender_id,
    senderName: row.sender_name,
    message: row.message,
    parentCommentId: row.parent_comment_id ?? undefined,
    createdAt: row.timestamp,
  };
}