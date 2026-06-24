-- Add premium subscription columns to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS premium_until TIMESTAMPTZ;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS premium_plan TEXT; -- 'monthly', 'yearly', 'lifetime'

-- Create subscription plans table
CREATE TABLE IF NOT EXISTS subscription_plans (
  id BIGINT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  name TEXT NOT NULL,
  price_monthly NUMERIC NOT NULL DEFAULT 9.99,
  price_yearly NUMERIC NOT NULL DEFAULT 79.99,
  price_lifetime NUMERIC NOT NULL DEFAULT 149.99,
  description TEXT,
  features TEXT[] DEFAULT '{}',
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Insert default plans
INSERT INTO subscription_plans (name, price_monthly, price_yearly, price_lifetime, description, features) VALUES
('Premium', 9.99, 79.99, 149.99, 'Unlock AI-powered features', 
 ARRAY['AI document review', 'AI improvement suggestions', 'Premium match score (20%)', 'Unlimited AI uses', 'Priority support']);
