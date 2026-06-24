-- Add program_url column to university_programs table for in-app WebView linking
ALTER TABLE university_programs ADD COLUMN IF NOT EXISTS program_url TEXT;

-- Add index for fast lookup (optional, useful if queried independently)
CREATE INDEX IF NOT EXISTS idx_university_programs_program_url ON university_programs (program_url)
  WHERE program_url IS NOT NULL;
