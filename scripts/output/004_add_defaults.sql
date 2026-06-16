-- Add missing columns
ALTER TABLE public.university_programs
ADD COLUMN IF NOT EXISTS deadline TEXT;

ALTER TABLE public.university_programs
ADD COLUMN IF NOT EXISTS link TEXT;

ALTER TABLE public.university_programs
ADD COLUMN IF NOT EXISTS data_source TEXT DEFAULT 'default';

-- ============================================================
-- Set defaults for ALL programs
-- ============================================================
--   Language: detect from program name & description
--   Tuition: 0 (public German universities are free)
--   Application fee: 0
--   Deadline: generic July 15 / January 15
--   Data source tag: 'default'

UPDATE public.university_programs
SET
    instruction_language = CASE
        WHEN LOWER(COALESCE(description, '')) LIKE '%english%'
          OR LOWER(COALESCE(description, '')) LIKE '%englisch%'
          OR LOWER(program_name) LIKE '%english%'
          OR LOWER(program_name) LIKE '%international%' THEN 'English'
        ELSE 'German'
    END,
    requires_ielts = CASE
        WHEN LOWER(COALESCE(description, '')) LIKE '%english%'
          OR LOWER(COALESCE(description, '')) LIKE '%englisch%'
          OR LOWER(program_name) LIKE '%english%'
          OR LOWER(program_name) LIKE '%international%' THEN true
        ELSE false
    END,
    min_ielts_score = CASE
        WHEN LOWER(COALESCE(description, '')) LIKE '%english%'
          OR LOWER(COALESCE(description, '')) LIKE '%englisch%'
          OR LOWER(program_name) LIKE '%english%'
          OR LOWER(program_name) LIKE '%international%'
        THEN CASE
            WHEN degree_type ILIKE '%master%' THEN 6.5
            ELSE 6.0
        END
        ELSE NULL
    END,
    accepts_moi = CASE
        WHEN LOWER(COALESCE(description, '')) LIKE '%english%'
          OR LOWER(COALESCE(description, '')) LIKE '%englisch%'
          OR LOWER(program_name) LIKE '%english%'
          OR LOWER(program_name) LIKE '%international%' THEN true
        ELSE false
    END,
    tuition_fee_per_year = 0,
    application_fee = 0,
    deadline = 'July 15 (Winter) / January 15 (Summer)',
    data_source = 'default'
WHERE data_source IS NULL OR data_source = 'default';
