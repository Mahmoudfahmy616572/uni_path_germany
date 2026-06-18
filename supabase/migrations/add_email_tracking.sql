-- Email tracking for auto portal status detection
CREATE TABLE IF NOT EXISTS email_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL CHECK (provider IN ('gmail', 'outlook')),
  email TEXT NOT NULL,
  access_token TEXT,
  refresh_token TEXT,
  token_expires_at TIMESTAMPTZ,
  last_sync_at TIMESTAMPTZ,
  auto_sync BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, provider)
);

-- Email tracking log: records each detected status update
CREATE TABLE IF NOT EXISTS email_status_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  application_id BIGINT REFERENCES my_applications(id) ON DELETE SET NULL,
  connection_id UUID REFERENCES email_connections(id) ON DELETE CASCADE,
  email_subject TEXT,
  email_from TEXT,
  detected_status TEXT,
  detected_payment TEXT,
  raw_snippet TEXT,
  applied BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE email_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_status_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own connections"
  ON email_connections FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users view own logs"
  ON email_status_log FOR SELECT
  USING (auth.uid() = user_id);
