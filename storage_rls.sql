-- ==========================================
-- VAKIL SIRJI - STORAGE RLS POLICIES
-- Run this in your Supabase SQL Editor to allow file uploads
-- ==========================================

-- Allow any authenticated user to upload files to the 'documents' bucket
CREATE POLICY "Allow authenticated uploads to documents"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK ( bucket_id = 'documents' );

-- Allow any authenticated user to update their files in the 'documents' bucket
CREATE POLICY "Allow authenticated updates to documents"
ON storage.objects FOR UPDATE TO authenticated
USING ( bucket_id = 'documents' );

-- Allow any authenticated user to view files in the 'documents' bucket
CREATE POLICY "Allow authenticated to view documents"
ON storage.objects FOR SELECT TO authenticated
USING ( bucket_id = 'documents' );

-- Allow any authenticated user to delete files in the 'documents' bucket
CREATE POLICY "Allow authenticated to delete documents"
ON storage.objects FOR DELETE TO authenticated
USING ( bucket_id = 'documents' );

-- ==========================================
-- Same policies for the 'properties' bucket
-- ==========================================

CREATE POLICY "Allow authenticated uploads to properties"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK ( bucket_id = 'properties' );

CREATE POLICY "Allow authenticated updates to properties"
ON storage.objects FOR UPDATE TO authenticated
USING ( bucket_id = 'properties' );

CREATE POLICY "Allow authenticated to view properties"
ON storage.objects FOR SELECT TO authenticated
USING ( bucket_id = 'properties' );

CREATE POLICY "Allow authenticated to delete properties"
ON storage.objects FOR DELETE TO authenticated
USING ( bucket_id = 'properties' );
