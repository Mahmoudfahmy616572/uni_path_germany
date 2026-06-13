-- ============================================================
-- 1. Create Storage bucket for university assets (logos, images)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('university-assets', 'university-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public uploads and reads for the storage bucket
DROP POLICY IF EXISTS "Allow public uploads" ON storage.objects;
CREATE POLICY "Allow public uploads"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'university-assets');

DROP POLICY IF EXISTS "Allow public reads" ON storage.objects;
CREATE POLICY "Allow public reads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'university-assets');

-- ============================================================
-- 2. Admin tracking table (breaks recursion: is_admin() queries
--    this table instead of profiles)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Backfill existing admins (safe to re-run)
INSERT INTO public.admin_users (user_id)
SELECT id FROM public.profiles WHERE role = 'admin'
ON CONFLICT DO NOTHING;

-- Trigger: keep admin_users in sync when profiles.role changes
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

-- ============================================================
-- 3. Helper function to check admin role (queries admin_users
--    instead of profiles to avoid infinite recursion in RLS)
-- ============================================================
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

-- ============================================================
-- 4. RLS policies for admin CRUD on universities
-- ============================================================
ALTER TABLE universities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read universities" ON universities;
CREATE POLICY "Anyone can read universities"
ON universities FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "Admins can insert universities" ON universities;
CREATE POLICY "Admins can insert universities"
ON universities FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update universities" ON universities;
CREATE POLICY "Admins can update universities"
ON universities FOR UPDATE
TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete universities" ON universities;
CREATE POLICY "Admins can delete universities"
ON universities FOR DELETE
TO authenticated
USING (public.is_admin());

-- ============================================================
-- 5. RLS policies for admin CRUD on university_programs
-- ============================================================
ALTER TABLE university_programs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read programs" ON university_programs;
CREATE POLICY "Anyone can read programs"
ON university_programs FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "Admins can insert programs" ON university_programs;
CREATE POLICY "Admins can insert programs"
ON university_programs FOR INSERT
TO authenticated
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins can update programs" ON university_programs;
CREATE POLICY "Admins can update programs"
ON university_programs FOR UPDATE
TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete programs" ON university_programs;
CREATE POLICY "Admins can delete programs"
ON university_programs FOR DELETE
TO authenticated
USING (public.is_admin());

-- ============================================================
-- 6. RLS policies for admin on my_applications
-- ============================================================
ALTER TABLE my_applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can read applications" ON my_applications;
CREATE POLICY "Anyone can read applications"
ON my_applications FOR SELECT
TO public
USING (true);

DROP POLICY IF EXISTS "Admins can update applications" ON my_applications;
CREATE POLICY "Admins can update applications"
ON my_applications FOR UPDATE
TO authenticated
USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete applications" ON my_applications;
CREATE POLICY "Admins can delete applications"
ON my_applications FOR DELETE
TO authenticated
USING (public.is_admin());

-- ============================================================
-- 7. RLS policies for admin on profiles
-- ============================================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- User can read own profile; admins can read all
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
CREATE POLICY "Admins can read all profiles"
ON profiles FOR SELECT
TO authenticated
USING (
  auth.uid() = id OR public.is_admin()
);

-- Users can update their own profile (fcm_token, etc.)
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE
TO authenticated
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- Admins can update any profile
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;
CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE
TO authenticated
USING (public.is_admin());

-- Prevent non-admin users from changing their own role
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
