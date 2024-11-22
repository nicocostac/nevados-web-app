-- Test data
SELECT 
    cp.*,
    p.name as product_name
FROM client_prices cp
JOIN products p ON p.id = cp.product_id
WHERE cp.client_id = '13cc520b-a18d-4ebf-a4e4-aed7f1e22a7e'  -- Replace with your client ID
AND cp.start_date <= CURRENT_DATE
AND (cp.end_date IS NULL OR cp.end_date > CURRENT_DATE);

-- Test the function directly
SELECT * FROM get_product_price_at_date(
    '492d2aa4-2135-4a62-860b-ac541aa5717b',  -- Replace with your product ID
    CURRENT_DATE,
    '13cc520b-a18d-4ebf-a4e4-aed7f1e22a7e'   -- Replace with your client ID
);

-- Test with a date when the special price is valid
SELECT * FROM get_product_price_at_date(
    '492d2aa4-2135-4a62-860b-ac541aa5717b',  -- product_id (Recarga 10L)
    '2024-11-22',                             -- target_date when special price is valid
    '13cc520b-a18d-4ebf-a4e4-aed7f1e22a7e'   -- client_id
);

-- Test multiple products at once
SELECT 
    p.id as product_id,
    p.name as product_name,
    price.price,
    price.price_type
FROM products p
CROSS JOIN LATERAL (
    SELECT * FROM get_product_price_at_date(
        p.id,
        CURRENT_DATE,
        '13cc520b-a18d-4ebf-a4e4-aed7f1e22a7e'  -- Replace with your client ID
    )
) price
WHERE p.id IN (
    '492d2aa4-2135-4a62-860b-ac541aa5717b',  -- Replace with your product IDs
    'aa5fced8-b36c-4196-9bcf-a36bb2204cd3'
)
ORDER BY p.name;
