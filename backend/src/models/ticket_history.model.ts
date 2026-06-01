export interface TicketHistory {
  id: string;
  ticketId: string;
  changedBy: string;
  oldStatus: string | null;
  newStatus: string;
  createdAt: string;
}

// Shape of the ticket_history table row in Supabase
export interface TicketHistoryRow {
  id: string;
  ticket_id: string;
  changed_by: string;
  old_status: string | null;
  new_status: string;
  created_at: string;
}

// Helper — maps Supabase row to TicketHistory interface
export function mapToTicketHistory(row: TicketHistoryRow): TicketHistory {
  return {
    id: row.id,
    ticketId: row.ticket_id,
    changedBy: row.changed_by,
    oldStatus: row.old_status,
    newStatus: row.new_status,
    createdAt: row.created_at,
  };
}