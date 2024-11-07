-- Drop tables if they exist (this will force a schema refresh)
drop table if exists sale_items;
drop table if exists sales;

-- Create sales table
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
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Create sale items table
create table if not exists sale_items (
    id uuid default uuid_generate_v4() primary key,
    sale_id uuid references sales(id),
    product_id uuid references products(id),
    quantity decimal(10,2) not null,
    unit_price decimal(10,2) not null,
    total_price decimal(10,2) not null,
    discount_percentage decimal(5,2),
    notes text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table sales enable row level security;
alter table sale_items enable row level security;

-- Drop existing policies if they exist
drop policy if exists "Users can view their own sales and admins can view all" on sales;
drop policy if exists "Users can insert their own sales" on sales;
drop policy if exists "Only admins can update sales" on sales;
drop policy if exists "Users can view sale items they have access to" on sale_items;
drop policy if exists "Users can insert sale items for their sales" on sale_items;

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

-- Create indexes
create index if not exists idx_sales_client_id on sales(client_id);
create index if not exists idx_sales_created_by on sales(created_by);
create index if not exists idx_sale_items_sale_id on sale_items(sale_id);
create index if not exists idx_sale_items_product_id on sale_items(product_id);

-- Force schema cache refresh
select pg_notify('pgrst', 'reload schema');