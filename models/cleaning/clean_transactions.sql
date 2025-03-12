{{ config(
    materialized='table'
) }}

WITH stg_transactions AS (
    SELECT *
    FROM {{ ref('stg_transactions') }}
),

final AS (
    SELECT DISTINCT
        transaction_id,
        device_id,
        REGEXP_REPLACE(product_sku, '[^0-9]', '') AS product_sku, /* Cleaning up ProductSKU as some "V"s are included - I assume letters are not allowed at all */
        LOWER(REGEXP_REPLACE(category_name, '[,.]', ''))  AS category_name,
        transaction_amount,
        transaction_status,
        transaction_created_at_timestamp,
        transaction_happened_at_timestamp
    FROM stg_transactions
    WHERE transaction_id IS NOT NULL
)

SELECT *
FROM final
