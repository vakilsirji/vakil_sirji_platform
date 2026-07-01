-- ==========================================
-- VAKIL SIRJI - TABLE RLS FIXES
-- Run this in your Supabase SQL Editor to allow database inserts
-- ==========================================

-- 1. Enable RLS on the missing tables (just in case)
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- 2. Create Policies for the Documents table
-- We'll allow authenticated users to perform operations on documents.
CREATE POLICY "Allow authenticated select documents" ON public.documents FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert documents" ON public.documents FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update documents" ON public.documents FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow authenticated delete documents" ON public.documents FOR DELETE TO authenticated USING (true);

-- 3. Create Policies for the Payments table
CREATE POLICY "Allow authenticated select payments" ON public.payments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow authenticated insert payments" ON public.payments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Allow authenticated update payments" ON public.payments FOR UPDATE TO authenticated USING (true);
CREATE POLICY "Allow authenticated delete payments" ON public.payments FOR DELETE TO authenticated USING (true);
