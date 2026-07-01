-- ==========================================
-- VAKIL SIRJI - DUMMY DATA SEED SCRIPT
-- Run this in your Supabase SQL Editor AFTER running the schema script!
-- ==========================================

-- Enable pgcrypto for password hashing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Create Dummy Users in auth.users
-- We pre-define the UUIDs so we can link them to properties and cases easily.
-- The passwords for all these accounts will be 'password123'
DO $$
DECLARE
  admin_id UUID := '11111111-1111-1111-1111-111111111111';
  owner_id UUID := '22222222-2222-2222-2222-222222222222';
  staff_id UUID := '33333333-3333-3333-3333-333333333333';
  tenant_id UUID := '44444444-4444-4444-4444-444444444444';
  
  property_1_id UUID := 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  service_request_1_id UUID := 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  case_1_id UUID := 'cccccccc-cccc-cccc-cccc-cccccccccccc';
BEGIN

  -- Clean up any conflicting emails by cascading deletes manually
  -- 1. Cases
  DELETE FROM cases WHERE service_request_id IN (
      SELECT service_requests.id FROM service_requests WHERE service_requests.customer_id IN (
          SELECT public.profiles.id FROM public.profiles WHERE email IN ('admin@vakilsirji.com', 'owner@vakilsirji.com', 'staff@vakilsirji.com')
      )
  );
  -- 2. Service Requests
  DELETE FROM service_requests WHERE service_requests.customer_id IN (
      SELECT public.profiles.id FROM public.profiles WHERE email IN ('admin@vakilsirji.com', 'owner@vakilsirji.com', 'staff@vakilsirji.com')
  );
  -- 3. Tenants
  DELETE FROM tenants WHERE property_id IN (
      SELECT properties.id FROM properties WHERE properties.owner_id IN (
          SELECT public.profiles.id FROM public.profiles WHERE email IN ('admin@vakilsirji.com', 'owner@vakilsirji.com', 'staff@vakilsirji.com')
      )
  );
  -- 4. Properties
  DELETE FROM properties WHERE properties.owner_id IN (
      SELECT public.profiles.id FROM public.profiles WHERE email IN ('admin@vakilsirji.com', 'owner@vakilsirji.com', 'staff@vakilsirji.com')
  );
  -- 5. UPSERT Auth Users (Updates password if user already exists, inserts if not)
  
  -- Insert Admin
  INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
  VALUES (admin_id, 'authenticated', 'authenticated', 'admin@vakilsirji.com', crypt('password123', gen_salt('bf')), now(), '{"name":"Super Admin","role":"admin"}', '{"provider":"email","providers":["email"]}', now(), now())
  ON CONFLICT (id) DO UPDATE SET 
    encrypted_password = EXCLUDED.encrypted_password,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    email_confirmed_at = EXCLUDED.email_confirmed_at;
  
  INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (uuid_generate_v4(), admin_id, admin_id, format('{"sub":"%s","email":"%s"}', admin_id::text, 'admin@vakilsirji.com')::jsonb, 'email', now(), now(), now())
  ON CONFLICT (provider_id, provider) DO UPDATE SET identity_data = EXCLUDED.identity_data;

  -- Insert Owner
  INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
  VALUES (owner_id, 'authenticated', 'authenticated', 'owner@vakilsirji.com', crypt('password123', gen_salt('bf')), now(), '{"name":"Vakil Sirji Landlord","role":"owner"}', '{"provider":"email","providers":["email"]}', now(), now())
  ON CONFLICT (id) DO UPDATE SET 
    encrypted_password = EXCLUDED.encrypted_password,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    email_confirmed_at = EXCLUDED.email_confirmed_at;

  INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (uuid_generate_v4(), owner_id, owner_id, format('{"sub":"%s","email":"%s"}', owner_id::text, 'owner@vakilsirji.com')::jsonb, 'email', now(), now(), now())
  ON CONFLICT (provider_id, provider) DO UPDATE SET identity_data = EXCLUDED.identity_data;

  -- Insert Staff
  INSERT INTO auth.users (id, aud, role, email, encrypted_password, email_confirmed_at, raw_user_meta_data, raw_app_meta_data, created_at, updated_at)
  VALUES (staff_id, 'authenticated', 'authenticated', 'staff@vakilsirji.com', crypt('password123', gen_salt('bf')), now(), '{"name":"CRM Executive","role":"manager"}', '{"provider":"email","providers":["email"]}', now(), now())
  ON CONFLICT (id) DO UPDATE SET 
    encrypted_password = EXCLUDED.encrypted_password,
    raw_app_meta_data = EXCLUDED.raw_app_meta_data,
    email_confirmed_at = EXCLUDED.email_confirmed_at;

  INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES (uuid_generate_v4(), staff_id, staff_id, format('{"sub":"%s","email":"%s"}', staff_id::text, 'staff@vakilsirji.com')::jsonb, 'email', now(), now(), now())
  ON CONFLICT (provider_id, provider) DO UPDATE SET identity_data = EXCLUDED.identity_data;

  -- Ensure Profiles exist in case the trigger didn't run (if users already existed)
  INSERT INTO public.profiles (id, email, name, role) VALUES (admin_id, 'admin@vakilsirji.com', 'Super Admin', 'admin') ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.profiles (id, email, name, role) VALUES (owner_id, 'owner@vakilsirji.com', 'Vakil Sirji Landlord', 'owner') ON CONFLICT (id) DO NOTHING;
  INSERT INTO public.profiles (id, email, name, role) VALUES (staff_id, 'staff@vakilsirji.com', 'CRM Executive', 'manager') ON CONFLICT (id) DO NOTHING;

  -- NOTE: The "handle_new_user" trigger you ran in the schema will automatically copy these users into the `profiles` table for NEW inserts!

  -- 2. Create Dummy Property for the Owner
  INSERT INTO properties (id, owner_id, name, address, city, state, pin_code, property_type, rent_amount, deposit_amount)
  VALUES (property_1_id, owner_id, 'Sunshine Apartments, Flat 402', 'Kalyani Nagar', 'Pune', 'Maharashtra', '411014', 'Flat', 25000, 75000)
  ON CONFLICT (id) DO NOTHING;

  -- 3. Create Dummy Tenant for the Property
  INSERT INTO tenants (id, property_id, name, email, mobile, current_address, move_in_date)
  VALUES (tenant_id, property_1_id, 'Rohan Deshmukh', 'rohan@example.com', '+91 9999988888', 'Wakad, Pune', '2026-06-01')
  ON CONFLICT (id) DO NOTHING;

  -- Link the tenant back to the property as the current tenant
  UPDATE properties SET current_tenant_id = tenant_id WHERE id = property_1_id;

  -- 4. Create a Service Request (Customer requested a Rent Agreement)
  INSERT INTO service_requests (id, customer_id, service_type, status)
  VALUES (service_request_1_id, owner_id, 'Rent Agreement', 'Submitted')
  ON CONFLICT (id) DO NOTHING;

  -- 5. Create a CRM Case for the Staff
  INSERT INTO cases (id, service_request_id, assigned_to, title, status, notes)
  VALUES (case_1_id, service_request_1_id, staff_id, 'Rent Agreement - Rohan Deshmukh', 'Verification', 'Documents uploaded. Needs verification.')
  ON CONFLICT (id) DO NOTHING;

  -- 6. Clean up existing dummy leads if any
  DELETE FROM leads;

  -- 7. Insert Dummy Leads
  INSERT INTO leads (id, name, mobile, email, source, status, notes, assigned_to)
  VALUES 
    (uuid_generate_v4(), 'Amit Patel', '+91 9876543210', 'amit.patel@example.com', 'Website', 'New Lead', 'Enquired about Rent Agreement drafting in Mumbai.', NULL),
    (uuid_generate_v4(), 'Priya Sharma', '+91 8765432109', 'priya.s@example.com', 'WhatsApp', 'Follow-up', 'Asked for pricing details. Need to call tomorrow.', staff_id),
    (uuid_generate_v4(), 'Rahul Desai', '+91 7654321098', 'rahuld@example.com', 'Facebook', 'Interested', 'Wants property registration in Pune.', staff_id),
    (uuid_generate_v4(), 'Sneha Kapoor', '+91 6543210987', 'sneha.k@example.com', 'Phone Call', 'New Lead', 'Missed call. Need to return call.', NULL),
    (uuid_generate_v4(), 'Vikram Singh', '+91 5432109876', 'vikram.s@example.com', 'Website', 'Converted', 'Paid advance for Rent Agreement.', staff_id),
    (uuid_generate_v4(), 'Neha Gupta', '+91 4321098765', 'neha.g@example.com', 'WhatsApp', 'Not Interested', 'Found another service provider.', NULL);

END $$;
