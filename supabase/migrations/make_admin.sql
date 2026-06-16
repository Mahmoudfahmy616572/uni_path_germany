-- Promote a user to admin by email
-- Run this in Supabase SQL Editor

DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- Get the user's UUID from profiles table by email
  SELECT id INTO v_user_id
  FROM public.profiles
  WHERE email = 'mahmoudfahmy7776@gmail.com';

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User with email mahmoudfahmy7776@gmail.com not found';
  END IF;

  -- Update role to admin (trigger will auto-sync admin_users table)
  UPDATE public.profiles
  SET role = 'admin'
  WHERE id = v_user_id;

  RAISE NOTICE 'User mahmoudfahmy7776@gmail.com (ID: %) promoted to admin successfully!', v_user_id;
END $$;
