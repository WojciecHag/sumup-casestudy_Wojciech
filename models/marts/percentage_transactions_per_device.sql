-- Percentage of Transactions per Device Type
SELECT device_type_id,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS transaction_percentage
FROM {{ ref('fct_transactions') }}
GROUP BY device_type_id