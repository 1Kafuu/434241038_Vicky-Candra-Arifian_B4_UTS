-- ============================================================
-- E-Ticketing Helpdesk - Database Schema
-- Supabase (PostgreSQL)
-- ============================================================

-- ============================================================
-- profiles
-- Stores user profile data linked to Supabase Auth.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid NOT NULL PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  role text NOT NULL DEFAULT 'user',
  profile_image text,
  created_at timestamp with time zone DEFAULT now()
);

-- ============================================================
-- tickets
-- Main ticket storage.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  status text NOT NULL DEFAULT 'Open',
  priority text NOT NULL DEFAULT 'Medium',
  user_id uuid NOT NULL REFERENCES public.profiles(id),
  assigned_to uuid REFERENCES public.profiles(id),
  attachments text[] DEFAULT '{}',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone,
  resolved_at timestamp with time zone,
  CONSTRAINT tickets_pkey PRIMARY KEY (id)
);

-- ============================================================
-- comments
-- Ticket comments with nested reply support.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES public.profiles(id),
  sender_name text NOT NULL,
  message text NOT NULL,
  parent_comment_id uuid REFERENCES public.comments(id) ON DELETE CASCADE,
  timestamp timestamp with time zone DEFAULT now(),
  CONSTRAINT comments_pkey PRIMARY KEY (id)
);

-- ============================================================
-- ticket_history
-- Audit log of all ticket actions.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ticket_history (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  action text NOT NULL,
  description text NOT NULL,
  updated_by uuid NOT NULL REFERENCES public.profiles(id),
  timestamp timestamp with time zone DEFAULT now(),
  CONSTRAINT ticket_history_pkey PRIMARY KEY (id)
);

-- ============================================================
-- password_reset_otps
-- OTP storage for password reset flow.
-- ============================================================
CREATE TABLE IF NOT EXISTS public.password_reset_otps (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email text NOT NULL,
  otp text NOT NULL,
  expires_at timestamp with time zone NOT NULL,
  used_at timestamp with time zone NULL,
  created_at timestamp with time zone DEFAULT now()
);

-- Indexes for password_reset_otps
CREATE INDEX IF NOT EXISTS idx_password_reset_otps_email
  ON public.password_reset_otps USING btree (email);

CREATE INDEX IF NOT EXISTS idx_password_reset_otps_otp
  ON public.password_reset_otps USING btree (otp);

-- ============================================================
-- Indexes for tickets
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_tickets_user_id
  ON public.tickets USING btree (user_id);

CREATE INDEX IF NOT EXISTS idx_tickets_assigned_to
  ON public.tickets USING btree (assigned_to);

CREATE INDEX IF NOT EXISTS idx_tickets_status
  ON public.tickets USING btree (status);

CREATE INDEX IF NOT EXISTS idx_tickets_created_at
  ON public.tickets USING btree (created_at DESC);

-- ============================================================
-- Indexes for comments
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_comments_ticket_id
  ON public.comments USING btree (ticket_id);

CREATE INDEX IF NOT EXISTS idx_comments_sender_id
  ON public.comments USING btree (sender_id);

CREATE INDEX IF NOT EXISTS idx_comments_parent_comment_id
  ON public.comments USING btree (parent_comment_id);

-- ============================================================
-- Indexes for ticket_history
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_ticket_history_ticket_id
  ON public.ticket_history USING btree (ticket_id);

CREATE INDEX IF NOT EXISTS idx_ticket_history_timestamp
  ON public.ticket_history USING btree (timestamp DESC);

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.password_reset_otps ENABLE ROW LEVEL SECURITY;

-- profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- tickets policies
CREATE POLICY "Users can view own tickets"
  ON public.tickets FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Helpdesk can view assigned tickets"
  ON public.tickets FOR SELECT USING (auth.uid() = assigned_to);

CREATE POLICY "Admins can view all tickets"
  ON public.tickets FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can insert own tickets"
  ON public.tickets FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Helpdesk can update assigned tickets"
  ON public.tickets FOR UPDATE
  USING (auth.uid() = assigned_to OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- comments policies
CREATE POLICY "Ticket participants can view comments"
  ON public.comments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.tickets
      WHERE id = ticket_id AND (user_id = auth.uid() OR assigned_to = auth.uid())
    ) OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Ticket participants can insert comments"
  ON public.comments FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tickets
      WHERE id = ticket_id AND (user_id = auth.uid() OR assigned_to = auth.uid())
    )
  );

CREATE POLICY "Comment owners and admins can delete comments"
  ON public.comments FOR DELETE
  USING (sender_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ticket_history policies
CREATE POLICY "Users can view history of own tickets"
  ON public.ticket_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.tickets
      WHERE id = ticket_id AND user_id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM public.tickets t
      JOIN public.profiles p ON t.assigned_to = p.id
      WHERE t.id = ticket_id AND p.id = auth.uid()
    ) OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- password_reset_otps - no RLS needed (server-side only)

-- ============================================================
-- Database Trigger: Auto-create profile on user signup
-- ============================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'Unknown'),
    COALESCE(new.raw_user_meta_data->>'role', 'user')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
