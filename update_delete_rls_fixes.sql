-- ==========================================
-- VAKIL SIRJI - UPDATE & DELETE RLS FIXES
-- Run this in your Supabase SQL Editor to allow editing and deleting
-- ==========================================

-- 1. Properties Table Policies
DROP POLICY IF EXISTS "Owners can update own properties" ON public.properties;
CREATE POLICY "Owners can update own properties" ON public.properties FOR UPDATE USING (auth.uid() = owner_id);

DROP POLICY IF EXISTS "Owners can delete own properties" ON public.properties;
CREATE POLICY "Owners can delete own properties" ON public.properties FOR DELETE USING (auth.uid() = owner_id);

-- 2. Tenants Table Policies
DROP POLICY IF EXISTS "Owners can update own tenants" ON public.tenants;
CREATE POLICY "Owners can update own tenants" ON public.tenants FOR UPDATE USING (true);

DROP POLICY IF EXISTS "Owners can delete own tenants" ON public.tenants;
CREATE POLICY "Owners can delete own tenants" ON public.tenants FOR DELETE USING (true);

-- 3. Cases Table Policies
DROP POLICY IF EXISTS "Users can delete own cases" ON public.cases;
CREATE POLICY "Users can delete own cases" ON public.cases FOR DELETE USING (true);
