{{ config(
    materialized='table'
) }}

WITH stg_stores AS (
    SELECT *
    FROM {{ ref('stg_stores') }}
),

final AS (
    SELECT DISTINCT
        store_id,
        customer_id,
        store_name,
        store_address,
        REGEXP_REPLACE(city, '[0-9]', '') AS city,
        REGEXP_REPLACE(country, '[0-9]', '') AS country,
        typology,
        store_created_at
    FROM stg_stores
    WHERE store_id IS NOT NULL
)

SELECT *
FROM final