-- ==========================================
-- VAKIL SIRJI - STAFF RLS FIXES
-- Run this in your Supabase SQL Editor to allow staff to see service requests!
-- ==========================================

-- 1. Allow everyone (including Staff) to view all service requests
DROP POLICY IF EXISTS "Users can view own requests" ON public.service_requests;
CREATE POLICY "Users can view own requests" ON public.service_requests FOR SELECT USING (true);

-- 2. Allow everyone (including Staff) to update cases and requests
DROP POLICY IF EXISTS "Users can update own cases" ON public.cases;
CREATE POLICY "Users can update own cases" ON public.cases FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Users can update own requests" ON public.service_requests;
CREATE POLICY "Users can update own requests" ON public.service_requests FOR UPDATE USING (true);
