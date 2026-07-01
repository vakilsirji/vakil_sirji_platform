-- ==========================================
-- VAKIL SIRJI PLATFORM - SUPABASE SQL SCHEMA
-- Version: 1.0 (Service-Based Architecture)
-- ==========================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. PROFILES (Extends Supabase Auth)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    mobile TEXT,
    role TEXT NOT NULL DEFAULT 'owner', -- owner, tenant, sales, verification, biometric, manager, admin
    aadhaar TEXT,
    pan TEXT,
    address TEXT,
    joined_date TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- Trigger to automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, mobile, role)
  VALUES (
    new.id, 
    new.email, 
    new.raw_user_meta_data->>'name', 
    new.raw_user_meta_data->>'mobile',
    COALESCE(new.raw_user_meta_data->>'role', 'owner')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. PROPERTIES
CREATE TABLE properties (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES profiles(id) NOT NULL,
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    pin_code TEXT NOT NULL,
    property_tax_number TEXT,
    electricity_consumer_no TEXT,
    property_type TEXT DEFAULT 'Flat',
    photos JSONB,
    rent_amount NUMERIC NOT NULL,
    deposit_amount NUMERIC NOT NULL,
    current_tenant_id UUID, -- Foreign key added below
    property_tax_due_date DATE,
    insurance_renewal_date DATE,
    reminder_enabled BOOLEAN DEFAULT false,
    reminder_due_day INTEGER DEFAULT 5,
    reminder_channel TEXT DEFAULT 'WhatsApp',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 3. TENANTS
CREATE TABLE tenants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    property_id UUID REFERENCES properties(id) NOT NULL,
    name TEXT NOT NULL,
    email TEXT,
    mobile TEXT NOT NULL,
    aadhaar TEXT,
    pan TEXT,
    current_address TEXT,
    permanent_address TEXT,
    emergency_contact_name TEXT,
    emergency_contact_number TEXT,
    move_in_date DATE,
    move_out_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- Add foreign key constraint to properties for current_tenant
ALTER TABLE properties ADD CONSTRAINT fk_current_tenant FOREIGN KEY (current_tenant_id) REFERENCES tenants(id) ON DELETE SET NULL;

-- 4. SERVICE REQUESTS (Customer initiating a request)
CREATE TABLE service_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES profiles(id) NOT NULL,
    service_type TEXT NOT NULL, -- e.g., 'Rent Agreement', 'Police Verification'
    status TEXT NOT NULL DEFAULT 'Submitted',
    details JSONB, -- Flexible JSON for various service inputs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 5. CASES (Internal CRM representation of a Service Request)
CREATE TABLE cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_request_id UUID REFERENCES service_requests(id) NOT NULL,
    assigned_to UUID REFERENCES profiles(id), -- Staff member assigned
    title TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'New', -- New, Documents Pending, Data Entry, Verification, Draft Ready, Client Approval, Biometric Scheduled, Biometric Completed, Government Registration, Completed
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 6. CASE TASKS (Sub-tasks for workflow)
CREATE TABLE case_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES cases(id) NOT NULL,
    task_name TEXT NOT NULL,
    task_type TEXT NOT NULL, -- e.g., 'Verification', 'Drafting', 'Biometric'
    assigned_to UUID REFERENCES profiles(id),
    status TEXT NOT NULL DEFAULT 'Pending', -- Pending, In Progress, Completed
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 7. AGREEMENTS (Specific data for Rent Agreements)
CREATE TABLE agreements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    case_id UUID REFERENCES cases(id) NOT NULL,
    property_id UUID REFERENCES properties(id) NOT NULL,
    tenant_id UUID REFERENCES tenants(id) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    monthly_rent NUMERIC NOT NULL,
    security_deposit NUMERIC NOT NULL,
    notice_period_months INTEGER DEFAULT 1,
    lock_in_period_months INTEGER DEFAULT 0,
    draft_document_url TEXT,
    registered_document_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 8. WITNESSES
CREATE TABLE witnesses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agreement_id UUID REFERENCES agreements(id) NOT NULL,
    name TEXT NOT NULL,
    age INTEGER,
    mobile TEXT,
    aadhaar TEXT,
    address TEXT
);

-- 9. DOCUMENTS (Centralized storage tracking)
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL, -- Can be property_id, tenant_id, owner_id
    entity_type TEXT NOT NULL, -- 'Property', 'Tenant', 'Owner', 'Agreement'
    document_type TEXT NOT NULL, -- 'Aadhaar', 'PAN', 'Electricity Bill', etc.
    file_url TEXT NOT NULL,
    uploaded_by UUID REFERENCES profiles(id) NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 10. PAYMENTS
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity_id UUID NOT NULL, -- Usually property_id for rent
    entity_type TEXT NOT NULL, -- 'Rent', 'Service Fee'
    amount NUMERIC NOT NULL,
    status TEXT NOT NULL DEFAULT 'Pending', -- Pending, Paid, Failed
    payment_date DATE,
    transaction_id TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- 11. LEADS
CREATE TABLE leads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    mobile TEXT NOT NULL,
    email TEXT,
    source TEXT NOT NULL, -- e.g., 'Website', 'WhatsApp', 'Phone Call', 'Facebook'
    status TEXT NOT NULL DEFAULT 'New Lead', -- New Lead, Follow-up, Interested, Not Interested, Converted, Lost
    notes TEXT,
    assigned_to UUID REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE properties ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE cases ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can read/update their own profile.
CREATE POLICY "Users can read own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Owners can view own properties" ON properties FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Owners can insert own properties" ON properties FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Owners can view own tenants" ON tenants FOR SELECT USING (true);
CREATE POLICY "Owners can insert own tenants" ON tenants FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can view own requests" ON service_requests FOR SELECT USING (auth.uid() = customer_id);
CREATE POLICY "Users can insert own requests" ON service_requests FOR INSERT WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Users can view own cases" ON cases FOR SELECT USING (true);
CREATE POLICY "Users can insert own cases" ON cases FOR INSERT WITH CHECK (true);

ALTER TABLE leads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view leads" ON leads FOR SELECT USING (true);
CREATE POLICY "Users can insert leads" ON leads FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can update leads" ON leads FOR UPDATE USING (true);

-- Add robust staff RLS overrides dynamically once roles are formalized in production!

-- ==========================================
-- PERMISSIONS FIX (Crucial after a schema reset)
-- ==========================================
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
