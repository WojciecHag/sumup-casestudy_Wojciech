{{ config(
    materialized='table'
) }}

WITH raw_transactions AS (
    SELECT *
    FROM {{ source('raw_data', 'transactions') }}
),

final AS(
    SELECT 
        id::INTEGER AS transaction_id,
        device_id::INTEGER AS device_id,
        product_sku::VARCHAR AS product_sku,
        category_name::VARCHAR AS category_name,
        amount::DECIMAL(10,2) AS transaction_amount,
        status::VARCHAR AS transaction_status,
        created_at::TIMESTAMP AS transaction_created_at_timestamp,
        happened_at::TIMESTAMP AS transaction_happened_at_timestamp 
    FROM raw_transactions
)

SELECT *
FROM final
