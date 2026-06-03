export interface TicketHistory {
  id: string;
  ticketId: string;
  action: string;
  description: string;
  updatedBy: string;       // UUID actor
  updatedByName: string;   // nama actor (dari join profiles)
  timestamp: string;
}

// Shape of the ticket_history table row in Supabase (+ optional join)
export interface TicketHistoryRow {
  id: string;
  ticket_id: string;
  action: string;
  description: string;
  updated_by: string;
  timestamp: string;
  profiles?: { name: string } | null; // hasil join profiles!updated_by(name)
}

// Helper — maps Supabase row to TicketHistory interface
export function mapToTicketHistory(row: TicketHistoryRow): TicketHistory {
  return {
    id: row.id,
    ticketId: row.ticket_id,
    action: row.action,
    description: row.description,
    updatedBy: row.updated_by,
    updatedByName: row.profiles?.name ?? 'Unknown',
    timestamp: row.timestamp,
  };
}
