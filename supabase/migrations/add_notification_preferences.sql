-- Add notification preference columns to profiles table
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS deadline_reminders BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS application_updates BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS general_notifications BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS reminder_days_before INT[] DEFAULT '{7,3,1}';

-- Add comment for documentation
COMMENT ON COLUMN profiles.notifications_enabled IS 'Master toggle for all notifications';
COMMENT ON COLUMN profiles.deadline_reminders IS 'Enable deadline reminder notifications';
COMMENT ON COLUMN profiles.application_updates IS 'Enable application status change notifications';
COMMENT ON COLUMN profiles.general_notifications IS 'Enable general/marketing notifications';
COMMENT ON COLUMN profiles.reminder_days_before IS 'Days before deadline to send reminders (e.g. {7,3,1})';