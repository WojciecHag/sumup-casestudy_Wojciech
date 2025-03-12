# ELT Pipeline Project - SUMUP Case-Study

## 1. Overview

This project demonstrates an end-to-end ELT pipeline using SQL, DBT, and Docker to transform raw data into structured models within a PostgreSQL data warehouse. The project answers key business questions based on transaction data.

## 2. Assumptions

The provided datasets (stores, transactions, devices) are treated as the raw source.

Transaction timestamps (created_at, happened_at) are correctly formatted.

A store can have multiple transactions, and devices are linked to transactions.

The ELT pipeline is designed to be reproducible and scalable.

## 3. Data Model Design

The pipeline follows a layered DBT structure:

```sql
├── dbt_project.yml         # DBT configuration
├── docker-compose.yml      # Docker setup
├── profiles.yml            # DBT connection settings
├── packages.yml            # DBT package dependencies
├── models/
│   ├── staging/            # Reads raw data, assigns correct data types
│   │   ├── stg_stores.sql
│   │   ├── stg_transactions.sql
│   │   ├── stg_devices.sql
│   ├── cleaning/           # Cleans and standardizes data
│   │   ├── clean_stores.sql
│   │   ├── clean_transactions.sql
│   │   ├── clean_devices.sql
│   ├── core/               # Joins tables and applies business rules
│   │   ├── fct_transactions.sql
│   ├── marts/              # Business-level queries for analysis
│   │   ├── top_stores_by_amount.sql
│   │   ├── top_products_sold.sql
│   │   ├── avg_transaction_per_typology_country.sql
│   │   ├── percentage_transactions_per_device.sql
│   │   ├── avg_time_first_5_transactions.sql
```
### Staging Layer

Loading data from source, ensuring correct DATATYPEs

### Cleaning Layer

The cleaning layer standardizes data and removes inconsistencies. This includes:

Removing letters from ```product_sku``` using ```regexp_replace```.

Removing ```,``` and ```.``` from ```category_name``` in ```clean_transactions``` using ```regexp_replace```.

Removing numbers from ```city``` and ```country``` in ```clean_stores``` using ```regexp_replace```.

Standardizing column formats and ensuring correct data types for reliable downstream processing.

### **Core Layer**
The **Core Layer** is responsible for structuring data into a **fact table** (`fct_transactions`) that serves as the foundation for business intelligence queries. This layer:
- Joins **cleaned transactions, stores, and devices**.
- Ensures that each transaction is linked to its respective store and device.
- Provides a **well-structured dataset** for the marts layer.

#### **File:** `models/core/fct_transactions.sql`
```sql
{{ config(
    materialized='incremental',
    unique_key='transaction_id'
) }}

WITH transactions AS (
    SELECT * FROM {{ ref('clean_transactions') }}
), 
stores AS (
    SELECT * FROM {{ ref('clean_stores') }}
), 
devices AS (
    SELECT * FROM {{ ref('clean_devices') }}
)

SELECT 
    t.transaction_id,
    t.device_id,
    t.product_sku,
    t.category_name,
    t.amount,
    t.status,
    t.transaction_created_at,
    t.transaction_happened_at,
    d.device_type,
    s.store_name,
    s.typology,
    s.country
FROM transactions t
LEFT JOIN devices d ON t.device_id = d.device_id
LEFT JOIN stores s ON d.store_id = s.store_id

{% if is_incremental() %}
WHERE t.transaction_happened_at > (SELECT MAX(transaction_happened_at) FROM {{ this }})
{% endif %}
```

### Marts Layer - Business Queries

The Marts Layer consists of individual models answering business questions:

#### **1. Top 10 Stores by Transacted Amount**
**File:** `models/marts/top_stores_by_amount.sql`
```sql
SELECT store_name, SUM(amount) AS total_transacted
FROM {{ ref('fct_transactions') }}
GROUP BY store_name
ORDER BY total_transacted DESC
LIMIT 10;
```
#### **2. Top 10 Products Sold**
**File:** `models/marts/top_products_sold.sql`
```sql
SELECT product_sku, COUNT(*) AS total_sold
FROM {{ ref('fct_transactions') }}
GROUP BY product_sku
ORDER BY total_sold DESC
LIMIT 10;
```

#### **3. Average Transacted Amount per Store Typology & Country**
**File:** `models/marts/avg_transaction_per_typology_country.sql`
```sql
SELECT typology, country, AVG(amount) AS avg_transaction
FROM {{ ref('fct_transactions') }}
GROUP BY typology, country;
```

#### **4. Percentage of Transactions per Device Type**
**File:** `models/marts/percentage_transactions_per_device.sql`
```sql
SELECT
    device_type,
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS transaction_percentage
FROM {{ ref('fct_transactions') }}
GROUP BY device_type;
```

#### **5. Average Time for a Store to Perform its First 5 Transactions**
**File:** `models/marts/avg_time_first_5_transactions.sql`

**Note:'' The original logic includes all transactions, including canceled ones. This was intentionally kept to maintain historical data accuracy and allow further business analysis. However, a possible refinement could be to exclude canceled or failed transactions to reflect only successful transactions. Additionally, outliers have not been removed, meaning some stores with large time gaps between the first 5 transactions might have significantly high average times. This was considered but kept to maintain data transparency.

```Explanation of EXTRACT(EPOCH FROM ...)```**Logic:**

The ```LAG()``` function retrieves the previous transaction timestamp for the same store.
```transaction_happened_at - previous_transaction``` calculates the time difference.
```EXTRACT(EPOCH FROM interval)``` converts this difference into seconds.
Dividing by ```60``` converts seconds into minutes.

This ensures that we accurately measure the **time difference between consecutive transactions** and compute the **average time taken for the first 5 transactions per store**.
```sql
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
```

## 4. Results

### **Top 10 Stores by Transacted Amount**
| Store Name  | Total Transacted (€) |
|------------|----------------------|
| Sem Ut Cursus Corp.	| 26230 |
| Eleifend Cras Institute	| 26206 |
| Nec Ante Ltd	| 26047 |
| Magnis Dis Inc.	| 18851 |
| Mauris Aliquam PC	| 18193 |
| Integer Mollis Integer Foundation	| 17199 |
| In LLP	| 16434 |
| Dolor Nonummy Ac Inc.	| 15644 |
| Erat Neque Foundation | 14835 |
| Tempus Mauris Ltd	| 14755 |

### **Top 10 Products Sold**
| Product SKU | Total Sold Units|
|------------------|------------------|
| 3770009015048    | 89               |
| 3770009015004    | 85               |
| 3770009015042    | 82               |
| 3770009015046    | 82               |
| 3770009015073    | 81               |
| 3770009015052    | 81               |
| 3770009015050    | 80               |
| 3770009015044    | 79               |
| 3770009015051    | 79               |
| 3770009015043    | 77               |

### **Average Transacted Amount per Store Typology & Country**
Note: Top 10 only, further can be queried
| Typology   | Country       | Avg. Transaction Amount (€) |
|------------|---------------|-------------------------|
| FoodTruck  | South Africa  | 885                     |
| Restaurant | Colombia      | 737                     |
| Hotel      | Nigeria       | 700.4                   |
| Florist    | Austria       | 684.86                  |
| Other      | France        | 615.86                  |
| Service    | Brazil        | 598.79                  |
| Florist    | Belgium       | 595.7                   |
| Hotel      | New Zealand   | 593.4                   |
| FoodTruck  | India         | 588.22                  |
| Beauty     | Austria       | 583.17                  |


### **Percentage of Transactions per Device Type**
Note: Top 10 only, further can be queried
| Device Type  | Transaction Percentage (%) |
|-------------|------------------------|
| 1           | 21.72                  |
| 3           | 20.45                  |
| 5           | 17.46                  |
| 2           | 17.06                  |
| 4           | 23.32                  |

### **Average Time for a Store to Perform its First 5 Transactions**
Note: Top 10 only, further can be queried
| Store Name                            | Avg Time (Minutes) | Avg. Time (Hours) | Avg. Time (Days) |
|---------------------------------------|--------------------|-------------------|------------------|
| Neque Tellus PC                       | 7918               | 132               | 5                |
| Sapien Nunc Pulvinar Institute        | 9052               | 151               | 6                |
| Sem Ut Cursus Corp.                   | 10492              | 175               | 7                |
| Nec Ante Ltd                          | 10377              | 173               | 7                |
| Arcu Vestibulum Ltd                   | 12193              | 203               | 8                |
| Et Magna Incorporated                 | 10848              | 181               | 8                |
| In LLP                                 | 12574              | 210               | 9                |
| Mollis Dui LLP                        | 15059              | 251               | 10               |
| Eleifend Cras Institute               | 15027              | 250               | 10               |
| Magna Suspendisse Tristique PC        | 16136              | 269               | 11               |

## 5. Setup Instructions (Optional)
### **Step 1: Clone the Repository**
```bash
git clone https://github.com/WojciecHag/elt-pipeline-case-study.git
cd elt-pipeline-case-study
```
### Step 2: Install DBT Packages

```dbt deps```

### Step 3: Start Docker Containers

```docker-compose up -d```

### Step 4: Test DBT Connection

```dbt debug```

### Step 5: Run DBT Models

```dbt run```

### Step 6: Run DBT Tests

```dbt test```

### Step 7: Verify Results in PostgreSQL

```docker exec -it elt_postgres psql -U WojciecHag -d sump```

Run:
```sql
SELECT * FROM case_study.top_stores_by_amount LIMIT 10;
SELECT * FROM case_study.top_products_sold LIMIT 10;
SELECT * FROM case_study.avg_transaction_per_typology_country LIMIT 10;
SELECT * FROM case_study.percentage_transactions_per_device LIMIT 10;
SELECT * FROM case_study.avg_time_first_5_transactions LIMIT 10;
```
