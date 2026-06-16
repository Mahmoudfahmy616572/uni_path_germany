-- ============================================================
-- Cleanup old data + Import BA API data
-- Run this FIRST, then run 002_import_ba_data.sql
-- ============================================================

-- 1. حذف التطبيقات اللي بتشير للجامعات القديمة
DELETE FROM public.my_applications
WHERE university_id IN (SELECT id FROM public.universities);

-- 2. حذف البرامج القديمة
DELETE FROM public.university_programs;

-- 3. حذف الجامعات القديمة
DELETE FROM public.universities;

-- 4. Resetting the ID sequence
ALTER SEQUENCE IF EXISTS universities_id_seq RESTART WITH 1;

-- 5. (اختياري) Resetting the programs ID sequence if it uses integer PK
-- ALTER SEQUENCE IF EXISTS university_programs_id_seq RESTART WITH 1;
