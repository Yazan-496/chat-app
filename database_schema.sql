-- ============================================
-- My Chat App - Professional Database Schema (WhatsApp-like)
-- ============================================

-- 1. EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. ENUMS (Custom types for better data integrity)
-- ============================================
DO $$ BEGIN
    CREATE TYPE public.user_status AS ENUM ('ONLINE', 'OFFLINE', 'AWAY');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.chat_type AS ENUM ('PRIVATE', 'GROUP', 'CHANNEL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.message_type AS ENUM ('TEXT', 'IMAGE', 'VIDEO', 'AUDIO', 'FILE', 'SYSTEM');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.participant_role AS ENUM ('OWNER', 'ADMIN', 'MEMBER');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.relation_status AS ENUM ('PENDING', 'ACCEPTED', 'BLOCKED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.relation_type AS ENUM ('FRIEND', 'LOVER');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 3. TABLES
-- ============================================

-- 3.1 PROFILES
-- Stores user information. Linked to auth.users.
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  avatar_color BIGINT DEFAULT (floor(random() * 16777215)::int + 4278190080), -- Fallback color
  about TEXT DEFAULT 'Hey there! I am using My Chat App.',
  status public.user_status DEFAULT 'OFFLINE',
  last_seen TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index for searching users
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);


-- 3.2 CHATS
-- Stores chat rooms (both 1-on-1 and groups).
CREATE TABLE IF NOT EXISTS public.chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type public.chat_type NOT NULL DEFAULT 'PRIVATE',
  name TEXT, -- Null for private chats
  image_url TEXT,
  created_by UUID REFERENCES public.profiles(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(), -- Used for sorting chat list
  last_message_id UUID, -- Forward reference updated via trigger/function
  metadata JSONB DEFAULT '{}'::jsonb -- For extensible settings (e.g., disappearing_messages_duration)
);

-- Index for sorting chats
CREATE INDEX IF NOT EXISTS idx_chats_updated_at ON public.chats(updated_at DESC);


-- 3.3 CHAT PARTICIPANTS
-- Junction table for Users <-> Chats. Stores per-user settings.
CREATE TABLE IF NOT EXISTS public.chat_participants (
  chat_id UUID REFERENCES public.chats(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role public.participant_role DEFAULT 'MEMBER',
  joined_at TIMESTAMPTZ DEFAULT now(),
  last_read_message_id UUID, -- The last message this user has seen
  unread_count INT DEFAULT 0, -- Denormalized counter for UI performance
  is_muted BOOLEAN DEFAULT false,
  is_pinned BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  PRIMARY KEY (chat_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_participants_user ON public.chat_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_participants_chat ON public.chat_participants(chat_id);


-- 3.4 MESSAGES
-- Stores all message content.
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES public.chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE SET NULL,
  content TEXT, -- Can be null for system messages or pure attachments
  type public.message_type DEFAULT 'TEXT',
  metadata JSONB DEFAULT '{}'::jsonb, -- Stores file_url, size, duration, width, height, etc.
  reply_to_message_id UUID REFERENCES public.messages(id) ON DELETE SET NULL,
  is_edited BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false, -- Soft delete
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON public.messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);


-- 3.5 MESSAGE READ RECEIPTS (Granular Status)
-- Tracks exactly who read which message (Blue ticks feature).
-- Note: For high volume, this table grows fast. Clean up old rows if needed.
CREATE TABLE IF NOT EXISTS public.message_read_receipts (
  message_id UUID REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  read_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (message_id, user_id)
);


-- 3.6 MESSAGE REACTIONS
-- Stores emoji reactions.
CREATE TABLE IF NOT EXISTS public.message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(message_id, user_id, emoji) -- Prevent duplicate same-emoji reactions from same user
);

CREATE INDEX IF NOT EXISTS idx_reactions_message ON public.message_reactions(message_id);


-- ;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_handle_new_message ON public.messages;
CREATE TRIGGER trigger_handle_new_message
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_message();


-- 4.2 RPC: Mark Chat as Read
-- Resets unread count and updates read receipt
CREATE OR REPLACE FUNCTION public.mark_chat_read(p_chat_id UUID)
RETURNS VOID AS $$
DECLARE
  v_last_message_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  -- Get the latest message in the chat
  SELECT id INTO v_last_message_id
  FROM public.messages
  WHERE chat_id = p_chat_id
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_last_message_id IS NOT NULL THEN
    -- Update participant status
    UPDATE public.chat_participants
    SET 
      unread_count = 0,
      last_read_message_id = v_last_message_id
    WHERE chat_id = p_chat_id AND user_id = v_user_id;

    -- Insert read receipt (idempotent)
    INSERT INTO public.message_read_receipts (message_id, user_id)
    VALUES (v_last_message_id, v_user_id)
    ON CONFLICT (message_id, user_id) DO NOTHING;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4.3 RPC: Create 1-on-1 Chat or Get Existing
CREATE OR REPLACE FUNCTION public.get_or_create_private_chat(p_other_user_id UUID)
RETURNS UUID AS $$
DECLARE
  v_chat_id UUID;
  v_current_user_id UUID;
BEGIN
  v_current_user_id := auth.uid();

  -- Check if a private chat already exists between these two users
  SELECT c.id INTO v_chat_id
  FROM public.chats c
  JOIN public.chat_participants cp1 ON c.id = cp1.chat_id
  JOIN public.chat_participants cp2 ON c.id = cp2.chat_id
  WHERE c.type = 'PRIVATE'
    AND cp1.user_id = v_current_user_id
    AND cp2.user_id = p_other_user_id;

  -- If exists, return it
  IF v_chat_id IS NOT NULL THEN
    RETURN v_chat_id;
  END IF;

  -- Create new chat
  INSERT INTO public.chats (type)
  VALUES ('PRIVATE')
  RETURNING id INTO v_chat_id;

  -- Add participants
  INSERT INTO public.chat_participants (chat_id, user_id)
  VALUES 
    (v_chat_id, v_current_user_id),
    (v_chat_id, p_other_user_id);

  -- Return the created chat id
  RETURN v_chat_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4.4 RPC: Send Relationship Request
CREATE OR REPLACE FUNCTION public.send_relationship_request(p_target_user_id UUID, p_type public.relation_type DEFAULT 'FRIEND')
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
  v_exists BOOLEAN;
BEGIN
  v_user_id := auth.uid();
  
  -- Prevent self-request
  IF v_user_id = p_target_user_id THEN
    RAISE EXCEPTION 'Cannot send request to self';
  END IF;

  -- Check if any relationship exists (in either direction)
  SELECT EXISTS(
    SELECT 1 FROM public.relationships 
    WHERE (requester_id = v_user_id AND receiver_id = p_target_user_id)
       OR (requester_id = p_target_user_id AND receiver_id = v_user_id)
  ) INTO v_exists;

  IF v_exists THEN
    RAISE EXCEPTION 'Relationship already exists or is pending';
  END IF;

  -- Insert new request
  INSERT INTO public.relationships (requester_id, receiver_id, status, type)
  VALUES (v_user_id, p_target_user_id, 'PENDING', p_type);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 4.5 RPC: Update Relationship (Accept/Block/Change Type)
CREATE OR REPLACE FUNCTION public.update_relationship(p_target_user_id UUID, p_status public.relation_status, p_type public.relation_type DEFAULT NULL)
RETURNS VOID AS $$
DECLARE
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  -- Update where current user is receiver (Accepting) OR requester (Changing type/Blocking)
  -- Case 1: I am receiver, I accept.
  UPDATE public.relationships
  SET 
    status = p_status,
    type = COALESCE(p_type, type),
    updated_at = now()
  WHERE (receiver_id = v_user_id AND requester_id = p_target_user_id)
     OR (requester_id = v_user_id AND receiver_id = p_target_user_id);
     
  -- Note: Complex block logic (who blocked who) might need a separate 'blocked_by' column 
  -- but for simple implementation, status='BLOCKED' is shared.
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 5. RLS POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_read_receipts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING ((SELECT auth.uid()) = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = id);

-- Chats
DROP POLICY IF EXISTS "View own chats" ON public.chats;
CREATE POLICY "View own chats" ON public.chats FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.chat_participants WHERE chat_id = id AND user_id = auth.uid()
));

-- Chat Participants
DROP POLICY IF EXISTS "View participants of own chats" ON public.chat_participants;
CREATE POLICY "View participants of own chats" ON public.chat_participants FOR SELECT
USING (EXISTS (
  SELECT 1 FROM public.chat_participants cp 
  WHERE cp.chat_id = chat_participants.chat_id AND cp.user_id = auth.uid()
));

-- Messages
-- View messages in chats you belong to
DROP POLICY IF EXISTS "View chat messages" ON public.messages;
CREATE POLICY "View chat messages" ON public.messages FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.chat_participants
    WHERE chat_id = messages.chat_id
      AND user_id = auth.uid()
  )
);

-- Message Reactions
DROP POLICY IF EXISTS "View reactions" ON public.message_reactions;
CREATE POLICY "View reactions" ON public.message_reactions FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.messages m
    JOIN public.chat_participants cp ON m.chat_id = es FOR UPDATE
USING (auth.uid() = sender_id);


-- Relationships
ALTER TABLE public.relationships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View own relationships" ON public.relationships;
CREATE POLICY "View own relationships" ON public.relationships FOR SELECT
USING (auth.uid() = requester_id OR auth.uid() = receiver_id);

DROP POLICY IF EXISTS "Update own relationships" ON public.relationships;
CREATE POLICY "Updatc own relationshipp" ON.public.relationships chat_id
    WHEauth.uid() = requester_id OR RE m.id = pubreceiver_id);

-- Inlirt hac.lmd via RPC usually, but policy allows if needed (requester only)
DROP POLICY IF EXISTS "Insert relationship request" ON public.eelationships;
CREATE POLICY "Insert relationship request" ON public.relationships FOR INSERT
WITH CHECK (auth.uid() = requesterssage

DROP POLICY IF EXISTS "Delete own relationships" ON public.relationships;
CREATE POLICY "Delete own relationships" ON public.relationships FOR DELETE
USING (auth.uid() = requester_id OR auth.uid() = receiver_id);
_reactions.message_id
      AND cp.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Add reaction" ON public.message_reactions;
CREATE POLICY "Add reaction" ON public.message_reactions FOR INSERT
WITH CHECK (
  auth.uid() = user_id AND
  EXISTS (
    SELECT 1
    FROM public.messages m
    JOIN public.chat_participants cp ON m.chat_id = cp.chat_id
    WHERE m.id = public.message_reactions.message_id
      AND cp.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Remove own reaction" ON public.message_reactions;
CREATE POLICY "Remove own reaction" ON public.message_reactions FOR DELETE
USING (auth.uid() = user_id);

-- Insert messages in chats you belong to
DROP POLICY IF EXISTS "Send messages" ON public.messages;
CREATE POLICY "Send messages" ON public.messages FOR INSERT
WITH CHECK (
  auth.uid() = sender_id AND
  EXISTS (
    SELECT 1
    FROM public.chat_participants
    WHERE chat_id = public.messages.chat_id
      AND user_id = auth.uid()
  )
);

-- Update own messages
DROP POLICY IF EXISTS "Update own messages" ON public.messages;
CREATE POLICY "Update own messages" ON public.messages FOR UPDATE
USING (auth.uid() = sender_id);

-- 6. STORAGE (Media)
-- ============================================
-- Ensure bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat_attachments', 'chat_attachments', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for Storage

DROP POLICY IF EXISTS "Public Access" ON storage.objects;
CREATE POLICY "Public Access" ON storage.objects FOR SELECT TO public USING (bucket_id = 'chat_attachments');
DROP POLICY IF EXISTS "Auth Upload" ON storage.objects;
CREATE POLICY "Auth Upload" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id = 'chat_attachments');
