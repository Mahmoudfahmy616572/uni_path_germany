-- Add portal tracking columns to my_applications table
ALTER TABLE my_applications
ADD COLUMN IF NOT EXISTS portal_url TEXT,
ADD COLUMN IF NOT EXISTS portal_status TEXT DEFAULT 'pending',
ADD COLUMN IF NOT EXISTS payment_status TEXT DEFAULT 'unpaid',
ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS auto_track BOOLEAN DEFAULT FALSE;
