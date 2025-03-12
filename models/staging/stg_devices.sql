{{ config(
    materialized='table'
) }}

WITH raw_devices AS (
    SELECT *
    FROM {{ source('raw_data', 'devices') }}
),

final AS (
    SELECT 
        id::INTEGER AS device_id,
        type::INTEGER AS device_type_id,
        store_id::INTEGER AS store_id
    FROM raw_devices
)

SELECT *
FROM final
