-- Add missing columns to existing tables

ALTER TABLE university_programs
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE university_programs
ADD COLUMN IF NOT EXISTS duration TEXT;

ALTER TABLE university_programs
ADD COLUMN IF NOT EXISTS language TEXT;

-- Add more columns to university_programs (safe to re-run)
ALTER TABLE university_programs
ADD COLUMN IF NOT EXISTS major TEXT,
ADD COLUMN IF NOT EXISTS intake_type TEXT DEFAULT 'Winter',
ADD COLUMN IF NOT EXISTS required_gpa NUMERIC,
ADD COLUMN IF NOT EXISTS instruction_language TEXT,
ADD COLUMN IF NOT EXISTS application_fee NUMERIC,
ADD COLUMN IF NOT EXISTS tuition_fee_per_year NUMERIC,
ADD COLUMN IF NOT EXISTS curriculum TEXT,
ADD COLUMN IF NOT EXISTS requires_ielts BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS min_ielts_score NUMERIC,
ADD COLUMN IF NOT EXISTS accepts_moi BOOLEAN DEFAULT FALSE;
