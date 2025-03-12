{{ config(
    materialized='table'
) }}

WITH raw_stores AS (
    SELECT *
    FROM {{ source('raw_data', 'stores') }}
),

final AS (
    SELECT
        id::INTEGER AS store_id,
        name::VARCHAR AS store_name,
        address::VARCHAR AS store_address,
        city::VARCHAR AS city,
        country::VARCHAR AS country,
        created_at::TIMESTAMP AS store_created_at,
        typology::VARCHAR AS typology,
        customer_id::INTEGER AS customer_id
    FROM raw_stores
)

SELECT *
FROM final