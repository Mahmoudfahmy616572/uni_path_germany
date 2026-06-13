-- ============================================================
-- FORCE FIX: Drop all policies that call is_admin() on profiles,
-- then replace is_admin() and recreate policies.
-- Run this if fix_rls_recursion.sql didn't work.
-- ============================================================

-- 1. Temporarily drop policies that depend on is_admin()
--    (order matters: drop dependent policies first)

-- Profiles policies
DROP POLICY IF EXISTS "Admins can read all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON profiles;

-- My applications policies
DROP POLICY IF EXISTS "Anyone can read applications" ON my_applications;
DROP POLICY IF EXISTS "Admins can update applications" ON my_applications;
DROP POLICY IF EXISTS "Admins can delete applications" ON my_applications;

-- University programs policies
DROP POLICY IF EXISTS "Anyone can read programs" ON university_programs;
DROP POLICY IF EXISTS "Admins can insert programs" ON university_programs;
DROP POLICY IF EXISTS "Admins can update programs" ON university_programs;
DROP POLICY IF EXISTS "Admins can delete programs" ON university_programs;

-- Universities policies
DROP POLICY IF EXISTS "Anyone can read universities" ON universities;
DROP POLICY IF EXISTS "Admins can insert universities" ON universities;
DROP POLICY IF EXISTS "Admins can update universities" ON universities;
DROP POLICY IF EXISTS "Admins can delete universities" ON universities;

-- 2. Drop old triggers
DROP TRIGGER IF EXISTS sync_admin_role_trigger ON profiles;
DROP TRIGGER IF EXISTS prevent_self_role_change_trigger ON profiles;

-- 3. Create admin_users table (if not exists)
CREATE TABLE IF NOT EXISTS public.admin_users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE
);

-- 4. Backfill existing admins
INSERT INTO public.admin_users (user_id)
SELECT id FROM public.profiles WHERE role = 'admin'
ON CONFLICT DO NOTHING;

-- 5. Create sync trigger function (safe with TG_OP)
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

CREATE TRIGGER sync_admin_role_trigger
  AFTER INSERT OR UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.sync_admin_role();

-- 6. Replace is_admin() to query admin_users not profiles
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

-- 7. Recreate all policies (using the NEW is_admin())

-- Universities
ALTER TABLE universities ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read universities"
ON universities FOR SELECT TO public USING (true);

CREATE POLICY "Admins can insert universities"
ON universities FOR INSERT TO authenticated WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update universities"
ON universities FOR UPDATE TO authenticated USING (public.is_admin());

CREATE POLICY "Admins can delete universities"
ON universities FOR DELETE TO authenticated USING (public.is_admin());

-- University programs
ALTER TABLE university_programs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read programs"
ON university_programs FOR SELECT TO public USING (true);

CREATE POLICY "Admins can insert programs"
ON university_programs FOR INSERT TO authenticated WITH CHECK (public.is_admin());

CREATE POLICY "Admins can update programs"
ON university_programs FOR UPDATE TO authenticated USING (public.is_admin());

CREATE POLICY "Admins can delete programs"
ON university_programs FOR DELETE TO authenticated USING (public.is_admin());

-- My applications
ALTER TABLE my_applications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read applications"
ON my_applications FOR SELECT TO public USING (true);

CREATE POLICY "Admins can update applications"
ON my_applications FOR UPDATE TO authenticated USING (public.is_admin());

CREATE POLICY "Admins can delete applications"
ON my_applications FOR DELETE TO authenticated USING (public.is_admin());

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Admins can read all profiles"
ON profiles FOR SELECT TO authenticated
USING (auth.uid() = id OR public.is_admin());

CREATE POLICY "Users can update own profile"
ON profiles FOR UPDATE TO authenticated
USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Admins can update any profile"
ON profiles FOR UPDATE TO authenticated
USING (public.is_admin());

-- 8. Prevent non-admin users from changing their own role
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

CREATE TRIGGER prevent_self_role_change_trigger
  BEFORE UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_self_role_change();
