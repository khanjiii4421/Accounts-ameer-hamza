-- 1. Enable UUID extension for unique IDs
create extension if not exists "uuid-ossp";

-- 2. Create TABLES

-- USERS (For Authentication & Roles)
create table users (
  id uuid default uuid_generate_v4() primary key,
  username text unique not null,
  password text not null, -- In a real app, hash this! For now, storing as is per request style
  name text,
  role text check (role in ('Admin', 'Manager', 'Accountant', 'Viewer')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- CLIENTS
create table clients (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  phone text,
  address text,
  email text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- VENDORS
create table vendors (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  phone text,
  address text,
  category text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- PROJECTS
create table projects (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  description text,
  location text,
  status text check (status in ('Active', 'Completed', 'OnHold')),
  client_id uuid references clients(id),
  start_date date,
  end_date date,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- LEDGER ENTRIES (The heart of the accounting)
create table ledger_entries (
  id uuid default uuid_generate_v4() primary key,
  type text check (type in ('CREDIT', 'DEBIT')),
  amount numeric(15, 2) not null,
  description text,
  date timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Links to other entities
  client_id uuid references clients(id) on delete set null,
  vendor_id uuid references vendors(id) on delete set null,
  project_id uuid references projects(id) on delete set null,
  
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- OFFICE EXPENSES
create table office_expenses (
  id uuid default uuid_generate_v4() primary key,
  title text not null,
  amount numeric(15, 2) not null,
  category text,
  date timestamp with time zone default timezone('utc'::text, now()) not null,
  created_by uuid references users(id),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- SETTINGS / PROFILE
create table company_profile (
  id integer primary key default 1, -- Singleton row
  name text default 'My Company',
  address text,
  phone text,
  admin_password text default 'admin123',
  letterhead_url text,
  logo_url text,
  sidebar_logo_url text,
  updated_at timestamp with time zone default timezone('utc'::text, now())
);

-- 3. INSERT DEFAULT ADMIN USER
insert into users (username, password, name, role)
values ('admin', 'admin123', 'Super Admin', 'Admin')
on conflict (username) do nothing;

-- 4. INSERT DEFAULT PROFILE
insert into company_profile (id, name, address)
values (1, 'Construction Co.', '123 Main St')
on conflict (id) do nothing;

-- 5. ENABLE ROW LEVEL SECURITY (Optional for now, but good practice)
alter table users enable row level security;
alter table clients enable row level security;
alter table vendors enable row level security;
alter table projects enable row level security;
alter table ledger_entries enable row level security;
alter table office_expenses enable row level security;

-- POLICY: Allow public read/write for now (since we use internal API logic)
-- IMPORTANT: For production, you should lock this down!
create policy "Allow all access" on users for all using (true) with check (true);
create policy "Allow all access" on clients for all using (true) with check (true);
create policy "Allow all access" on vendors for all using (true) with check (true);
create policy "Allow all access" on projects for all using (true) with check (true);
create policy "Allow all access" on ledger_entries for all using (true) with check (true);
create policy "Allow all access" on office_expenses for all using (true) with check (true);
create policy "Allow all access" on company_profile for all using (true) with check (true);
