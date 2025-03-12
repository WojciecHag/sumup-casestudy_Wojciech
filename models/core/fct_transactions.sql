{{ config(
    materialized='incremental',
    unique_key='transaction_id'
) }}

WITH clean_transactions AS (
    SELECT * FROM {{ ref('clean_transactions') }}
),

clean_stores AS (
    SELECT * FROM {{ ref('clean_stores') }}
),

clean_devices AS (
    SELECT * FROM {{ ref('clean_devices') }}
),

final AS (
    SELECT
        tra.transaction_id,
        tra.device_id,
        dev.device_type_id,
        tra.product_sku,
        tra.category_name,
        tra.transaction_amount,
        tra.transaction_status,
        sto.store_name,
        sto.typology,
        sto.country,
        tra.transaction_created_at_timestamp,
        tra.transaction_happened_at_timestamp
FROM clean_transactions AS tra
LEFT JOIN clean_devices AS dev ON tra.device_id = dev.device_id
LEFT JOIN clean_stores AS sto ON dev.store_id = sto.store_id
)

SELECT *
FROM final
{% if is_incremental() %}
WHERE transaction_happened_at_timestamp > (SELECT MAX(transaction_happened_at_timestamp) FROM {{ this}})
{% endif %}