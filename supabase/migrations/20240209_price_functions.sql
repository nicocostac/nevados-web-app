-- First revoke permissions
REVOKE ALL ON FUNCTION public.get_product_price_at_date(uuid, date, uuid) FROM anon;
REVOKE ALL ON FUNCTION public.get_product_price_at_date(uuid, date, uuid) FROM authenticated;
REVOKE ALL ON FUNCTION public.get_product_price_at_date(uuid, date, uuid) FROM service_role;

-- Then drop the existing function
DROP FUNCTION IF EXISTS public.get_product_price_at_date(uuid, date, uuid);

-- Create new function with updated return type
CREATE OR REPLACE FUNCTION public.get_product_price_at_date(
    product_id uuid,
    target_date date,
    client_id uuid DEFAULT NULL::uuid
) RETURNS TABLE (
    price numeric,
    price_type text,
    bundle_id uuid,
    bundle_quantity numeric,
    bundle_products jsonb,
    quantity_bundles jsonb
) AS $$
DECLARE
    v_quantity_bundles jsonb;
BEGIN
    -- First get all quantity bundles for the product
    SELECT jsonb_agg(
        jsonb_build_object(
            'bundle_quantity', mbi.quantity,
            'price', mb.total_price
        )
    )
    INTO v_quantity_bundles
    FROM mixed_bundles mb
    JOIN mixed_bundle_items mbi ON mbi.bundle_id = mb.id
    WHERE mbi.product_id = get_product_price_at_date.product_id
    AND mb.start_date <= target_date
    AND (mb.end_date IS NULL OR mb.end_date >= target_date)
    AND (
        -- Check if this is a quantity bundle (only one product in bundle)
        SELECT COUNT(DISTINCT mbi2.product_id) = 1
        FROM mixed_bundle_items mbi2
        WHERE mbi2.bundle_id = mb.id
    );

    -- Then check for client-specific prices
    RETURN QUERY
    WITH bundle_info AS (
        -- Get bundle information including number of products
        SELECT 
            mb.id,
            mb.total_price,
            COUNT(mbi.product_id) as product_count,
            MIN(mbi.quantity) as min_quantity,
            jsonb_agg(jsonb_build_object(
                'product_id', mbi.product_id,
                'quantity', mbi.quantity
            )) as bundle_products
        FROM mixed_bundles mb
        JOIN mixed_bundle_items mbi ON mbi.bundle_id = mb.id
        WHERE mb.start_date <= target_date
        AND (mb.end_date IS NULL OR mb.end_date >= target_date)
        GROUP BY mb.id, mb.total_price
    ),
    price_sources AS (
        -- Client specific price (highest priority)
        SELECT 
            cp.final_price as price,
            'client'::text as price_type,
            NULL::uuid as bundle_id,
            NULL::numeric as bundle_quantity,
            NULL::jsonb as bundle_products,
            v_quantity_bundles as quantity_bundles,
            1 as priority
        FROM client_prices cp
        WHERE cp.product_id = get_product_price_at_date.product_id
        AND cp.client_id = get_product_price_at_date.client_id
        AND cp.start_date <= target_date
        AND (cp.end_date IS NULL OR cp.end_date >= target_date)
        
        UNION ALL
        
        -- Mixed bundle price (if this is a bundle)
        SELECT 
            mb.total_price as price,
            'bundle'::text as price_type,
            mb.id as bundle_id,
            NULL::numeric as bundle_quantity,
            bi.bundle_products,
            v_quantity_bundles as quantity_bundles,
            2 as priority
        FROM mixed_bundles mb
        JOIN bundle_info bi ON bi.id = mb.id
        WHERE mb.id = get_product_price_at_date.product_id
        AND mb.start_date <= target_date
        AND (mb.end_date IS NULL OR mb.end_date >= target_date)
        
        UNION ALL
        
        -- Regular product price (lowest priority)
        SELECT 
            pp.price as price,
            'regular'::text as price_type,
            NULL::uuid as bundle_id,
            NULL::numeric as bundle_quantity,
            NULL::jsonb as bundle_products,
            v_quantity_bundles as quantity_bundles,
            3 as priority
        FROM product_prices pp
        WHERE pp.product_id = get_product_price_at_date.product_id
        AND pp.start_date <= target_date
        AND (pp.end_date IS NULL OR pp.end_date >= target_date)
    )
    SELECT 
        ps.price,
        ps.price_type,
        ps.bundle_id,
        ps.bundle_quantity,
        ps.bundle_products,
        ps.quantity_bundles
    FROM price_sources ps
    ORDER BY ps.priority
    LIMIT 1;

    -- If no price found, return 0 with type 'none'
    IF NOT FOUND THEN
        RETURN QUERY SELECT 
            0::numeric as price,
            'none'::text as price_type,
            NULL::uuid as bundle_id,
            NULL::numeric as bundle_quantity,
            NULL::jsonb as bundle_products,
            v_quantity_bundles as quantity_bundles;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER
SET search_path = public;

-- Grant permissions
GRANT ALL ON FUNCTION public.get_product_price_at_date(uuid, date, uuid) TO anon;
GRANT ALL ON FUNCTION public.get_product_price_at_date(uuid, date, uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_product_price_at_date(uuid, date, uuid) TO service_role;
