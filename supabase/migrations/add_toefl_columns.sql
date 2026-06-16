-- Add has_toefl and toefl_score columns to profiles table
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS has_toefl BOOLEAN DEFAULT FALSE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS toefl_score NUMERIC DEFAULT 0;
