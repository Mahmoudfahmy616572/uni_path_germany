-- Add global document URL columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS has_transcripts TEXT,
ADD COLUMN IF NOT EXISTS has_bachelor_cert TEXT,
ADD COLUMN IF NOT EXISTS has_sop TEXT,
ADD COLUMN IF NOT EXISTS has_cv TEXT;
