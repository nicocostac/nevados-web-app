--
-- PostgreSQL database dump
--

-- Dumped from database version 15.6
-- Dumped by pg_dump version 15.9 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: pgsodium; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgsodium;


--
-- Name: pgsodium; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgsodium WITH SCHEMA pgsodium;


--
-- Name: EXTENSION pgsodium; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgsodium IS 'Pgsodium is a modern cryptography library for Postgres.';


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: pgjwt; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgjwt WITH SCHEMA extensions;


--
-- Name: EXTENSION pgjwt; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgjwt IS 'JSON Web Token API for Postgresql';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: sale_item_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.sale_item_type AS (
	product_id uuid,
	quantity numeric,
	unit_price numeric,
	total_price numeric
);


--
-- Name: user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'manager',
    'salesperson',
    'support'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
    ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

    ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
    ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

    REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
    REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

    GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    RAISE WARNING 'PgBouncer auth request: %', p_usename;

    RETURN QUERY
    SELECT usename::TEXT, passwd::TEXT FROM pg_catalog.pg_shadow
    WHERE usename = p_usename;
END;
$$;


--
-- Name: create_sale_with_items(uuid, timestamp with time zone, timestamp with time zone, uuid, numeric, text, jsonb[], text, uuid, timestamp with time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.create_sale_with_items(p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items jsonb[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    v_sale_id uuid;
    v_item jsonb;
BEGIN
    -- Insert the sale
    INSERT INTO sales (
        client_id,
        sale_date,
        delivery_date,
        delivery_address_id,
        total_amount,
        notes,
        payment_status,
        payment_method_id,
        payment_date,
        payment_notes
    ) VALUES (
        p_client_id,
        p_sale_date,
        p_delivery_date,
        p_delivery_address_id,
        p_total_amount,
        p_notes,
        p_payment_status,
        p_payment_method_id,
        p_payment_date,
        p_payment_notes
    )
    RETURNING id INTO v_sale_id;

    -- Insert sale items
    FOR i IN 1..array_length(p_items, 1) LOOP
        v_item := p_items[i];
        INSERT INTO sale_items (
            sale_id,
            product_id,
            item_number,
            quantity,
            unit_price,
            total_price,
            discount_percentage
        ) VALUES (
            v_sale_id,
            (v_item->>'productId')::uuid,
            i,
            COALESCE((v_item->>'quantity')::numeric, 0),
            COALESCE((v_item->>'unitPrice')::numeric, 0),
            COALESCE((v_item->>'totalPrice')::numeric, 0),
            COALESCE((v_item->>'discountPercentage')::numeric, 0)
        );
    END LOOP;

    RETURN v_sale_id;
END;
$$;


--
-- Name: ensure_single_default_address(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.ensure_single_default_address() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.is_default THEN
        UPDATE client_addresses
        SET is_default = false
        WHERE client_id = NEW.client_id
        AND id != NEW.id;
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: get_product_price_at_date(uuid, date, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_product_price_at_date(product_id uuid, target_date date, client_id uuid DEFAULT NULL::uuid) RETURNS TABLE(price numeric, price_type text, bundle_id uuid, bundle_quantity numeric, bundle_products jsonb, quantity_bundles jsonb)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
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
$$;


--
-- Name: get_quantity_based_price(uuid, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_quantity_based_price(p_product_id uuid, p_quantity numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_price numeric;
BEGIN
    SELECT price INTO v_price
    FROM public.product_prices
    WHERE product_id = p_product_id
        AND min_quantity <= p_quantity
        AND (max_quantity IS NULL OR max_quantity >= p_quantity)
        AND (end_date IS NULL OR end_date >= CURRENT_DATE)
    ORDER BY min_quantity DESC
    LIMIT 1;

    RETURN COALESCE(v_price, (
        SELECT price 
        FROM public.product_prices 
        WHERE product_id = p_product_id 
        AND min_quantity = 1
        AND (end_date IS NULL OR end_date >= CURRENT_DATE)
        ORDER BY start_date DESC 
        LIMIT 1
    ));
END;
$$;


--
-- Name: handle_client_price_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_client_price_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: handle_client_type_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_client_type_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: handle_client_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_client_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    INSERT INTO public.profiles (id, email, role, first_name, last_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'role', 'salesperson')::user_role,
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name'
    )
    ON CONFLICT (id) DO UPDATE
    SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name;
    RETURN NEW;
END;
$$;


--
-- Name: handle_product_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_product_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: handle_profile_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_profile_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


--
-- Name: sync_user_email(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sync_user_email() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
   BEGIN
       UPDATE public.profiles
       SET email = NEW.email
       WHERE id = NEW.id;
       RETURN NEW;
   END;
   $$;


--
-- Name: trigger_set_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trigger_set_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc'::text, NOW());
  RETURN NEW;
END;
$$;


--
-- Name: update_address_coordinates(uuid, double precision, double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_address_coordinates(address_id uuid, lat double precision, lng double precision) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
begin
  update client_addresses
  set 
    latitude = lat,
    longitude = lng,
    updated_at = now()
  where id = address_id;
end;
$$;


--
-- Name: update_product_price(numeric, uuid, uuid, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_product_price(p_new_price numeric, p_product_id uuid, p_user_id uuid, p_start_date date DEFAULT CURRENT_DATE) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_price numeric;
    v_current_price_id uuid;
    v_current_start_date date;
    v_next_price_record RECORD;
    v_price_exists boolean;
BEGIN
    -- Get current active price record
    SELECT id, price, start_date INTO v_current_price_id, v_current_price, v_current_start_date
    FROM product_prices
    WHERE product_id = p_product_id
    AND start_date <= CURRENT_DATE
    AND (end_date IS NULL OR end_date > CURRENT_DATE)
    ORDER BY start_date DESC
    LIMIT 1;

    -- Get next scheduled price change if any
    SELECT * INTO v_next_price_record
    FROM product_prices
    WHERE product_id = p_product_id
    AND start_date > CURRENT_DATE
    ORDER BY start_date ASC
    LIMIT 1;

    -- Check if there's already a price for this date
    SELECT EXISTS (
        SELECT 1 
        FROM product_prices 
        WHERE product_id = p_product_id 
        AND start_date = p_start_date
    ) INTO v_price_exists;

    -- Only proceed if the price is different or date is different
    IF NOT v_price_exists AND (v_current_price IS DISTINCT FROM p_new_price OR v_current_start_date IS DISTINCT FROM p_start_date) THEN
        -- If the new start date is before any existing future prices
        IF v_next_price_record.id IS NOT NULL AND p_start_date >= v_next_price_record.start_date THEN
            RAISE EXCEPTION 'Cannot set price with start date % as it conflicts with a future price starting at %', 
                p_start_date, v_next_price_record.start_date;
        END IF;

        -- Update end_date of the current active price to be the day before the new price starts
        IF v_current_price_id IS NOT NULL THEN
            UPDATE product_prices
            SET end_date = p_start_date - INTERVAL '1 day'
            WHERE id = v_current_price_id;
        END IF;

        -- Insert the new price
        INSERT INTO product_prices (
            product_id,
            price,
            start_date,
            end_date,
            created_by
        ) VALUES (
            p_product_id,
            p_new_price,
            p_start_date,
            NULL,
            p_user_id
        );
    END IF;
END;
$$;


--
-- Name: update_product_price(uuid, integer, date, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_product_price(p_product_id uuid, p_new_price integer, p_valid_from date, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- End any existing price periods that overlap with the new price
    UPDATE product_prices pp
    SET valid_until = p_valid_from - INTERVAL '1 day',
        updated_at = NOW()
    WHERE pp.product_id = p_product_id
    AND pp.valid_until IS NULL
    AND pp.valid_from < p_valid_from;

    -- Insert the new price
    INSERT INTO product_prices (
        product_id,
        price,
        valid_from,
        created_at,
        updated_at
    )
    VALUES (
        p_product_id,
        p_new_price,
        p_valid_from,
        NOW(),
        NOW()
    );
END;
$$;


--
-- Name: update_sale_with_items(uuid, uuid, timestamp with time zone, timestamp with time zone, uuid, numeric, text, public.sale_item_type[], text, uuid, timestamp with time zone, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_sale_with_items(p_sale_id uuid, p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items public.sale_item_type[], p_payment_status text DEFAULT 'pending'::text, p_payment_method_id uuid DEFAULT NULL::uuid, p_payment_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_payment_notes text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
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


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_;

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
    declare
      res jsonb;
    begin
      execute format('select to_jsonb(%L::'|| type_::text || ')', val)  into res;
      return res;
    end
    $$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  partition_name text;
BEGIN
  partition_name := 'messages_' || to_char(NOW(), 'YYYY_MM_DD');

  IF NOT EXISTS (
    SELECT 1
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'realtime'
    AND c.relname = partition_name
  ) THEN
    EXECUTE format(
      'CREATE TABLE realtime.%I PARTITION OF realtime.messages FOR VALUES FROM (%L) TO (%L)',
      partition_name,
      NOW(),
      (NOW() + interval '1 day')::timestamp
    );
  END IF;

  INSERT INTO realtime.messages (payload, event, topic, private, extension)
  VALUES (payload, event, topic, private, 'broadcast');
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
_filename text;
BEGIN
	select string_to_array(name, '/') into _parts;
	select _parts[array_length(_parts,1)] into _filename;
	-- @todo return the last part instead of 2
	return reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[1:array_length(_parts,1)-1];
END
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::int) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(name COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                        substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1)))
                    ELSE
                        name
                END AS name, id, metadata, updated_at
            FROM
                storage.objects
            WHERE
                bucket_id = $5 AND
                name ILIKE $1 || ''%'' AND
                CASE
                    WHEN $6 != '''' THEN
                    name COLLATE "C" > $6
                ELSE true END
                AND CASE
                    WHEN $4 != '''' THEN
                        CASE
                            WHEN position($2 IN substring(name from length($1) + 1)) > 0 THEN
                                substring(name from 1 for length($1) + position($2 IN substring(name from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                name COLLATE "C" > $4
                            END
                    ELSE
                        true
                END
            ORDER BY
                name COLLATE "C" ASC) as e order by name COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_token, bucket_id, start_after;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
declare
  v_order_by text;
  v_sort_order text;
begin
  case
    when sortcolumn = 'name' then
      v_order_by = 'name';
    when sortcolumn = 'updated_at' then
      v_order_by = 'updated_at';
    when sortcolumn = 'created_at' then
      v_order_by = 'created_at';
    when sortcolumn = 'last_accessed_at' then
      v_order_by = 'last_accessed_at';
    else
      v_order_by = 'name';
  end case;

  case
    when sortorder = 'asc' then
      v_sort_order = 'asc';
    when sortorder = 'desc' then
      v_sort_order = 'desc';
    else
      v_sort_order = 'asc';
  end case;

  v_order_by = v_order_by || ' ' || v_sort_order;

  return query execute
    'with folders as (
       select path_tokens[$1] as folder
       from storage.objects
         where objects.name ilike $2 || $3 || ''%''
           and bucket_id = $4
           and array_length(objects.path_tokens, 1) <> $1
       group by folder
       order by folder ' || v_sort_order || '
     )
     (select folder as "name",
            null as id,
            null as updated_at,
            null as created_at,
            null as last_accessed_at,
            null as metadata from folders)
     union all
     (select path_tokens[$1] as "name",
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
     from storage.objects
     where objects.name ilike $2 || $3 || ''%''
       and bucket_id = $4
       and array_length(objects.path_tokens, 1) = $1
     order by ' || v_order_by || ')
     limit $5
     offset $6' using levels, prefix, search, bucketname, limits, offsets;
end;
$_$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


--
-- Name: secrets_encrypt_secret_secret(); Type: FUNCTION; Schema: vault; Owner: -
--

CREATE FUNCTION vault.secrets_encrypt_secret_secret() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
		BEGIN
		        new.secret = CASE WHEN new.secret IS NULL THEN NULL ELSE
			CASE WHEN new.key_id IS NULL THEN NULL ELSE pg_catalog.encode(
			  pgsodium.crypto_aead_det_encrypt(
				pg_catalog.convert_to(new.secret, 'utf8'),
				pg_catalog.convert_to((new.id::text || new.description::text || new.created_at::text || new.updated_at::text)::text, 'utf8'),
				new.key_id::uuid,
				new.nonce
			  ),
				'base64') END END;
		RETURN new;
		END;
		$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text NOT NULL,
    code_challenge_method auth.code_challenge_method NOT NULL,
    code_challenge text NOT NULL,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'stores metadata for pkce logins';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: boroughs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.boroughs (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT boroughs_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text])))
);


--
-- Name: client_addresses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_addresses (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    client_id uuid,
    street_address text NOT NULL,
    additional_info text,
    is_default boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    borough_id uuid,
    neighborhood_id uuid,
    latitude numeric(10,8),
    longitude numeric(11,8),
    contact_person text
);


--
-- Name: client_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_prices (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    client_id uuid,
    product_id uuid,
    discount_percentage numeric(5,2),
    final_price numeric(10,2) NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    start_date date DEFAULT CURRENT_DATE NOT NULL,
    end_date date,
    CONSTRAINT valid_discount CHECK (((discount_percentage >= (0)::numeric) AND (discount_percentage <= (100)::numeric)))
);


--
-- Name: client_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_types (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    email text,
    phone text,
    notes text,
    type_id uuid,
    communication_preference text DEFAULT 'email'::text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_by uuid,
    is_tj boolean DEFAULT false NOT NULL,
    phone_2 text
);


--
-- Name: mixed_bundle_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mixed_bundle_items (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    bundle_id uuid NOT NULL,
    product_id uuid NOT NULL,
    quantity numeric(10,2) NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT positive_quantity CHECK ((quantity > (0)::numeric))
);


--
-- Name: mixed_bundles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mixed_bundles (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    description text,
    total_price numeric(10,2) NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_by uuid,
    updated_by uuid,
    start_date date DEFAULT CURRENT_DATE NOT NULL,
    end_date date
);


--
-- Name: neighborhoods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.neighborhoods (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    borough_id uuid NOT NULL,
    status character varying(20) DEFAULT 'active'::character varying,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT neighborhoods_status_check CHECK (((status)::text = ANY (ARRAY[('active'::character varying)::text, ('inactive'::character varying)::text])))
);


--
-- Name: payment_methods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payment_methods (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    description text,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: product_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_categories (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    description text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: product_prices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_prices (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    product_id uuid,
    price numeric(10,2) NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_by uuid,
    updated_by uuid,
    start_date date DEFAULT CURRENT_DATE NOT NULL,
    end_date date,
    min_quantity integer DEFAULT 1 NOT NULL,
    max_quantity integer,
    CONSTRAINT valid_quantity_range CHECK (((max_quantity IS NULL) OR ((min_quantity < max_quantity) AND (min_quantity > 0))))
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    name text NOT NULL,
    description text,
    unit_of_sale text DEFAULT 'unit'::text NOT NULL,
    category_id uuid,
    status text DEFAULT 'active'::text NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    first_name text,
    last_name text,
    phone text,
    is_active boolean DEFAULT true,
    role public.user_role DEFAULT 'salesperson'::public.user_role NOT NULL,
    email text
);


--
-- Name: sale_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sale_items (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    sale_id uuid,
    product_id uuid,
    item_number integer NOT NULL,
    quantity numeric(10,2) NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    total_price numeric(10,2) NOT NULL,
    discount_percentage numeric(5,2),
    notes text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: sales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales (
    id uuid DEFAULT extensions.uuid_generate_v4() NOT NULL,
    client_id uuid,
    created_by uuid,
    sale_date date DEFAULT CURRENT_DATE NOT NULL,
    delivery_date date,
    delivery_address_id uuid,
    status text DEFAULT 'active'::text NOT NULL,
    total_amount numeric(10,2) NOT NULL,
    notes text,
    payment_status text DEFAULT 'pending'::text NOT NULL,
    payment_method_id uuid,
    payment_date timestamp with time zone,
    payment_notes text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    salesperson_id uuid,
    product_id uuid,
    quantity integer DEFAULT 1
);


--
-- Name: sales_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.sales_report AS
 SELECT s.id,
    s.sale_date,
    s.total_amount,
    s.quantity,
    s.salesperson_id,
    p.email AS salesperson_email,
    s.product_id,
    pr.name AS product_name
   FROM ((public.sales s
     LEFT JOIN public.profiles p ON ((s.salesperson_id = p.id)))
     LEFT JOIN public.products pr ON ((s.product_id = pr.id)));


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: decrypted_secrets; Type: VIEW; Schema: vault; Owner: -
--

CREATE VIEW vault.decrypted_secrets AS
 SELECT secrets.id,
    secrets.name,
    secrets.description,
    secrets.secret,
        CASE
            WHEN (secrets.secret IS NULL) THEN NULL::text
            ELSE
            CASE
                WHEN (secrets.key_id IS NULL) THEN NULL::text
                ELSE convert_from(pgsodium.crypto_aead_det_decrypt(decode(secrets.secret, 'base64'::text), convert_to(((((secrets.id)::text || secrets.description) || (secrets.created_at)::text) || (secrets.updated_at)::text), 'utf8'::name), secrets.key_id, secrets.nonce), 'utf8'::name)
            END
        END AS decrypted_secret,
    secrets.key_id,
    secrets.nonce,
    secrets.created_at,
    secrets.updated_at
   FROM vault.secrets;


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
00000000-0000-0000-0000-000000000000	5d37be4a-80d7-42fd-9b0e-59bd55853422	{"action":"user_signedup","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"test@example.com","user_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","user_phone":""}}	2024-11-04 22:41:35.40362+00	
00000000-0000-0000-0000-000000000000	372f665a-3eb3-4ea2-8548-779e0a1c861d	{"action":"user_repeated_signup","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-04 22:43:22.768634+00	
00000000-0000-0000-0000-000000000000	8caf9e52-1039-4c62-9308-053110b4c062	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-04 22:43:22.991402+00	
00000000-0000-0000-0000-000000000000	901a0884-625c-4450-a8ac-8dc6d5419804	{"action":"user_repeated_signup","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-04 22:45:42.026077+00	
00000000-0000-0000-0000-000000000000	5c378856-073b-4dd5-a239-a2aeb12eb11b	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-04 22:45:42.24816+00	
00000000-0000-0000-0000-000000000000	d1375493-2ae8-445e-9355-7d82f14631d3	{"action":"user_repeated_signup","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-04 22:48:50.125438+00	
00000000-0000-0000-0000-000000000000	14d7779a-b513-4e1a-b285-bf7cbee928b2	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-04 22:48:50.321347+00	
00000000-0000-0000-0000-000000000000	ad05b8f1-e2cc-4dfc-8dc4-99c6270bf878	{"action":"user_repeated_signup","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-04 23:01:07.661674+00	
00000000-0000-0000-0000-000000000000	841c137d-d0a3-4017-b760-298129237f4e	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-04 23:01:07.885338+00	
00000000-0000-0000-0000-000000000000	16734e65-006c-462c-8124-365be6b958d5	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 16:55:37.518084+00	
00000000-0000-0000-0000-000000000000	44fdd7aa-ff5f-4aaf-a660-e991dff335a1	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 16:55:52.349351+00	
00000000-0000-0000-0000-000000000000	dad4d483-fac7-45eb-ba8b-209ae69fce56	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 16:56:20.237294+00	
00000000-0000-0000-0000-000000000000	21794fc7-5cfb-4dcc-8873-5524002c3295	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 16:57:56.275395+00	
00000000-0000-0000-0000-000000000000	6826a299-f8d3-48d7-a571-9ffbbf221297	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 16:58:50.724098+00	
00000000-0000-0000-0000-000000000000	3372a7e6-8160-4863-872e-d061d2f9c842	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 16:58:52.9504+00	
00000000-0000-0000-0000-000000000000	2590d771-025f-4e84-856e-1101ec859a35	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 16:59:45.835445+00	
00000000-0000-0000-0000-000000000000	92dacd3c-5223-4b25-ab08-61ae2d9a729a	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:01:09.474232+00	
00000000-0000-0000-0000-000000000000	397f3a4e-482f-4aea-9dd5-06c7468c0e14	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:01:11.171563+00	
00000000-0000-0000-0000-000000000000	8bd168b0-a968-4242-90bd-9cff019ed704	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:01:25.238614+00	
00000000-0000-0000-0000-000000000000	323d785a-aad1-4aea-8e5f-2cc556f65186	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:01:29.973671+00	
00000000-0000-0000-0000-000000000000	db5a6e83-515a-49d3-80be-10533b29d5d5	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:01:42.288834+00	
00000000-0000-0000-0000-000000000000	00532e88-b22e-444e-9c74-3ac4e500c1c9	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:01:47.894072+00	
00000000-0000-0000-0000-000000000000	235af5bb-05f0-4b1b-a279-75e24d160ef5	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:01:48.893162+00	
00000000-0000-0000-0000-000000000000	991602f1-cdc0-4ed9-a7c2-888cebf7c401	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:19.491757+00	
00000000-0000-0000-0000-000000000000	6e5a5357-88c7-4ea1-9f9d-e88cac82422e	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:25.491944+00	
00000000-0000-0000-0000-000000000000	beae2478-37ef-486b-a985-735fd1309cb3	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:26.635319+00	
00000000-0000-0000-0000-000000000000	e3323999-6440-4311-bc4b-4add3d32db39	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:27.240878+00	
00000000-0000-0000-0000-000000000000	ed71fc54-90bd-41cf-9471-ce10cfce96c5	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:27.292766+00	
00000000-0000-0000-0000-000000000000	5b173824-5503-4f0d-b122-6aedad1a04c9	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:27.431574+00	
00000000-0000-0000-0000-000000000000	52312043-8d0a-42df-a009-5b357a7a08da	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:27.587889+00	
00000000-0000-0000-0000-000000000000	df54a8cf-c448-4ddb-a9ba-efe4eb1b8da5	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:09:27.74413+00	
00000000-0000-0000-0000-000000000000	0b1578da-9621-4f44-83a5-5ded8a445457	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:13:01.658179+00	
00000000-0000-0000-0000-000000000000	799b6f8c-ebc3-48d7-b209-4aea002f2b14	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:13:05.708963+00	
00000000-0000-0000-0000-000000000000	35fcde51-74f8-4c70-88d6-60724940e788	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:13:22.118449+00	
00000000-0000-0000-0000-000000000000	0fd6c0ab-186a-46f6-9dd1-55250aa24a37	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:13:58.024694+00	
00000000-0000-0000-0000-000000000000	d5c596d3-86c4-446a-b09e-723c9b6a50e0	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 17:16:01.331135+00	
00000000-0000-0000-0000-000000000000	c2286087-a6a4-4482-914b-1a24d7dc837f	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 18:07:11.056443+00	
00000000-0000-0000-0000-000000000000	b48ce60d-376c-49a6-ba57-6c3ffe03d8d6	{"action":"token_refreshed","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"token"}	2024-11-05 20:03:59.110894+00	
00000000-0000-0000-0000-000000000000	13fd059c-3460-4b0b-97c1-72b6447a72cc	{"action":"token_revoked","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"token"}	2024-11-05 20:03:59.112443+00	
00000000-0000-0000-0000-000000000000	f7816474-e912-4f71-a970-c3200b9a9a04	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:17:36.31642+00	
00000000-0000-0000-0000-000000000000	95cc96db-c87e-4349-99fd-3e8b3a8364cd	{"action":"logout","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:17:42.114399+00	
00000000-0000-0000-0000-000000000000	7fd79765-16a0-40a2-9fb7-df6922b899ad	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:18:28.339317+00	
00000000-0000-0000-0000-000000000000	fe74780b-0156-4afc-9fc4-7f3fd1faad4b	{"action":"logout","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:18:32.869182+00	
00000000-0000-0000-0000-000000000000	760b96c6-5f67-4133-b326-4726d0a05fdf	{"action":"login","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:19:05.193634+00	
00000000-0000-0000-0000-000000000000	e63c5201-f8f9-4e4b-8dcb-ffe18c05e840	{"action":"logout","actor_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","actor_username":"test@example.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:19:06.939478+00	
00000000-0000-0000-0000-000000000000	53d8a818-d192-4025-95c9-f3be08690fb0	{"action":"user_confirmation_requested","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-05 20:23:16.617811+00	
00000000-0000-0000-0000-000000000000	a670fa78-96ae-4f19-bfc6-de750e0c16b1	{"action":"user_signedup","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"team"}	2024-11-05 20:23:34.235377+00	
00000000-0000-0000-0000-000000000000	26321692-bef8-4ef9-b1ce-9f0a5ad23524	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"test@example.com","user_id":"ef1c70d4-6f85-48f6-97eb-4a22f776856e","user_phone":""}}	2024-11-05 20:24:26.015597+00	
00000000-0000-0000-0000-000000000000	d76cdb66-047b-4b79-b357-f5d30803aef8	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:26:45.548655+00	
00000000-0000-0000-0000-000000000000	660cbd7a-3c21-482c-9634-6288b99d2f7c	{"action":"user_recovery_requested","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"user"}	2024-11-05 20:26:54.203184+00	
00000000-0000-0000-0000-000000000000	5e652e9b-6516-4c75-93e4-a4933a9a24fe	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:27:24.44973+00	
00000000-0000-0000-0000-000000000000	a698402f-ad89-4078-81a8-8b296c6448bc	{"action":"user_updated_password","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"user"}	2024-11-05 20:27:32.308579+00	
00000000-0000-0000-0000-000000000000	ab25d19c-366d-441d-96b3-5a7395c158d4	{"action":"user_modified","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"user"}	2024-11-05 20:27:32.309197+00	
00000000-0000-0000-0000-000000000000	e5e87126-9045-48f2-bd45-1a4a507c73c9	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:28:30.5291+00	
00000000-0000-0000-0000-000000000000	9ddedf8e-8f22-4159-b68f-2c79298fe37d	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:28:33.01181+00	
00000000-0000-0000-0000-000000000000	8e9675a3-e3c5-4a12-aecd-994219e060f0	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:31:29.147982+00	
00000000-0000-0000-0000-000000000000	59c77fec-eca0-4bdc-8fb9-f039e3b43759	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:33:25.158361+00	
00000000-0000-0000-0000-000000000000	d5c34311-f9b1-4773-8175-627dfdceb1d7	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:51:49.992723+00	
00000000-0000-0000-0000-000000000000	f23f378e-9900-4961-ae55-3c0c0a7f28ad	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:52:14.056485+00	
00000000-0000-0000-0000-000000000000	9717075a-7bc3-4788-a71b-6a0e1d3e987f	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:52:16.687937+00	
00000000-0000-0000-0000-000000000000	aabd0755-e426-4249-8641-c6f754c90368	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:55:29.774149+00	
00000000-0000-0000-0000-000000000000	008b1f08-04fc-462d-b40f-770a3d731ecf	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:55:34.028828+00	
00000000-0000-0000-0000-000000000000	8e7231ea-fe0c-4496-90d7-470c96811081	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 20:57:17.63192+00	
00000000-0000-0000-0000-000000000000	384ff091-53c6-4049-9136-c849ec36e059	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 20:57:19.73625+00	
00000000-0000-0000-0000-000000000000	38bf584c-3b3f-4c08-9883-42b5d15b4011	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 21:23:19.595907+00	
00000000-0000-0000-0000-000000000000	0500c9c4-4f2c-4203-a32c-3831bfeea101	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 21:23:22.897954+00	
00000000-0000-0000-0000-000000000000	e683a7ba-7a28-4416-b13c-89b71bdea548	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 21:24:04.807099+00	
00000000-0000-0000-0000-000000000000	512b7fef-0265-4674-92e4-04cf3e87aca0	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 21:24:06.820766+00	
00000000-0000-0000-0000-000000000000	0d7475ae-d094-4655-8f42-1e6ab6eaf7c1	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 21:26:53.166004+00	
00000000-0000-0000-0000-000000000000	f09876db-47a0-401b-b596-b8d8cf09cb70	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 21:26:55.229379+00	
00000000-0000-0000-0000-000000000000	1998247c-3177-49bf-983d-f345c78122c6	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 21:44:56.778357+00	
00000000-0000-0000-0000-000000000000	ed214847-c27b-4397-888f-051fdf8fab90	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 21:44:59.081316+00	
00000000-0000-0000-0000-000000000000	ec82edf8-2804-48a1-9802-2346c06b67e4	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 21:59:57.362931+00	
00000000-0000-0000-0000-000000000000	6b3e2920-8c88-42b9-950c-4b2f7ea1832b	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 21:59:59.402774+00	
00000000-0000-0000-0000-000000000000	66a65bb2-65f0-46e6-a615-ac89a57e97dd	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 22:31:23.893198+00	
00000000-0000-0000-0000-000000000000	952e144a-5ab1-4f43-81d9-c5826c0dcd9b	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 22:31:25.953928+00	
00000000-0000-0000-0000-000000000000	d6bb963d-bc6e-4960-a447-c3d0c93310bc	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 22:35:09.992279+00	
00000000-0000-0000-0000-000000000000	a95ba444-a5e7-4616-b75a-eeae73c1fa5d	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 22:35:12.335122+00	
00000000-0000-0000-0000-000000000000	2def2739-36ad-43aa-93f4-0197d9f5a917	{"action":"user_confirmation_requested","actor_id":"a1b5dd84-ef1a-48eb-925b-8ff45ede81b0","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-05 22:44:37.659885+00	
00000000-0000-0000-0000-000000000000	53f63650-7585-4350-af7b-63f1e8fce6e6	{"action":"user_confirmation_requested","actor_id":"a1b5dd84-ef1a-48eb-925b-8ff45ede81b0","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-05 22:45:57.241772+00	
00000000-0000-0000-0000-000000000000	e4228591-3ba7-40c5-b745-18ce2609c2f4	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"nicocostac@gmail.com","user_id":"a1b5dd84-ef1a-48eb-925b-8ff45ede81b0","user_phone":""}}	2024-11-05 22:47:47.638972+00	
00000000-0000-0000-0000-000000000000	6788d4e2-59b4-4809-b11f-670a187ae282	{"action":"user_confirmation_requested","actor_id":"9648467a-b93a-4d41-8fd4-ac2c17017ef8","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-05 22:49:21.373442+00	
00000000-0000-0000-0000-000000000000	80db9404-4d23-465e-8f06-8dfb8bd9c289	{"action":"user_deleted","actor_id":"00000000-0000-0000-0000-000000000000","actor_username":"service_role","actor_via_sso":false,"log_type":"team","traits":{"user_email":"nicocostac@gmail.com","user_id":"9648467a-b93a-4d41-8fd4-ac2c17017ef8","user_phone":""}}	2024-11-05 22:51:18.143419+00	
00000000-0000-0000-0000-000000000000	2f25b3a2-b904-4b21-8ebb-11d505118c81	{"action":"user_confirmation_requested","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"user","traits":{"provider":"email"}}	2024-11-05 22:59:10.31522+00	
00000000-0000-0000-0000-000000000000	50bba43e-b4be-4fd3-896a-2d4bb7def8bb	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 22:59:21.295811+00	
00000000-0000-0000-0000-000000000000	1e5a3549-d364-4243-a40c-2719cb8f6809	{"action":"user_signedup","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"team"}	2024-11-05 23:00:45.203305+00	
00000000-0000-0000-0000-000000000000	7570d5ab-c119-4ed0-a682-e6d02aa5e6ad	{"action":"logout","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 23:01:06.668264+00	
00000000-0000-0000-0000-000000000000	0dfad7e9-33ed-41a6-999b-f1deadcbd148	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 23:01:14.261163+00	
00000000-0000-0000-0000-000000000000	cb31d338-bfd8-435c-aa6b-01b6ac16e2f8	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 23:01:36.038588+00	
00000000-0000-0000-0000-000000000000	db3a97d4-a8d2-4cc4-b8c7-760df13dd13e	{"action":"user_recovery_requested","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"user"}	2024-11-05 23:01:57.594786+00	
00000000-0000-0000-0000-000000000000	c66f1a70-3971-4c3b-b847-61d4509ed095	{"action":"login","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 23:02:16.384271+00	
00000000-0000-0000-0000-000000000000	b4cb7fec-c05f-4f25-a495-e470029ce3a4	{"action":"user_updated_password","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"user"}	2024-11-05 23:02:24.655248+00	
00000000-0000-0000-0000-000000000000	56092124-ee29-40b1-b16a-fb65b6bd8e48	{"action":"user_modified","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"user"}	2024-11-05 23:02:24.656531+00	
00000000-0000-0000-0000-000000000000	8ec1db8e-862c-461a-a748-c51d94350159	{"action":"logout","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 23:03:03.025372+00	
00000000-0000-0000-0000-000000000000	58353d24-a083-4087-9868-5c708ce7749d	{"action":"login","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 23:03:11.489307+00	
00000000-0000-0000-0000-000000000000	2b3f631a-5bc5-4c95-95bc-df28a5534cc1	{"action":"logout","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-05 23:07:58.600362+00	
00000000-0000-0000-0000-000000000000	14cf804e-45cc-44ca-ac1a-d7439faa80d6	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-05 23:08:00.754801+00	
00000000-0000-0000-0000-000000000000	542dd3ca-908d-4c3c-a5ee-a5d8e0ae8bd8	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-06 13:31:34.978686+00	
00000000-0000-0000-0000-000000000000	349b6c97-d945-495c-9f12-a5399f2b1422	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-06 13:31:35.000536+00	
00000000-0000-0000-0000-000000000000	b46af0a4-f350-44dc-928f-84505be83ae0	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-06 14:29:56.437686+00	
00000000-0000-0000-0000-000000000000	7218cf02-a6ec-4de9-bc1e-994e30bd097d	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-06 14:29:56.43916+00	
00000000-0000-0000-0000-000000000000	0389e921-8f5d-4376-8cf0-fd8a7d38fee5	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-06 15:39:03.547654+00	
00000000-0000-0000-0000-000000000000	ceb69611-8f2c-44e2-973e-1b0a09e4b069	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-06 15:39:03.549219+00	
00000000-0000-0000-0000-000000000000	a3d56718-7965-41df-b161-2830356f29ed	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 00:33:55.472565+00	
00000000-0000-0000-0000-000000000000	393334f8-2bec-4354-930e-f4222e49850c	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 00:33:55.476145+00	
00000000-0000-0000-0000-000000000000	279b219f-696a-483d-aba5-43f106de1466	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 01:35:14.683756+00	
00000000-0000-0000-0000-000000000000	0f5976de-0052-4a17-a6f4-5a250bc35084	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 01:35:14.687324+00	
00000000-0000-0000-0000-000000000000	f1178a6e-fabc-4b12-9f69-20c51303d469	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 02:33:27.177313+00	
00000000-0000-0000-0000-000000000000	21810fab-cb4b-48ec-9334-2722287d0c93	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 02:33:27.178474+00	
00000000-0000-0000-0000-000000000000	4fac2c04-2fad-4752-8700-a10ee581f07a	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 14:27:15.695928+00	
00000000-0000-0000-0000-000000000000	5758de56-85b8-4f04-859f-a4ab13c08739	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 14:27:15.705494+00	
00000000-0000-0000-0000-000000000000	99bea585-5cf4-438c-98cd-e039f9f77ac2	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 17:59:43.117789+00	
00000000-0000-0000-0000-000000000000	a6a275c1-04f4-4c12-9ae6-26bda67506a2	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 17:59:43.128952+00	
00000000-0000-0000-0000-000000000000	89adaed3-007a-4665-9c36-11cafe717f07	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 18:58:00.383204+00	
00000000-0000-0000-0000-000000000000	68c8ebb0-1efb-4765-b641-055cd8686685	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 18:58:00.394554+00	
00000000-0000-0000-0000-000000000000	c8d08445-e459-4ce4-8e59-b3e6e84140c5	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 21:22:17.514247+00	
00000000-0000-0000-0000-000000000000	42da1151-aa6e-4263-86cd-9c7c9cf8d93d	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 21:22:17.517257+00	
00000000-0000-0000-0000-000000000000	e84ed96c-fd18-4c5b-96fc-723c2649a0d9	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 21:48:59.05454+00	
00000000-0000-0000-0000-000000000000	500f1659-b200-42db-8741-62e085eca3e7	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-07 21:53:36.452579+00	
00000000-0000-0000-0000-000000000000	27bfbb21-be2f-4614-a7d9-b32562e09076	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 21:53:38.762387+00	
00000000-0000-0000-0000-000000000000	37a2916c-d549-4b35-b9d4-257fc0ddb511	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-07 21:54:09.041817+00	
00000000-0000-0000-0000-000000000000	458c8dcc-0470-45b7-a015-f709b427ca40	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 21:54:10.803142+00	
00000000-0000-0000-0000-000000000000	84216544-ab09-4228-91e5-9e1d5677c239	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-07 21:54:55.551567+00	
00000000-0000-0000-0000-000000000000	0e64c814-57f0-488c-b1d2-537458fba6a5	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 21:54:57.513613+00	
00000000-0000-0000-0000-000000000000	46f16573-d2e4-47ad-9149-0484bd56f055	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-07 22:04:46.783219+00	
00000000-0000-0000-0000-000000000000	c7d5fe12-ae65-4a01-9145-f1dc2d548762	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 22:04:48.764143+00	
00000000-0000-0000-0000-000000000000	4ce2e614-0c4e-4659-b606-2b731317fcb9	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-07 22:04:51.546189+00	
00000000-0000-0000-0000-000000000000	e257a25b-3e94-4563-90fe-7e5739a505b2	{"action":"login","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 22:04:59.565609+00	
00000000-0000-0000-0000-000000000000	01b2ffc2-7390-43c2-846c-b2b2a5212597	{"action":"logout","actor_id":"dc1406e9-fcd3-40e2-b960-152af5211b8b","actor_username":"nicocostac@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-07 22:05:46.924312+00	
00000000-0000-0000-0000-000000000000	87568b56-add4-4bfc-9eaf-f2a0d76bf981	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 22:05:48.864555+00	
00000000-0000-0000-0000-000000000000	ccd1350f-8790-4a8c-bb89-27c222611350	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-07 22:21:57.568969+00	
00000000-0000-0000-0000-000000000000	20a0b0e8-04bf-4f53-b7f4-f7e06a35372f	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 23:22:01.85426+00	
00000000-0000-0000-0000-000000000000	4f450389-ef4a-4276-9534-36eac4c3d89b	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-07 23:22:01.856635+00	
00000000-0000-0000-0000-000000000000	7758176e-8553-4a0e-98b9-0b72ccde3905	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-08 05:29:22.028+00	
00000000-0000-0000-0000-000000000000	7ec10411-3493-4aa5-8168-badf8cdf22b0	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-08 05:29:22.029021+00	
00000000-0000-0000-0000-000000000000	1f7d41e7-3a02-4c93-92d1-d4fe49b017f7	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-08 05:42:52.344307+00	
00000000-0000-0000-0000-000000000000	f58757d9-d009-446e-8d18-c752fd5014eb	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-08 05:42:56.241054+00	
00000000-0000-0000-0000-000000000000	fcf365b0-b761-46dd-a6db-0d29306c0e56	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-08 05:42:58.598354+00	
00000000-0000-0000-0000-000000000000	d26e9d53-df34-4abf-a89a-4ee4867a56e8	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-08 05:43:08.643292+00	
00000000-0000-0000-0000-000000000000	43f498b4-e208-48ba-bf3f-d7e38db418cb	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-08 05:43:25.442146+00	
00000000-0000-0000-0000-000000000000	abce9242-b2bf-4d47-99fb-2e5792b20e56	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-08 05:44:54.217302+00	
00000000-0000-0000-0000-000000000000	8bba62f7-33cb-4ee9-901e-191dc22e5672	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-08 05:44:59.751149+00	
00000000-0000-0000-0000-000000000000	8c280ab3-9a57-4c53-b52f-f924e4a81fef	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-08 22:14:58.089103+00	
00000000-0000-0000-0000-000000000000	ba464aa3-c5df-41a9-b987-24842c290e98	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-10 15:05:27.899772+00	
00000000-0000-0000-0000-000000000000	f1c72e3a-ba02-4939-85da-307ee9b5e6b2	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-10 15:05:27.922069+00	
00000000-0000-0000-0000-000000000000	9bc8d871-2533-46e6-8f88-48071ff13115	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-10 16:39:26.677734+00	
00000000-0000-0000-0000-000000000000	28a1a511-35d6-43fd-8597-8638092daf4c	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-10 16:39:26.679407+00	
00000000-0000-0000-0000-000000000000	61068eec-3285-4fac-869c-acdfd2a03b2e	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-10 19:13:47.551798+00	
00000000-0000-0000-0000-000000000000	80118b09-1932-40c0-9aa6-c030bd500d55	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-10 19:13:47.554543+00	
00000000-0000-0000-0000-000000000000	4b106dd7-fd76-47be-ab3b-a03b586e261b	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 16:10:40.785289+00	
00000000-0000-0000-0000-000000000000	df2f6121-20fe-4db2-a306-3c3462d1fce6	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 16:10:40.791294+00	
00000000-0000-0000-0000-000000000000	e9a00bbc-7cca-4c82-83f8-eef85b1b3dd6	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-19 16:31:57.737229+00	
00000000-0000-0000-0000-000000000000	894c0137-fccf-47f0-8a17-d892972f887e	{"action":"logout","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account"}	2024-11-19 16:33:40.526624+00	
00000000-0000-0000-0000-000000000000	84ed5cf8-bea0-4f81-ba36-298eadb30879	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-19 16:33:43.718761+00	
00000000-0000-0000-0000-000000000000	34ee3e3d-d185-41ac-95e8-3951c0fd9d61	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-19 16:36:13.096285+00	
00000000-0000-0000-0000-000000000000	e9bc3c45-cddf-4cca-83c8-0aa6744e559d	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-19 16:45:15.000887+00	
00000000-0000-0000-0000-000000000000	5531ec70-7394-44fa-a7b6-6237a5071693	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 21:12:46.435775+00	
00000000-0000-0000-0000-000000000000	71346863-427f-423a-a07c-8d6288126b1b	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 21:12:46.443388+00	
00000000-0000-0000-0000-000000000000	57d5ca2d-8298-408e-9b7a-ef07955f235e	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 22:11:10.11704+00	
00000000-0000-0000-0000-000000000000	e74108c3-8eda-4075-9dcf-785ff833ffb8	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 22:11:10.119008+00	
00000000-0000-0000-0000-000000000000	6e2daaf2-2e19-40c7-a425-a3e071b58a5a	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 23:09:20.267227+00	
00000000-0000-0000-0000-000000000000	d0ecfafa-2400-4020-ac72-57b08c5666ef	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-19 23:09:20.269066+00	
00000000-0000-0000-0000-000000000000	09a65801-b3e7-49f8-b3a1-f7e4bddd751e	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 00:55:35.113146+00	
00000000-0000-0000-0000-000000000000	ae9b9c72-6f83-4b27-9efd-1dc901f08722	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 00:55:35.114835+00	
00000000-0000-0000-0000-000000000000	487c62a3-0aed-46dc-8c8f-76fe824e2f18	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 01:54:04.179602+00	
00000000-0000-0000-0000-000000000000	fc82430f-7752-47b4-bb57-1a3d6b98fedb	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 01:54:04.181807+00	
00000000-0000-0000-0000-000000000000	f2f45cb0-e019-4c8a-a5d1-6bb3a61be545	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 16:50:26.020095+00	
00000000-0000-0000-0000-000000000000	7e9d7742-c215-45d5-a2e8-ea0b0d1a01fa	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 16:50:26.038322+00	
00000000-0000-0000-0000-000000000000	d0a8b132-2fbf-44c5-abb7-fe8da16745f2	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 20:04:52.183003+00	
00000000-0000-0000-0000-000000000000	1b38f319-7e43-4c77-9e2a-f48eab773268	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 20:04:52.187931+00	
00000000-0000-0000-0000-000000000000	e85e8130-d607-4335-bf57-9afd592e6792	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 21:37:17.373872+00	
00000000-0000-0000-0000-000000000000	0c8da722-9fbf-4051-be1b-233d721aa6ee	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-20 21:37:17.37706+00	
00000000-0000-0000-0000-000000000000	0425ef2b-ee1d-4c7e-a5fc-7a088f05d68d	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 17:01:08.511837+00	
00000000-0000-0000-0000-000000000000	1e4f50da-f99b-45bf-b7a9-954ec7552020	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 17:01:08.52378+00	
00000000-0000-0000-0000-000000000000	c3246809-fca0-4d89-bbc6-65c5c8c22e25	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 17:59:26.416033+00	
00000000-0000-0000-0000-000000000000	e2ed68f3-318f-4173-b1fd-fe42c4ed2bcb	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 17:59:26.419119+00	
00000000-0000-0000-0000-000000000000	9b7dae3c-fa7a-45b7-9333-61ea2e937ed9	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 18:57:46.479957+00	
00000000-0000-0000-0000-000000000000	cf2357d5-eb92-4998-b0a6-d7bf60de31cd	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 18:57:46.481734+00	
00000000-0000-0000-0000-000000000000	5cde1e93-9d6e-4bae-aa93-17f63a4294d7	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 19:56:04.716472+00	
00000000-0000-0000-0000-000000000000	79c747b1-ac53-423c-b281-bfd0e4eb317f	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 19:56:04.718815+00	
00000000-0000-0000-0000-000000000000	bf6e6ad0-105a-40fe-9806-1c828272dd51	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 20:54:09.89044+00	
00000000-0000-0000-0000-000000000000	7f0e9ed3-1bc0-4592-a527-70cc3460616e	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 20:54:09.903906+00	
00000000-0000-0000-0000-000000000000	cb0d6939-c439-46b7-a81b-810ec65dd380	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 23:58:22.186338+00	
00000000-0000-0000-0000-000000000000	fb534a5e-1e3f-4a4c-bc63-af1846f8ddb7	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-21 23:58:22.187187+00	
00000000-0000-0000-0000-000000000000	bca0340f-159a-4f2a-a192-d1b4bee7ea6f	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 00:57:16.243947+00	
00000000-0000-0000-0000-000000000000	cb229a40-d7ce-41c6-b268-b61b17ba04cc	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 00:57:16.248006+00	
00000000-0000-0000-0000-000000000000	90d4b751-217d-4b27-8fc1-1f74ac352711	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 01:55:38.743116+00	
00000000-0000-0000-0000-000000000000	2808b4d9-d3fc-4923-a7b1-ad5e31b870b3	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 01:55:38.748439+00	
00000000-0000-0000-0000-000000000000	3a0956b9-1c53-43cc-bc45-797073d7a522	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 02:53:53.749525+00	
00000000-0000-0000-0000-000000000000	085c1bb0-5e8f-430d-bde3-271ed08186e8	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 02:53:53.750391+00	
00000000-0000-0000-0000-000000000000	ca48d4e2-4750-46c8-ad69-6174c63562f2	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 03:52:05.151589+00	
00000000-0000-0000-0000-000000000000	e9a97e09-3307-46f2-8d43-c893b26c1214	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 03:52:05.152945+00	
00000000-0000-0000-0000-000000000000	4ea402b7-e7bd-41e6-a0da-df3acd153b94	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-11-22 04:39:38.237239+00	
00000000-0000-0000-0000-000000000000	9483a579-f8c5-47e4-baca-590ff68ae4e9	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 04:50:06.484462+00	
00000000-0000-0000-0000-000000000000	a3b4328d-3f03-4403-91cd-c9c89bf4cad2	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 04:50:06.485409+00	
00000000-0000-0000-0000-000000000000	751c0256-7043-46df-a06b-2d9da9de1390	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 15:51:10.733021+00	
00000000-0000-0000-0000-000000000000	0176f608-024e-4bf6-be58-d2e5cd883b6f	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 15:51:10.754663+00	
00000000-0000-0000-0000-000000000000	660827c0-cfb4-472d-9cb4-81215a5c019d	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 16:49:30.263695+00	
00000000-0000-0000-0000-000000000000	208dab80-8662-4f94-a2ef-c208fbbe012b	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 16:49:30.265084+00	
00000000-0000-0000-0000-000000000000	6fe4cc27-694e-410a-9302-28c3ed7c8a1f	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 17:47:33.842814+00	
00000000-0000-0000-0000-000000000000	eed641c0-0b4e-4aa2-ac40-df624e6b087a	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 17:47:33.844837+00	
00000000-0000-0000-0000-000000000000	465120c5-8025-4bf2-9a78-313bbf2da1dd	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 18:45:54.807301+00	
00000000-0000-0000-0000-000000000000	cd509ce2-21c3-469f-9aec-c9524e4f8756	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 18:45:54.809366+00	
00000000-0000-0000-0000-000000000000	12bc9329-2810-43b0-96d0-f2c9459c4922	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 21:26:30.918608+00	
00000000-0000-0000-0000-000000000000	b710515d-7425-4d9b-b60d-474b8063c48d	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 21:26:30.921104+00	
00000000-0000-0000-0000-000000000000	95931de0-9235-4e62-a319-da0d215e7cf6	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 22:24:31.036099+00	
00000000-0000-0000-0000-000000000000	4c0b7591-d0ca-4eed-9122-8ab8e77b409c	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 22:24:31.038984+00	
00000000-0000-0000-0000-000000000000	e8704e37-dfaf-4061-8e35-3a59b2176f71	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 23:22:53.862312+00	
00000000-0000-0000-0000-000000000000	69a7a3bd-a4f2-40fd-9035-8f0f6b6e27d1	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-22 23:22:53.86416+00	
00000000-0000-0000-0000-000000000000	fd0b366c-8827-4db2-9de1-822df66c4443	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-25 15:05:14.668451+00	
00000000-0000-0000-0000-000000000000	f8702c87-518b-4ae7-8fc6-6d482b5b73fb	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-25 15:05:14.684316+00	
00000000-0000-0000-0000-000000000000	5f59ec18-6f79-4293-84f1-5f9c65a4ce00	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-25 16:05:20.446363+00	
00000000-0000-0000-0000-000000000000	c9dc20cd-8727-45f1-8189-85c534af8e24	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-11-25 16:05:20.451652+00	
00000000-0000-0000-0000-000000000000	79c5f68e-0d01-461f-b90f-5ae4a2add95e	{"action":"login","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"account","traits":{"provider":"email"}}	2024-12-06 18:57:55.27472+00	
00000000-0000-0000-0000-000000000000	6560e4a2-079d-4889-9283-25a64e60153d	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 13:40:16.13557+00	
00000000-0000-0000-0000-000000000000	d89eec53-4f0b-419c-8a0f-2cce19da2fd9	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 13:40:16.148352+00	
00000000-0000-0000-0000-000000000000	482090fb-e762-4ff7-b828-9a492f0275c7	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 14:40:20.366612+00	
00000000-0000-0000-0000-000000000000	a98576d6-e6d5-45b3-b429-fa031436d836	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 14:40:20.370473+00	
00000000-0000-0000-0000-000000000000	7f30c2bd-8f29-4827-b562-15d518143ee0	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 15:53:23.618085+00	
00000000-0000-0000-0000-000000000000	d8fd3e4a-8efd-46f2-b6fc-8ea6dff1b191	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 15:53:23.622136+00	
00000000-0000-0000-0000-000000000000	f1b1c76c-881e-4a53-9492-68b8a339623a	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 16:51:26.240496+00	
00000000-0000-0000-0000-000000000000	bda8e6ef-f843-41fe-8a55-eade7740366e	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 16:51:26.24378+00	
00000000-0000-0000-0000-000000000000	e911a848-cbaf-49c3-b3c8-11e0becaf999	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 17:52:15.072606+00	
00000000-0000-0000-0000-000000000000	40891ce4-ee70-4e4d-bd45-0b42a30e52f2	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 17:52:15.07885+00	
00000000-0000-0000-0000-000000000000	88f51003-73c5-426d-a0b1-f0076116a5b4	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 18:52:20.940407+00	
00000000-0000-0000-0000-000000000000	ecf41a8d-bed6-4265-8232-9500fafb50e3	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 18:52:20.942759+00	
00000000-0000-0000-0000-000000000000	5db017b1-4bdb-437c-b75f-a80111cb28a1	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 19:52:25.948424+00	
00000000-0000-0000-0000-000000000000	364ec4b5-8cc6-4c31-af0e-6e0f1cf298a7	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-09 19:52:25.961334+00	
00000000-0000-0000-0000-000000000000	26c03e55-88f6-4a11-942f-aeae8fef5079	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 13:27:29.951912+00	
00000000-0000-0000-0000-000000000000	d77e8f51-2dd7-442a-8c22-879a3cb491cc	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 13:27:29.967507+00	
00000000-0000-0000-0000-000000000000	7a6f6f04-9214-4677-9d00-4827e4db5a6e	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 14:28:50.291935+00	
00000000-0000-0000-0000-000000000000	d30ac28f-7b33-4ae2-a47b-7e6852f32cd3	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 14:28:50.29771+00	
00000000-0000-0000-0000-000000000000	94073718-d6a6-4757-b0de-b2cc9dc5fc76	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 15:27:54.933336+00	
00000000-0000-0000-0000-000000000000	9986d56a-5717-496a-82f9-e8661b379016	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 15:27:54.936565+00	
00000000-0000-0000-0000-000000000000	e3867a76-c031-4cbd-98a2-980f06f10143	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 16:26:03.622628+00	
00000000-0000-0000-0000-000000000000	96da1e41-485d-4284-9eee-d57565f7edf6	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 16:26:03.624314+00	
00000000-0000-0000-0000-000000000000	6a0c3f36-885e-4af5-92f6-678d27be425a	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 17:31:27.311163+00	
00000000-0000-0000-0000-000000000000	0d460b65-757b-4ae9-9ceb-25a6598924cd	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 17:31:27.325568+00	
00000000-0000-0000-0000-000000000000	c61daf82-16bf-4c12-a1f9-b5666d32accb	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 18:31:43.155902+00	
00000000-0000-0000-0000-000000000000	92a79758-97cf-413b-823f-b727f1f28b9e	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 18:31:43.158874+00	
00000000-0000-0000-0000-000000000000	e87bf656-5826-4b1e-8f72-258ee8f473cb	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 19:30:15.938848+00	
00000000-0000-0000-0000-000000000000	c60b8089-2983-40e3-b202-61e63867d92e	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 19:30:15.949664+00	
00000000-0000-0000-0000-000000000000	a32cdf95-7255-4a49-86d9-eb229e705def	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 23:41:39.456095+00	
00000000-0000-0000-0000-000000000000	f789237d-959d-488c-823f-ed9e49367b2b	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-10 23:41:39.462161+00	
00000000-0000-0000-0000-000000000000	9d3148e0-d494-455f-b236-c79f491a5763	{"action":"token_refreshed","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-11 12:32:16.513292+00	
00000000-0000-0000-0000-000000000000	98e98e06-edd7-4e9e-adf8-7c136013d7f5	{"action":"token_revoked","actor_id":"36837910-176b-48b8-9a49-e2bc08431bd9","actor_username":"nicocostac+nevados@gmail.com","actor_via_sso":false,"log_type":"token"}	2024-12-11 12:32:16.527798+00	
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	{"sub": "36837910-176b-48b8-9a49-e2bc08431bd9", "email": "nicocostac+nevados@gmail.com", "email_verified": false, "phone_verified": false}	email	2024-11-05 20:23:16.613717+00	2024-11-05 20:23:16.613774+00	2024-11-05 20:23:16.613774+00	12fedfba-7949-4d85-985a-6f48fb73b77f
dc1406e9-fcd3-40e2-b960-152af5211b8b	dc1406e9-fcd3-40e2-b960-152af5211b8b	{"sub": "dc1406e9-fcd3-40e2-b960-152af5211b8b", "email": "nicocostac@gmail.com", "last_name": "asdasd", "first_name": "asdasd", "email_verified": false, "phone_verified": false}	email	2024-11-05 22:59:10.312253+00	2024-11-05 22:59:10.312382+00	2024-11-05 22:59:10.312382+00	362bf805-3320-4667-8488-f0035e1e9c68
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
78382f47-5b8d-4d73-80ab-55bf82b2e30c	2024-11-19 16:33:43.721942+00	2024-11-19 16:33:43.721942+00	password	e7356341-ba78-460c-bde7-5899da155da4
6fb858d0-e4de-4622-847f-a730665ee4ff	2024-11-19 16:36:13.107988+00	2024-11-19 16:36:13.107988+00	password	3864ac5c-8ac6-4ffe-a4d9-ebe15d9f9a2e
04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b	2024-11-19 16:45:15.004861+00	2024-11-19 16:45:15.004861+00	password	cee73b14-59a8-459d-b063-44a1191949a9
d57ce5bf-6ae1-4cab-ad62-d3f360bd0796	2024-11-22 04:39:38.245243+00	2024-11-22 04:39:38.245243+00	password	4480a62a-7eb3-41e0-8213-d03dae679b6e
db09d6bd-540b-4c85-8968-a610d88dbe23	2024-12-06 18:57:55.307831+00	2024-12-06 18:57:55.307831+00	password	9fd4c34a-29d2-454e-b04c-7b96dde2a7ca
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
00000000-0000-0000-0000-000000000000	89	fc5Sx5mTdhB8vZsHenClUg	36837910-176b-48b8-9a49-e2bc08431bd9	f	2024-11-19 16:33:43.720376+00	2024-11-19 16:33:43.720376+00	\N	78382f47-5b8d-4d73-80ab-55bf82b2e30c
00000000-0000-0000-0000-000000000000	90	R1zL-qDzDCTqJtLKGh0IIg	36837910-176b-48b8-9a49-e2bc08431bd9	f	2024-11-19 16:36:13.10596+00	2024-11-19 16:36:13.10596+00	\N	6fb858d0-e4de-4622-847f-a730665ee4ff
00000000-0000-0000-0000-000000000000	91	V5uCpIbFHg1pWspFw_7BFg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-19 16:45:15.002993+00	2024-11-19 21:12:46.444557+00	\N	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	92	DPYVSARdV-Qa1G5rnpENxQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-19 21:12:46.448128+00	2024-11-19 22:11:10.119561+00	V5uCpIbFHg1pWspFw_7BFg	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	93	o37bMtJSbOCXCwmzxs_-Gg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-19 22:11:10.120647+00	2024-11-19 23:09:20.269547+00	DPYVSARdV-Qa1G5rnpENxQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	94	2gz4egXerQBUyryTqzziMA	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-19 23:09:20.270139+00	2024-11-20 00:55:35.115347+00	o37bMtJSbOCXCwmzxs_-Gg	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	95	s9Snyx9YH4AK3fAxjJ98eA	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-20 00:55:35.115943+00	2024-11-20 01:54:04.182326+00	2gz4egXerQBUyryTqzziMA	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	96	vSSoFEfhljHe5XpECiYPmQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-20 01:54:04.182941+00	2024-11-20 16:50:26.038949+00	s9Snyx9YH4AK3fAxjJ98eA	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	97	MbB3lkSdsDKAq3xQfbiHig	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-20 16:50:26.046534+00	2024-11-20 20:04:52.18844+00	vSSoFEfhljHe5XpECiYPmQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	98	oe2TUW_3dfd-nARxlHmz5w	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-20 20:04:52.191943+00	2024-11-20 21:37:17.377535+00	MbB3lkSdsDKAq3xQfbiHig	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	99	O6SDIBzYz5kYPjKSKELMMw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-20 21:37:17.3794+00	2024-11-21 17:01:08.524849+00	oe2TUW_3dfd-nARxlHmz5w	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	100	2RHLwFTvbcH1eHrh-owCRw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-21 17:01:08.541394+00	2024-11-21 17:59:26.419654+00	O6SDIBzYz5kYPjKSKELMMw	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	101	4B7PN95rKNx4NA-tzWsD3Q	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-21 17:59:26.421731+00	2024-11-21 18:57:46.482307+00	2RHLwFTvbcH1eHrh-owCRw	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	102	xPj9dQBTwn6xB8Qcq12LLQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-21 18:57:46.482957+00	2024-11-21 19:56:04.719336+00	4B7PN95rKNx4NA-tzWsD3Q	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	103	iYKhvwaOzKvX0ATCZWrEsw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-21 19:56:04.720981+00	2024-11-21 20:54:09.904522+00	xPj9dQBTwn6xB8Qcq12LLQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	104	41699BuBLE9EMbF3KNGoGA	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-21 20:54:09.906923+00	2024-11-21 23:58:22.187639+00	iYKhvwaOzKvX0ATCZWrEsw	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	105	f0qJOQTHkyfUyvuAK8t2Hg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-21 23:58:22.188249+00	2024-11-22 00:57:16.248529+00	41699BuBLE9EMbF3KNGoGA	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	106	xgmzWotOywa-gPsLwO01Kw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 00:57:16.249259+00	2024-11-22 01:55:38.749019+00	f0qJOQTHkyfUyvuAK8t2Hg	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	107	ZMif9fcI0Jbwz8emXIUQDA	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 01:55:38.750131+00	2024-11-22 02:53:53.750905+00	xgmzWotOywa-gPsLwO01Kw	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	108	Mc1bsI3j9HihHHAezGuYSQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 02:53:53.752051+00	2024-11-22 03:52:05.153428+00	ZMif9fcI0Jbwz8emXIUQDA	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	110	6sAXHFIcFU4VnuHFLf_afQ	36837910-176b-48b8-9a49-e2bc08431bd9	f	2024-11-22 04:39:38.24265+00	2024-11-22 04:39:38.24265+00	\N	d57ce5bf-6ae1-4cab-ad62-d3f360bd0796
00000000-0000-0000-0000-000000000000	109	9-JXROVYwxxYDAxJP7Waig	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 03:52:05.154804+00	2024-11-22 04:50:06.485924+00	Mc1bsI3j9HihHHAezGuYSQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	111	0y7KjsUW5pg5pu7GyAulSQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 04:50:06.486525+00	2024-11-22 15:51:10.756507+00	9-JXROVYwxxYDAxJP7Waig	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	112	ogYMxoXJb57ABp_nGXnqhQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 15:51:10.769053+00	2024-11-22 16:49:30.265654+00	0y7KjsUW5pg5pu7GyAulSQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	113	KW9qhKj2zSLXXCD3HE3XCw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 16:49:30.26759+00	2024-11-22 17:47:33.845341+00	ogYMxoXJb57ABp_nGXnqhQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	114	muNOzkW0peJYdAfLd--9IQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 17:47:33.847286+00	2024-11-22 18:45:54.809906+00	KW9qhKj2zSLXXCD3HE3XCw	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	115	yetU_5Yex816bH7k76cgYQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 18:45:54.812198+00	2024-11-22 21:26:30.921589+00	muNOzkW0peJYdAfLd--9IQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	116	YiegC11FlCyPTYU0pKYhnQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 21:26:30.923914+00	2024-11-22 22:24:31.039582+00	yetU_5Yex816bH7k76cgYQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	117	YI_kVDBxekU2g-Y96oCunw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 22:24:31.041975+00	2024-11-22 23:22:53.86465+00	YiegC11FlCyPTYU0pKYhnQ	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	118	N_ftcnvOo-0Qwst_Zdh1eg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-22 23:22:53.866134+00	2024-11-25 15:05:14.68494+00	YI_kVDBxekU2g-Y96oCunw	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	119	cvXtYJ_LDIKhtVnkP5_i5Q	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-11-25 15:05:14.692644+00	2024-11-25 16:05:20.452201+00	N_ftcnvOo-0Qwst_Zdh1eg	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	120	1AYV3EpUIic_XaVfugWYjg	36837910-176b-48b8-9a49-e2bc08431bd9	f	2024-11-25 16:05:20.457316+00	2024-11-25 16:05:20.457316+00	cvXtYJ_LDIKhtVnkP5_i5Q	04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b
00000000-0000-0000-0000-000000000000	121	ij0vxKAqY3s61kRzqMPUtg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-06 18:57:55.289776+00	2024-12-09 13:40:16.149638+00	\N	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	122	oPiqjbuXysY9j9owcBfTKQ	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-09 13:40:16.160408+00	2024-12-09 14:40:20.370963+00	ij0vxKAqY3s61kRzqMPUtg	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	123	PDbsmL0uNn0Y3sLP4DQW2g	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-09 14:40:20.372543+00	2024-12-09 15:53:23.623164+00	oPiqjbuXysY9j9owcBfTKQ	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	124	6_VpSfa0zrmlT5Le2ieA5g	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-09 15:53:23.624314+00	2024-12-09 16:51:26.244349+00	PDbsmL0uNn0Y3sLP4DQW2g	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	125	Kpai9yJ1md7bogeUfwxyZA	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-09 16:51:26.245744+00	2024-12-09 17:52:15.079338+00	6_VpSfa0zrmlT5Le2ieA5g	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	126	m4jcZn23C1bo27mC0F8nSg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-09 17:52:15.080962+00	2024-12-09 18:52:20.943297+00	Kpai9yJ1md7bogeUfwxyZA	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	127	tPj1SimfKe7JVdBqn48OaA	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-09 18:52:20.944599+00	2024-12-09 19:52:25.962455+00	m4jcZn23C1bo27mC0F8nSg	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	128	uoz-gxr43pVGqEkod1-gog	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-09 19:52:25.966797+00	2024-12-10 13:27:29.969354+00	tPj1SimfKe7JVdBqn48OaA	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	129	BY6m0VVPVZeEWuFC3QRlzw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 13:27:29.977418+00	2024-12-10 14:28:50.298218+00	uoz-gxr43pVGqEkod1-gog	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	130	00GZJsl0KLJkjXlgXGB91Q	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 14:28:50.300707+00	2024-12-10 15:27:54.93709+00	BY6m0VVPVZeEWuFC3QRlzw	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	131	pYNDBCxOtVIPeUtqdEAnpg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 15:27:54.939677+00	2024-12-10 16:26:03.624825+00	00GZJsl0KLJkjXlgXGB91Q	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	132	ZPSx16iuiWFEpZVlt9SYJw	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 16:26:03.626945+00	2024-12-10 17:31:27.326706+00	pYNDBCxOtVIPeUtqdEAnpg	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	133	WHK5r4BRmJV05nmjcwCnsg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 17:31:27.327913+00	2024-12-10 18:31:43.15946+00	ZPSx16iuiWFEpZVlt9SYJw	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	134	V3c-S8zwmHBybFvROu5Gag	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 18:31:43.162301+00	2024-12-10 19:30:15.950238+00	WHK5r4BRmJV05nmjcwCnsg	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	135	txDpziggTzQHggHF6PIUPg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 19:30:15.952475+00	2024-12-10 23:41:39.462743+00	V3c-S8zwmHBybFvROu5Gag	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	136	vMWeraBP0gfGU5ZU7E2vNg	36837910-176b-48b8-9a49-e2bc08431bd9	t	2024-12-10 23:41:39.468685+00	2024-12-11 12:32:16.528285+00	txDpziggTzQHggHF6PIUPg	db09d6bd-540b-4c85-8968-a610d88dbe23
00000000-0000-0000-0000-000000000000	137	n4UMtnHwfkTLPHEsYCKBdQ	36837910-176b-48b8-9a49-e2bc08431bd9	f	2024-12-11 12:32:16.535571+00	2024-12-11 12:32:16.535571+00	vMWeraBP0gfGU5ZU7E2vNg	db09d6bd-540b-4c85-8968-a610d88dbe23
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag) FROM stdin;
78382f47-5b8d-4d73-80ab-55bf82b2e30c	36837910-176b-48b8-9a49-e2bc08431bd9	2024-11-19 16:33:43.719537+00	2024-11-19 16:33:43.719537+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15	104.28.47.230	\N
6fb858d0-e4de-4622-847f-a730665ee4ff	36837910-176b-48b8-9a49-e2bc08431bd9	2024-11-19 16:36:13.103975+00	2024-11-19 16:36:13.103975+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15	104.28.47.230	\N
04a70cd0-dbae-44a5-9d2c-a566d9aa5c3b	36837910-176b-48b8-9a49-e2bc08431bd9	2024-11-19 16:45:15.00192+00	2024-11-25 16:05:20.46177+00	\N	aal1	\N	2024-11-25 16:05:20.4617	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15	146.75.208.29	\N
d57ce5bf-6ae1-4cab-ad62-d3f360bd0796	36837910-176b-48b8-9a49-e2bc08431bd9	2024-11-22 04:39:38.239729+00	2024-11-22 04:39:38.239729+00	\N	aal1	\N	\N	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15	172.225.84.100	\N
db09d6bd-540b-4c85-8968-a610d88dbe23	36837910-176b-48b8-9a49-e2bc08431bd9	2024-12-06 18:57:55.284277+00	2024-12-11 12:32:16.540052+00	\N	aal1	\N	2024-12-11 12:32:16.539976	Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15	148.222.205.114	\N
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
00000000-0000-0000-0000-000000000000	dc1406e9-fcd3-40e2-b960-152af5211b8b	authenticated	authenticated	nicocostac@gmail.com	$2a$10$iKZlMebIC.i4U1PSCRV4TOS2mILqTz32LeEAmH9HWWjYfxj/oOajS	2024-11-05 23:00:45.204697+00	\N		\N		\N			\N	2024-11-07 22:04:59.56634+00	{"provider": "email", "providers": ["email"]}	{"sub": "dc1406e9-fcd3-40e2-b960-152af5211b8b", "email": "nicocostac@gmail.com", "last_name": "asdasd", "first_name": "asdasd", "email_verified": false, "phone_verified": false}	\N	2024-11-05 22:59:10.30863+00	2024-11-07 22:04:59.568722+00	\N	\N			\N		0	\N		\N	f	\N	f
00000000-0000-0000-0000-000000000000	36837910-176b-48b8-9a49-e2bc08431bd9	authenticated	authenticated	nicocostac+nevados@gmail.com	$2a$10$uaUKe9lknKJHbgLUMp8GOOqS3KPLEa9vNrnz/3HQr3cUBWuMUg/cu	2024-11-05 20:23:34.236033+00	\N		\N		\N			\N	2024-12-06 18:57:55.283711+00	{"provider": "email", "providers": ["email"]}	{"sub": "36837910-176b-48b8-9a49-e2bc08431bd9", "email": "nicocostac+nevados@gmail.com", "email_verified": false, "phone_verified": false}	\N	2024-11-05 20:23:16.594568+00	2024-12-11 12:32:16.537349+00	\N	\N			\N		0	\N		\N	f	\N	f
\.


--
-- Data for Name: key; Type: TABLE DATA; Schema: pgsodium; Owner: -
--

COPY pgsodium.key (id, status, created, expires, key_type, key_id, key_context, name, associated_data, raw_key, raw_key_nonce, parent_key, comment, user_data) FROM stdin;
\.


--
-- Data for Name: boroughs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.boroughs (id, name, status, created_at, updated_at) FROM stdin;
1bd0af9e-f376-48ea-999d-5858cb39f9e8	Peñaflor	active	2024-11-07 22:43:37.905653+00	2024-11-07 22:43:37.905653+00
96d99b1a-95fe-45f5-9c8f-d5d7439912a0	Maipu	active	2024-11-07 22:43:55.469932+00	2024-11-07 22:43:55.469932+00
3280cf14-245d-4562-a16a-9afed9dad934	Talagantee	inactive	2024-11-07 22:45:17.127026+00	2024-11-07 22:45:29.398018+00
4bf42445-430d-4f23-928e-8a83e69ca9c9	Talagante	active	2024-11-22 22:20:43.183979+00	2024-11-22 22:20:43.183979+00
186604c8-a965-4bd0-852b-1055f4ef9209	Padre Hurtado	active	2024-11-22 22:21:22.156931+00	2024-11-22 22:21:22.156931+00
be87ece8-a46d-430e-9e94-8abe40668575	Calera de Tango	active	2024-11-22 22:22:19.332046+00	2024-11-22 22:22:19.332046+00
79948be8-4794-497d-bfb6-c7d6257ce912	Cerrillos	active	2024-11-22 22:23:44.302129+00	2024-11-22 22:23:44.302129+00
\.


--
-- Data for Name: client_addresses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.client_addresses (id, client_id, street_address, additional_info, is_default, created_at, updated_at, borough_id, neighborhood_id, latitude, longitude, contact_person) FROM stdin;
3cc33a63-d33c-49d4-9de0-5a3d9ca3db53	e3739229-0a2c-4b7a-96fc-7f9e62e3befd	Condominio El Curato parcela 75		t	2024-12-10 14:37:19.854198+00	2024-12-10 14:41:33.443446+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.58104580	-70.90112650	Camilo Salazar
82701a5c-7c01-484e-9b05-7f1bfb239218	955eda10-ae83-45a5-91bf-ec1d23e7028d	Miraflores 1337	Casa 35	t	2024-12-10 14:43:16.734287+00	2024-12-10 14:43:16.734287+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Carlos Chandía
14d0c8e2-98da-44a3-9594-37cf3de28944	410d48c2-1357-4471-9a86-ca260dd6f278	Los Maquis 1672		t	2024-12-10 13:35:28.094162+00	2024-12-10 14:02:10.953107+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56896670	-70.80653680	Adriana Goza
25b2a515-1623-408b-8bd8-c1211d05af99	dfc19e2e-b24c-4e7a-9fd8-c7fe18f237cb	José Bernardo Suárez 1069		t	2024-12-10 13:38:55.172203+00	2024-12-10 14:02:11.815791+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60809960	-70.86511600	Alejandra Duarte
1e2ee825-0f79-452b-92eb-5259ea0e7436	fddec35e-5fc5-443b-8249-49835c4f9da8	Miraflores 1337	Casa 145	t	2024-12-10 13:41:55.071575+00	2024-12-10 14:02:12.62131+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60043840	-70.86423010	Alejandra León
08ed5f2a-e0b7-498b-b8f8-76ae65560131	215bf1ed-6208-4220-a889-ebe4b4715e15	Miraflores 1337	Portería Altué	t	2024-12-10 13:44:21.290397+00	2024-12-10 14:02:13.493878+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Alexis Contreras
ac97850e-a809-44fa-a5a7-a2d79220a7a6	aa2056b9-af4f-42ac-a3e0-50fac4f9f51c	Miraflores 1337	Casa 38	t	2024-12-10 13:45:21.368358+00	2024-12-10 14:02:14.056697+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Alfredo Franco
8dc1b905-2655-42d9-bcc0-734db79b293c	c0519100-db35-4f5f-81f7-2a79d080d558	Miraflores 1135	Casa C	t	2024-12-10 13:57:12.676042+00	2024-12-10 14:02:14.864752+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	dbf126d9-d719-4760-b87b-3ac2ae662f89	-33.60078760	-70.86226760	Ana Maía Durán
9ae3212c-679a-4761-a8f3-8328c6e37cec	c48b8200-a21f-438b-b61b-94994399d1ad	Padre José Gregorio Mesa 3038		t	2024-12-10 14:00:12.331323+00	2024-12-10 14:02:15.668647+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.59996250	-70.86249010	Ana María Garrido
16aa1f88-21bb-430d-9c0d-c4f8771ebdc5	8dd56a6e-378d-4752-b08a-3f2eb3f177d4	Radal Siete Tazas 1271		t	2024-12-10 14:06:16.604809+00	2024-12-10 14:13:28.603858+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57257720	-70.79868050	Andrés Carrión
66b809e0-cdd9-49b6-bf81-738494f57889	2d3fd002-9602-4920-9c9d-3abc738d4feb	Totoralillo 235		t	2024-12-10 14:07:21.46695+00	2024-12-10 14:13:29.313666+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	\N	-33.52545730	-70.78750800	Ángela Aguayo
109c6864-55e7-409a-9035-a261ef1f33ac	07042a4b-93af-4876-9392-2610ec62a209	Alberto Blest Gana 554		t	2024-12-10 14:08:03.202421+00	2024-12-10 14:13:30.036474+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56357340	-70.79934940	Angélica Jiménez
37a897f5-424a-4849-9929-428bfed1396b	0562054e-e962-42da-99f4-9fa70862ab4e	Miraflores 1337	Casa 74	t	2024-12-10 14:09:04.429009+00	2024-12-10 14:13:30.537809+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Aracely González
72c9359c-07a2-4fe1-b9f4-edaf2fd4257e	920d7b35-776b-41d4-bda2-b550279dc44e	Valle del Elqui 1978		t	2024-12-10 14:19:07.215352+00	2024-12-10 14:29:27.820183+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57534440	-70.80357530	Ástrid De Torres
3aa67ef1-a493-43aa-8079-cebb14ce93bd	34b982e7-80eb-4de2-8ae1-6ad99575e610	Ottawa 938		t	2024-12-10 14:20:20.620285+00	2024-12-10 14:29:28.579313+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60788280	-70.86616620	Ástrid Salinas
87a84730-7302-4e3c-93ca-fa1297be330e	ac241d67-5a00-4360-ad52-517731d0eb22	Miraflores 506	Chilexpress	t	2024-12-10 14:21:31.454955+00	2024-12-10 14:29:29.316363+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60206790	-70.85651950	Audie
4a221224-388c-46a9-9f2e-bca137d6b1d9	eb07e857-8869-42cd-a652-0e2ad7ee8537	Maule 1292		t	2024-12-10 14:22:31.77674+00	2024-12-10 14:29:30.008226+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60884470	-70.87102510	Bárbara González
fb3238ee-8bde-425f-ad31-566a3b9c11fd	dabfc366-dee1-4655-a822-5b909533dbd2	Condominio Los Almendros Norte, Parcela 37	Calera de Tango Paradero 2	t	2024-12-10 14:29:20.817019+00	2024-12-10 14:29:30.820238+00	be87ece8-a46d-430e-9e94-8abe40668575	\N	-33.63138620	-70.74983380	Beatriz Baeza
f30b2910-667f-4c12-aa13-eb0da56c45df	3368aea8-9c83-44c2-8b65-a8739ae99a85	Violeta Parra 1781		t	2024-12-10 14:34:00.909909+00	2024-12-10 14:37:41.728272+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60135730	-70.87136570	Belén López
1e680c3b-bcf0-4cbf-a249-f322c7ceeb58	25482691-aff8-44e8-a26a-df88cca75129	Calle La Cosecha 2030		t	2024-12-10 14:34:47.315488+00	2024-12-10 14:37:42.594189+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57681620	-70.80235010	Betzabé Cofré
4398cd29-057d-4808-bf4a-ef92bdd29d0d	8c4d9d6d-8f1a-419f-aaf8-790d99324776	Óscar Castro 575		t	2024-12-10 14:35:37.057948+00	2024-12-10 14:37:43.333933+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60857140	-70.86506620	Bryan Álvarez
d9965df9-2d3e-4979-85ab-027e23b2a8f4	3fbf1be6-0473-48ab-aa83-b02a77aa9466	Pasaje Herrera Casa 4		t	2024-12-10 14:45:09.674742+00	2024-12-10 14:45:09.674742+00	be87ece8-a46d-430e-9e94-8abe40668575	\N	-33.62846830	-70.77319920	Carlos Herrera
4bbfc4a6-92f7-474d-97fc-ef43d3001aac	bdee04b5-88d3-4f0c-a5f6-88c37ace1737	Presbítero Félix Zaragoza Sésmero 2731		t	2024-12-10 13:33:21.011926+00	2024-12-10 14:53:02.255882+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.59498070	-70.85101270	Adalexis López
be6a4465-61ff-4517-82ab-b1bbe7171bee	68db6b79-229c-4afc-abc9-a054a0ac0875	Lonquén Sur paradero 24 1/2 Condominio Los Copihues p.24		t	2024-12-10 14:53:38.581342+00	2024-12-10 14:53:38.581342+00	4bf42445-430d-4f23-928e-8a83e69ca9c9	3cb885ba-6fba-4cc1-8c93-d43e74b289aa	-33.64735230	-70.82231580	
5059cff5-a935-4d23-8e3a-d2e9c926fd6d	8a7fb007-01af-4bb0-be0d-7c08e97de263	Miraflores 1337	Casa 21	t	2024-12-10 15:40:04.186145+00	2024-12-10 15:40:04.186145+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Cintia Jerez
5abb373a-f427-40bc-a126-08ea6204ee08	471b4294-954c-473b-a4ae-7dbc22e015fa	Vicuña Mackenna 838  Condominio Las Vertientes III		f	2024-12-10 14:56:00.185511+00	2024-12-10 14:57:33.419976+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.61213320	-70.86674750	Carola San Martín
7f62a56a-493c-4f21-a45a-a70a406cb60e	b37ed689-015e-4707-808f-167bdcab5069	Condominio Los Almendros Sur parcela 22		t	2024-12-10 15:00:47.796734+00	2024-12-10 15:00:47.796734+00	be87ece8-a46d-430e-9e94-8abe40668575	\N	-33.63182600	-70.74963430	Carolina Salcedo
92e237c7-52fe-4ba1-a2a6-6353d9872ebc	41303b5a-6f07-4d8d-906d-30866333c8a1	Santa Herminia 753 Condominio Los Esteros Casa 80		t	2024-12-10 15:03:19.591157+00	2024-12-10 15:03:19.591157+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56865520	-70.82980330	Carolina Samaritani
e18c1785-a90b-4b91-ad57-01332ecb441b	46e01b27-d86b-4d40-bca0-6fe207a59961	Hospital de Peñaflor	 Dirección	t	2024-12-10 15:04:45.530305+00	2024-12-10 15:04:45.530305+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.61016430	-70.90376060	Carolina San Martín
49f84764-4fc5-4c7c-8aaa-038bd9be1448	ac39ce70-ea62-42e9-9196-20ecebc86b49	Av. Jorge Montt 535		t	2024-12-10 15:07:13.696452+00	2024-12-10 15:07:13.696452+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.59756670	-70.85400920	Carolina Vidal
4c0f33b0-b8e6-4411-940b-90c6488d7fc0	f306915d-e80d-4dea-a8ea-7ab490d62257	Miraflores 1337	Casa 91	t	2024-12-10 15:26:27.723954+00	2024-12-10 15:26:27.723954+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Caroly Flores
7e836e92-5213-473c-b706-8a4f64a118b0	4903ceb5-1ab4-4c55-b712-15d6f04a00bb	Lonquén Sur paradero 37 1/2 Sitio 39		t	2024-12-10 15:28:14.378243+00	2024-12-10 15:28:14.378243+00	4bf42445-430d-4f23-928e-8a83e69ca9c9	3cb885ba-6fba-4cc1-8c93-d43e74b289aa	-33.66054670	-70.83444590	Cecilia Gamboa
b40c1d9e-373b-43cd-8e8e-fb58b7a66851	0bdd6a67-7511-4b8b-89c3-be04015d2984	San Marcos 2064		t	2024-12-10 15:30:23.657229+00	2024-12-10 15:30:23.657229+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57323850	-70.80791800	Cecilia Herrera
dc48b6de-ce62-41d5-a4d9-25a1de13c608	6272cc76-9378-48b0-83a1-c68e7855fc29	Condominio San José parcela 21		f	2024-12-10 15:31:51.451623+00	2024-12-10 15:31:51.451623+00	4bf42445-430d-4f23-928e-8a83e69ca9c9	9101c473-d055-4d98-a03b-45927804b672	-33.66608600	-70.87045150	Christopher Hermosilla
2d28c6ef-3ae8-45e3-915d-27694951215c	b0fdd82b-0121-4e25-85fb-6c333d3f990d	Miraflores 1337	Casa 117	t	2024-12-10 15:42:59.135477+00	2024-12-10 15:42:59.135477+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Claudia Díaz
6761dc2e-b1a8-48d5-9cac-bb4f9208af7e	785db10b-61bd-486d-be05-411690a1d87b	C° Melipilla 14200 Cond. El Curato	parcela 28	t	2024-12-10 15:47:02.745798+00	2024-12-10 15:47:02.745798+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.58159750	-70.82847060	Claudia Veli
80a3d9ea-5cfb-4dd1-9fac-1983eeb5296f	2cd05dec-b15e-4ebd-8d28-a126ade84fde	Av. La Laguna 3581 Condominio Los Veleros	Casa 34	f	2024-12-10 15:58:31.967914+00	2024-12-10 15:58:31.967914+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56138410	-70.83227210	Claudio Fernández
ad53d887-9907-46a6-b774-07e47fd950e6	bd64a5ba-c0a5-462c-afec-0fd5b5c4e987	Zoila Yamerich 1991		t	2024-12-10 16:11:31.200228+00	2024-12-10 16:11:31.200228+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57569970	-70.80329660	Cristián Opazo
18782990-418e-49fa-bd81-649251834d89	bd64a5ba-c0a5-462c-afec-0fd5b5c4e987	Parque Conguillío 1210		f	2024-12-10 16:11:58.480345+00	2024-12-10 16:11:58.480345+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57410290	-70.80012200	Cristián Opazo
8168ea88-169f-4129-af53-ccd9f980bcc0	0d93a064-5b9f-4780-93d2-50888452d781	C° Valparaíso s/n Club de Pádel Del Sol		t	2024-12-10 16:17:20.741053+00	2024-12-10 16:17:20.741053+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.55752540	-70.82642470	Cristóbal Bustos
8141598c-d776-410c-b122-9edb85bde978	f55d0e09-42f7-4726-a58b-987cb63f49de	Av. Alcalde José Luis Infante Larraín 1279 Condominio Barrio Norte 	Casa 102	t	2024-12-10 16:19:04.31095+00	2024-12-10 16:19:04.31095+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.56021220	-70.78407480	Rodrigo Peñaloza
2a387136-d914-4833-a2b9-c7161ea3e095	0e9b8159-8b6b-4a54-84b3-61af7f83130a	Av. Alcalde José del Valle Sur 504		t	2024-12-10 16:19:50.938141+00	2024-12-10 16:19:50.938141+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.59562420	-70.85215320	Felipe Sánchez
58242a28-604f-415d-9f97-46cd6fdf5adc	764063f5-7028-498b-b5e3-535bdf78dd11	Arturo Prat 2, Congelados Refrigerato	Congelados Refrigerato	f	2024-12-10 16:24:06.296184+00	2024-12-10 16:24:06.296184+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60989720	-70.90167800	Leslie Espinoza
c55645c9-1e48-4cf2-852c-58dd7a19db87	719b48ef-f16b-4fdd-99a8-28e622239899	Siglo XX 1566		t	2024-12-10 15:43:56.750438+00	2024-12-10 17:17:31.980771+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	\N	-33.51643660	-70.78263500	Claudia González Vargas
b415532d-d0ce-4658-8d11-1fb5b61cbdf3	bc4a096f-f1d8-415e-bd1c-4de41b0eaa8e	Acapulco 1524		t	2024-12-10 16:25:12.171364+00	2024-12-10 16:25:12.171364+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	\N	-33.49319660	-70.73765900	Felipe Escudero
2a9794b8-f79d-49ab-8938-6aee9d7efedb	f2e1c1cf-d6f5-4630-8db7-d4c447f07599	Av. Alcalde José Luis Infante Larraín 1492 Condominio Barrio Oriente I 	Casa 30	t	2024-12-10 16:27:09.102637+00	2024-12-10 16:27:09.102637+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.55995290	-70.78132300	Maricette Lagos
74759a58-61e3-428a-a6b2-b9759dcfe0cf	40c94b4d-140b-4089-91d0-5112f7e85999	AV. Alcalde José Luis Infante Larraín 1701 Cond. Barrio Central 	Casa 102	t	2024-12-10 16:28:35.16479+00	2024-12-10 16:28:35.16479+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.56163970	-70.77836910	Ingrid Farías
82a69900-9b1e-43b1-add0-4deb79019617	4658676d-d736-4d9d-9e7d-8d42478617e3	Av. Alcalde José Luis Infante Larraín 1701 Cond. Barrio Central 	Casa 147	t	2024-12-10 16:29:17.347088+00	2024-12-10 16:29:17.347088+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.56163970	-70.77836910	Giovanna Gutiérrez
5ea99026-a760-4977-aadb-7edf545c96fe	5363aad9-a6f4-486e-9753-c2f6e4037988	Av. Alcalde José Luis Infante Larraín 1701 Cond. Barrio Central	Casa 42	t	2024-12-10 16:29:57.911117+00	2024-12-10 16:29:57.911117+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.56163970	-70.77836910	Patricia Barrera
cecec6e4-de82-4208-be4f-3ad3a3c4d4c3	32e9b4c2-d072-4ffb-843b-914b15241adf	Av. Alcalde José Luis Infante Larraín 1900 Cond. Patagonia I 	Casa 104	t	2024-12-10 16:30:41.084136+00	2024-12-10 16:30:41.084136+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.56181030	-70.77644470	Gloria Ambiado
498c1dff-78c9-4549-9022-4337aa788ca7	f4a93d1f-b737-4a6e-963c-f187e2d1d79e	Av. Alcalde José Luis Infante Larraín 1900 Cond. Patagonia I	Casa 38	t	2024-12-10 16:31:04.897275+00	2024-12-10 16:31:04.897275+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.56181030	-70.77644470	Ivanna Gutiérrez
c654c814-c034-4081-9854-47653f70186b	b4c107a5-263c-4db3-b920-a6edb283301c	Av. Balmaceda 173	Ferretería Miraflor	f	2024-12-10 16:32:15.515888+00	2024-12-10 16:32:15.515888+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60160840	-70.85003470	Valeria Wall
bcf33179-a7c7-4898-bb08-db657d02e6c8	ff6e6e32-e38b-4371-95a2-5570e03dbd13	Av. Balmaceda 7801	Jumptastic	t	2024-12-10 16:33:21.504089+00	2024-12-10 16:33:21.504089+00	4bf42445-430d-4f23-928e-8a83e69ca9c9	\N	-33.65164060	-70.89369810	Romina Espinoza
32a3bf93-cbe8-4900-9a5e-b7948f414860	1b229fd4-6b41-486d-9490-2a329d55ca0e	Avenida Miraflores 2123	Local A: Cervecería Raíces	f	2024-12-10 16:39:32.861252+00	2024-12-10 16:39:32.861252+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.59874120	-70.87310180	Sebastián Barraza
08c8d7c8-0501-4124-8a43-5edf33e6ff50	b73beb0b-a8f4-48c1-a633-be19ed9ef123	Condominio Los Copihues	Parcela 22	t	2024-12-10 15:36:53.440125+00	2024-12-10 17:13:17.23983+00	4bf42445-430d-4f23-928e-8a83e69ca9c9	3cb885ba-6fba-4cc1-8c93-d43e74b289aa	-33.64735230	-70.82231580	Cinthya Rojo
7df6a61b-e68c-46e3-9ac5-3fd28bf19858	ce3455b8-0a64-498d-bd4b-e68dcf915d09	C° Melipilla 3812 Cond. El Descanso	Parcela 61	t	2024-12-10 17:34:18.45593+00	2024-12-10 17:34:18.45593+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57955580	-70.82505400	Cristián Ramírez
e148c164-75d1-4269-9ae9-1df860d75fc8	33c350f1-8df0-4303-ab47-5864957f2a40	Michimalongo 2393 Condominio Aires de Chena 	Casa 34	t	2024-12-10 18:03:26.097903+00	2024-12-10 18:04:08.275296+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.55947170	-70.76945820	Daniela Castro
a50c2724-1022-44d7-915f-a5c4a939d09e	6b1782b8-7bc2-4a17-b7e1-fbe3caca0dcd	Michimalongo 2393 Condominio Aires de Chena	Casa 2	t	2024-12-10 18:04:56.80678+00	2024-12-10 18:04:56.80678+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.55947170	-70.76945820	Maritza Oyarzún
f945b5c0-b29f-409b-af84-3a2d949b3ffd	bb7d6dbd-2468-4595-94e4-ac079f8fd5db	El Ombú Oriente 120		t	2024-12-10 18:07:33.508209+00	2024-12-10 18:07:33.508209+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.61294590	-70.89677850	Michel Moraga
fef0e132-b41a-4a20-8e04-2feb198705f6	bbfcf642-50df-4507-8e2e-d44faf690a22	Las Compuertas 901 Condominio Aguas Claras 	Casa 33	t	2024-12-10 18:08:49.883481+00	2024-12-10 18:08:49.883481+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56591810	-70.82878050	Reinaldo Maureira
47a098fb-bf5a-4a08-a717-c27c6f0482bb	facab9a6-4cf0-43f7-a2d5-43125531fd0a	Tilo 535		t	2024-12-10 18:10:32.479134+00	2024-12-10 18:10:32.479134+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60468980	-70.85883570	Richard Baxter
bfc85d91-b0d3-4b25-b1d2-45c1f2c3801f	e4de5aae-2172-4ad9-94a4-0ed90266f400	Valle del Elqui 1973		t	2024-12-10 18:11:07.405765+00	2024-12-10 18:11:07.405765+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.57512400	-70.80364500	Richard Mendoza
0e29f554-5507-4e95-aa2c-813f5ea938bf	c67f73ee-d3e6-4cac-8f16-1619b9f0eb64	Miraflores 1337	Casa 139	t	2024-12-10 18:11:47.127006+00	2024-12-10 18:11:47.127006+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Viviana Ramos
9eeb2e82-95ec-4b98-8781-9a6a086fd571	86efd7e1-425d-4986-9227-0c85607ba409	Las Compuertas 901 Cond. Aguas Clara	Casa 42	t	2024-12-10 23:46:49.463222+00	2024-12-10 23:46:49.463222+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56588230	-70.82873740	Venta en Ruta
51e69e6a-ebc1-4bab-9af5-67d7ac59287e	86efd7e1-425d-4986-9227-0c85607ba409	C° Melipilla 14200 Cond. El Curato	Parcela 63	f	2024-12-10 23:46:49.463222+00	2024-12-10 23:46:49.463222+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.58159750	-70.82847060	Venta en Ruta
805425e4-a433-414e-8baf-8aa478e2a33b	241f836c-f5c1-492a-bd6c-987230bd081b	Francisco De Aguirre 435		t	2024-12-10 23:50:15.243858+00	2024-12-10 23:50:15.243858+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.60404580	-70.86264630	Danaís Contreras
0235d73e-6e91-4b58-9845-746e76b74908	50ad729b-e715-4245-8176-ed395a4806e1	Las Aralias Cuatro 261		t	2024-12-10 23:51:46.534216+00	2024-12-10 23:51:46.534216+00	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	84eac37e-b169-4ec1-959c-1e24f6d46c27	-33.55751840	-70.79568580	Danilo Ormazábal
9d9c1f3e-9eb6-4094-b398-ca8abf9c854b	0a6ce6d0-6b4f-45c5-87be-f1a81353b5a3	Las Compuertas 901 Condominio Aguas Claras 	Casa 35	t	2024-12-10 23:52:15.656831+00	2024-12-10 23:52:15.656831+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56591810	-70.82878050	Diego Mendoza
55b78f53-4969-4ac0-97a5-be0e2ee1615d	d7ae2933-4e5b-400c-a2f7-6a21048aac80	Calle Los Alerces 1260		t	2024-12-11 00:02:11.261117+00	2024-12-11 00:02:11.261117+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	\N	-33.61013750	-70.87655470	Eliana Mera
1ac64333-93a7-4d00-b527-654567959ce6	82fc1108-c78e-4b3b-b6db-60e9d71edea6	Gabriela Mistral 790		t	2024-12-11 00:04:13.155324+00	2024-12-11 00:04:13.155324+00	186604c8-a965-4bd0-852b-1055f4ef9209	\N	-33.56460330	-70.79974470	Eliana Vallejos
c7b75735-037a-4ae8-8012-7a0f43a47477	b576f416-7e94-4ce6-b455-662812ba1f69	Miraflores 1337	Casa 109	t	2024-12-11 00:08:25.657186+00	2024-12-11 00:08:25.657186+00	1bd0af9e-f376-48ea-999d-5858cb39f9e8	0f84a81f-6f4d-430e-9597-03f70dd4e9d9	-33.60044250	-70.86419660	Elizabeth Santibáñez
\.


--
-- Data for Name: client_prices; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.client_prices (id, client_id, product_id, discount_percentage, final_price, notes, created_at, updated_at, start_date, end_date) FROM stdin;
bdc73f66-2e27-43d1-9978-5009ccdddc48	1b229fd4-6b41-486d-9490-2a329d55ca0e	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	64.29	1250.00		2024-12-10 16:39:33.118673+00	2024-12-10 16:39:33.118673+00	2024-01-01	\N
\.


--
-- Data for Name: client_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.client_types (id, name, description, created_at, updated_at) FROM stdin;
2312066a-44b2-4e6d-8cf5-1813dbc9d948	retail	Individual retail customers	2024-11-06 14:42:44.295938+00	2024-11-06 14:42:44.295938+00
a0782090-0b4d-45ea-a968-3cd7c34f739d	wholesale	Wholesale business customers	2024-11-06 14:42:44.295938+00	2024-11-06 14:42:44.295938+00
9a9dc8e6-78c5-40d7-a378-100abc3074a8	corporate	Corporate accounts	2024-11-06 14:42:44.295938+00	2024-11-06 14:42:44.295938+00
\.


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clients (id, name, email, phone, notes, type_id, communication_preference, status, created_at, updated_at, created_by, is_tj, phone_2) FROM stdin;
410d48c2-1357-4471-9a86-ca260dd6f278	Adriana Goza		+56978445620		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 13:35:27.950443+00	2024-12-10 13:35:27.950443+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	\N
dfc19e2e-b24c-4e7a-9fd8-c7fe18f237cb	Alejandra Duarte		+56949714601		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 13:38:54.990451+00	2024-12-10 13:38:54.990451+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	\N
fddec35e-5fc5-443b-8249-49835c4f9da8	Alejandra León		+56986690725		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 13:41:54.882186+00	2024-12-10 13:41:54.882186+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	\N
215bf1ed-6208-4220-a889-ebe4b4715e15	Alexis Contreras		+56993480977		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 13:44:21.027304+00	2024-12-10 13:44:21.027304+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	\N
aa2056b9-af4f-42ac-a3e0-50fac4f9f51c	Alfredo Franco		+56923720229		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 13:45:21.215566+00	2024-12-10 13:45:21.215566+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	\N
c0519100-db35-4f5f-81f7-2a79d080d558	Ana Maía Durán		+56959165860		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 13:57:12.440398+00	2024-12-10 13:58:40.346041+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	+56939484251
c48b8200-a21f-438b-b61b-94994399d1ad	Ana María Garrido		+56958411051		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:00:12.167768+00	2024-12-10 14:01:35.74175+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	+56223158190
8dd56a6e-378d-4752-b08a-3f2eb3f177d4	Andrés Carrión		+56982001714		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:06:16.412806+00	2024-12-10 14:06:16.412806+00	36837910-176b-48b8-9a49-e2bc08431bd9	t	
2d3fd002-9602-4920-9c9d-3abc738d4feb	Ángela Aguayo		+56964771723		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:07:21.162824+00	2024-12-10 14:07:21.162824+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
07042a4b-93af-4876-9392-2610ec62a209	Angélica Jiménez		+56981324858		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:08:02.984819+00	2024-12-10 14:08:02.984819+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
0562054e-e962-42da-99f4-9fa70862ab4e	Aracely González		+56975240179		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:09:04.246667+00	2024-12-10 14:09:04.246667+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
920d7b35-776b-41d4-bda2-b550279dc44e	Ástrid De Torres		+56945377199		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:19:06.974824+00	2024-12-10 14:19:06.974824+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
34b982e7-80eb-4de2-8ae1-6ad99575e610	Ástrid Salinas		+56999387143		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:20:20.417709+00	2024-12-10 14:20:20.417709+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
ac241d67-5a00-4360-ad52-517731d0eb22	Audie		+56971775598		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:21:31.284949+00	2024-12-10 14:21:31.284949+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
eb07e857-8869-42cd-a652-0e2ad7ee8537	Bárbara González		+56981598156		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:22:31.561777+00	2024-12-10 14:22:31.561777+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
dabfc366-dee1-4655-a822-5b909533dbd2	Beatriz Baeza		+56998222409		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:29:20.540702+00	2024-12-10 14:31:01.261116+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
3368aea8-9c83-44c2-8b65-a8739ae99a85	Belén López		+56999687903		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:34:00.768846+00	2024-12-10 14:34:00.768846+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
25482691-aff8-44e8-a26a-df88cca75129	Betzabé Cofré		+56963937029		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:34:47.167023+00	2024-12-10 14:34:47.167023+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
8c4d9d6d-8f1a-419f-aaf8-790d99324776	Bryan Álvarez		+56975790564		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:35:36.906909+00	2024-12-10 14:35:36.906909+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
e3739229-0a2c-4b7a-96fc-7f9e62e3befd	Camilo Salazar		+56974786317		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:37:19.696176+00	2024-12-10 14:41:52.779062+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
955eda10-ae83-45a5-91bf-ec1d23e7028d	Carlos Chandía		+56987807246		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:43:16.504739+00	2024-12-10 14:44:22.058751+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
3fbf1be6-0473-48ab-aa83-b02a77aa9466	Carlos Herrera		+56984494484		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:45:09.519056+00	2024-12-10 14:46:13.065405+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
bdee04b5-88d3-4f0c-a5f6-88c37ace1737	Adalexis López		+56942418120		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 13:33:20.681488+00	2024-12-10 14:53:05.470514+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
68db6b79-229c-4afc-abc9-a054a0ac0875	Carola Barra		+56992990079		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:50:31.795792+00	2024-12-10 14:54:01.920027+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
b0fdd82b-0121-4e25-85fb-6c333d3f990d	Claudia Díaz				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:40:55.573698+00	2024-12-10 15:43:05.024791+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
471b4294-954c-473b-a4ae-7dbc22e015fa	Carola San Martín		+56987405894		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 14:55:59.974701+00	2024-12-10 14:59:18.795239+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
b37ed689-015e-4707-808f-167bdcab5069	Carolina Salcedo		+56993278819		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:00:47.627442+00	2024-12-10 15:00:47.627442+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
41303b5a-6f07-4d8d-906d-30866333c8a1	Carolina Samaritani		+56944060011		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:03:19.450055+00	2024-12-10 15:03:19.450055+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	+56992965857
46e01b27-d86b-4d40-bca0-6fe207a59961	Carolina San Martín		+56992283725		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:04:45.364816+00	2024-12-10 15:04:45.364816+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
ac39ce70-ea62-42e9-9196-20ecebc86b49	Carolina Vidal		+56959101234		2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:07:13.452131+00	2024-12-10 15:07:13.452131+00	36837910-176b-48b8-9a49-e2bc08431bd9	t	
f306915d-e80d-4dea-a8ea-7ab490d62257	Caroly Flores				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:26:26.877899+00	2024-12-10 15:26:26.877899+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
4903ceb5-1ab4-4c55-b712-15d6f04a00bb	Cecilia Gamboa				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:28:14.215755+00	2024-12-10 15:28:14.215755+00	36837910-176b-48b8-9a49-e2bc08431bd9	t	
0bdd6a67-7511-4b8b-89c3-be04015d2984	Cecilia Herrera				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:30:23.488626+00	2024-12-10 15:30:23.488626+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
6272cc76-9378-48b0-83a1-c68e7855fc29	Christopher Hermosilla				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:31:51.31101+00	2024-12-10 15:34:35.890243+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
719b48ef-f16b-4fdd-99a8-28e622239899	Claudia González Vargas				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:43:56.593284+00	2024-12-10 17:17:33.493683+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
8a7fb007-01af-4bb0-be0d-7c08e97de263	Cintia Jerez				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:38:15.715007+00	2024-12-10 15:40:06.366483+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
ce3455b8-0a64-498d-bd4b-e68dcf915d09	Cristián Ramírez				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 17:34:18.218966+00	2024-12-10 17:34:18.218966+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
785db10b-61bd-486d-be05-411690a1d87b	Claudia Veli				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:47:02.510236+00	2024-12-10 15:47:02.510236+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
2cd05dec-b15e-4ebd-8d28-a126ade84fde	Claudio Fernández				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:58:31.745766+00	2024-12-10 15:58:31.745766+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
bd64a5ba-c0a5-462c-afec-0fd5b5c4e987	Cristián Opazo				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:11:30.967388+00	2024-12-10 16:12:14.942015+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
0d93a064-5b9f-4780-93d2-50888452d781	Cristóbal Bustos				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:17:20.574811+00	2024-12-10 16:17:20.574811+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
f55d0e09-42f7-4726-a58b-987cb63f49de	Rodrigo Peñaloza				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:19:04.159799+00	2024-12-10 16:19:04.159799+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
0e9b8159-8b6b-4a54-84b3-61af7f83130a	Felipe Sánchez				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:19:50.78211+00	2024-12-10 16:19:50.78211+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
764063f5-7028-498b-b5e3-535bdf78dd11	Leslie Espinoza				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:24:06.061625+00	2024-12-10 16:24:06.061625+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
bc4a096f-f1d8-415e-bd1c-4de41b0eaa8e	Felipe Escudero				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:25:11.982421+00	2024-12-10 16:25:11.982421+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
f2e1c1cf-d6f5-4630-8db7-d4c447f07599	Maricette Lagos				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:27:08.929747+00	2024-12-10 16:27:25.410942+00	36837910-176b-48b8-9a49-e2bc08431bd9	t	
40c94b4d-140b-4089-91d0-5112f7e85999	Ingrid Farías				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:28:35.000684+00	2024-12-10 16:28:35.000684+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
4658676d-d736-4d9d-9e7d-8d42478617e3	Giovanna Gutiérrez				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:29:17.180017+00	2024-12-10 16:29:17.180017+00	36837910-176b-48b8-9a49-e2bc08431bd9	t	
5363aad9-a6f4-486e-9753-c2f6e4037988	Patricia Barrera				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:29:57.742743+00	2024-12-10 16:29:57.742743+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
32e9b4c2-d072-4ffb-843b-914b15241adf	Gloria Ambiado				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:30:40.927732+00	2024-12-10 16:30:40.927732+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
f4a93d1f-b737-4a6e-963c-f187e2d1d79e	Ivanna Gutiérrez				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:31:04.754579+00	2024-12-10 16:31:04.754579+00	36837910-176b-48b8-9a49-e2bc08431bd9	t	
b4c107a5-263c-4db3-b920-a6edb283301c	Valeria Wall				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:32:15.354291+00	2024-12-10 16:32:15.354291+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
ff6e6e32-e38b-4371-95a2-5570e03dbd13	Romina Espinoza				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:33:21.349241+00	2024-12-10 16:33:21.349241+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
1b229fd4-6b41-486d-9490-2a329d55ca0e	Sebastián Barraza				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 16:39:32.613729+00	2024-12-10 16:39:32.613729+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
b73beb0b-a8f4-48c1-a633-be19ed9ef123	Cinthya Rojo				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 15:36:53.188232+00	2024-12-10 17:13:18.92309+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
33c350f1-8df0-4303-ab47-5864957f2a40	Daniela Castro				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 18:03:25.909644+00	2024-12-10 18:04:21.262077+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
6b1782b8-7bc2-4a17-b7e1-fbe3caca0dcd	Maritza Oyarzún				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 18:04:56.663768+00	2024-12-10 18:04:56.663768+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
bb7d6dbd-2468-4595-94e4-ac079f8fd5db	Michel Moraga				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 18:07:33.354308+00	2024-12-10 18:07:33.354308+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
bbfcf642-50df-4507-8e2e-d44faf690a22	Reinaldo Maureira				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 18:08:49.722955+00	2024-12-10 18:08:49.722955+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
facab9a6-4cf0-43f7-a2d5-43125531fd0a	Richard Baxter				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 18:10:32.034755+00	2024-12-10 18:10:32.034755+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
e4de5aae-2172-4ad9-94a4-0ed90266f400	Richard Mendoza				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 18:11:06.85391+00	2024-12-10 18:11:19.578251+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
c67f73ee-d3e6-4cac-8f16-1619b9f0eb64	Viviana Ramos				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 18:11:46.956177+00	2024-12-10 18:11:46.956177+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
86efd7e1-425d-4986-9227-0c85607ba409	Venta en Ruta				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 23:46:49.237505+00	2024-12-10 23:46:49.237505+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
241f836c-f5c1-492a-bd6c-987230bd081b	Danaís Contreras				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 23:50:15.096929+00	2024-12-10 23:50:15.096929+00	36837910-176b-48b8-9a49-e2bc08431bd9	t	
50ad729b-e715-4245-8176-ed395a4806e1	Danilo Ormazábal				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 23:51:46.392588+00	2024-12-10 23:51:46.392588+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
0a6ce6d0-6b4f-45c5-87be-f1a81353b5a3	Diego Mendoza				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-10 23:52:15.512834+00	2024-12-10 23:52:15.512834+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
d7ae2933-4e5b-400c-a2f7-6a21048aac80	Eliana Mera				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-11 00:02:11.051929+00	2024-12-11 00:02:11.051929+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
82fc1108-c78e-4b3b-b6db-60e9d71edea6	Eliana Vallejos				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-11 00:04:13.024422+00	2024-12-11 00:04:13.024422+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
b576f416-7e94-4ce6-b455-662812ba1f69	Elizabeth Santibáñez				2312066a-44b2-4e6d-8cf5-1813dbc9d948	whatsapp	active	2024-12-11 00:08:25.519831+00	2024-12-11 00:08:25.519831+00	36837910-176b-48b8-9a49-e2bc08431bd9	f	
\.


--
-- Data for Name: mixed_bundle_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mixed_bundle_items (id, bundle_id, product_id, quantity, created_at) FROM stdin;
9c8a99db-be53-44a3-883f-cf4da206249d	1c081b11-f94a-4b88-8d79-98b1fe613cce	492d2aa4-2135-4a62-860b-ac541aa5717b	2.00	2024-12-09 15:09:40.632242+00
53750dca-dd83-4279-9383-01467d1bec76	4076a6d8-ca49-4d78-91ea-d5f15736ac9e	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	2.00	2024-12-09 15:28:41.239489+00
3819a735-569e-4620-8303-fd9197f50dab	4076a6d8-ca49-4d78-91ea-d5f15736ac9e	fc03bf9b-d474-4e05-8796-1a002501e7c6	2.00	2024-12-09 15:28:41.239489+00
81319c53-b804-4e6f-87e2-4c94ccfb4651	4076a6d8-ca49-4d78-91ea-d5f15736ac9e	71d896bf-921a-40aa-9e59-162c912ebf8d	1.00	2024-12-09 15:28:41.239489+00
046c5f3a-7f6f-48e1-bb32-8382b93848d1	e7c246b8-5e6f-4fea-9848-d776c8c1cdd2	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	2.00	2024-12-10 16:49:36.346679+00
b9475c9f-2325-4e06-aa97-c4d362de02ca	ec2de1a7-8a75-4869-8c8a-d3712ebe3ef7	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	10.00	2024-12-10 19:19:50.798073+00
\.


--
-- Data for Name: mixed_bundles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.mixed_bundles (id, name, description, total_price, status, created_at, updated_at, created_by, updated_by, start_date, end_date) FROM stdin;
1c081b11-f94a-4b88-8d79-98b1fe613cce	2 Recargas de 10L		4000.00	active	2024-12-09 14:48:12.151735+00	2024-12-09 15:09:39.915536+00	\N	\N	2024-12-09	\N
4076a6d8-ca49-4d78-91ea-d5f15736ac9e	Pack Inicial 	Pack Inicial para nuevos clientes	15000.00	active	2024-12-09 15:16:49.027932+00	2024-12-09 15:28:40.486522+00	\N	\N	2024-12-09	\N
e7c246b8-5e6f-4fea-9848-d776c8c1cdd2	2 Recargas de 20L		5000.00	active	2024-12-09 14:35:01.710765+00	2024-12-10 16:49:35.263589+00	\N	\N	2024-09-01	\N
ec2de1a7-8a75-4869-8c8a-d3712ebe3ef7	10 Recargas de 20L		20000.00	active	2024-12-09 18:09:51.639962+00	2024-12-10 19:19:49.76822+00	\N	\N	2024-09-01	\N
\.


--
-- Data for Name: neighborhoods; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.neighborhoods (id, name, borough_id, status, created_at, updated_at) FROM stdin;
3f6f4f41-a358-41a6-8f30-676888e39fa9	Las Praderas	1bd0af9e-f376-48ea-999d-5858cb39f9e8	active	2024-11-07 22:43:46.575095+00	2024-11-07 22:43:46.575095+00
3cb885ba-6fba-4cc1-8c93-d43e74b289aa	Lonquén	4bf42445-430d-4f23-928e-8a83e69ca9c9	active	2024-11-22 22:20:57.369072+00	2024-11-22 22:20:57.369072+00
84eac37e-b169-4ec1-959c-1e24f6d46c27	Ciudad Satélite	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	active	2024-11-07 22:44:03.112244+00	2024-11-22 22:21:41.657322+00
9101c473-d055-4d98-a03b-45927804b672	El Oliveto	4bf42445-430d-4f23-928e-8a83e69ca9c9	active	2024-11-22 22:23:04.718454+00	2024-11-22 22:23:04.718454+00
fe8a2510-1eb0-4227-9f0a-f62e9fd1d69a	El Abrazo	96d99b1a-95fe-45f5-9c8f-d5d7439912a0	active	2024-11-22 22:24:15.978664+00	2024-11-22 22:24:15.978664+00
0f84a81f-6f4d-430e-9597-03f70dd4e9d9	Condominio Altué	1bd0af9e-f376-48ea-999d-5858cb39f9e8	active	2024-12-10 13:42:22.550754+00	2024-12-10 13:42:22.550754+00
dbf126d9-d719-4760-b87b-3ac2ae662f89	Condominio Elqui II	1bd0af9e-f376-48ea-999d-5858cb39f9e8	active	2024-12-10 13:57:41.037202+00	2024-12-10 13:57:41.037202+00
\.


--
-- Data for Name: payment_methods; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.payment_methods (id, name, description, status, created_at, updated_at) FROM stdin;
3fa46566-bc26-4feb-a60a-762c0144bc7a	Cash	Cash payment	active	2024-11-07 18:57:01.172849+00	2024-11-07 18:57:01.172849+00
f4ee3668-57e1-4126-b64a-3fafe32201bc	Bank Transfer	Direct bank transfer	active	2024-11-07 18:57:01.172849+00	2024-11-07 18:57:01.172849+00
1e7a6e59-0c6d-47d8-a743-3d6c782e86da	Debit Card	Payment via debit card	active	2024-11-07 18:57:01.172849+00	2024-11-07 18:57:01.172849+00
7c7268f6-a8ff-4c82-b141-b1d2c55c60a9	Credit Card	Payment via credit card	active	2024-11-07 18:57:01.172849+00	2024-11-07 18:57:01.172849+00
\.


--
-- Data for Name: product_categories; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_categories (id, name, description, created_at, updated_at) FROM stdin;
0c40f723-5937-4987-91b3-392590138050	Recargas	Recargas de Agua	2024-11-05 23:19:44.20918+00	2024-11-05 23:19:44.20918+00
f24af995-e915-4eba-b7df-cc4812ed18c8	Otros	Otros productos en venta	2024-11-22 21:53:03.811019+00	2024-11-22 21:53:16.141994+00
\.


--
-- Data for Name: product_prices; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.product_prices (id, product_id, price, created_at, updated_at, created_by, updated_by, start_date, end_date, min_quantity, max_quantity) FROM stdin;
e403e4c2-4a49-4a40-9d19-7770a1bbdafd	\N	2000.00	2024-11-22 21:53:53.612173+00	2024-11-22 21:53:53.612173+00	36837910-176b-48b8-9a49-e2bc08431bd9	\N	2024-09-01	\N	1	\N
e25c02b0-8ede-4eea-8c8d-8f1b4b08c813	a4db3fd2-3310-451c-80a3-f9a77761c295	2000.00	2024-11-22 21:54:23.870465+00	2024-11-22 21:55:43.603375+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
295f15fb-abe0-4174-b59e-419478ae70c8	08136a79-3396-4085-aee7-c9db9e2867af	2500.00	2024-11-22 21:56:53.799665+00	2024-11-22 21:56:55.782362+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
f9ed9e0f-098a-4343-be0d-e096d87584ba	fc03bf9b-d474-4e05-8796-1a002501e7c6	3500.00	2024-11-22 21:58:54.412852+00	2024-11-22 21:58:56.271169+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
3d9db4d2-d355-46eb-82f9-30386b1244d2	71d896bf-921a-40aa-9e59-162c912ebf8d	5000.00	2024-11-22 21:59:49.679652+00	2024-11-22 21:59:51.768154+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
562b8135-9b01-46b9-8107-467be84cc213	0b88e3e1-d05c-432f-bf3e-5ff147d56956	15000.00	2024-11-22 22:00:46.233221+00	2024-11-22 22:00:50.914208+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
5a5b4d95-f847-442d-bed7-85012bd204a8	2e2705bf-2d6e-4a9f-bbd2-6ead7ac804f9	30000.00	2024-11-22 22:02:46.560372+00	2024-11-22 22:02:48.622219+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
d65ebd3c-cfae-4988-8563-8e76a157360b	6e14cb92-1afe-4791-944d-dcdc54570f00	75000.00	2024-11-22 22:03:28.363187+00	2024-11-22 22:03:31.467287+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
581f9c3c-be81-43eb-8a25-948154845e56	6f2470ad-80ae-4131-a42f-9a509ca619fc	120000.00	2024-11-22 22:04:20.831031+00	2024-11-22 22:04:25.079308+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
2d1ee1f3-6b48-4ed9-a207-82bd7654bd23	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	3500.00	2024-11-22 00:01:36.761615+00	2024-12-09 14:36:23.34628+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
97837e96-35d0-4cfc-9000-ee76f0611872	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	3000.00	2024-11-22 00:01:19.556044+00	2024-12-09 14:36:23.461418+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-01-01	2024-08-31	1	\N
4e107fe8-3edc-4c43-8833-abff0b10c5ec	492d2aa4-2135-4a62-860b-ac541aa5717b	2000.00	2024-11-22 02:27:58.395551+00	2024-12-10 19:40:51.362093+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-09-01	\N	1	\N
50398440-e7f9-4bf2-bf07-b59067598819	492d2aa4-2135-4a62-860b-ac541aa5717b	1500.00	2024-11-22 02:40:54.865545+00	2024-12-10 19:40:51.635202+00	36837910-176b-48b8-9a49-e2bc08431bd9	36837910-176b-48b8-9a49-e2bc08431bd9	2024-01-01	2024-08-31	1	\N
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.products (id, name, description, unit_of_sale, category_id, status, created_at, updated_at) FROM stdin;
a4db3fd2-3310-451c-80a3-f9a77761c295	Recarga 12L	Recarga de 12L	unit	0c40f723-5937-4987-91b3-392590138050	active	2024-11-22 21:54:09.283075+00	2024-11-22 21:55:43.449442+00
08136a79-3396-4085-aee7-c9db9e2867af	Bidón 10L	Bidón nuevo de 10L	unit	f24af995-e915-4eba-b7df-cc4812ed18c8	active	2024-11-22 21:56:34.073336+00	2024-11-22 21:56:55.593794+00
fc03bf9b-d474-4e05-8796-1a002501e7c6	Bidón 20L	Bidón nuevo de 20L	unit	f24af995-e915-4eba-b7df-cc4812ed18c8	active	2024-11-22 21:58:35.702703+00	2024-11-22 21:58:56.060612+00
71d896bf-921a-40aa-9e59-162c912ebf8d	Dispensador Básico	Dispensador de Agua Básico	unit	f24af995-e915-4eba-b7df-cc4812ed18c8	active	2024-11-22 21:59:33.601479+00	2024-11-22 21:59:51.573608+00
0b88e3e1-d05c-432f-bf3e-5ff147d56956	Bomba USB	Bomba USB tipo monomando	unit	f24af995-e915-4eba-b7df-cc4812ed18c8	active	2024-11-22 22:00:29.204697+00	2024-11-22 22:00:50.70942+00
2e2705bf-2d6e-4a9f-bbd2-6ead7ac804f9	Pack 50 botellas 500cc	50 botellas de 500cc	pack	f24af995-e915-4eba-b7df-cc4812ed18c8	active	2024-11-22 22:02:27.440678+00	2024-11-22 22:02:48.430404+00
6e14cb92-1afe-4791-944d-dcdc54570f00	Dispensador eléctrico de sobre mesa		unit	f24af995-e915-4eba-b7df-cc4812ed18c8	active	2024-11-22 22:03:13.321383+00	2024-11-22 22:03:31.27403+00
6f2470ad-80ae-4131-a42f-9a509ca619fc	Dispensador eléctrico de pedestal	Dispensador eléctrico de pedestal de ventilador	unit	f24af995-e915-4eba-b7df-cc4812ed18c8	active	2024-11-22 22:03:56.84286+00	2024-11-22 22:04:24.890731+00
aa5fced8-b36c-4196-9bcf-a36bb2204cd3	Recarga 20L	Recarga de 20L	unit	0c40f723-5937-4987-91b3-392590138050	active	2024-11-05 23:21:35.452476+00	2024-12-09 14:36:23.199108+00
492d2aa4-2135-4a62-860b-ac541aa5717b	Recarga 10L	Recarga de 10L	unit	0c40f723-5937-4987-91b3-392590138050	active	2024-11-22 00:24:46.816861+00	2024-12-10 19:40:51.138185+00
\.


--
-- Data for Name: profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.profiles (id, created_at, updated_at, first_name, last_name, phone, is_active, role, email) FROM stdin;
36837910-176b-48b8-9a49-e2bc08431bd9	2024-11-05 20:23:16.594221+00	2024-11-05 22:43:18.970945+00	Nicolás	Costa	+51951038516	t	admin	nicocostac+nevados@gmail.com
dc1406e9-fcd3-40e2-b960-152af5211b8b	2024-11-05 22:59:12.338718+00	2024-11-07 22:04:30.983881+00	asdasd	asdasd	123123123	t	manager	nicocostac@gmail.com
\.


--
-- Data for Name: sale_items; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sale_items (id, sale_id, product_id, item_number, quantity, unit_price, total_price, discount_percentage, notes, created_at) FROM stdin;
97ad48f0-fc3e-421b-9360-a2033af943ed	b58b254d-7331-4cb5-a013-d171bae23c48	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	5000.00	0.00	\N	2024-12-11 12:53:54.696389+00
ac5bcaf2-fdb4-4b64-bd5d-0037dccea967	fc9a8483-5bd0-46de-905f-7647531f40bb	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	5.00	2500.00	12500.00	0.00	\N	2024-12-10 19:46:47.206226+00
474715d9-9e8a-4a7f-a708-e3501d516fa2	349e2cc1-b99f-411e-bdbd-5f770b2b2893	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	10000.00	0.00	\N	2024-12-10 19:54:17.100384+00
06f04a24-c599-4e04-b704-8871d25374e5	a9895bf4-440c-4bc1-8b42-2f39aa8ed13e	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	9.00	2500.00	22500.00	0.00	\N	2024-12-10 19:56:50.623015+00
c9d0e715-e648-4c8c-9625-a57a9663dfbb	f6b5eab7-4d70-487a-a20f-3044caceb1c6	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	10000.00	0.00	\N	2024-12-10 19:58:54.663889+00
8efa465e-8067-4a9f-8e13-032f2c54e2b2	f4771039-9bf9-4c72-a424-f7b8b4568f46	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-10 19:59:34.029107+00
8cc0f494-c965-40ae-ac1e-b2236205d405	38c2a473-5c92-4f69-9b8c-289cc0efe4a7	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	10000.00	0.00	\N	2024-12-10 20:00:18.147914+00
6b003787-9299-4bf7-b69b-f4c30a36b305	14b51ca4-5a30-47da-b0ca-2f1fb5006069	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 23:47:32.966034+00
a9c31279-068e-4d08-984b-48d26836be74	716345d6-1ea6-4430-927c-c2749477f7a2	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 23:48:06.874838+00
79204479-6bae-4463-89bc-4b35ef9cf7b1	abbc4b95-288a-45bd-96e0-3dd83091d857	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-11 00:10:35.81057+00
b6b3b583-2697-42ef-9c6b-a9497fe40bba	d66c9161-100a-4289-93cb-9ea756d2293a	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	6.00	2500.00	15000.00	\N	\N	2024-12-11 12:45:07.093856+00
3bebf551-33a2-4a3f-9593-c85039e8dec9	8f612e81-5f9b-432f-8222-0bfa9b54eefd	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	52.00	1250.00	65000.00	\N	\N	2024-12-10 16:43:17.825052+00
a463ca8e-2fc4-4bf7-9f88-b0b3ae72cd29	65f14b6d-db3b-4571-b520-c6589438210b	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 17:02:20.432618+00
27bb78bf-2fa3-45e6-a28a-384bc6bf0ac2	1261a59f-5b93-4d59-ad9c-e8cc429a23d4	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-10 17:05:16.994916+00
e526cfd9-74f0-4143-81a9-910fba46ec7b	1e1c6e11-2b6e-4d7d-bb5b-f5d5d850862f	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	10000.00	0.00	\N	2024-12-10 17:06:55.551099+00
a49be69d-da2f-41c1-86d6-d6abf5e66882	60d55367-a55e-42b6-94c2-cd76b1a68ec1	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	5.00	2500.00	12500.00	0.00	\N	2024-12-10 17:12:05.573518+00
ba4e117c-0c80-4e08-9a38-7c84932047b2	60d55367-a55e-42b6-94c2-cd76b1a68ec1	492d2aa4-2135-4a62-860b-ac541aa5717b	2	2.00	2000.00	4000.00	0.00	\N	2024-12-10 17:12:05.573518+00
ebba502f-d4b2-4bfb-90a2-74906128f343	7043b0b9-bd1f-4774-a034-4131c8cfeae5	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 17:13:54.512955+00
5038e0f7-264a-40dc-85a0-b9f17ceee3fa	38a3fcbf-4380-4d63-bb77-6a3da96997bc	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-10 17:15:10.637379+00
99291849-a698-4e7a-8d03-cfb2e2caf398	02826d9b-295b-4d37-8d25-6f21e4721212	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	9.00	2500.00	22500.00	0.00	\N	2024-12-10 17:17:21.044311+00
7f938293-f136-4783-834d-981844c0dcfd	178e4b53-ca79-49ff-b6b5-b6b39b7e1823	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	10000.00	0.00	\N	2024-12-10 17:35:04.945285+00
7d0f102b-c2d2-4d39-af39-85c074588f8e	2f962d21-50a0-494f-ae35-0236f41054a8	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 18:20:56.979307+00
adae9e78-748e-4ba0-b138-3c66f890fd39	a31a5d20-93d2-4057-bbce-959aa5aa683a	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 18:26:17.737367+00
107dfe38-35e5-4192-ab7e-aceff7782194	bfa274f1-caeb-408a-a922-aff050ef87fc	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 18:26:52.094991+00
285f912d-03fd-44f4-a0b3-ef9baeacece7	a4b4def1-2f91-4f1c-bf27-043afebf4a5c	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	5.00	2500.00	12500.00	0.00	\N	2024-12-11 12:51:24.953612+00
77ba06ce-b1be-47b2-b365-3308206de2a7	4f48032b-f4da-4116-a774-555801e9f68b	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-11 13:00:48.368997+00
988bebd1-3145-42bd-9426-58493d895bf3	06e554f0-76ea-4ec3-b2ed-58e345434bab	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-10 19:13:13.446279+00
4347ac4b-6373-455a-bcf2-d15e6bdc95ce	41c5e1bd-e0bf-419e-8150-98cb988f05ef	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	1.00	3500.00	3500.00	0.00	\N	2024-12-11 12:52:44.178102+00
9236165b-3e65-494d-9ab3-3afce554c3a2	f526279a-09fc-4287-9672-9f501e87116e	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 18:41:51.84592+00
d7bba392-0e4e-4e54-a882-15ea3651ccff	f526279a-09fc-4287-9672-9f501e87116e	492d2aa4-2135-4a62-860b-ac541aa5717b	2	1.00	2000.00	2000.00	0.00	\N	2024-12-10 18:41:51.84592+00
6c04bdea-0550-4682-a7b6-a5a723490558	b6e6502d-2166-416f-be77-72c31b811e37	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	6.00	2500.00	15000.00	0.00	\N	2024-12-11 12:52:09.349884+00
8e47c0b9-6a5c-4b8c-bf4d-9eed754c427f	29ba1c18-0ca9-4ba9-a487-a20c5c16b8bf	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	10000.00	0.00	\N	2024-12-11 12:53:26.713553+00
ce21d748-2d84-42c4-85fc-3ea362582917	68fd6af4-6e1a-4b26-a263-bc660a456582	492d2aa4-2135-4a62-860b-ac541aa5717b	1	5.00	2000.00	10000.00	0.00	\N	2024-12-10 19:25:35.110583+00
1d5f4cdd-e603-44ed-b128-b0319cfdbeea	5619bf4c-0462-4eac-8783-2dfe78efed9e	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	6.00	2500.00	15000.00	0.00	\N	2024-12-10 19:04:07.848867+00
264369dc-e97a-4f6e-aabb-e20c6bd5ae34	8a8f3d9b-947d-47d0-b833-4536d8994dfd	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	5.00	2500.00	12500.00	0.00	\N	2024-12-10 19:05:27.242413+00
9330d5ed-af48-46c5-b56d-4c06ba55ac43	e35bad62-f877-45ad-a859-d6d6d3b39cc9	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	\N	\N	2024-12-10 16:56:43.962491+00
5419b70d-2623-4e7a-9d18-bedaf80414ba	68039766-a740-4483-960c-398ef0b27c60	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	4.00	2500.00	10000.00	0.00	\N	2024-12-11 13:03:36.904397+00
18f65dac-dead-4418-8a30-d8d85e94ec6b	32fba8b7-fb27-466c-96b3-f3b3047bfd9a	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	10.00	2000.00	20000.00	0.00	\N	2024-12-10 19:21:35.962904+00
e6f55c79-d122-450f-9e3f-4af2ca16ac38	febcb9a2-2d80-4d4c-9bb5-9c6015afd9aa	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-11 13:07:35.268564+00
396fe204-5406-4fa7-ac53-811c9fb26716	3a82e972-0c77-4d1d-a222-44222c333e23	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-10 19:41:34.549211+00
9e78116b-c798-4290-b1b2-e71550e94d32	3a82e972-0c77-4d1d-a222-44222c333e23	492d2aa4-2135-4a62-860b-ac541aa5717b	2	1.00	2000.00	2000.00	0.00	\N	2024-12-10 19:41:34.549211+00
e15ad7d4-21c2-4ae5-be7f-b526bc603bac	73e6a67a-ed87-45f0-8bef-524340ec04aa	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	2.00	2500.00	5000.00	0.00	\N	2024-12-11 13:11:31.94209+00
1387bc51-2af1-4d3f-a01e-93b3fb87b8f6	65fe1152-0310-4fdd-836a-13abc7af280b	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-11 13:18:20.70905+00
b1d890d2-6e5c-4e9f-85cf-2075b29ba529	f79f92e8-e1da-4465-b531-f7a5794169e2	aa5fced8-b36c-4196-9bcf-a36bb2204cd3	1	3.00	2500.00	7500.00	0.00	\N	2024-12-11 13:20:25.887535+00
\.


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sales (id, client_id, created_by, sale_date, delivery_date, delivery_address_id, status, total_amount, notes, payment_status, payment_method_id, payment_date, payment_notes, created_at, updated_at, salesperson_id, product_id, quantity) FROM stdin;
3a82e972-0c77-4d1d-a222-44222c333e23	fddec35e-5fc5-443b-8249-49835c4f9da8	\N	2024-10-19	2024-10-19	1e2ee825-0f79-452b-92eb-5259ea0e7436	active	7000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-19 00:00:00+00		2024-12-10 19:41:34.549211+00	2024-12-10 19:41:34.549211+00	\N	\N	1
8f612e81-5f9b-432f-8222-0bfa9b54eefd	1b229fd4-6b41-486d-9490-2a329d55ca0e	\N	2024-11-05	2024-11-05	32a3bf93-cbe8-4900-9a5e-b7948f414860	active	65000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-05 00:00:00+00		2024-12-10 16:43:02.297059+00	2024-12-10 16:43:17.825052+00	\N	\N	1
e35bad62-f877-45ad-a859-d6d6d3b39cc9	215bf1ed-6208-4220-a889-ebe4b4715e15	\N	2024-11-04	2024-11-04	08ed5f2a-e0b7-498b-b8f8-76ae65560131	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-04 00:00:00+00		2024-12-10 16:53:19.796707+00	2024-12-10 16:56:43.962491+00	\N	\N	1
65f14b6d-db3b-4571-b520-c6589438210b	c48b8200-a21f-438b-b61b-94994399d1ad	\N	2024-11-07	2024-11-07	9ae3212c-679a-4761-a8f3-8328c6e37cec	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-07 00:00:00+00		2024-12-10 17:02:20.432618+00	2024-12-10 17:02:20.432618+00	\N	\N	1
1261a59f-5b93-4d59-ad9c-e8cc429a23d4	8dd56a6e-378d-4752-b08a-3f2eb3f177d4	\N	2024-11-04	2024-12-04	16aa1f88-21bb-430d-9c0d-c4f8771ebdc5	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-04 00:00:00+00		2024-12-10 17:05:16.994916+00	2024-12-10 17:05:16.994916+00	\N	\N	1
1e1c6e11-2b6e-4d7d-bb5b-f5d5d850862f	2d3fd002-9602-4920-9c9d-3abc738d4feb	\N	2024-11-02	2024-11-02	66b809e0-cdd9-49b6-bf81-738494f57889	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-02 00:00:00+00		2024-12-10 17:06:55.551099+00	2024-12-10 17:06:55.551099+00	\N	\N	1
60d55367-a55e-42b6-94c2-cd76b1a68ec1	ac39ce70-ea62-42e9-9196-20ecebc86b49	\N	2024-11-02	2024-11-02	49f84764-4fc5-4c7c-8aaa-038bd9be1448	active	16500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-02 00:00:00+00		2024-12-10 17:12:05.573518+00	2024-12-10 17:12:05.573518+00	\N	\N	1
7043b0b9-bd1f-4774-a034-4131c8cfeae5	b73beb0b-a8f4-48c1-a633-be19ed9ef123	\N	2024-11-02	2024-11-02	08c8d7c8-0501-4124-8a43-5edf33e6ff50	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-02 00:00:00+00		2024-12-10 17:13:54.512955+00	2024-12-10 17:13:54.512955+00	\N	\N	1
38a3fcbf-4380-4d63-bb77-6a3da96997bc	8a7fb007-01af-4bb0-be0d-7c08e97de263	\N	2024-11-02	2024-11-02	5059cff5-a935-4d23-8e3a-d2e9c926fd6d	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-02 00:00:00+00		2024-12-10 17:15:10.637379+00	2024-12-10 17:15:10.637379+00	\N	\N	1
02826d9b-295b-4d37-8d25-6f21e4721212	719b48ef-f16b-4fdd-99a8-28e622239899	\N	2024-11-02	2024-11-02	c55645c9-1e48-4cf2-852c-58dd7a19db87	active	22500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-02 00:00:00+00		2024-12-10 17:17:21.044311+00	2024-12-10 17:17:21.044311+00	\N	\N	1
178e4b53-ca79-49ff-b6b5-b6b39b7e1823	ce3455b8-0a64-498d-bd4b-e68dcf915d09	\N	2024-11-02	2024-11-02	7df6a61b-e68c-46e3-9ac5-3fd28bf19858	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-02 00:00:00+00		2024-12-10 17:35:04.945285+00	2024-12-10 17:35:04.945285+00	\N	\N	1
2f962d21-50a0-494f-ae35-0236f41054a8	c48b8200-a21f-438b-b61b-94994399d1ad	\N	2024-10-12	2024-10-12	9ae3212c-679a-4761-a8f3-8328c6e37cec	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-12 00:00:00+00		2024-12-10 18:20:56.979307+00	2024-12-10 18:20:56.979307+00	\N	\N	1
a31a5d20-93d2-4057-bbce-959aa5aa683a	8dd56a6e-378d-4752-b08a-3f2eb3f177d4	\N	2024-10-04	2024-10-04	16aa1f88-21bb-430d-9c0d-c4f8771ebdc5	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-04 00:00:00+00		2024-12-10 18:26:17.737367+00	2024-12-10 18:26:17.737367+00	\N	\N	1
bfa274f1-caeb-408a-a922-aff050ef87fc	8dd56a6e-378d-4752-b08a-3f2eb3f177d4	\N	2024-10-11	2024-10-11	16aa1f88-21bb-430d-9c0d-c4f8771ebdc5	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-11 00:00:00+00		2024-12-10 18:26:52.094991+00	2024-12-10 18:26:52.094991+00	\N	\N	1
f526279a-09fc-4287-9672-9f501e87116e	8dd56a6e-378d-4752-b08a-3f2eb3f177d4	\N	2024-10-22	2024-10-22	16aa1f88-21bb-430d-9c0d-c4f8771ebdc5	active	7000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-22 00:00:00+00		2024-12-10 18:41:51.84592+00	2024-12-10 18:41:51.84592+00	\N	\N	1
5619bf4c-0462-4eac-8783-2dfe78efed9e	aa2056b9-af4f-42ac-a3e0-50fac4f9f51c	\N	2024-10-25	2024-10-25	ac97850e-a809-44fa-a5a7-a2d79220a7a6	active	15000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-25 00:00:00+00		2024-12-10 19:04:07.848867+00	2024-12-10 19:04:07.848867+00	\N	\N	1
8a8f3d9b-947d-47d0-b833-4536d8994dfd	c0519100-db35-4f5f-81f7-2a79d080d558	\N	2024-10-25	2024-10-25	8dc1b905-2655-42d9-bcc0-734db79b293c	active	12500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-25 00:00:00+00		2024-12-10 19:05:27.242413+00	2024-12-10 19:05:27.242413+00	\N	\N	1
06e554f0-76ea-4ec3-b2ed-58e345434bab	bdee04b5-88d3-4f0c-a5f6-88c37ace1737	\N	2024-10-14	2024-10-14	4bbfc4a6-92f7-474d-97fc-ef43d3001aac	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-14 00:00:00+00		2024-12-10 19:13:13.446279+00	2024-12-10 19:13:13.446279+00	\N	\N	1
32fba8b7-fb27-466c-96b3-f3b3047bfd9a	410d48c2-1357-4471-9a86-ca260dd6f278	\N	2024-10-02	2024-10-02	14d0c8e2-98da-44a3-9594-37cf3de28944	active	20000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-02 00:00:00+00		2024-12-10 19:21:35.962904+00	2024-12-10 19:21:35.962904+00	\N	\N	1
68fd6af4-6e1a-4b26-a263-bc660a456582	dfc19e2e-b24c-4e7a-9fd8-c7fe18f237cb	\N	2024-10-19	2024-10-19	25b2a515-1623-408b-8bd8-c1211d05af99	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-19 00:00:00+00		2024-12-10 19:25:35.110583+00	2024-12-10 19:25:35.110583+00	\N	\N	1
fc9a8483-5bd0-46de-905f-7647531f40bb	2d3fd002-9602-4920-9c9d-3abc738d4feb	\N	2024-10-05	2024-10-05	66b809e0-cdd9-49b6-bf81-738494f57889	active	12500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-05 00:00:00+00		2024-12-10 19:46:47.206226+00	2024-12-10 19:46:47.206226+00	\N	\N	1
349e2cc1-b99f-411e-bdbd-5f770b2b2893	2d3fd002-9602-4920-9c9d-3abc738d4feb	\N	2024-10-19	2024-10-19	66b809e0-cdd9-49b6-bf81-738494f57889	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-19 00:00:00+00		2024-12-10 19:54:17.100384+00	2024-12-10 19:54:17.100384+00	\N	\N	1
a9895bf4-440c-4bc1-8b42-2f39aa8ed13e	07042a4b-93af-4876-9392-2610ec62a209	\N	2024-10-30	2024-10-30	109c6864-55e7-409a-9035-a261ef1f33ac	active	22500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-30 00:00:00+00		2024-12-10 19:56:50.623015+00	2024-12-10 19:56:50.623015+00	\N	\N	1
f6b5eab7-4d70-487a-a20f-3044caceb1c6	920d7b35-776b-41d4-bda2-b550279dc44e	\N	2024-11-04	2024-11-04	72c9359c-07a2-4fe1-b9f4-edaf2fd4257e	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-04 00:00:00+00		2024-12-10 19:58:54.663889+00	2024-12-10 19:58:54.663889+00	\N	\N	1
f4771039-9bf9-4c72-a424-f7b8b4568f46	920d7b35-776b-41d4-bda2-b550279dc44e	\N	2024-10-08	2024-10-08	72c9359c-07a2-4fe1-b9f4-edaf2fd4257e	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-08 00:00:00+00		2024-12-10 19:59:34.029107+00	2024-12-10 19:59:34.029107+00	\N	\N	1
38c2a473-5c92-4f69-9b8c-289cc0efe4a7	920d7b35-776b-41d4-bda2-b550279dc44e	\N	2024-10-21	2024-10-21	72c9359c-07a2-4fe1-b9f4-edaf2fd4257e	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-21 00:00:00+00		2024-12-10 20:00:18.147914+00	2024-12-10 20:00:18.147914+00	\N	\N	1
14b51ca4-5a30-47da-b0ca-2f1fb5006069	86efd7e1-425d-4986-9227-0c85607ba409	\N	2024-10-01	2024-10-01	9eeb2e82-95ec-4b98-8781-9a6a086fd571	active	5000.00		paid	3fa46566-bc26-4feb-a60a-762c0144bc7a	2024-10-01 00:00:00+00		2024-12-10 23:47:32.966034+00	2024-12-10 23:47:32.966034+00	\N	\N	1
716345d6-1ea6-4430-927c-c2749477f7a2	86efd7e1-425d-4986-9227-0c85607ba409	\N	2024-10-14	2024-10-14	9eeb2e82-95ec-4b98-8781-9a6a086fd571	active	5000.00		paid	3fa46566-bc26-4feb-a60a-762c0144bc7a	2024-10-14 00:00:00+00		2024-12-10 23:48:06.874838+00	2024-12-10 23:48:06.874838+00	\N	\N	1
abbc4b95-288a-45bd-96e0-3dd83091d857	b576f416-7e94-4ce6-b455-662812ba1f69	\N	2024-10-18	2024-10-18	c7b75735-037a-4ae8-8012-7a0f43a47477	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-18 00:00:00+00		2024-12-11 00:10:35.81057+00	2024-12-11 00:10:35.81057+00	\N	\N	1
65fe1152-0310-4fdd-836a-13abc7af280b	25482691-aff8-44e8-a26a-df88cca75129	\N	2024-10-15	2024-10-15	1e680c3b-bcf0-4cbf-a249-f322c7ceeb58	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-15 00:00:00+00		2024-12-11 13:18:20.70905+00	2024-12-11 13:18:20.70905+00	\N	\N	1
f79f92e8-e1da-4465-b531-f7a5794169e2	8c4d9d6d-8f1a-419f-aaf8-790d99324776	\N	2024-10-04	2024-10-04	4398cd29-057d-4808-bf4a-ef92bdd29d0d	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-04 00:00:00+00		2024-12-11 13:20:25.887535+00	2024-12-11 13:20:25.887535+00	\N	\N	1
d66c9161-100a-4289-93cb-9ea756d2293a	0562054e-e962-42da-99f4-9fa70862ab4e	\N	2024-11-07	2024-11-07	37a897f5-424a-4849-9929-428bfed1396b	active	15000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-11-07 00:00:00+00		2024-12-10 19:58:03.901984+00	2024-12-11 12:45:07.093856+00	\N	\N	1
a4b4def1-2f91-4f1c-bf27-043afebf4a5c	34b982e7-80eb-4de2-8ae1-6ad99575e610	\N	2024-10-11	2024-10-11	3aa67ef1-a493-43aa-8079-cebb14ce93bd	active	12500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-11 00:00:00+00		2024-12-11 12:51:24.953612+00	2024-12-11 12:51:24.953612+00	\N	\N	1
b6e6502d-2166-416f-be77-72c31b811e37	34b982e7-80eb-4de2-8ae1-6ad99575e610	\N	2024-10-30	2024-10-30	3aa67ef1-a493-43aa-8079-cebb14ce93bd	active	15000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-30 00:00:00+00		2024-12-11 12:52:09.349884+00	2024-12-11 12:52:09.349884+00	\N	\N	1
41c5e1bd-e0bf-419e-8150-98cb988f05ef	ac241d67-5a00-4360-ad52-517731d0eb22	\N	2024-10-25	2024-10-25	87a84730-7302-4e3c-93ca-fa1297be330e	active	3500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-25 00:00:00+00		2024-12-11 12:52:44.178102+00	2024-12-11 12:52:44.178102+00	\N	\N	1
29ba1c18-0ca9-4ba9-a487-a20c5c16b8bf	eb07e857-8869-42cd-a652-0e2ad7ee8537	\N	2024-10-01	2024-10-01	4a221224-388c-46a9-9f2e-bca137d6b1d9	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-01 00:00:00+00		2024-12-11 12:53:26.713553+00	2024-12-11 12:53:26.713553+00	\N	\N	1
b58b254d-7331-4cb5-a013-d171bae23c48	eb07e857-8869-42cd-a652-0e2ad7ee8537	\N	2024-10-28	2024-10-28	4a221224-388c-46a9-9f2e-bca137d6b1d9	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-28 00:00:00+00		2024-12-11 12:53:54.696389+00	2024-12-11 12:53:54.696389+00	\N	\N	1
4f48032b-f4da-4116-a774-555801e9f68b	dabfc366-dee1-4655-a822-5b909533dbd2	\N	2024-10-05	2024-10-05	fb3238ee-8bde-425f-ad31-566a3b9c11fd	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-05 00:00:00+00		2024-12-11 13:00:48.368997+00	2024-12-11 13:00:48.368997+00	\N	\N	1
68039766-a740-4483-960c-398ef0b27c60	dabfc366-dee1-4655-a822-5b909533dbd2	\N	2024-10-25	2024-10-25	fb3238ee-8bde-425f-ad31-566a3b9c11fd	active	10000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-25 00:00:00+00		2024-12-11 13:03:36.904397+00	2024-12-11 13:03:36.904397+00	\N	\N	1
febcb9a2-2d80-4d4c-9bb5-9c6015afd9aa	3368aea8-9c83-44c2-8b65-a8739ae99a85	\N	2024-10-10	2024-10-10	f30b2910-667f-4c12-aa13-eb0da56c45df	active	7500.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-10 00:00:00+00		2024-12-11 13:07:35.268564+00	2024-12-11 13:07:35.268564+00	\N	\N	1
73e6a67a-ed87-45f0-8bef-524340ec04aa	3368aea8-9c83-44c2-8b65-a8739ae99a85	\N	2024-10-28	2024-10-28	f30b2910-667f-4c12-aa13-eb0da56c45df	active	5000.00		paid	f4ee3668-57e1-4126-b64a-3fafe32201bc	2024-10-28 00:00:00+00		2024-12-11 13:11:31.94209+00	2024-12-11 13:11:31.94209+00	\N	\N	1
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2024-11-04 22:27:53
20211116045059	2024-11-04 22:27:55
20211116050929	2024-11-04 22:27:56
20211116051442	2024-11-04 22:27:57
20211116212300	2024-11-04 22:27:59
20211116213355	2024-11-04 22:28:00
20211116213934	2024-11-04 22:28:01
20211116214523	2024-11-04 22:28:02
20211122062447	2024-11-04 22:28:04
20211124070109	2024-11-04 22:28:05
20211202204204	2024-11-04 22:28:06
20211202204605	2024-11-04 22:28:07
20211210212804	2024-11-04 22:28:11
20211228014915	2024-11-04 22:28:12
20220107221237	2024-11-04 22:28:13
20220228202821	2024-11-04 22:28:14
20220312004840	2024-11-04 22:28:15
20220603231003	2024-11-04 22:28:17
20220603232444	2024-11-04 22:28:18
20220615214548	2024-11-04 22:28:20
20220712093339	2024-11-04 22:28:21
20220908172859	2024-11-04 22:28:22
20220916233421	2024-11-04 22:28:23
20230119133233	2024-11-04 22:28:24
20230128025114	2024-11-04 22:28:26
20230128025212	2024-11-04 22:28:27
20230227211149	2024-11-04 22:28:28
20230228184745	2024-11-04 22:28:29
20230308225145	2024-11-04 22:28:30
20230328144023	2024-11-04 22:28:31
20231018144023	2024-11-04 22:28:33
20231204144023	2024-11-04 22:28:35
20231204144024	2024-11-04 22:28:36
20231204144025	2024-11-04 22:28:37
20240108234812	2024-11-04 22:28:38
20240109165339	2024-11-04 22:28:39
20240227174441	2024-11-04 22:28:41
20240311171622	2024-11-04 22:28:43
20240321100241	2024-11-04 22:28:45
20240401105812	2024-11-04 22:28:48
20240418121054	2024-11-04 22:28:50
20240523004032	2024-11-04 22:28:54
20240618124746	2024-11-04 22:28:55
20240801235015	2024-11-04 22:28:56
20240805133720	2024-11-04 22:28:58
20240827160934	2024-11-04 22:28:59
20240919163303	2024-11-04 22:29:00
20240919163305	2024-11-04 22:29:01
20241019105805	2024-11-04 22:29:03
20241030150047	2024-11-19 16:09:53
20241108114728	2024-11-19 16:09:55
20241121104152	2024-12-06 18:57:07
20241130184212	2024-12-06 18:57:09
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id) FROM stdin;
nevados-bucket	nevados-bucket	\N	2024-11-04 22:44:53.389349+00	2024-11-04 22:44:53.389349+00	f	f	\N	\N	\N
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2024-11-04 22:25:36.904569
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2024-11-04 22:25:36.974145
2	storage-schema	5c7968fd083fcea04050c1b7f6253c9771b99011	2024-11-04 22:25:37.040218
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2024-11-04 22:25:37.125788
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2024-11-04 22:25:37.165764
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2024-11-04 22:25:37.187165
6	change-column-name-in-get-size	f93f62afdf6613ee5e7e815b30d02dc990201044	2024-11-04 22:25:37.250574
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2024-11-04 22:25:37.318596
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2024-11-04 22:25:37.383778
9	fix-search-function	3a0af29f42e35a4d101c259ed955b67e1bee6825	2024-11-04 22:25:37.459256
10	search-files-search-function	68dc14822daad0ffac3746a502234f486182ef6e	2024-11-04 22:25:37.522893
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2024-11-04 22:25:37.586089
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2024-11-04 22:25:37.608645
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2024-11-04 22:25:37.678004
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2024-11-04 22:25:37.742263
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2024-11-04 22:25:37.82798
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2024-11-04 22:25:37.895672
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2024-11-04 22:25:37.962904
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2024-11-04 22:25:37.984828
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2024-11-04 22:25:38.065976
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2024-11-04 22:25:38.088843
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2024-11-04 22:25:38.160343
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2024-11-04 22:25:38.256848
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2024-11-04 22:25:38.343368
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2024-11-04 22:25:38.365872
25	custom-metadata	67eb93b7e8d401cafcdc97f9ac779e71a79bfe03	2024-11-04 22:25:38.388741
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) FROM stdin;
72f50573-1c5e-4280-a20f-aec45116382a	nevados-bucket	xebsc1_1/.emptyFolderPlaceholder	\N	2024-11-04 22:59:21.708487+00	2024-11-04 22:59:21.708487+00	2024-11-04 22:59:21.708487+00	{"eTag": "\\"d41d8cd98f00b204e9800998ecf8427e\\"", "size": 0, "mimetype": "application/octet-stream", "cacheControl": "max-age=3600", "lastModified": "2024-11-04T22:59:22.000Z", "contentLength": 0, "httpStatusCode": 200}	c2282471-184b-467a-a0f4-dd54976b727d	\N	{}
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 137, true);


--
-- Name: key_key_id_seq; Type: SEQUENCE SET; Schema: pgsodium; Owner: -
--

SELECT pg_catalog.setval('pgsodium.key_key_id_seq', 1, false);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: boroughs boroughs_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boroughs
    ADD CONSTRAINT boroughs_name_key UNIQUE (name);


--
-- Name: boroughs boroughs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.boroughs
    ADD CONSTRAINT boroughs_pkey PRIMARY KEY (id);


--
-- Name: client_addresses client_addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_addresses
    ADD CONSTRAINT client_addresses_pkey PRIMARY KEY (id);


--
-- Name: client_prices client_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_prices
    ADD CONSTRAINT client_prices_pkey PRIMARY KEY (id);


--
-- Name: client_types client_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_types
    ADD CONSTRAINT client_types_pkey PRIMARY KEY (id);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: mixed_bundle_items mixed_bundle_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mixed_bundle_items
    ADD CONSTRAINT mixed_bundle_items_pkey PRIMARY KEY (id);


--
-- Name: mixed_bundles mixed_bundles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mixed_bundles
    ADD CONSTRAINT mixed_bundles_pkey PRIMARY KEY (id);


--
-- Name: neighborhoods neighborhoods_name_borough_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.neighborhoods
    ADD CONSTRAINT neighborhoods_name_borough_id_key UNIQUE (name, borough_id);


--
-- Name: neighborhoods neighborhoods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.neighborhoods
    ADD CONSTRAINT neighborhoods_pkey PRIMARY KEY (id);


--
-- Name: payment_methods payment_methods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payment_methods
    ADD CONSTRAINT payment_methods_pkey PRIMARY KEY (id);


--
-- Name: product_categories product_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_categories
    ADD CONSTRAINT product_categories_pkey PRIMARY KEY (id);


--
-- Name: product_prices product_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_prices
    ADD CONSTRAINT product_prices_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: sale_items sale_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items
    ADD CONSTRAINT sale_items_pkey PRIMARY KEY (id);


--
-- Name: sale_items sale_items_sale_id_product_id_item_number_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items
    ADD CONSTRAINT sale_items_sale_id_product_id_item_number_key UNIQUE (sale_id, product_id, item_number);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: idx_client_addresses_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_client_addresses_client ON public.client_addresses USING btree (client_id);


--
-- Name: idx_client_addresses_coordinates; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_client_addresses_coordinates ON public.client_addresses USING btree (latitude, longitude);


--
-- Name: idx_client_prices_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_client_prices_client ON public.client_prices USING btree (client_id);


--
-- Name: idx_client_prices_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_client_prices_product ON public.client_prices USING btree (product_id);


--
-- Name: idx_client_types_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_client_types_name ON public.client_types USING btree (name);


--
-- Name: idx_clients_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_status ON public.clients USING btree (status);


--
-- Name: idx_clients_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_type ON public.clients USING btree (type_id);


--
-- Name: idx_mixed_bundle_items_bundle_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mixed_bundle_items_bundle_id ON public.mixed_bundle_items USING btree (bundle_id);


--
-- Name: idx_mixed_bundle_items_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mixed_bundle_items_product_id ON public.mixed_bundle_items USING btree (product_id);


--
-- Name: idx_mixed_bundles_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mixed_bundles_status ON public.mixed_bundles USING btree (status);


--
-- Name: idx_product_prices_min_quantity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_prices_min_quantity ON public.product_prices USING btree (min_quantity);


--
-- Name: idx_product_prices_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_prices_product ON public.product_prices USING btree (product_id);


--
-- Name: idx_product_prices_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_prices_product_id ON public.product_prices USING btree (product_id);


--
-- Name: idx_products_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_products_category ON public.products USING btree (category_id);


--
-- Name: idx_sale_items_product_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_items_product_id ON public.sale_items USING btree (product_id);


--
-- Name: idx_sale_items_sale_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sale_items_sale_id ON public.sale_items USING btree (sale_id);


--
-- Name: idx_sales_client_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_client_id ON public.sales USING btree (client_id);


--
-- Name: idx_sales_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_created_by ON public.sales USING btree (created_by);


--
-- Name: idx_sales_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_date ON public.sales USING btree (sale_date);


--
-- Name: idx_sales_payment_method; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_payment_method ON public.sales USING btree (payment_method_id);


--
-- Name: idx_sales_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_product ON public.sales USING btree (product_id);


--
-- Name: idx_sales_salesperson; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_salesperson ON public.sales USING btree (salesperson_id);


--
-- Name: profiles_email_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX profiles_email_idx ON public.profiles USING btree (email);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: subscription_subscription_id_entity_filters_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_key ON realtime.subscription USING btree (subscription_id, entity, filters);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: users update_user_email; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER update_user_email AFTER UPDATE OF email ON auth.users FOR EACH ROW EXECUTE FUNCTION public.sync_user_email();


--
-- Name: client_addresses manage_default_address; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER manage_default_address BEFORE INSERT OR UPDATE ON public.client_addresses FOR EACH ROW EXECUTE FUNCTION public.ensure_single_default_address();


--
-- Name: boroughs set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.boroughs FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: neighborhoods set_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.neighborhoods FOR EACH ROW EXECUTE FUNCTION public.trigger_set_timestamp();


--
-- Name: client_addresses update_addresses_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_addresses_updated_at BEFORE UPDATE ON public.client_addresses FOR EACH ROW EXECUTE FUNCTION public.handle_client_update();


--
-- Name: product_categories update_categories_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON public.product_categories FOR EACH ROW EXECUTE FUNCTION public.handle_product_update();


--
-- Name: client_prices update_client_prices_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_client_prices_updated_at BEFORE UPDATE ON public.client_prices FOR EACH ROW EXECUTE FUNCTION public.handle_client_price_update();


--
-- Name: client_types update_client_types_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_client_types_updated_at BEFORE UPDATE ON public.client_types FOR EACH ROW EXECUTE FUNCTION public.handle_client_type_update();


--
-- Name: clients update_clients_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.handle_client_update();


--
-- Name: mixed_bundles update_mixed_bundles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_mixed_bundles_updated_at BEFORE UPDATE ON public.mixed_bundles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: product_prices update_prices_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_prices_updated_at BEFORE UPDATE ON public.product_prices FOR EACH ROW EXECUTE FUNCTION public.handle_product_update();


--
-- Name: products update_products_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.handle_product_update();


--
-- Name: profiles update_profiles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_profile_update();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: client_addresses client_addresses_borough_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_addresses
    ADD CONSTRAINT client_addresses_borough_id_fkey FOREIGN KEY (borough_id) REFERENCES public.boroughs(id);


--
-- Name: client_addresses client_addresses_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_addresses
    ADD CONSTRAINT client_addresses_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id) ON DELETE CASCADE;


--
-- Name: client_addresses client_addresses_neighborhood_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_addresses
    ADD CONSTRAINT client_addresses_neighborhood_id_fkey FOREIGN KEY (neighborhood_id) REFERENCES public.neighborhoods(id);


--
-- Name: client_prices client_prices_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_prices
    ADD CONSTRAINT client_prices_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: clients clients_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: clients clients_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_type_id_fkey FOREIGN KEY (type_id) REFERENCES public.client_types(id);


--
-- Name: mixed_bundle_items mixed_bundle_items_bundle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mixed_bundle_items
    ADD CONSTRAINT mixed_bundle_items_bundle_id_fkey FOREIGN KEY (bundle_id) REFERENCES public.mixed_bundles(id) ON DELETE CASCADE;


--
-- Name: mixed_bundle_items mixed_bundle_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mixed_bundle_items
    ADD CONSTRAINT mixed_bundle_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: mixed_bundles mixed_bundles_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mixed_bundles
    ADD CONSTRAINT mixed_bundles_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: mixed_bundles mixed_bundles_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mixed_bundles
    ADD CONSTRAINT mixed_bundles_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: neighborhoods neighborhoods_borough_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.neighborhoods
    ADD CONSTRAINT neighborhoods_borough_id_fkey FOREIGN KEY (borough_id) REFERENCES public.boroughs(id) ON DELETE CASCADE;


--
-- Name: product_prices product_prices_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_prices
    ADD CONSTRAINT product_prices_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);


--
-- Name: product_prices product_prices_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_prices
    ADD CONSTRAINT product_prices_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: product_prices product_prices_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_prices
    ADD CONSTRAINT product_prices_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id);


--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.product_categories(id);


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sale_items sale_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items
    ADD CONSTRAINT sale_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: sale_items sale_items_sale_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sale_items
    ADD CONSTRAINT sale_items_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES public.sales(id);


--
-- Name: sales sales_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clients(id);


--
-- Name: sales sales_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id);


--
-- Name: sales sales_delivery_address_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_delivery_address_id_fkey FOREIGN KEY (delivery_address_id) REFERENCES public.client_addresses(id);


--
-- Name: sales sales_payment_method_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_payment_method_id_fkey FOREIGN KEY (payment_method_id) REFERENCES public.payment_methods(id);


--
-- Name: sales sales_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id);


--
-- Name: sales sales_salesperson_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_salesperson_id_fkey FOREIGN KEY (salesperson_id) REFERENCES public.profiles(id);


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: client_addresses Admins and managers can manage addresses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins and managers can manage addresses" ON public.client_addresses USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::public.user_role, 'manager'::public.user_role]))))));


--
-- Name: product_categories Admins and managers can manage categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins and managers can manage categories" ON public.product_categories USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::public.user_role, 'manager'::public.user_role]))))));


--
-- Name: client_prices Admins and managers can manage client prices; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins and managers can manage client prices" ON public.client_prices USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::public.user_role, 'manager'::public.user_role]))))));


--
-- Name: client_types Admins and managers can manage client types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins and managers can manage client types" ON public.client_types USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::public.user_role, 'manager'::public.user_role]))))));


--
-- Name: clients Admins and managers can manage clients; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins and managers can manage clients" ON public.clients USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::public.user_role, 'manager'::public.user_role]))))));


--
-- Name: product_prices Admins and managers can manage prices; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins and managers can manage prices" ON public.product_prices USING (((auth.jwt() ->> 'role'::text) = ANY (ARRAY['admin'::text, 'manager'::text])));


--
-- Name: products Admins and managers can manage products; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Admins and managers can manage products" ON public.products USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = ANY (ARRAY['admin'::public.user_role, 'manager'::public.user_role]))))));


--
-- Name: product_prices Enable delete for admin users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for admin users" ON public.product_prices FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::public.user_role)))));


--
-- Name: profiles Enable delete for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for authenticated users" ON public.profiles FOR DELETE USING ((auth.uid() IS NOT NULL));


--
-- Name: mixed_bundle_items Enable delete for authenticated users only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for authenticated users only" ON public.mixed_bundle_items FOR DELETE USING ((auth.role() = 'authenticated'::text));


--
-- Name: mixed_bundles Enable delete for authenticated users only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable delete for authenticated users only" ON public.mixed_bundles FOR DELETE USING ((auth.role() = 'authenticated'::text));


--
-- Name: product_prices Enable insert for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users" ON public.product_prices FOR INSERT TO authenticated WITH CHECK (true);


--
-- Name: profiles Enable insert for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users" ON public.profiles FOR INSERT WITH CHECK ((auth.uid() IS NOT NULL));


--
-- Name: mixed_bundle_items Enable insert for authenticated users only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users only" ON public.mixed_bundle_items FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: mixed_bundles Enable insert for authenticated users only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert for authenticated users only" ON public.mixed_bundles FOR INSERT WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: client_addresses Enable insert/update for service role; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable insert/update for service role" ON public.client_addresses TO service_role USING (true) WITH CHECK (true);


--
-- Name: mixed_bundle_items Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.mixed_bundle_items FOR SELECT USING (((auth.role() = 'authenticated'::text) AND (EXISTS ( SELECT 1
   FROM public.mixed_bundles mb
  WHERE ((mb.id = mixed_bundle_items.bundle_id) AND (mb.status = 'active'::text) AND ((mb.end_date IS NULL) OR (mb.end_date >= CURRENT_DATE)))))));


--
-- Name: mixed_bundles Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.mixed_bundles FOR SELECT USING (((auth.role() = 'authenticated'::text) AND (status = 'active'::text) AND ((end_date IS NULL) OR (end_date >= CURRENT_DATE))));


--
-- Name: profiles Enable read access for all users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for all users" ON public.profiles FOR SELECT USING (true);


--
-- Name: product_prices Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public.product_prices FOR SELECT TO authenticated USING (true);


--
-- Name: sales Enable read access for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read access for authenticated users" ON public.sales FOR SELECT TO authenticated USING (true);


--
-- Name: client_addresses Enable read for all authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable read for all authenticated users" ON public.client_addresses FOR SELECT TO authenticated USING (true);


--
-- Name: product_prices Enable update for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for authenticated users" ON public.product_prices FOR UPDATE TO authenticated USING (true) WITH CHECK (true);


--
-- Name: profiles Enable update for authenticated users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for authenticated users" ON public.profiles FOR UPDATE USING ((auth.uid() IS NOT NULL));


--
-- Name: mixed_bundles Enable update for authenticated users only; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Enable update for authenticated users only" ON public.mixed_bundles FOR UPDATE USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: clients Everyone can view active clients; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can view active clients" ON public.clients FOR SELECT USING ((status = 'active'::text));


--
-- Name: payment_methods Everyone can view active payment methods; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can view active payment methods" ON public.payment_methods FOR SELECT USING ((status = 'active'::text));


--
-- Name: products Everyone can view active products; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can view active products" ON public.products FOR SELECT USING ((status = 'active'::text));


--
-- Name: product_categories Everyone can view categories; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can view categories" ON public.product_categories FOR SELECT TO authenticated USING (true);


--
-- Name: client_addresses Everyone can view client addresses; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can view client addresses" ON public.client_addresses FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.clients
  WHERE ((clients.id = client_addresses.client_id) AND (clients.status = 'active'::text)))));


--
-- Name: client_types Everyone can view client types; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Everyone can view client types" ON public.client_types FOR SELECT TO authenticated USING (true);


--
-- Name: payment_methods Only admins can insert payment methods; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can insert payment methods" ON public.payment_methods FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::public.user_role)))));


--
-- Name: payment_methods Only admins can update payment methods; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can update payment methods" ON public.payment_methods FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::public.user_role)))));


--
-- Name: sales Only admins can update sales; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Only admins can update sales" ON public.sales FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::public.user_role)))));


--
-- Name: sale_items Users can delete sale items for their sales; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can delete sale items for their sales" ON public.sale_items FOR DELETE USING ((EXISTS ( SELECT 1
   FROM public.sales
  WHERE ((sales.id = sale_items.sale_id) AND (sales.created_by = auth.uid())))));


--
-- Name: sale_items Users can insert sale items for their sales; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert sale items for their sales" ON public.sale_items FOR INSERT WITH CHECK ((EXISTS ( SELECT 1
   FROM public.sales
  WHERE ((sales.id = sale_items.sale_id) AND (sales.created_by = auth.uid())))));


--
-- Name: sales Users can insert their own sales; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can insert their own sales" ON public.sales FOR INSERT WITH CHECK ((auth.uid() = created_by));


--
-- Name: sale_items Users can update sale items for their sales; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update sale items for their sales" ON public.sale_items FOR UPDATE USING ((EXISTS ( SELECT 1
   FROM public.sales
  WHERE ((sales.id = sale_items.sale_id) AND (sales.created_by = auth.uid())))));


--
-- Name: profiles Users can update their own profile; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- Name: product_prices Users can view product prices; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view product prices" ON public.product_prices FOR SELECT USING (true);


--
-- Name: sale_items Users can view sale items they have access to; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view sale items they have access to" ON public.sale_items FOR SELECT USING ((EXISTS ( SELECT 1
   FROM public.sales
  WHERE ((sales.id = sale_items.sale_id) AND ((sales.created_by = auth.uid()) OR (EXISTS ( SELECT 1
           FROM public.profiles
          WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::public.user_role)))))))));


--
-- Name: sales Users can view their own sales and admins can view all; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Users can view their own sales and admins can view all" ON public.sales FOR SELECT USING (((auth.uid() = created_by) OR (EXISTS ( SELECT 1
   FROM public.profiles
  WHERE ((profiles.id = auth.uid()) AND (profiles.role = 'admin'::public.user_role))))));


--
-- Name: client_addresses; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.client_addresses ENABLE ROW LEVEL SECURITY;

--
-- Name: client_prices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.client_prices ENABLE ROW LEVEL SECURITY;

--
-- Name: client_types; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.client_types ENABLE ROW LEVEL SECURITY;

--
-- Name: clients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

--
-- Name: mixed_bundle_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.mixed_bundle_items ENABLE ROW LEVEL SECURITY;

--
-- Name: mixed_bundles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.mixed_bundles ENABLE ROW LEVEL SECURITY;

--
-- Name: payment_methods; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;

--
-- Name: product_categories; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_categories ENABLE ROW LEVEL SECURITY;

--
-- Name: product_prices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.product_prices ENABLE ROW LEVEL SECURITY;

--
-- Name: products; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profile_all_admin; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_all_admin ON public.profiles USING (((auth.jwt() ->> 'role'::text) = 'admin'::text));


--
-- Name: profiles profile_delete_manager; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_delete_manager ON public.profiles FOR DELETE USING ((((auth.jwt() ->> 'role'::text) = 'manager'::text) AND (role = 'salesperson'::public.user_role)));


--
-- Name: profiles profile_insert_manager; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_insert_manager ON public.profiles FOR INSERT WITH CHECK ((((auth.jwt() ->> 'role'::text) = 'manager'::text) AND (role = 'salesperson'::public.user_role)));


--
-- Name: profiles profile_select_admin_manager; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_select_admin_manager ON public.profiles FOR SELECT USING (((auth.jwt() ->> 'role'::text) = ANY (ARRAY['admin'::text, 'manager'::text])));


--
-- Name: profiles profile_select_manager; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_select_manager ON public.profiles FOR SELECT USING (((auth.jwt() ->> 'role'::text) = 'manager'::text));


--
-- Name: profiles profile_select_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_select_own ON public.profiles FOR SELECT USING ((auth.uid() = id));


--
-- Name: profiles profile_update_manager; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_update_manager ON public.profiles FOR UPDATE USING ((((auth.jwt() ->> 'role'::text) = 'manager'::text) AND (role = 'salesperson'::public.user_role))) WITH CHECK ((((auth.jwt() ->> 'role'::text) = 'manager'::text) AND (role = 'salesperson'::public.user_role)));


--
-- Name: profiles profile_update_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profile_update_own ON public.profiles FOR UPDATE USING ((auth.uid() = id));


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: sale_items; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

--
-- Name: sales; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: SCHEMA auth; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA auth TO anon;
GRANT USAGE ON SCHEMA auth TO authenticated;
GRANT USAGE ON SCHEMA auth TO service_role;
GRANT ALL ON SCHEMA auth TO supabase_auth_admin;
GRANT ALL ON SCHEMA auth TO dashboard_user;
GRANT ALL ON SCHEMA auth TO postgres;


--
-- Name: SCHEMA extensions; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA extensions TO anon;
GRANT USAGE ON SCHEMA extensions TO authenticated;
GRANT USAGE ON SCHEMA extensions TO service_role;
GRANT ALL ON SCHEMA extensions TO dashboard_user;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA public TO postgres;
GRANT USAGE ON SCHEMA public TO anon;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT USAGE ON SCHEMA public TO service_role;


--
-- Name: SCHEMA realtime; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA realtime TO postgres;
GRANT USAGE ON SCHEMA realtime TO anon;
GRANT USAGE ON SCHEMA realtime TO authenticated;
GRANT USAGE ON SCHEMA realtime TO service_role;
GRANT ALL ON SCHEMA realtime TO supabase_realtime_admin;


--
-- Name: SCHEMA storage; Type: ACL; Schema: -; Owner: -
--

GRANT ALL ON SCHEMA storage TO postgres;
GRANT USAGE ON SCHEMA storage TO anon;
GRANT USAGE ON SCHEMA storage TO authenticated;
GRANT USAGE ON SCHEMA storage TO service_role;
GRANT ALL ON SCHEMA storage TO supabase_storage_admin;
GRANT ALL ON SCHEMA storage TO dashboard_user;


--
-- Name: FUNCTION email(); Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON FUNCTION auth.email() TO dashboard_user;
GRANT ALL ON FUNCTION auth.email() TO postgres;


--
-- Name: FUNCTION jwt(); Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON FUNCTION auth.jwt() TO postgres;
GRANT ALL ON FUNCTION auth.jwt() TO dashboard_user;


--
-- Name: FUNCTION role(); Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON FUNCTION auth.role() TO dashboard_user;
GRANT ALL ON FUNCTION auth.role() TO postgres;


--
-- Name: FUNCTION uid(); Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON FUNCTION auth.uid() TO dashboard_user;
GRANT ALL ON FUNCTION auth.uid() TO postgres;


--
-- Name: FUNCTION algorithm_sign(signables text, secret text, algorithm text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.algorithm_sign(signables text, secret text, algorithm text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.algorithm_sign(signables text, secret text, algorithm text) TO dashboard_user;


--
-- Name: FUNCTION armor(bytea); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.armor(bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.armor(bytea) TO dashboard_user;


--
-- Name: FUNCTION armor(bytea, text[], text[]); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.armor(bytea, text[], text[]) TO dashboard_user;


--
-- Name: FUNCTION crypt(text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.crypt(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.crypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION dearmor(text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.dearmor(text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.dearmor(text) TO dashboard_user;


--
-- Name: FUNCTION decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION decrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.decrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.digest(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION digest(text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.digest(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.digest(text, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.encrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION encrypt_iv(bytea, bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.encrypt_iv(bytea, bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION gen_random_bytes(integer); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_random_bytes(integer) TO dashboard_user;


--
-- Name: FUNCTION gen_random_uuid(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_random_uuid() TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.gen_salt(text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_salt(text) TO dashboard_user;


--
-- Name: FUNCTION gen_salt(text, integer); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.gen_salt(text, integer) TO dashboard_user;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: ACL; Schema: extensions; Owner: -
--

REVOKE ALL ON FUNCTION extensions.grant_pg_cron_access() FROM postgres;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_cron_access() TO dashboard_user;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.grant_pg_graphql_access() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION grant_pg_net_access(); Type: ACL; Schema: extensions; Owner: -
--

REVOKE ALL ON FUNCTION extensions.grant_pg_net_access() FROM postgres;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.grant_pg_net_access() TO dashboard_user;


--
-- Name: FUNCTION hmac(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.hmac(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION hmac(text, text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.hmac(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT blk_read_time double precision, OUT blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT blk_read_time double precision, OUT blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pg_stat_statements(showtext boolean, OUT userid oid, OUT dbid oid, OUT toplevel boolean, OUT queryid bigint, OUT query text, OUT plans bigint, OUT total_plan_time double precision, OUT min_plan_time double precision, OUT max_plan_time double precision, OUT mean_plan_time double precision, OUT stddev_plan_time double precision, OUT calls bigint, OUT total_exec_time double precision, OUT min_exec_time double precision, OUT max_exec_time double precision, OUT mean_exec_time double precision, OUT stddev_exec_time double precision, OUT rows bigint, OUT shared_blks_hit bigint, OUT shared_blks_read bigint, OUT shared_blks_dirtied bigint, OUT shared_blks_written bigint, OUT local_blks_hit bigint, OUT local_blks_read bigint, OUT local_blks_dirtied bigint, OUT local_blks_written bigint, OUT temp_blks_read bigint, OUT temp_blks_written bigint, OUT blk_read_time double precision, OUT blk_write_time double precision, OUT temp_blk_read_time double precision, OUT temp_blk_write_time double precision, OUT wal_records bigint, OUT wal_fpi bigint, OUT wal_bytes numeric, OUT jit_functions bigint, OUT jit_generation_time double precision, OUT jit_inlining_count bigint, OUT jit_inlining_time double precision, OUT jit_optimization_count bigint, OUT jit_optimization_time double precision, OUT jit_emission_count bigint, OUT jit_emission_time double precision) TO dashboard_user;


--
-- Name: FUNCTION pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pg_stat_statements_info(OUT dealloc bigint, OUT stats_reset timestamp with time zone) TO dashboard_user;


--
-- Name: FUNCTION pg_stat_statements_reset(userid oid, dbid oid, queryid bigint); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pg_stat_statements_reset(userid oid, dbid oid, queryid bigint) TO dashboard_user;


--
-- Name: FUNCTION pgp_armor_headers(text, OUT key text, OUT value text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_armor_headers(text, OUT key text, OUT value text) TO dashboard_user;


--
-- Name: FUNCTION pgp_key_id(bytea); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_key_id(bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_decrypt_bytea(bytea, bytea, text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_decrypt_bytea(bytea, bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt(text, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt(text, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea) TO dashboard_user;


--
-- Name: FUNCTION pgp_pub_encrypt_bytea(bytea, bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_pub_encrypt_bytea(bytea, bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt(bytea, text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_decrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_decrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt(text, text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt(text, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text) TO dashboard_user;


--
-- Name: FUNCTION pgp_sym_encrypt_bytea(bytea, text, text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.pgp_sym_encrypt_bytea(bytea, text, text) TO dashboard_user;


--
-- Name: FUNCTION pgrst_ddl_watch(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgrst_ddl_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION pgrst_drop_watch(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.pgrst_drop_watch() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.set_graphql_placeholder() TO postgres WITH GRANT OPTION;


--
-- Name: FUNCTION sign(payload json, secret text, algorithm text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.sign(payload json, secret text, algorithm text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.sign(payload json, secret text, algorithm text) TO dashboard_user;


--
-- Name: FUNCTION try_cast_double(inp text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.try_cast_double(inp text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.try_cast_double(inp text) TO dashboard_user;


--
-- Name: FUNCTION url_decode(data text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.url_decode(data text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.url_decode(data text) TO dashboard_user;


--
-- Name: FUNCTION url_encode(data bytea); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.url_encode(data bytea) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.url_encode(data bytea) TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v1(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v1mc(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v1mc() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v3(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v3(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v4(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v4() TO dashboard_user;


--
-- Name: FUNCTION uuid_generate_v5(namespace uuid, name text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_generate_v5(namespace uuid, name text) TO dashboard_user;


--
-- Name: FUNCTION uuid_nil(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_nil() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_nil() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_dns(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_dns() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_oid(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_oid() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_url(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_url() TO dashboard_user;


--
-- Name: FUNCTION uuid_ns_x500(); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.uuid_ns_x500() TO dashboard_user;


--
-- Name: FUNCTION verify(token text, secret text, algorithm text); Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON FUNCTION extensions.verify(token text, secret text, algorithm text) TO postgres WITH GRANT OPTION;
GRANT ALL ON FUNCTION extensions.verify(token text, secret text, algorithm text) TO dashboard_user;


--
-- Name: FUNCTION graphql("operationName" text, query text, variables jsonb, extensions jsonb); Type: ACL; Schema: graphql_public; Owner: -
--

GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO postgres;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO anon;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO authenticated;
GRANT ALL ON FUNCTION graphql_public.graphql("operationName" text, query text, variables jsonb, extensions jsonb) TO service_role;


--
-- Name: FUNCTION get_auth(p_usename text); Type: ACL; Schema: pgbouncer; Owner: -
--

REVOKE ALL ON FUNCTION pgbouncer.get_auth(p_usename text) FROM PUBLIC;
GRANT ALL ON FUNCTION pgbouncer.get_auth(p_usename text) TO pgbouncer;


--
-- Name: FUNCTION crypto_aead_det_decrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea); Type: ACL; Schema: pgsodium; Owner: -
--

GRANT ALL ON FUNCTION pgsodium.crypto_aead_det_decrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea) TO service_role;


--
-- Name: FUNCTION crypto_aead_det_encrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea); Type: ACL; Schema: pgsodium; Owner: -
--

GRANT ALL ON FUNCTION pgsodium.crypto_aead_det_encrypt(message bytea, additional bytea, key_uuid uuid, nonce bytea) TO service_role;


--
-- Name: FUNCTION crypto_aead_det_keygen(); Type: ACL; Schema: pgsodium; Owner: -
--

GRANT ALL ON FUNCTION pgsodium.crypto_aead_det_keygen() TO service_role;


--
-- Name: FUNCTION create_sale_with_items(p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items jsonb[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.create_sale_with_items(p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items jsonb[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text) TO anon;
GRANT ALL ON FUNCTION public.create_sale_with_items(p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items jsonb[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.create_sale_with_items(p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items jsonb[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text) TO service_role;


--
-- Name: FUNCTION ensure_single_default_address(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.ensure_single_default_address() TO anon;
GRANT ALL ON FUNCTION public.ensure_single_default_address() TO authenticated;
GRANT ALL ON FUNCTION public.ensure_single_default_address() TO service_role;


--
-- Name: FUNCTION get_product_price_at_date(product_id uuid, target_date date, client_id uuid); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_product_price_at_date(product_id uuid, target_date date, client_id uuid) TO anon;
GRANT ALL ON FUNCTION public.get_product_price_at_date(product_id uuid, target_date date, client_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.get_product_price_at_date(product_id uuid, target_date date, client_id uuid) TO service_role;


--
-- Name: FUNCTION get_quantity_based_price(p_product_id uuid, p_quantity numeric); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.get_quantity_based_price(p_product_id uuid, p_quantity numeric) TO anon;
GRANT ALL ON FUNCTION public.get_quantity_based_price(p_product_id uuid, p_quantity numeric) TO authenticated;
GRANT ALL ON FUNCTION public.get_quantity_based_price(p_product_id uuid, p_quantity numeric) TO service_role;


--
-- Name: FUNCTION handle_client_price_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_client_price_update() TO anon;
GRANT ALL ON FUNCTION public.handle_client_price_update() TO authenticated;
GRANT ALL ON FUNCTION public.handle_client_price_update() TO service_role;


--
-- Name: FUNCTION handle_client_type_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_client_type_update() TO anon;
GRANT ALL ON FUNCTION public.handle_client_type_update() TO authenticated;
GRANT ALL ON FUNCTION public.handle_client_type_update() TO service_role;


--
-- Name: FUNCTION handle_client_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_client_update() TO anon;
GRANT ALL ON FUNCTION public.handle_client_update() TO authenticated;
GRANT ALL ON FUNCTION public.handle_client_update() TO service_role;


--
-- Name: FUNCTION handle_new_user(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_new_user() TO anon;
GRANT ALL ON FUNCTION public.handle_new_user() TO authenticated;
GRANT ALL ON FUNCTION public.handle_new_user() TO service_role;


--
-- Name: FUNCTION handle_product_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_product_update() TO anon;
GRANT ALL ON FUNCTION public.handle_product_update() TO authenticated;
GRANT ALL ON FUNCTION public.handle_product_update() TO service_role;


--
-- Name: FUNCTION handle_profile_update(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.handle_profile_update() TO anon;
GRANT ALL ON FUNCTION public.handle_profile_update() TO authenticated;
GRANT ALL ON FUNCTION public.handle_profile_update() TO service_role;


--
-- Name: FUNCTION sync_user_email(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.sync_user_email() TO anon;
GRANT ALL ON FUNCTION public.sync_user_email() TO authenticated;
GRANT ALL ON FUNCTION public.sync_user_email() TO service_role;


--
-- Name: FUNCTION trigger_set_timestamp(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.trigger_set_timestamp() TO anon;
GRANT ALL ON FUNCTION public.trigger_set_timestamp() TO authenticated;
GRANT ALL ON FUNCTION public.trigger_set_timestamp() TO service_role;


--
-- Name: FUNCTION update_address_coordinates(address_id uuid, lat double precision, lng double precision); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_address_coordinates(address_id uuid, lat double precision, lng double precision) TO anon;
GRANT ALL ON FUNCTION public.update_address_coordinates(address_id uuid, lat double precision, lng double precision) TO authenticated;
GRANT ALL ON FUNCTION public.update_address_coordinates(address_id uuid, lat double precision, lng double precision) TO service_role;


--
-- Name: FUNCTION update_product_price(p_new_price numeric, p_product_id uuid, p_user_id uuid, p_start_date date); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_product_price(p_new_price numeric, p_product_id uuid, p_user_id uuid, p_start_date date) TO anon;
GRANT ALL ON FUNCTION public.update_product_price(p_new_price numeric, p_product_id uuid, p_user_id uuid, p_start_date date) TO authenticated;
GRANT ALL ON FUNCTION public.update_product_price(p_new_price numeric, p_product_id uuid, p_user_id uuid, p_start_date date) TO service_role;


--
-- Name: FUNCTION update_product_price(p_product_id uuid, p_new_price integer, p_valid_from date, p_user_id uuid); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_product_price(p_product_id uuid, p_new_price integer, p_valid_from date, p_user_id uuid) TO anon;
GRANT ALL ON FUNCTION public.update_product_price(p_product_id uuid, p_new_price integer, p_valid_from date, p_user_id uuid) TO authenticated;
GRANT ALL ON FUNCTION public.update_product_price(p_product_id uuid, p_new_price integer, p_valid_from date, p_user_id uuid) TO service_role;


--
-- Name: FUNCTION update_sale_with_items(p_sale_id uuid, p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items public.sale_item_type[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_sale_with_items(p_sale_id uuid, p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items public.sale_item_type[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text) TO anon;
GRANT ALL ON FUNCTION public.update_sale_with_items(p_sale_id uuid, p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items public.sale_item_type[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text) TO authenticated;
GRANT ALL ON FUNCTION public.update_sale_with_items(p_sale_id uuid, p_client_id uuid, p_sale_date timestamp with time zone, p_delivery_date timestamp with time zone, p_delivery_address_id uuid, p_total_amount numeric, p_notes text, p_items public.sale_item_type[], p_payment_status text, p_payment_method_id uuid, p_payment_date timestamp with time zone, p_payment_notes text) TO service_role;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON FUNCTION public.update_updated_at_column() TO anon;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO authenticated;
GRANT ALL ON FUNCTION public.update_updated_at_column() TO service_role;


--
-- Name: FUNCTION apply_rls(wal jsonb, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO anon;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO authenticated;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO service_role;
GRANT ALL ON FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer) TO supabase_realtime_admin;


--
-- Name: FUNCTION broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO postgres;
GRANT ALL ON FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text) TO dashboard_user;


--
-- Name: FUNCTION build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO postgres;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO anon;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO service_role;
GRANT ALL ON FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION "cast"(val text, type_ regtype); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO postgres;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO dashboard_user;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO anon;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO authenticated;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO service_role;
GRANT ALL ON FUNCTION realtime."cast"(val text, type_ regtype) TO supabase_realtime_admin;


--
-- Name: FUNCTION check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO postgres;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO anon;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO authenticated;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO service_role;
GRANT ALL ON FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) TO supabase_realtime_admin;


--
-- Name: FUNCTION is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO postgres;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO anon;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO authenticated;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO service_role;
GRANT ALL ON FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) TO supabase_realtime_admin;


--
-- Name: FUNCTION list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO postgres;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO anon;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO authenticated;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO service_role;
GRANT ALL ON FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) TO supabase_realtime_admin;


--
-- Name: FUNCTION quote_wal2json(entity regclass); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO postgres;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO anon;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO authenticated;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO service_role;
GRANT ALL ON FUNCTION realtime.quote_wal2json(entity regclass) TO supabase_realtime_admin;


--
-- Name: FUNCTION send(payload jsonb, event text, topic text, private boolean); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO postgres;
GRANT ALL ON FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean) TO dashboard_user;


--
-- Name: FUNCTION subscription_check_filters(); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO postgres;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO dashboard_user;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO anon;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO authenticated;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO service_role;
GRANT ALL ON FUNCTION realtime.subscription_check_filters() TO supabase_realtime_admin;


--
-- Name: FUNCTION to_regrole(role_name text); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO postgres;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO dashboard_user;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO anon;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO authenticated;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO service_role;
GRANT ALL ON FUNCTION realtime.to_regrole(role_name text) TO supabase_realtime_admin;


--
-- Name: FUNCTION topic(); Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON FUNCTION realtime.topic() TO postgres;
GRANT ALL ON FUNCTION realtime.topic() TO dashboard_user;


--
-- Name: FUNCTION can_insert_object(bucketid text, name text, owner uuid, metadata jsonb); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) TO postgres;


--
-- Name: FUNCTION extension(name text); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.extension(name text) TO postgres;


--
-- Name: FUNCTION filename(name text); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.filename(name text) TO postgres;


--
-- Name: FUNCTION foldername(name text); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.foldername(name text) TO postgres;


--
-- Name: FUNCTION get_size_by_bucket(); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.get_size_by_bucket() TO postgres;


--
-- Name: FUNCTION list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, next_key_token text, next_upload_token text); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, next_key_token text, next_upload_token text) TO postgres;


--
-- Name: FUNCTION list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, start_after text, next_token text); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.list_objects_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer, start_after text, next_token text) TO postgres;


--
-- Name: FUNCTION operation(); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.operation() TO postgres;


--
-- Name: FUNCTION search(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.search(prefix text, bucketname text, limits integer, levels integer, offsets integer, search text, sortcolumn text, sortorder text) TO postgres;


--
-- Name: FUNCTION update_updated_at_column(); Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON FUNCTION storage.update_updated_at_column() TO postgres;


--
-- Name: TABLE audit_log_entries; Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON TABLE auth.audit_log_entries TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.audit_log_entries TO postgres;
GRANT SELECT ON TABLE auth.audit_log_entries TO postgres WITH GRANT OPTION;


--
-- Name: TABLE flow_state; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.flow_state TO postgres;
GRANT SELECT ON TABLE auth.flow_state TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.flow_state TO dashboard_user;


--
-- Name: TABLE identities; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.identities TO postgres;
GRANT SELECT ON TABLE auth.identities TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.identities TO dashboard_user;


--
-- Name: TABLE instances; Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON TABLE auth.instances TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.instances TO postgres;
GRANT SELECT ON TABLE auth.instances TO postgres WITH GRANT OPTION;


--
-- Name: TABLE mfa_amr_claims; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_amr_claims TO postgres;
GRANT SELECT ON TABLE auth.mfa_amr_claims TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_amr_claims TO dashboard_user;


--
-- Name: TABLE mfa_challenges; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_challenges TO postgres;
GRANT SELECT ON TABLE auth.mfa_challenges TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_challenges TO dashboard_user;


--
-- Name: TABLE mfa_factors; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.mfa_factors TO postgres;
GRANT SELECT ON TABLE auth.mfa_factors TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.mfa_factors TO dashboard_user;


--
-- Name: TABLE one_time_tokens; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.one_time_tokens TO postgres;
GRANT SELECT ON TABLE auth.one_time_tokens TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.one_time_tokens TO dashboard_user;


--
-- Name: TABLE refresh_tokens; Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON TABLE auth.refresh_tokens TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.refresh_tokens TO postgres;
GRANT SELECT ON TABLE auth.refresh_tokens TO postgres WITH GRANT OPTION;


--
-- Name: SEQUENCE refresh_tokens_id_seq; Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO dashboard_user;
GRANT ALL ON SEQUENCE auth.refresh_tokens_id_seq TO postgres;


--
-- Name: TABLE saml_providers; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.saml_providers TO postgres;
GRANT SELECT ON TABLE auth.saml_providers TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.saml_providers TO dashboard_user;


--
-- Name: TABLE saml_relay_states; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.saml_relay_states TO postgres;
GRANT SELECT ON TABLE auth.saml_relay_states TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.saml_relay_states TO dashboard_user;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON TABLE auth.schema_migrations TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.schema_migrations TO postgres;
GRANT SELECT ON TABLE auth.schema_migrations TO postgres WITH GRANT OPTION;


--
-- Name: TABLE sessions; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sessions TO postgres;
GRANT SELECT ON TABLE auth.sessions TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sessions TO dashboard_user;


--
-- Name: TABLE sso_domains; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sso_domains TO postgres;
GRANT SELECT ON TABLE auth.sso_domains TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sso_domains TO dashboard_user;


--
-- Name: TABLE sso_providers; Type: ACL; Schema: auth; Owner: -
--

GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.sso_providers TO postgres;
GRANT SELECT ON TABLE auth.sso_providers TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE auth.sso_providers TO dashboard_user;


--
-- Name: TABLE users; Type: ACL; Schema: auth; Owner: -
--

GRANT ALL ON TABLE auth.users TO dashboard_user;
GRANT INSERT,REFERENCES,DELETE,TRIGGER,TRUNCATE,UPDATE ON TABLE auth.users TO postgres;
GRANT SELECT ON TABLE auth.users TO postgres WITH GRANT OPTION;


--
-- Name: TABLE pg_stat_statements; Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON TABLE extensions.pg_stat_statements TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE extensions.pg_stat_statements TO dashboard_user;


--
-- Name: TABLE pg_stat_statements_info; Type: ACL; Schema: extensions; Owner: -
--

GRANT ALL ON TABLE extensions.pg_stat_statements_info TO postgres WITH GRANT OPTION;
GRANT ALL ON TABLE extensions.pg_stat_statements_info TO dashboard_user;


--
-- Name: TABLE decrypted_key; Type: ACL; Schema: pgsodium; Owner: -
--

GRANT ALL ON TABLE pgsodium.decrypted_key TO pgsodium_keyholder;


--
-- Name: TABLE masking_rule; Type: ACL; Schema: pgsodium; Owner: -
--

GRANT ALL ON TABLE pgsodium.masking_rule TO pgsodium_keyholder;


--
-- Name: TABLE mask_columns; Type: ACL; Schema: pgsodium; Owner: -
--

GRANT ALL ON TABLE pgsodium.mask_columns TO pgsodium_keyholder;


--
-- Name: TABLE boroughs; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.boroughs TO anon;
GRANT ALL ON TABLE public.boroughs TO authenticated;
GRANT ALL ON TABLE public.boroughs TO service_role;


--
-- Name: TABLE client_addresses; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.client_addresses TO anon;
GRANT ALL ON TABLE public.client_addresses TO authenticated;
GRANT ALL ON TABLE public.client_addresses TO service_role;


--
-- Name: TABLE client_prices; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.client_prices TO anon;
GRANT ALL ON TABLE public.client_prices TO authenticated;
GRANT ALL ON TABLE public.client_prices TO service_role;


--
-- Name: TABLE client_types; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.client_types TO anon;
GRANT ALL ON TABLE public.client_types TO authenticated;
GRANT ALL ON TABLE public.client_types TO service_role;


--
-- Name: TABLE clients; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.clients TO anon;
GRANT ALL ON TABLE public.clients TO authenticated;
GRANT ALL ON TABLE public.clients TO service_role;


--
-- Name: TABLE mixed_bundle_items; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.mixed_bundle_items TO anon;
GRANT ALL ON TABLE public.mixed_bundle_items TO authenticated;
GRANT ALL ON TABLE public.mixed_bundle_items TO service_role;


--
-- Name: TABLE mixed_bundles; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.mixed_bundles TO anon;
GRANT ALL ON TABLE public.mixed_bundles TO authenticated;
GRANT ALL ON TABLE public.mixed_bundles TO service_role;


--
-- Name: TABLE neighborhoods; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.neighborhoods TO anon;
GRANT ALL ON TABLE public.neighborhoods TO authenticated;
GRANT ALL ON TABLE public.neighborhoods TO service_role;


--
-- Name: TABLE payment_methods; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.payment_methods TO anon;
GRANT ALL ON TABLE public.payment_methods TO authenticated;
GRANT ALL ON TABLE public.payment_methods TO service_role;


--
-- Name: TABLE product_categories; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_categories TO anon;
GRANT ALL ON TABLE public.product_categories TO authenticated;
GRANT ALL ON TABLE public.product_categories TO service_role;


--
-- Name: TABLE product_prices; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.product_prices TO anon;
GRANT ALL ON TABLE public.product_prices TO authenticated;
GRANT ALL ON TABLE public.product_prices TO service_role;


--
-- Name: TABLE products; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.products TO anon;
GRANT ALL ON TABLE public.products TO authenticated;
GRANT ALL ON TABLE public.products TO service_role;


--
-- Name: TABLE profiles; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.profiles TO anon;
GRANT ALL ON TABLE public.profiles TO authenticated;
GRANT ALL ON TABLE public.profiles TO service_role;


--
-- Name: TABLE sale_items; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sale_items TO anon;
GRANT ALL ON TABLE public.sale_items TO authenticated;
GRANT ALL ON TABLE public.sale_items TO service_role;


--
-- Name: TABLE sales; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sales TO anon;
GRANT ALL ON TABLE public.sales TO authenticated;
GRANT ALL ON TABLE public.sales TO service_role;


--
-- Name: TABLE sales_report; Type: ACL; Schema: public; Owner: -
--

GRANT ALL ON TABLE public.sales_report TO anon;
GRANT ALL ON TABLE public.sales_report TO authenticated;
GRANT ALL ON TABLE public.sales_report TO service_role;


--
-- Name: TABLE messages; Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON TABLE realtime.messages TO postgres;
GRANT ALL ON TABLE realtime.messages TO dashboard_user;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO anon;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO authenticated;
GRANT SELECT,INSERT,UPDATE ON TABLE realtime.messages TO service_role;


--
-- Name: TABLE schema_migrations; Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON TABLE realtime.schema_migrations TO postgres;
GRANT ALL ON TABLE realtime.schema_migrations TO dashboard_user;
GRANT SELECT ON TABLE realtime.schema_migrations TO anon;
GRANT SELECT ON TABLE realtime.schema_migrations TO authenticated;
GRANT SELECT ON TABLE realtime.schema_migrations TO service_role;
GRANT ALL ON TABLE realtime.schema_migrations TO supabase_realtime_admin;


--
-- Name: TABLE subscription; Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON TABLE realtime.subscription TO postgres;
GRANT ALL ON TABLE realtime.subscription TO dashboard_user;
GRANT SELECT ON TABLE realtime.subscription TO anon;
GRANT SELECT ON TABLE realtime.subscription TO authenticated;
GRANT SELECT ON TABLE realtime.subscription TO service_role;
GRANT ALL ON TABLE realtime.subscription TO supabase_realtime_admin;


--
-- Name: SEQUENCE subscription_id_seq; Type: ACL; Schema: realtime; Owner: -
--

GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO postgres;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO dashboard_user;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO anon;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO authenticated;
GRANT USAGE ON SEQUENCE realtime.subscription_id_seq TO service_role;
GRANT ALL ON SEQUENCE realtime.subscription_id_seq TO supabase_realtime_admin;


--
-- Name: TABLE buckets; Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON TABLE storage.buckets TO anon;
GRANT ALL ON TABLE storage.buckets TO authenticated;
GRANT ALL ON TABLE storage.buckets TO service_role;
GRANT ALL ON TABLE storage.buckets TO postgres;


--
-- Name: TABLE migrations; Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON TABLE storage.migrations TO anon;
GRANT ALL ON TABLE storage.migrations TO authenticated;
GRANT ALL ON TABLE storage.migrations TO service_role;
GRANT ALL ON TABLE storage.migrations TO postgres;


--
-- Name: TABLE objects; Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON TABLE storage.objects TO anon;
GRANT ALL ON TABLE storage.objects TO authenticated;
GRANT ALL ON TABLE storage.objects TO service_role;
GRANT ALL ON TABLE storage.objects TO postgres;


--
-- Name: TABLE s3_multipart_uploads; Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON TABLE storage.s3_multipart_uploads TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads TO anon;
GRANT ALL ON TABLE storage.s3_multipart_uploads TO postgres;


--
-- Name: TABLE s3_multipart_uploads_parts; Type: ACL; Schema: storage; Owner: -
--

GRANT ALL ON TABLE storage.s3_multipart_uploads_parts TO service_role;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO authenticated;
GRANT SELECT ON TABLE storage.s3_multipart_uploads_parts TO anon;
GRANT ALL ON TABLE storage.s3_multipart_uploads_parts TO postgres;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: auth; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON SEQUENCES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: auth; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON FUNCTIONS  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: auth; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_auth_admin IN SCHEMA auth GRANT ALL ON TABLES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: extensions; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON SEQUENCES  TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: extensions; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON FUNCTIONS  TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: extensions; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA extensions GRANT ALL ON TABLES  TO postgres WITH GRANT OPTION;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: graphql_public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: graphql_public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: graphql_public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA graphql_public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: pgsodium; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium GRANT ALL ON SEQUENCES  TO pgsodium_keyholder;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: pgsodium; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium GRANT ALL ON TABLES  TO pgsodium_keyholder;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: pgsodium_masks; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium_masks GRANT ALL ON SEQUENCES  TO pgsodium_keyiduser;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: pgsodium_masks; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium_masks GRANT ALL ON FUNCTIONS  TO pgsodium_keyiduser;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: pgsodium_masks; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA pgsodium_masks GRANT ALL ON TABLES  TO pgsodium_keyiduser;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT ALL ON TABLES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: realtime; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON SEQUENCES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: realtime; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON FUNCTIONS  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: realtime; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA realtime GRANT ALL ON TABLES  TO dashboard_user;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: storage; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON SEQUENCES  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR FUNCTIONS; Type: DEFAULT ACL; Schema: storage; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON FUNCTIONS  TO service_role;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: storage; Owner: -
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO postgres;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO anon;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA storage GRANT ALL ON TABLES  TO service_role;


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

