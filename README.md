# Inventory & Supply Chain Analytics System
### SQL Server | Star Schema | FIFO | ABC Analysis | Safety Stock

[![SQL Server](https://img.shields.io/badge/SQL-Server-blue)]()
[![Queries](https://img.shields.io/badge/Queries-60-green)]()
[![SKUs](https://img.shields.io/badge/SKUs-1000+-orange)]()

---

## Business Problem

Warehouse operations running on gut feeling and Excel:
- Millions locked in dead stock — nobody tracking
- Products expiring unsold — discovered too late
- Reorder decisions made without data
- No FIFO cost allocation — profit numbers wrong
- No supplier performance measurement

**This system solves all of it.**

---

## Project Scale

| Metric | Value |
|--------|-------|
| SKUs | 1,000+ |
| Warehouses | 10 |
| Suppliers | 200 |
| SQL Queries | 60 |
| Data Pipeline | Raw → Clean → Fact → Analysis |

---

## Database Architecture

![Schema Diagram](assets/schema_diagram.png)

---

## SQL Concepts Used

| Concept | Used For |
|---------|----------|
| CTEs (3–4 chained) | All FIFO queries |
| SUM OVER PARTITION BY | Cumulative quantity for FIFO |
| ROW_NUMBER OVER | Batch sequence ordering |
| NTILE(3) | Fast/Normal/Slow classification |
| CASE WHEN | Age buckets, risk levels, status |
| DATEDIFF / DATEADD | Age days, expiry countdown |
| NULLIF | Division by zero protection |
| ISNULL | NULL replacement |
| LEFT JOIN + WHERE IS NULL | Anti-join for lost sales |
| CROSS JOIN | Analysis date from control_panel |
| STDEV() × SQRT() | Safety stock formula |
| GROUP BY + HAVING | Supplier performance |

---

## Key Analytics Built

### 1. FIFO Inventory Valuation
```sql
-- 3-CTE FIFO Pattern
WITH sales_summary AS (
    SELECT sku, SUM(qty) AS total_sold
    FROM fact_sales GROUP BY sku
),
batch_ordered AS (
    SELECT *, SUM(qty) OVER(
        PARTITION BY sku
        ORDER BY purchase_date
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
    FROM fact_inventory
),
fifo_calc AS (
    SELECT bo.*,
        CASE
            WHEN ss.total_sold >= bo.cumulative_qty
                THEN bo.batch_qty
            WHEN ss.total_sold > bo.cumulative_qty - bo.batch_qty
                THEN ss.total_sold - (bo.cumulative_qty - bo.batch_qty)
            ELSE 0
        END AS batch_sold_qty
    FROM batch_ordered bo
    LEFT JOIN sales_summary ss ON bo.sku = ss.sku
)
SELECT * FROM fifo_calc;
```

### 2. Safety Stock Formula
```sql
-- 95% Service Level Safety Stock
safety_stock = 1.65 × STDEV(daily_demand) × SQRT(lead_time)
```

### 3. ABC Classification
```sql
-- Pareto 80/15/5 using Cumulative Window Function
CASE
    WHEN cum_pct <= 80 THEN 'A - Star'
    WHEN cum_pct <= 95 THEN 'B - Normal'
    ELSE 'C - Tail'
END AS abc_class
```

---

## Query Index (All 60 Queries)

| Range | Topic |
|-------|-------|
| Q01–Q15 | Basic Analytics |
| Q16–Q27 | Inventory Ageing and FIFO |
| Q28–Q35 | Stock Ratios and Lead Times |
| Q36–Q50 | Business Profitability |
| Q51–Q60 | Advanced Analytics |

Full list in [query_index.md](06_documentation/query_index.md)

---

## Business KPIs Generated
