-- Top 10 Products Sold by Amount
SELECT product_sku, COUNT(*) AS total_sold
FROM {{ ref('fct_transactions') }}
GROUP BY product_sku
ORDER BY total_sold DESC
