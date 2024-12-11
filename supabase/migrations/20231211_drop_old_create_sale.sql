-- Drop the old version of create_sale_with_items that uses sale_item_type[]
DROP FUNCTION IF EXISTS public.create_sale_with_items(
    p_client_id uuid,
    p_sale_date timestamp with time zone,
    p_delivery_date timestamp with time zone,
    p_delivery_address_id uuid,
    p_total_amount numeric,
    p_notes text,
    p_items public.sale_item_type[]
);
