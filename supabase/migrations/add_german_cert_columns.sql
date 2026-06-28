-- Add missing columns to profiles table
-- Safe to re-run (uses IF NOT EXISTS)

ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS has_german_cert BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS german_cert_type TEXT,
ADD COLUMN IF NOT EXISTS german_cert_level TEXT,
ADD COLUMN IF NOT EXISTS has_german_cert_doc TEXT,
ADD COLUMN IF NOT EXISTS german_level TEXT,
ADD COLUMN IF NOT EXISTS goals TEXT;
