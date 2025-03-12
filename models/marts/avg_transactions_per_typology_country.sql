-- Average Transacted Amount per Store Typology & Country
SELECT typology, country, ROUND(AVG(transaction_amount), 2) AS avg_transaction
FROM {{ ref('fct_transactions') }}
GROUP BY typology, country
ORDER BY avg_transaction DESC