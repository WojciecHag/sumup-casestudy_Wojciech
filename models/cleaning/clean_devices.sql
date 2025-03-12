{{ config(
    materialized='table'
) }}

WITH stg_devices AS (
    SELECT *
    FROM {{ ref('stg_devices') }}
),

final AS (
    SELECT DISTINCT
        device_id,
        device_type_id,
        store_id
    FROM stg_devices
)

SELECT *
from final