# BigQuery Advanced & Analytics Engineering

## Overview

This project explores advanced SQL and Analytics Engineering techniques using Google BigQuery. The goal is to optimize analytical workloads, transform transactional data into business-ready datasets, and develop sales performance insights.

The project was developed as part of the IT Academy Data Analytics specialization.

## Objectives

- Optimize query performance through partitioning and clustering.
- Compare query processing costs using BigQuery dry runs.
- Build a materialized view for daily sales aggregation.
- Apply Common Table Expressions (CTEs) and window functions to customer and sales analysis.
- Transform nested product arrays into a flat analytical table.
- Create a reusable SQL User-Defined Function (UDF) to calculate prices including VAT.
- Build a sales performance dashboard in Looker Studio.

## Tools & Technologies

- **Google BigQuery** — data storage and SQL analytics.
- **SQL** — data transformation, aggregation, and analytical logic.
- **Window Functions** — period-over-period comparisons, cumulative sales, and customer purchase ranking.
- **Partitioning & Clustering** — query performance and cost optimization.
- **Looker Studio** — sales performance visualization.

## Project Workflow

### 1. Query Optimization

Created a recent-transactions table and an optimized fact table using date partitioning and clustering by business ID.

A dry-run comparison for transactions from the last 30 days showed a reduction in estimated processed data from 11.85 MB to 7.22 MB, representing an approximate **39.07% reduction**.

### 2. Materialized Views

Created a materialized view to aggregate daily sales and support downstream analysis without repeatedly expressing the base aggregation.

### 3. Advanced SQL Analytics

Applied CTEs and window functions to:
- Identify VIP customers based on cumulative spending.
- Compare daily sales with the previous day.
- Calculate year-to-date cumulative sales.
- Analyze customers' first three transactions.

### 4. Arrays and Data Modeling

Used `CROSS JOIN UNNEST()` to transform arrays of product IDs into individual product rows, then joined the resulting records with the product catalog.

### 5. Reusable Business Logic

Created a SQL UDF named `calculate_tax` to calculate product prices including 21% VAT and incorporated the result into the flattened analytical table.

### 6. Sales Performance Dashboard

Built a Looker Studio dashboard featuring:
- Total product value including VAT.
- Unique transaction count.
- Average value per transaction.
- Daily sales evolution.
- Product sales and VAT metrics.

[View the Looker Studio dashboard](https://datastudio.google.com/s/g5V_W7JH8y4)

## Repository Structure

```text
.
├── README.md
├── sql/
│   └── sprint4_bigquery_analytics_engineering.sql
└── docs/
    └── Tasca_S4.01_BigQuery_Analytics_Engineering.pdf
```

## Automation Note

The scheduled daily refresh was not completed because the Google Cloud project did not have a billing account associated with it. The SQL logic and table transformation were implemented, but automatic scheduling remains a limitation of the environment used for this exercise.

## Documentation

The accompanying PDF contains the exercise explanations, SQL evidence, screenshots, and dashboard reference.

## Key Takeaway

This project demonstrates practical experience with BigQuery optimization, analytical SQL, data modeling, reusable business logic, and BI visualization.
