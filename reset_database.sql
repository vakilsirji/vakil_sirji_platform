-- ==========================================
-- VAKIL SIRJI - TOTAL DATABASE WIPE
-- WARNING: This will delete absolutely EVERYTHING in your public schema.
-- ==========================================

-- 1. Drop the entire public schema and all its tables/data
DROP SCHEMA public CASCADE;

-- 2. Recreate a fresh, empty public schema
CREATE SCHEMA public;

-- 3. Restore default permissions for Supabase
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

-- 4. Delete ANY existing users in auth.users
DELETE FROM auth.users;

-- ==========================================
-- Your database is now completely empty!
-- You can now run `supabase_schema.sql` followed by `seed_data.sql`.
-- ==========================================
