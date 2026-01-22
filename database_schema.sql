-- =====================================================
-- FINAL 1-ON-1 CHAT SCHEMA WITH DELIVERED + READ
-- =====================================================

-- =====================
-- 1. EXTENSIONS
-- =====================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================
-- 2. ENUMS
-- =====================
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='user_status') THEN
    CREATE TYPE public.user_status AS ENUM ('ONLINE','OFFLINE');
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='message_type') THEN
    CREATE TYPE public.message_type AS ENUM ('TEXT','IMAGE','AUDIO','FILE','SYSTEM');
  END IF;
END $$;

-- =====================
-- 3. PROFILES
-- =====================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  avatar_color INT NOT NULL DEFAULT (floor(random()*16777215)::int + 4278190080),
  status public.user_status DEFAULT 'OFFLINE',
  last_seen TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_profiles_username ON public.profiles(username);

-- =====================
-- 4. PRIVATE CHATS
-- =====================
CREATE TABLE public.private_chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_one UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_two UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message_id UUID,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX idx_unique_private_chat
ON public.private_chats (
  LEAST(user_one, user_two),
  GREATEST(user_one, user_two)
);

-- =====================
-- 5. CHAT PARTICIPANTS
-- =====================
CREATE TABLE public.chat_participants (
  chat_id UUID REFERENCES public.private_chats(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- DELIVERY & READ STATE
  last_delivered_message_id UUID,
  last_read_message_id UUID,

  unread_count INT DEFAULT 0,

  PRIMARY KEY (chat_id,user_id)
);

-- =====================
-- 6. MESSAGES
-- =====================
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.private_chats(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  content TEXT,
  type public.message_type DEFAULT 'TEXT',
  reply_to_message_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_messages_chat_time
ON public.messages(chat_id, created_at DESC);

-- =====================
-- 7. MESSAGE REACTIONS
-- =====================
CREATE TABLE public.message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (message_id,user_id,emoji)
);

-- =====================
-- 8. HELPER FUNCTIONS
-- =====================
CREATE OR REPLACE FUNCTION public.is_chat_member(p_chat UUID, p_user UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.chat_participants
    WHERE chat_id=p_chat AND user_id=p_user
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path=public;

-- =====================
-- 9. CHAT LOGIC
-- =====================

-- Get or create chat
CREATE OR REPLACE FUNCTION public.get_or_create_private_chat(p_other UUID)
RETURNS UUID AS $$
DECLARE
  v_chat UUID;
  v_me UUID := auth.uid();
BEGIN
  SELECT id INTO v_chat
  FROM public.private_chats
  WHERE LEAST(user_one,user_two)=LEAST(v_me,p_other)
    AND GREATEST(user_one,user_two)=GREATEST(v_me,p_other)
  LIMIT 1;

  IF v_chat IS NOT NULL THEN
    RETURN v_chat;
  END IF;

  INSERT INTO public.private_chats(user_one,user_two)
  VALUES (v_me,p_other)
  RETURNING id INTO v_chat;

  INSERT INTO public.chat_participants(chat_id,user_id)
  VALUES (v_chat,v_me),(v_chat,p_other);

  RETURN v_chat;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path=public;

-- Mark chat as READ
CREATE OR REPLACE FUNCTION public.mark_chat_read(p_chat UUID)
RETURNS VOID AS $$
DECLARE
  v_last UUID;
BEGIN
  SELECT id INTO v_last
  FROM public.messages
  WHERE chat_id=p_chat
  ORDER BY created_at DESC
  LIMIT 1;

  UPDATE public.chat_participants
  SET last_read_message_id=v_last,
      last_delivered_message_id=v_last,
      unread_count=0
  WHERE chat_id=p_chat AND user_id=auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path=public;

-- Mark message as DELIVERED
CREATE OR REPLACE FUNCTION public.mark_message_delivered(
  p_chat UUID,
  p_message UUID
)
RETURNS VOID AS $$
BEGIN
  UPDATE public.chat_participants
  SET last_delivered_message_id=p_message
  WHERE chat_id=p_chat AND user_id=auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path=public;

-- =====================
-- 10. TRIGGERS
-- =====================
CREATE OR REPLACE FUNCTION public.on_new_message()
RETURNS trigger AS $$
BEGIN
  -- increase unread for receiver
  UPDATE public.chat_participants
  SET unread_count = unread_count + 1
  WHERE chat_id=NEW.chat_id
    AND user_id <> NEW.sender_id;

  UPDATE public.private_chats
  SET last_message_id=NEW.id
  WHERE id=NEW.chat_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path=public;

CREATE TRIGGER trg_on_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.on_new_message();

-- =====================
-- 11. RLS
-- =====================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- Profiles
CREATE POLICY profiles_read
ON public.profiles FOR SELECT USING (true);

CREATE POLICY profiles_update
ON public.profiles FOR UPDATE USING (auth.uid()=id);

CREATE POLICY profiles_insert
ON public.profiles FOR INSERT WITH CHECK (auth.uid()=id);

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON public.profiles TO anon, authenticated;
GRANT INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT, INSERT ON public.messages TO authenticated;
GRANT SELECT ON public.messages TO anon;

-- Chats
CREATE POLICY chats_read
ON public.private_chats FOR SELECT
USING (user_one=auth.uid() OR user_two=auth.uid());

-- Participants
CREATE POLICY participants_read
ON public.chat_participants FOR SELECT
USING (public.is_chat_member(chat_id, auth.uid()));

-- Messages
CREATE POLICY messages_read
ON public.messages FOR SELECT
USING (public.is_chat_member(chat_id,auth.uid()));

DROP POLICY IF EXISTS messages_send ON public.messages;

CREATE POLICY messages_send
ON public.messages
FOR INSERT
WITH CHECK (
  sender_id = auth.uid()
  AND public.is_chat_member(chat_id, auth.uid())
);
-- Reactions
CREATE POLICY reactions_rw
ON public.message_reactions
FOR ALL
USING (user_id=auth.uid());

-- =====================
-- 12. PRESENCE
-- =====================
CREATE TABLE public.user_presence (
  user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT false,
  active_chat_id UUID REFERENCES public.private_chats(id) ON DELETE SET NULL,
  last_seen TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.handle_user_status(
  p_user_id UUID,
  p_online_status BOOLEAN,
  p_active_chat_id UUID DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO public.user_presence(user_id, is_online, active_chat_id, last_seen, updated_at)
  VALUES (p_user_id, p_online_status, p_active_chat_id, now(), now())
  ON CONFLICT (user_id) DO UPDATE
  SET is_online = EXCLUDED.is_online,
      active_chat_id = EXCLUDED.active_chat_id,
      last_seen = now(),
      updated_at = now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path=public;

ALTER TABLE public.user_presence ENABLE ROW LEVEL SECURITY;

CREATE POLICY user_presence_read
ON public.user_presence FOR SELECT USING (true);

CREATE POLICY user_presence_upsert
ON public.user_presence FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY user_presence_update
ON public.user_presence FOR UPDATE USING (auth.uid() = user_id);

GRANT SELECT, INSERT, UPDATE ON public.user_presence TO authenticated;



-- Relations

CREATE TYPE public.relationship_type AS ENUM ('FRIEND','LOVER');
CREATE TYPE public.relationship_status AS ENUM ('PENDING','ACCEPTED','REJECTED','BLOCKED');

CREATE TABLE public.user_relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  receiver_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

  type public.relationship_type NOT NULL,
  status public.relationship_status DEFAULT 'PENDING',

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),

  CHECK (requester_id <> receiver_id)
);

CREATE UNIQUE INDEX idx_unique_relationship
ON public.user_relationships (
  LEAST(requester_id, receiver_id),
  GREATEST(requester_id, receiver_id)
);

CREATE OR REPLACE FUNCTION public.accept_relationship(p_relationship UUID)
RETURNS UUID AS $$
DECLARE
  v_chat UUID;
  v_other UUID;
BEGIN
  UPDATE public.user_relationships
  SET status='ACCEPTED', updated_at=now()
  WHERE id=p_relationship AND receiver_id=auth.uid();

  SELECT
    CASE
      WHEN requester_id=auth.uid() THEN receiver_id
      ELSE requester_id
    END
  INTO v_other
  FROM public.user_relationships
  WHERE id=p_relationship;

  v_chat := public.get_or_create_private_chat(v_other);

  RETURN v_chat;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.can_chat(p_chat UUID, p_user UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM public.private_chats c
    JOIN public.user_relationships r
      ON (
        LEAST(c.user_one,c.user_two)=LEAST(r.requester_id,r.receiver_id)
        AND GREATEST(c.user_one,c.user_two)=GREATEST(r.requester_id,r.receiver_id)
      )
    WHERE c.id=p_chat
      AND r.status='ACCEPTED'
      AND (r.requester_id=p_user OR r.receiver_id=p_user)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
