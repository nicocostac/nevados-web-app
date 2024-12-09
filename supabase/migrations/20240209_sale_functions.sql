-- Drop and recreate function (type already exists)
CREATE OR REPLACE FUNCTION create_sale_with_items(
    p_client_id uuid,
    p_sale_date timestamp with time zone,
    p_delivery_date timestamp with time zone,
    p_delivery_address_id uuid,
    p_total_amount numeric,
    p_notes text,
    p_items sale_item_type[]
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_sale_id uuid;
    v_item sale_item_type;
    v_item_number integer := 1;
BEGIN
    -- Insert the sale
    INSERT INTO sales (
        client_id,
        sale_date,
        delivery_date,
        delivery_address_id,
        total_amount,
        notes,
        created_at,
        updated_at
    ) VALUES (
        p_client_id,
        p_sale_date,
        p_delivery_date,
        p_delivery_address_id,
        p_total_amount,
        p_notes,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO v_sale_id;

    -- Insert each sale item
    FOREACH v_item IN ARRAY p_items
    LOOP
        INSERT INTO sale_items (
            sale_id,
            product_id,
            item_number,
            quantity,
            unit_price,
            total_price,
            created_at
        ) VALUES (
            v_sale_id,
            v_item.product_id,
            v_item_number,
            v_item.quantity,
            v_item.unit_price,
            v_item.total_price,
            CURRENT_TIMESTAMP
        );
        
        v_item_number := v_item_number + 1;
    END LOOP;

    RETURN v_sale_id;
END;
$$;

-- Function to update an existing sale with items
CREATE OR REPLACE FUNCTION update_sale_with_items(
    p_sale_id uuid,
    p_client_id uuid,
    p_sale_date timestamp with time zone,
    p_delivery_date timestamp with time zone,
    p_delivery_address_id uuid,
    p_total_amount numeric,
    p_notes text,
    p_items sale_item_type[],
    p_payment_status text DEFAULT 'pending',
    p_payment_method_id uuid DEFAULT NULL,
    p_payment_date timestamp with time zone DEFAULT NULL,
    p_payment_notes text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_item sale_item_type;
    v_item_number integer := 1;
BEGIN
    -- Update the sale
    UPDATE sales SET
        client_id = p_client_id,
        sale_date = p_sale_date,
        delivery_date = p_delivery_date,
        delivery_address_id = p_delivery_address_id,
        total_amount = p_total_amount,
        notes = p_notes,
        payment_status = p_payment_status,
        payment_method_id = p_payment_method_id,
        payment_date = p_payment_date,
        payment_notes = p_payment_notes,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_sale_id;

    -- Delete existing items
    DELETE FROM sale_items WHERE sale_id = p_sale_id;

    -- Insert updated items
    FOREACH v_item IN ARRAY p_items
    LOOP
        INSERT INTO sale_items (
            sale_id,
            product_id,
            item_number,
            quantity,
            unit_price,
            total_price,
            created_at
        ) VALUES (
            p_sale_id,
            v_item.product_id,
            v_item_number,
            v_item.quantity,
            v_item.unit_price,
            v_item.total_price,
            CURRENT_TIMESTAMP
        );
        
        v_item_number := v_item_number + 1;
    END LOOP;

    RETURN p_sale_id;
END;
$$;
