-- Top 10 Stores by Transacted Amount
SELECT store_name, SUM(transaction_amount) AS total_transacted
FROM {{ ref('fct_transactions') }}
GROUP BY store_name
ORDER BY total_transacted DESC