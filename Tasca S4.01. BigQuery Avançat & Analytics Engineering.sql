-- Nivell 1
-- Exercici 1 
SELECT *
FROM `sprint3-analytics-gabriella.sprint3_silver.transactions_clean` t
JOIN `sprint3-analytics-gabriella.sprint3_silver.companies_clean` c ON c.company_id = t.business_id
WHERE c.country = 'Germany'
AND DATE(t.timestamp) = '2022-03-12';

-- Exercici 2
CREATE OR REPLACE TABLE `sprint3-analytics-gabriella.sprint3_silver.transactions_recent` AS
SELECT * EXCEPT(timestamp), 
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL CAST(RAND() * 50 AS INT64) DAY) AS timestamp
FROM `sprint3-analytics-gabriella.sprint3_silver.transactions_clean`;

CREATE OR REPLACE TABLE `sprint3-analytics-gabriella.sprint3_gold.fact_transactions_optimized`
  PARTITION BY DATE(timestamp)
  CLUSTER BY business_id AS

SELECT * 
FROM `sprint3-analytics-gabriella.sprint3_silver.transactions_recent`;

-- Exercici 3
SELECT * 
FROM `sprint3-analytics-gabriella.sprint3_silver.transactions_recent`
WHERE timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);

SELECT * 
FROM `sprint3-analytics-gabriella.sprint3_gold.fact_transactions_optimized`
WHERE timestamp > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY);

-- Exercici 4
CREATE MATERIALIZED VIEW `sprint3-analytics-gabriella.sprint3_gold.mv_daily_sales` AS
SELECT DATE(timestamp) AS date, SUM(amount) AS total_sales
FROM `sprint3-analytics-gabriella.sprint3_gold.fact_transactions_optimized`
GROUP BY DATE(timestamp);

SELECT date, ROUND(total_sales,2) AS total_sales
FROM `sprint3-analytics-gabriella.sprint3_gold.mv_daily_sales`;

-- Nivell 2
-- Exercici 1
WITH VIP_Stats AS (
  SELECT user_id,   
    ROUND(SUM(amount),2) AS despesa_total, 
    COUNT(*) AS cantidad_transacciones, 
    ROUND(AVG(amount),2) AS ticket_medio,
    ROUND(MAX(amount),2) AS compra_maxima
  FROM `sprint3-analytics-gabriella.sprint3_gold.fact_transactions_optimized` 
  GROUP BY user_id
  HAVING despesa_total > 500
)

SELECT
  v.user_id,
  CONCAT(u.name, ' ', u.surname) AS nome_completo,
  u.email,
  v.cantidad_transacciones,
  v.ticket_medio,
  v.compra_maxima,
  v.despesa_total
FROM VIP_Stats v
JOIN `sprint3-analytics-gabriella.sprint3_silver.users_combined` u ON v.user_id = u.user_id
ORDER BY v.despesa_total DESC;

-- Exercici 2
SELECT date,
  ROUND(total_sales,2) AS vendas_hoy,
  ROUND(LAG(total_sales) OVER (ORDER BY date),2) AS vendas_ayer,
  ROUND(((total_sales-LAG(total_sales) OVER (ORDER BY date))/LAG(total_sales) OVER (ORDER BY date))*100,2) AS variacion_porcentaje
FROM `sprint3-analytics-gabriella.sprint3_gold.mv_daily_sales`
ORDER BY date DESC;

-- Exercici 3
SELECT date,
  ROUND(total_sales,2) AS vendas_hoy,
  ROUND(SUM(total_sales) OVER (PARTITION BY EXTRACT(YEAR FROM date) ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),2) AS vendas_acumuladas
FROM `sprint3-analytics-gabriella.sprint3_gold.mv_daily_sales`
ORDER BY EXTRACT(YEAR FROM date) DESC;

-- Exercici 4
WITH rank_transactions AS (
  SELECT
    user_id, timestamp, amount,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY timestamp ASC) AS position
  FROM `sprint3-analytics-gabriella.sprint3_gold.fact_transactions_optimized`
  WHERE declined = 0
  QUALIFY position <= 3
),

first_three AS (
  SELECT
    user_id, AVG(amount) AS media_primeras_tres
  FROM rank_transactions
  GROUP BY user_id
  HAVING COUNT(*) = 3
)

SELECT
  u.user_id,
  CONCAT(u.name, ' ', u.surname) AS nombre,
  u.email,
  t.timestamp AS data_tercera_compra,
  ROUND(t.amount,2) AS total_tercera_compra,
  ROUND(f.media_primeras_tres, 2) AS media_primeras_tres
FROM rank_transactions t
JOIN first_three f ON t.user_id = f.user_id
JOIN `sprint3-analytics-gabriella.sprint3_silver.users_combined` u ON t.user_id = u.user_id
WHERE t.position = 3
ORDER BY t.timestamp DESC;

-- Nivell 3
-- Exercici 1
CREATE OR REPLACE TABLE `sprint3-analytics-gabriella.sprint3_gold.dim_transactions_flat` AS

SELECT t.transaction_id, 
  t.timestamp, 
  t.amount AS total_ticket, 
  product_id AS product_sku, 
  p.name AS product_name, 
  p.price AS product_price
FROM `sprint3-analytics-gabriella.sprint3_gold.fact_transactions_optimized` t
CROSS JOIN UNNEST(product_ids) AS product_id
JOIN `sprint3-analytics-gabriella.sprint3_silver.products_clean` p 
ON CAST(product_id AS STRING) = CAST(p.product_id AS STRING);

-- Exercici 2
SELECT product_sku, product_name, COUNT(*) AS vendas_total
FROM `sprint3-analytics-gabriella.sprint3_gold.dim_transactions_flat`
GROUP BY product_sku, product_name 
ORDER BY vendas_total DESC
LIMIT 5;

-- Exercici 3
CREATE OR REPLACE FUNCTION `sprint3-analytics-gabriella.sprint3_gold.calculate_tax`(amount FLOAT64) 
RETURNS FLOAT64 
AS (amount * 1.21);

CREATE OR REPLACE TABLE `sprint3-analytics-gabriella.sprint3_gold.dim_transactions_flat` AS

SELECT t.transaction_id, 
  t.timestamp, 
  t.amount AS total_ticket, 
  product_id AS product_sku, 
  p.name AS product_name, 
  p.price AS product_price,
  `sprint3-analytics-gabriella.sprint3_gold.calculate_tax`(p.price) AS product_price_tax_inc,
  CURRENT_TIMESTAMP() AS last_update
FROM `sprint3-analytics-gabriella.sprint3_gold.fact_transactions_optimized` t
CROSS JOIN UNNEST(product_ids) AS product_id
JOIN `sprint3-analytics-gabriella.sprint3_silver.products_clean` p 
ON CAST(product_id AS STRING) = CAST(p.product_id AS STRING);
