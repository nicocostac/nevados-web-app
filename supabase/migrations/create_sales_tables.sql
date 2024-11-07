-- Create payment methods table first
create table if not exists payment_methods (
    id uuid default uuid_generate_v4() primary key,
    name text not null,
    description text,
    status text not null default 'active',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Add default payment methods
insert into payment_methods (name, description) values
    ('Cash', 'Cash payment'),
    ('Bank Transfer', 'Direct bank transfer'),
    ('Debit Card', 'Payment via debit card'),
    ('Credit Card', 'Payment via credit card');

-- Drop existing tables
drop table if exists sale_items;
drop table if exists sales;

-- Create sales table with payment fields
create table if not exists sales (
    id uuid default uuid_generate_v4() primary key,
    client_id uuid references clients(id),
    created_by uuid references profiles(id),
    sale_date date not null default current_date,
    delivery_date date,
    delivery_address_id uuid references client_addresses(id),
    status text not null default 'active',
    total_amount decimal(10,2) not null,
    notes text,
    payment_status text not null default 'pending',
    payment_method_id uuid references payment_methods(id),
    payment_date timestamp with time zone,
    payment_notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create sale items table
create table if not exists sale_items (
    id uuid default uuid_generate_v4() primary key,
    sale_id uuid references sales(id),
    product_id uuid references products(id),
    item_number integer not null,
    quantity decimal(10,2) not null,
    unit_price decimal(10,2) not null,
    total_price decimal(10,2) not null,
    discount_percentage decimal(5,2),
    notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    -- Update unique constraint to include item_number
    unique(sale_id, product_id, item_number)
);

-- Enable RLS
alter table sales enable row level security;
alter table sale_items enable row level security;
alter table payment_methods enable row level security;

-- Drop existing policies if they exist
drop policy if exists "Users can view their own sales and admins can view all" on sales;
drop policy if exists "Users can insert their own sales" on sales;
drop policy if exists "Only admins can update sales" on sales;
drop policy if exists "Users can view sale items they have access to" on sale_items;
drop policy if exists "Users can insert sale items for their sales" on sale_items;
drop policy if exists "Users can update sale items for their sales" on sale_items;
drop policy if exists "Users can delete sale items for their sales" on sale_items;
drop policy if exists "Everyone can view active payment methods" on payment_methods;
drop policy if exists "Only admins can insert payment methods" on payment_methods;
drop policy if exists "Only admins can update payment methods" on payment_methods;

-- Create policies
create policy "Users can view their own sales and admins can view all"
    on sales for select
    using (
        auth.uid() = created_by
        or exists (
            select 1 from profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "Users can insert their own sales"
    on sales for insert
    with check (auth.uid() = created_by);

create policy "Only admins can update sales"
    on sales for update
    using (
        exists (
            select 1 from profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

-- Policies for sale items
create policy "Users can view sale items they have access to"
    on sale_items for select
    using (
        exists (
            select 1 from sales
            where sales.id = sale_items.sale_id
            and (
                sales.created_by = auth.uid()
                or exists (
                    select 1 from profiles
                    where profiles.id = auth.uid()
                    and profiles.role = 'admin'
                )
            )
        )
    );

create policy "Users can insert sale items for their sales"
    on sale_items for insert
    with check (
        exists (
            select 1 from sales
            where sales.id = sale_items.sale_id
            and sales.created_by = auth.uid()
        )
    );

create policy "Users can update sale items for their sales"
    on sale_items for update
    using (
        exists (
            select 1 from sales
            where sales.id = sale_items.sale_id
            and sales.created_by = auth.uid()
        )
    );

create policy "Users can delete sale items for their sales"
    on sale_items for delete
    using (
        exists (
            select 1 from sales
            where sales.id = sale_items.sale_id
            and sales.created_by = auth.uid()
        )
    );

-- Policies for payment_methods
create policy "Everyone can view active payment methods"
    on payment_methods for select
    using (status = 'active');

create policy "Only admins can insert payment methods"
    on payment_methods for insert
    with check (
        exists (
            select 1 from profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

create policy "Only admins can update payment methods"
    on payment_methods for update
    using (
        exists (
            select 1 from profiles
            where profiles.id = auth.uid()
            and profiles.role = 'admin'
        )
    );

-- Create indexes
create index if not exists idx_sales_client_id on sales(client_id);
create index if not exists idx_sales_created_by on sales(created_by);
create index if not exists idx_sale_items_sale_id on sale_items(sale_id);
create index if not exists idx_sale_items_product_id on sale_items(product_id);
create index if not exists idx_sales_payment_method on sales(payment_method_id);

-- Force schema cache refresh
select pg_notify('pgrst', 'reload schema');