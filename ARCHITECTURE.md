# Vakil Sirji Platform - Architecture Diagram

## Tech Stack
- **Frontend**: Flutter (cross-platform mobile/web)
- **Backend**: Supabase (PostgreSQL + Auth + Storage)
- **State Management**: Provider
- **Routing**: go_router
- **File Handling**: file_picker
- **Deep Linking**: url_launcher

## Architecture Overview

```mermaid
graph TB
    subgraph "Flutter App"
        App[main.dart]
        Router[Go<br/>Router]
        AuthWrapper[Auth<br/>Wrapper]
        
        subgraph "Features"
            Customer[Customer<br/>Dashboard]
            Tenant[Tenant<br/>Dashboard]
            Staff[Staff<br/>Dashboard]
            Admin[Admin<br/>Dashboard]
        end
        
        subgraph "Services"
            AuthService[Auth<br/>Service]
            DBService[Database<br/>Service]
            SupabaseService[Supabase<br/>Service]
        end
        
        subgraph "Models"
            UserProfile[User<br/>Profile]
            Property[Property]
            Tenant[Tenant]
            LegalCase[Legal<br/>Case]
            Document[Document]
            Payment[Payment]
            Lead[Lead]
            Client[Client]
        end
    end
    
    subgraph "Supabase Backend"
        Auth[Supabase<br/>Auth]
        PostgreSQL[(PostgreSQL<br/>Database)]
        Storage[Supabase<br/>Storage]
    end
    
    App --> Router
    Router --> AuthWrapper
    AuthWrapper -->|Role-based| Customer
    AuthWrapper -->|Role-based| Tenant
    AuthWrapper -->|Role-based| Staff
    AuthWrapper -->|Role-based| Admin
    
    Customer --> AuthService
    Customer --> DBService
    Tenant --> AuthService
    Tenant --> DBService
    Staff --> AuthService
    Staff --> DBService
    Admin --> AuthService
    Admin --> DBService
    
    AuthService --> SupabaseService
    DBService --> SupabaseService
    SupabaseService --> Auth
    SupabaseService --> PostgreSQL
    DBService --> Storage
    
    DBService --> UserProfile
    DBService --> Property
    DBService --> Tenant
    DBService --> LegalCase
    DBService --> Document
    DBService --> Payment
    DBService --> Lead
    DBService --> Client
```

## User Roles & Dashboards

```mermaid
graph LR
    User[User] -->|Authenticates| AuthSystem[Supabase Auth]
    AuthSystem -->|Returns Role| RoleCheck[Role Check]
    
    RoleCheck -->|Admin| AdminDash[Admin Dashboard]
    RoleCheck -->|Owner| CustomerDash[Customer Dashboard]
    RoleCheck -->|Tenant| TenantDash[Tenant Dashboard]
    RoleCheck -->|Staff| StaffDash[Staff Dashboard]
    
    AdminDash -->|Can Manage| StaffMgmt[Staff Management]
    AdminDash -->|Can View| AllData[All Platform Data]
    
    CustomerDash -->|Can Manage| Properties[Properties]
    CustomerDash -->|Can Create| ServiceReq[Service Requests]
    CustomerDash -->|Can View| Cases[Legal Cases]
    CustomerDash -->|Can Track| Payments[Payments]
    
    TenantDash -->|Can View| TenantProp[Rented Property]
    TenantDash -->|Can View| TenantDocs[Documents]
    TenantDash -->|Can View| TenantPays[Payments]
    
    StaffDash -->|Can Process| CRM[CRM Cases]
    StaffDash -->|Can Manage| Leads[Leads]
    StaffDash -->|Can Manage| Clients[Clients]
```

## Database Schema

```mermaid
erDiagram
    profiles ||--o{ properties : "owns"
    profiles ||--o{ service_requests : "creates"
    profiles ||--o{ cases : "assigned to"
    profiles ||--o{ leads : "assigned to"
    profiles ||--o{ documents : "uploads"
    
    properties ||--o{ tenants : "has current"
    properties ||--o{ service_requests : "references"
    properties ||--o{ agreements : "references"
    properties ||--o{ documents : "has"
    properties ||--o{ payments : "generates"
    
    tenants ||--o{ agreements : "party to"
    tenants ||--o{ service_requests : "references"
    tenants ||--o{ documents : "has"
    
    service_requests ||--|| cases : "becomes"
    cases ||--o{ agreements : "has"
    cases ||--o{ case_tasks : "contains"
    
    agreements ||--o{ witnesses : "has"
    
    profiles {
        uuid id PK
        string name
        string email
        string mobile
        string role
        string aadhaar
        string pan
        string address
        timestamp joined_date
    }
    
    properties {
        uuid id PK
        uuid owner_id FK
        string name
        string address
        string city
        string state
        string pin_code
        string property_type
        jsonb photos
        numeric rent_amount
        numeric deposit_amount
        uuid current_tenant_id FK
        boolean reminder_enabled
        int reminder_due_day
        string reminder_channel
    }
    
    tenants {
        uuid id PK
        uuid property_id FK
        string name
        string email
        string mobile
        string aadhaar
        string pan
        string current_address
        string permanent_address
        date move_in_date
        date move_out_date
    }
    
    service_requests {
        uuid id PK
        uuid customer_id FK
        string service_type
        string status
        jsonb details
    }
    
    cases {
        uuid id PK
        uuid service_request_id FK
        uuid assigned_to FK
        string title
        string status
        text notes
    }
    
    agreements {
        uuid id PK
        uuid case_id FK
        uuid property_id FK
        uuid tenant_id FK
        date start_date
        date end_date
        numeric monthly_rent
        numeric security_deposit
    }
    
    documents {
        uuid id PK
        uuid entity_id
        string entity_type
        string document_type
        string file_url
        uuid uploaded_by FK
    }
    
    payments {
        uuid id PK
        uuid entity_id
        string entity_type
        numeric amount
        string status
        date payment_date
        string transaction_id
    }
    
    leads {
        uuid id PK
        string name
        string mobile
        string email
        string source
        string status
        text notes
        uuid assigned_to FK
    }
```

## Data Flow: Service Request to Case

```mermaid
sequenceDiagram
    participant Customer
    participant CustomerDash
    participant DBService
    participant Supabase
    participant Staff
    participant StaffDash
    
    Customer->>CustomerDash: Create Service Request
    CustomerDash->>DBService: createServiceRequest()
    DBService->>Supabase: Insert service_requests
    Supabase-->>DBService: Returns service_request_id
    DBService->>Supabase: Insert cases (auto-created)
    DBService->>Supabase: Update property (if existing agreement)
    DBService-->>CustomerDash: Success
    CustomerDash-->>Customer: Request Created
    
    Staff->>StaffDash: View Dashboard
    StaffDash->>DBService: fetchAdminDashboardData()
    DBService->>Supabase: Fetch all cases
    Supabase-->>DBService: Cases with service_requests
    DBService-->>StaffDash: Display Cases
    
    Staff->>StaffDash: Process Case
    StaffDash->>DBService: updateCaseStatus()
    DBService->>Supabase: Update case status
    DBService-->>StaffDash: Status Updated
```

## Key Service Methods

### AuthService
- `signIn(email, password)` - User authentication
- `signUp(email, password, name, mobile, role)` - User registration
- `adminCreateStaff(email, password, name, mobile)` - Staff creation by admin
- `signOut()` - User logout
- Listens to Supabase auth state changes

### DatabaseService
- `fetchCustomerDashboardData(userId)` - Loads owner's properties, tenants, cases
- `fetchTenantDashboardData(userMobile)` - Loads tenant's property, payments, documents
- `fetchAdminDashboardData()` - Loads all platform data
- `createServiceRequest(customerId, serviceType, propertyId, tenantId)` - Creates request + case
- `addProperty()`, `updateProperty()`, `deleteProperty()` - Property CRUD
- `addTenant()`, `updateTenant()`, `deleteTenant()` - Tenant CRUD
- `uploadPropertyPhoto()`, `uploadDocument()` - File uploads
- `addPayment()`, `generateInvoice()` - Payment management
- `addLead()`, `updateLeadStatus()` - Lead management

## Feature Structure

```
lib/
├── core/
│   ├── constants.dart          # App colors, Supabase credentials
│   └── router.dart              # GoRouter configuration
├── services/
│   ├── auth_service.dart        # Authentication logic
│   ├── database_service.dart    # Data operations (806 lines)
│   └── supabase_service.dart    # Supabase initialization
├── models/
│   ├── user_profile.dart        # User roles enum + profile
│   ├── property.dart            # Property model
│   ├── tenant.dart              # Tenant model
│   ├── legal_case.dart          # Legal case model
│   ├── document.dart            # Document model
│   ├── payment.dart             # Payment model
│   ├── lead.dart                # Lead model
│   └── client.dart              # Client model
└── features/
    ├── auth/
    │   ├── auth_wrapper.dart    # Role-based routing
    │   ├── login_screen.dart    # Login UI
    │   └── register_screen.dart # Registration UI
    ├── customer/                # Owner dashboard (11 screens)
    ├── tenant/                  # Tenant dashboard (3 tabs)
    ├── crm/                     # Staff dashboard (11 screens)
    └── admin/                   # Admin dashboard (3 screens)
```

## Security Model

- **Row Level Security (RLS)** enabled on all tables
- **Profiles**: Users can only read/update their own profile
- **Properties**: Owners can only view/manage their properties
- **Service Requests**: Users can only view their own requests
- **Cases**: Staff can view all cases (for CRM operations)
- **Leads**: Staff can manage all leads

## Storage Buckets

- `properties` - Property photos
- `documents` - General documents (Aadhaar, PAN, etc.)
- `agreements` - Legal agreement documents
