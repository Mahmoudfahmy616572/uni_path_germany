-- ============================================================
-- Fix: Infinite recursion in profiles RLS policy
-- 
-- The old is_admin() queried profiles, which triggered
-- the profiles policy, which called is_admin() → recursion.
-- 
-- Fix: Query a dedicated admin_users table instead.
-- ============================================================

-- 1. Admin tracking table (breaks the recursion chain)
CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Backfill existing admin users
INSERT INTO public.admin_users (user_id)
SELECT id FROM public.profiles WHERE role = 'admin'
ON CONFLICT DO NOTHING;

-- 2. Trigger: keep admin_users in sync when profiles.role changes
CREATE OR REPLACE FUNCTION public.sync_admin_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.role = 'admin' THEN
      INSERT INTO public.admin_users (user_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
    END IF;
  ELSIF TG_OP = 'UPDATE' AND NEW.role IS DISTINCT FROM OLD.role THEN
    IF NEW.role = 'admin' THEN
      INSERT INTO public.admin_users (user_id) VALUES (NEW.id) ON CONFLICT DO NOTHING;
    ELSIF OLD.role = 'admin' THEN
      DELETE FROM public.admin_users WHERE user_id = NEW.id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS sync_admin_role_trigger ON public.profiles;
CREATE TRIGGER sync_admin_role_trigger
  AFTER INSERT OR UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.sync_admin_role();

-- 3. Update is_admin() to query admin_users instead of profiles
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.admin_users WHERE user_id = auth.uid()
  );
END;
$$;

-- 4. Prevent non-admin users from changing their own role
CREATE OR REPLACE FUNCTION public.prevent_self_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.role IS DISTINCT FROM OLD.role AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admins can change user roles';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS prevent_self_role_change_trigger ON public.profiles;
CREATE TRIGGER prevent_self_role_change_trigger
  BEFORE UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_self_role_change();
