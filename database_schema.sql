-- ============================================
-- Complete Database Schema for My Chat App (fixed)
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- 1. PROFILES TABLE (User profiles)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  profile_picture_url TEXT,
  is_online BOOLEAN DEFAULT false,
  last_seen TIMESTAMPTZ,
  active_chat_id TEXT,
  avatar_color BIGINT DEFAULT (floor(random() * 16777215)::int + 4278190080),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create index on username for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);

-- ============================================
-- 2. CHATS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  participant_ids TEXT[] NOT NULL,
  relationship_type TEXT DEFAULT 'friend',
  last_message_time TIMESTAMPTZ DEFAULT now(),
  last_message_content TEXT,
  last_message_sender_id TEXT,
  last_message_status TEXT,
  typing_status JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Create index on participantids for faster chat lookups
CREATE INDEX IF NOT EXISTS idx_chats_participant_ids ON chats USING GIN(participant_ids);

-- ============================================
-- 3. MESSAGES TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  chat_id UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'text',
  content TEXT NOT NULL,
  timestamp TIMESTAMPTZ DEFAULT now(),
  status TEXT DEFAULT 'sent',
  reply_to_message_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  edited_content TEXT,
  reactions JSONB DEFAULT '{}'::jsonb,
  deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Enable Realtime for messages table
ALTER TABLE messages REPLICA IDENTITY FULL;

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_timestamp ON messages(timestamp DESC);

-- ============================================
-- 4. RELATIONSHIPS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS relationships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id1 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_id2 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'none',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id1, user_id2)
);

-- Create index for faster relationship lookups
CREATE INDEX IF NOT EXISTS idx_relationships_user_id1 ON relationships(user_id1);
CREATE INDEX IF NOT EXISTS idx_relationships_user_id2 ON relationships(user_id2);

-- ============================================
-- ENABLE ROW LEVEL SECURITY (RLS)
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE relationships ENABLE ROW LEVEL SECURITY;

-- Ensure participantids column/index on public.chats exists (idempotent)
ALTER TABLE public.chats
  ADD COLUMN IF NOT EXISTS participant_ids TEXT[];

CREATE INDEX IF NOT EXISTS idx_chats_participant_ids ON public.chats USING GIN(participant_ids);

-- ============================================
-- RLS POLICIES FOR PROFILES
-- ============================================
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

-- Allow authenticated users to view all profiles
CREATE POLICY "Users can view all profiles" 
  ON profiles FOR SELECT 
  TO authenticated 
  USING (true);

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile" 
  ON profiles FOR INSERT 
  TO authenticated 
  WITH CHECK ((auth.uid())::uuid = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile" 
  ON profiles FOR UPDATE 
  TO authenticated 
  USING ((auth.uid())::uuid = id)
  WITH CHECK ((auth.uid())::uuid = id);

-- ============================================
-- RLS POLICIES FOR CHATS
-- ============================================
DROP POLICY IF EXISTS "Users can view chats they participate in" ON chats;
DROP POLICY IF EXISTS "Users can create chats" ON chats;
DROP POLICY IF EXISTS "Users can update chats they participate in" ON chats;
DROP POLICY IF EXISTS "Users can delete chats they participate in" ON chats;

-- Users can view chats where they are a participant
CREATE POLICY "Users can view chats they participate in" 
  ON chats FOR SELECT 
  TO authenticated 
  USING ((auth.uid())::text = ANY(participant_ids));

-- Users can create chats (they must be in participantids)
CREATE POLICY "Users can create chats" 
  ON chats FOR INSERT 
  TO authenticated 
  WITH CHECK ((auth.uid())::text = ANY(participant_ids));

-- Users can update chats they participate in
CREATE POLICY "Users can update chats they participate in" 
  ON chats FOR UPDATE 
  TO authenticated 
  USING ((auth.uid())::text = ANY(participant_ids))
  WITH CHECK ((auth.uid())::text = ANY(participant_ids));

-- Users can delete chats they participate in
CREATE POLICY "Users can delete chats they participate in" 
  ON chats FOR DELETE 
  TO authenticated 
  USING ((auth.uid())::text = ANY(participant_ids));

-- ============================================
-- RLS POLICIES FOR MESSAGES
-- ============================================
DROP POLICY IF EXISTS "Users can view messages in their chats" ON messages;
DROP POLICY IF EXISTS "Users can insert messages" ON messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON messages;

-- Users can view messages in chats they participate in
CREATE POLICY "Users can view messages in their chats" 
  ON messages FOR SELECT 
  TO authenticated 
  USING (
    EXISTS (
      SELECT 1 FROM chats 
      WHERE chats.id = messages.chat_id 
      AND (auth.uid())::text = ANY(chats.participant_ids)
    )
  );

-- Users can insert messages where they are the sender
CREATE POLICY "Users can insert messages" 
  ON messages FOR INSERT 
  TO authenticated 
  WITH CHECK (
    (auth.uid())::uuid = sender_id
    AND EXISTS (
      SELECT 1 FROM chats 
      WHERE chats.id = messages.chat_id 
      AND (auth.uid())::text = ANY(chats.participant_ids)
    )
  );

-- Users can update their own messages (edit, delete) or messages they receive (status, reactions)
CREATE POLICY "Users can update their own messages or received message status" 
  ON messages FOR UPDATE 
  TO authenticated 
  USING ((auth.uid())::uuid = sender_id OR (auth.uid())::uuid = receiver_id)
  WITH CHECK ((auth.uid())::uuid = sender_id OR (auth.uid())::uuid = receiver_id);

-- Users can delete their own messages (soft delete via update)
CREATE POLICY "Users can delete their own messages" 
  ON messages FOR UPDATE 
  TO authenticated 
  USING ((auth.uid())::uuid = sender_id)
  WITH CHECK ((auth.uid())::uuid = sender_id);

-- ============================================
-- RLS POLICIES FOR RELATIONSHIPS
-- ============================================
DROP POLICY IF EXISTS "Users can view relationships they are part of" ON relationships;
DROP POLICY IF EXISTS "Users can create relationships" ON relationships;
DROP POLICY IF EXISTS "Users can update relationships they are part of" ON relationships;
DROP POLICY IF EXISTS "Users can delete relationships they are part of" ON relationships;

-- Users can view relationships they are part of
CREATE POLICY "Users can view relationships they are part of" 
  ON relationships FOR SELECT 
  TO authenticated 
  USING ((auth.uid())::uuid = user_id1 OR (auth.uid())::uuid = user_id2);

-- Users can create relationships where they are userid1
CREATE POLICY "Users can create relationships" 
  ON relationships FOR INSERT 
  TO authenticated 
  WITH CHECK ((auth.uid())::uuid = user_id1);

-- Users can update relationships they are part of
CREATE POLICY "Users can update relationships they are part of" 
  ON relationships FOR UPDATE 
  TO authenticated 
  USING ((auth.uid())::uuid = user_id1 OR (auth.uid())::uuid = user_id2)
  WITH CHECK ((auth.uid())::uuid = user_id1 OR (auth.uid())::uuid = user_id2);

-- Users can delete relationships they are part of
CREATE POLICY "Users can delete relationships they are part of" 
  ON relationships FOR DELETE 
  TO authenticated 
  USING ((auth.uid())::uuid = user_id1 OR (auth.uid())::uuid = user_id2);

-- ============================================
-- GRANT PERMISSIONS (if needed)
-- ============================================
-- Grant usage on schema (usually not needed as authenticated role has access)
-- GRANT USAGE ON SCHEMA public TO authenticated;
-- GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;