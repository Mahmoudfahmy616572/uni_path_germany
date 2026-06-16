-- Migration: Add BA API tracking columns
ALTER TABLE public.universities ADD COLUMN IF NOT EXISTS ba_ban_id TEXT;
ALTER TABLE public.university_programs ADD COLUMN IF NOT EXISTS ba_program_id TEXT;

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_universities_ba_ban_id ON public.universities (ba_ban_id);
CREATE INDEX IF NOT EXISTS idx_programs_ba_program_id ON public.university_programs (ba_program_id);
