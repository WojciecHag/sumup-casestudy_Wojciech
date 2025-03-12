-- Average Time for a Store to Perform Its First 5 Transactions
WITH ranked_transactions AS (
    SELECT
        store_name,
        transaction_id,
        transaction_happened_at_timestamp,
        ROW_NUMBER() OVER(PARTITION BY store_name ORDER BY transaction_happened_at_timestamp) AS txn_rank,
        EXTRACT(EPOCH FROM (transaction_happened_at_timestamp - LAG(transaction_happened_at_timestamp, 1)
            OVER (PARTITION BY store_name ORDER BY transaction_happened_at_timestamp))) / 60 AS time_diff_minutes
    FROM {{ ref('fct_transactions') }}
)
SELECT
    store_name,
    ROUND(AVG(time_diff_minutes), 0) AS avg_minutes_first_5_transactions,
    ROUND(ROUND(AVG(time_diff_minutes), 0) /60, 0) AS avg_hours_first_5_transactions,
    ROUND((ROUND(AVG(time_diff_minutes), 0)/60) / 24, 0)  avg_days_first_5_transactions
FROM ranked_transactions
WHERE txn_rank <= 5
AND time_diff_minutes IS NOT NULL
GROUP BY store_name
ORDER BY avg_minutes_first_5_transactions desc
