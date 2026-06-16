-- Fix auto-increment sequence after manual inserts
-- Run this if you get "duplicate key value violates unique constraint"

SELECT setval(
  pg_get_serial_sequence('universities', 'id'),
  COALESCE((SELECT MAX(id) FROM universities), 0) + 1,
  false
);
