/*========================================================
CREATE DATABASE
========================================================*/

CREATE DATABASE inventory_analyst;
GO

USE inventory_analyst;
GO


/*========================================================
RAW TABLES
========================================================*/
DROP TABLE IF EXISTS raw_products
CREATE TABLE raw_products (
    sku VARCHAR(50),
    product_name VARCHAR(255),
    category VARCHAR(100),
    cost_price DECIMAL(10,2),
    selling_price DECIMAL(10,2)
);

DROP TABLE IF EXISTS raw_purchases
CREATE TABLE raw_purchases (
    purchase_id VARCHAR(50),
    sku VARCHAR(50),
    supplier VARCHAR(100),
    warehouse VARCHAR(50),
    qty INT,
    cost DECIMAL(10,2),
    purchase_date DATE,
    delivery_date DATE
);

DROP TABLE IF EXISTS raw_sales
CREATE TABLE raw_sales (
    sale_id VARCHAR(50),
    sku VARCHAR(50),
    warehouse VARCHAR(50),
    store VARCHAR(50),
    qty INT,
    selling_price DECIMAL(10,2),
    sale_date DATE
);

DROP TABLE IF EXISTS raw_inventory_batches
CREATE TABLE raw_inventory_batches (
    batch_id VARCHAR(50),
    sku VARCHAR(50),
    warehouse VARCHAR(50),
    qty INT,
    unit_cost DECIMAL(10,2),
    purchase_date DATE,
    expiry_date DATE
);



/*========================================================
CHECK RAW DATA
========================================================*/

SELECT * FROM raw_products;
SELECT * FROM raw_purchases;
SELECT * FROM raw_sales;
SELECT * FROM raw_inventory_batches;



/*========================================================
CLEAN PRODUCTS
========================================================*/

DROP TABLE IF EXISTS clean_products;

SELECT DISTINCT

    UPPER(LTRIM(RTRIM(sku))) AS sku,

    LTRIM(RTRIM(product_name)) AS product_name,

    LTRIM(RTRIM(category)) AS category,

    CAST(cost_price AS DECIMAL(10,2)) AS cost_price,

    CAST(selling_price AS DECIMAL(10,2)) AS selling_price

INTO clean_products

FROM raw_products

WHERE sku IS NOT NULL
AND LTRIM(RTRIM(sku)) <> ''

AND product_name IS NOT NULL
AND LTRIM(RTRIM(product_name)) <> ''

AND category IS NOT NULL
AND LTRIM(RTRIM(category)) <> ''

AND cost_price > 0
AND selling_price > 0;

SELECT * FROM clean_products;



/*========================================================
CLEAN PURCHASES
========================================================*/

DROP TABLE IF EXISTS clean_purchases;

SELECT DISTINCT

    UPPER(LTRIM(RTRIM(purchase_id))) AS purchase_id,

    UPPER(LTRIM(RTRIM(sku))) AS sku,

    UPPER(LTRIM(RTRIM(supplier))) AS supplier,

    UPPER(LTRIM(RTRIM(warehouse))) AS warehouse,

    CAST(qty AS BIGINT) AS qty,

    CAST(cost AS DECIMAL(10,2)) AS cost,

    purchase_date,

    delivery_date

INTO clean_purchases

FROM raw_purchases

WHERE purchase_id IS NOT NULL
AND LTRIM(RTRIM(purchase_id)) <> ''

AND sku IS NOT NULL
AND LTRIM(RTRIM(sku)) <> ''

AND supplier IS NOT NULL
AND LTRIM(RTRIM(supplier)) <> ''

AND warehouse IS NOT NULL
AND LTRIM(RTRIM(warehouse)) <> ''

AND qty > 0
AND cost > 0

AND purchase_date IS NOT NULL
AND delivery_date IS NOT NULL

AND delivery_date >= purchase_date;

SELECT * FROM clean_purchases;



/*========================================================
CLEAN SALES
========================================================*/

DROP TABLE IF EXISTS clean_sales;

SELECT DISTINCT

    UPPER(LTRIM(RTRIM(sale_id))) AS sale_id,

    UPPER(LTRIM(RTRIM(sku))) AS sku,

    UPPER(LTRIM(RTRIM(warehouse))) AS warehouse,

    UPPER(LTRIM(RTRIM(store))) AS store,

    CAST(qty AS BIGINT) AS qty,

    CAST(selling_price AS DECIMAL(10,2)) AS selling_price,

    sale_date

INTO clean_sales

FROM raw_sales

WHERE sale_id IS NOT NULL
AND LTRIM(RTRIM(sale_id)) <> ''

AND sku IS NOT NULL
AND LTRIM(RTRIM(sku)) <> ''

AND warehouse IS NOT NULL
AND LTRIM(RTRIM(warehouse)) <> ''

AND store IS NOT NULL
AND LTRIM(RTRIM(store)) <> ''

AND qty > 0
AND selling_price > 0

AND sale_date IS NOT NULL;

SELECT * FROM clean_sales;



/*========================================================
CLEAN INVENTORY
========================================================*/

DROP TABLE IF EXISTS clean_inventory;

SELECT DISTINCT

    UPPER(LTRIM(RTRIM(batch_id))) AS batch_id,

    UPPER(LTRIM(RTRIM(sku))) AS sku,

    UPPER(LTRIM(RTRIM(warehouse))) AS warehouse,

    CAST(qty AS BIGINT) AS qty,

    CAST(unit_cost AS DECIMAL(10,2)) AS unit_cost,

    purchase_date,

    expiry_date

INTO clean_inventory

FROM raw_inventory_batches

WHERE batch_id IS NOT NULL
AND LTRIM(RTRIM(batch_id)) <> ''

AND sku IS NOT NULL
AND LTRIM(RTRIM(sku)) <> ''

AND warehouse IS NOT NULL
AND LTRIM(RTRIM(warehouse)) <> ''

AND qty > 0
AND unit_cost > 0

AND purchase_date IS NOT NULL

AND (
    expiry_date IS NULL
    OR expiry_date >= purchase_date
);

SELECT * FROM clean_inventory;



/*========================================================
DUPLICATE CHECKS
========================================================*/

SELECT sale_id, COUNT(*) duplicate_count
FROM clean_sales
GROUP BY sale_id
HAVING COUNT(*) > 1;


SELECT purchase_id, COUNT(*) duplicate_count
FROM clean_purchases
GROUP BY purchase_id
HAVING COUNT(*) > 1;


SELECT batch_id, COUNT(*) duplicate_count
FROM clean_inventory
GROUP BY batch_id
HAVING COUNT(*) > 1;



/*========================================================
INVALID SKU CHECK
========================================================*/

SELECT DISTINCT sku
FROM clean_sales
WHERE sku NOT IN (
    SELECT sku FROM clean_products
);


SELECT DISTINCT sku
FROM clean_purchases
WHERE sku NOT IN (
    SELECT sku FROM clean_products
);


SELECT DISTINCT sku
FROM clean_inventory
WHERE sku NOT IN (
    SELECT sku FROM clean_products
);



/*========================================================
CONTROL PANEL
========================================================*/

DROP TABLE IF EXISTS control_panel;

CREATE TABLE control_panel (
    analysis_date DATE
);

INSERT INTO control_panel
SELECT MAX(sale_date)
FROM clean_sales;

SELECT * FROM control_panel;



/*========================================================
DIM PRODUCTS
========================================================*/

DROP TABLE IF EXISTS dim_products;

SELECT DISTINCT

    sku,
    product_name,
    category,
    cost_price,
    selling_price

INTO dim_products

FROM clean_products;

SELECT * FROM dim_products;



/*========================================================
DIM WAREHOUSE
========================================================*/

DROP TABLE IF EXISTS dim_warehouse;

SELECT DISTINCT warehouse

INTO dim_warehouse

FROM (

    SELECT warehouse FROM clean_inventory

    UNION

    SELECT warehouse FROM clean_sales

    UNION

    SELECT warehouse FROM clean_purchases

) t;

SELECT * FROM dim_warehouse;



/*========================================================
DIM SUPPLIER
========================================================*/

DROP TABLE IF EXISTS dim_supplier;

SELECT DISTINCT supplier

INTO dim_supplier

FROM clean_purchases;

SELECT * FROM dim_supplier;



/*========================================================
DIM STORE
========================================================*/

DROP TABLE IF EXISTS dim_store;

SELECT DISTINCT store

INTO dim_store

FROM clean_sales;

SELECT * FROM dim_store;



/*========================================================
FACT PURCHASES
========================================================*/

DROP TABLE IF EXISTS fact_purchases;

SELECT

    purchase_id,
    sku,
    supplier,
    warehouse,
    qty,
    cost,
    purchase_date,
    delivery_date

INTO fact_purchases

FROM clean_purchases;

SELECT * FROM fact_purchases;



/*========================================================
FACT SALES
========================================================*/

DROP TABLE IF EXISTS fact_sales;

SELECT

    sale_id,
    sku,
    warehouse,
    store,
    qty,
    selling_price,
    sale_date

INTO fact_sales

FROM clean_sales;

SELECT * FROM fact_sales;



/*========================================================
FACT INVENTORY
========================================================*/

DROP TABLE IF EXISTS fact_inventory;

SELECT

    batch_id,
    sku,
    warehouse,
    qty,
    unit_cost,
    purchase_date,
    expiry_date

INTO fact_inventory

FROM clean_inventory;

SELECT * FROM fact_inventory
ORDER BY sku, warehouse;



/*========================================================
FACT INVENTORY SNAPSHOT
========================================================*/

DROP TABLE IF EXISTS fact_inventory_snapshot;

CREATE TABLE fact_inventory_snapshot (

    snapshot_date DATE,

    sku VARCHAR(50),

    warehouse VARCHAR(50),

    total_qty BIGINT
);


INSERT INTO fact_inventory_snapshot

SELECT

    cp.analysis_date,

    fi.sku,

    fi.warehouse,

    SUM(fi.qty) AS total_qty

FROM fact_inventory fi

CROSS JOIN control_panel cp

GROUP BY
    cp.analysis_date,
    fi.sku,
    fi.warehouse;

SELECT * FROM fact_inventory_snapshot;



/*========================================================
FACT STOCK MOVEMENT
========================================================*/

DROP TABLE IF EXISTS fact_stock_movement;

CREATE TABLE fact_stock_movement (

    movement_id INT IDENTITY(1,1),

    sku VARCHAR(50),

    warehouse VARCHAR(50),

    movement_type VARCHAR(10),

    qty BIGINT,

    movement_date DATE
);



/*---------------------------
STOCK IN
---------------------------*/

INSERT INTO fact_stock_movement (
    sku,
    warehouse,
    movement_type,
    qty,
    movement_date
)

SELECT

    sku,
    warehouse,
    'IN',
    qty,
    purchase_date

FROM fact_purchases

WHERE purchase_date IS NOT NULL;



/*---------------------------
STOCK OUT
---------------------------*/

INSERT INTO fact_stock_movement (
    sku,
    warehouse,
    movement_type,
    qty,
    movement_date
)

SELECT

    sku,
    warehouse,
    'OUT',
    qty,
    sale_date

FROM fact_sales

WHERE sale_date IS NOT NULL;



SELECT * FROM fact_stock_movement;



/*========================================================
FINAL VALIDATION CHECKS
========================================================*/


/* Total rows */

SELECT COUNT(*) total_products FROM clean_products;

SELECT COUNT(*) total_sales FROM clean_sales;

SELECT COUNT(*) total_purchases FROM clean_purchases;

SELECT COUNT(*) total_inventory FROM clean_inventory;


/* Null check */

SELECT *
FROM clean_products
WHERE sku IS NULL;


SELECT *
FROM clean_sales
WHERE sku IS NULL;


SELECT *
FROM clean_inventory
WHERE sku IS NULL;


/* Negative check */

SELECT *
FROM clean_inventory
WHERE qty <= 0;


SELECT *
FROM clean_sales
WHERE qty <= 0;


/* SKU validation */

SELECT DISTINCT sku
FROM clean_sales
WHERE sku NOT IN (
    SELECT sku FROM clean_products
);


/*========================================================
PROJECT READY
========================================================*/

1.	**What is the total inventory quantity?**

select sum(qty)as total_qty from fact_inventory

2.	**What is the total inventory value?**

SELECT 
    SUM(qty * unit_cost) AS total_inventory_value
FROM fact_inventory;


3.	What is the total revenue generated?

 SELECT SUM(qty * selling_price) AS total_revenue
FROM fact_sales;


4.	How many unique SKUs are there?

SELECT COUNT(DISTINCT(SKU)) FROM dim_products

5.	How many warehouses exist?

select COUNT(distinct(warehouse))from dim_warehouse

6	What is the total purchase quantity?

select sum(qty) from fact_purchases

7.	What is the total sales quantity?

select sum(qty) from fact_sales

8.	Which records have missing (NULL) data?

SELECT *
FROM raw_sales
WHERE sale_id IS NULL
   OR sku IS NULL
   OR warehouse IS NULL
   OR store IS NULL
   OR qty IS NULL OR qty = 0
   OR selling_price IS NULL OR selling_price = 0
   OR sale_date IS NULL OR sale_date = 0;

9.	Are there any negative or zero quantities?

 select * from raw_sales
 where qty<=0

10.	What is the latest transaction date?

select max(sale_date) from fact_sales

11.	Which are the top 10 high stock SKUs?

SELECT TOP 10

    sku,

    SUM(qty) AS total_stock_qty,

    COUNT(DISTINCT warehouse) AS warehouse_count,

    SUM(qty * unit_cost) AS total_inventory_value

FROM fact_inventory

GROUP BY sku

ORDER BY total_stock_qty DESC;

12.	Which SKUs have thce lowest stock?

SELECT TOP 10

    sku,

    SUM(qty) AS total_stock_qty,

    COUNT(DISTINCT warehouse) AS warehouse_count,

    SUM(qty * unit_cost) AS total_inventory_value

FROM fact_inventory

GROUP BY sku

ORDER BY total_stock_qty asc;

13.	What is the warehouse-wise stock distribution?

select warehouse,sum(qty) as WH_stock from fact_inventory
GROUP BY warehouse
order by  WH_stock desc

14.	Which SKUs are the top selling?

select sku,sum(qty) as sale_qty from fact_sales
group by sku
order by sale_qty desc

15.	What is the revenue generated per SKU?

select sku,ROUND(sum(qty * selling_price),2) as revenue from fact_sales
group by sku
order by revenue desc

16.	How is inventory distributed across warehouses?

select sku,warehouse from fact_inventory

WITH sku_wh AS (
    SELECT 
        sku, warehouse,
        SUM(qty) AS qty
    FROM fact_inventory
    GROUP BY sku, warehouse
)

SELECT 
    sku,
    warehouse,
    qty,
    ROUND(
        qty * 100.0 / 
        SUM(qty) OVER (PARTITION BY sku)
    , 2) AS sku_distribution_pct
FROM sku_wh
ORDER BY sku, sku_distribution_pct DESC;

17.	Which SKUs are present in multiple warehouses?

SELECT 
    sku,
    warehouse,
    qty
FROM fact_inventory
WHERE sku IN (
    SELECT sku
    FROM fact_inventory
    GROUP BY sku
    HAVING COUNT(DISTINCT warehouse) > 1
)
ORDER BY sku


SELECT 
    sku,
    warehouse,
    SUM(qty) AS total_qty
FROM fact_inventory
WHERE sku IN (
    SELECT sku
    FROM fact_inventory
    GROUP BY sku
    HAVING COUNT(DISTINCT warehouse) > 1
)
GROUP BY sku, warehouse
ORDER BY sku, warehouse;


18.	What is the purchase trend over time?

SELECT 
   format (purchase_date,'yyyy-MM')as month,
   count(*) as orders,
   sum(qty)as total_qty,
   sum(qty *cost)as total_spent
   from fact_purchases
   GROUP BY FORMAT(purchase_date, 'yyyy-MM')
ORDER BY month;


19.	What is the sales trend over time?

SELECT 
   format (sale_date,'yyyy-MM')as month,
   count(*) as orders,
   sum(qty)as total_qty,
   sum(qty *selling_price)as total_spent
   from fact_sales
   GROUP BY FORMAT(sale_date, 'yyyy-MM')
ORDER BY month;


20.	What is the supplier-wise purchase quantity?

select supplier,
COUNT(*) orders,
SUM(qty) total_qty,  
SUM(qty * cost) total_spend
from  fact_purchases
GROUP BY supplier
ORDER BY total_qty desc


SELECT 

    sku,
    supplier,

    COUNT(*) AS orders,

    SUM(qty) AS total_qty,

    AVG(cost) AS avg_unit_price,

    MIN(cost) AS min_unit_price,

    MAX(cost) AS max_unit_price,

    SUM(qty * cost) AS total_purchase_value,

    AVG(qty * cost) AS avg_order_value,

    MIN(qty * cost) AS min_order_value,

    MAX(qty * cost) AS max_order_value

FROM fact_purchases

WHERE sku IN (

    SELECT sku
    FROM fact_purchases
    GROUP BY sku
    HAVING COUNT(DISTINCT supplier) > 1

)

GROUP BY sku, supplier

ORDER BY sku, avg_unit_price ASC;


21.	What is the inventory ageing for each SKU?

SELECT 
    fi.sku,
    DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) AS inventory_age_days,
    SUM(fi.qty) AS total_qty
FROM fact_inventory fi
CROSS JOIN control_panel cp
GROUP BY 
    fi.sku,
    DATEDIFF(DAY, fi.purchase_date, cp.analysis_date)
ORDER BY fi.sku, inventory_age_days DESC;

SELECT 
    fi.sku,
    fi.warehouse,
    fi.purchase_date,
    DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) AS inventory_age_days,
    SUM(fi.qty) AS total_qty
FROM fact_inventory fi
CROSS JOIN control_panel cp
GROUP BY 
    fi.sku,
    fi.warehouse,
    fi.purchase_date,
    DATEDIFF(DAY, fi.purchase_date, cp.analysis_date)
ORDER BY 
    fi.sku,
    fi.warehouse,
    inventory_age_days DESC;

       -------------------------------------------------------
    --2nd  query in deep
    -------------------------------------------------------


WITH sales_summary AS (

    -------------------------------------------------------
    -- SKU LEVEL SALES SUMMARY
    -------------------------------------------------------

    SELECT

        sku,

        SUM(qty) AS total_sold_qty,

        MIN(sale_date) AS first_sale_date,

        MAX(sale_date) AS last_sale_date,

        COUNT(DISTINCT sale_date) AS active_sale_days,

        CAST(
            SUM(qty) * 1.0 /
            NULLIF(COUNT(DISTINCT sale_date),0)
            AS DECIMAL(10,2)
        ) AS avg_daily_sales

    FROM fact_sales
    GROUP BY sku
),

inventory_batches AS (

    -------------------------------------------------------
    -- FIFO BATCH ORDER
    -------------------------------------------------------

    SELECT

        fi.batch_id,
        fi.sku,
        fi.warehouse,

        fi.purchase_date,
        fi.expiry_date,

        fi.qty AS batch_qty,

        fi.unit_cost,

        ROW_NUMBER() OVER(
            PARTITION BY fi.sku
            ORDER BY fi.purchase_date
        ) AS batch_order,

        SUM(fi.qty) OVER(
            PARTITION BY fi.sku
            ORDER BY fi.purchase_date
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW
        ) AS cumulative_batch_qty

    FROM fact_inventory fi
),

batch_calculation AS (

    -------------------------------------------------------
    -- FIFO SOLD / REMAINING LOGIC
    -------------------------------------------------------

    SELECT

        ib.batch_id,
        ib.sku,
        ib.warehouse,

        ib.purchase_date,
        ib.expiry_date,

        ib.batch_qty,

        ib.unit_cost,

        ss.total_sold_qty,

        ss.first_sale_date,
        ss.last_sale_date,

        ss.avg_daily_sales,

        ---------------------------------------------------
        -- ESTIMATED BATCH SOLD QTY
        ---------------------------------------------------

        CASE

            WHEN ISNULL(ss.total_sold_qty,0)
                >= ib.cumulative_batch_qty
            THEN ib.batch_qty

            WHEN ISNULL(ss.total_sold_qty,0)
                < ib.cumulative_batch_qty - ib.batch_qty
            THEN 0

            ELSE
                ISNULL(ss.total_sold_qty,0)
                - (ib.cumulative_batch_qty - ib.batch_qty)

        END AS estimated_batch_sold_qty

    FROM inventory_batches ib

    LEFT JOIN sales_summary ss
    ON ib.sku = ss.sku
)

SELECT

    -------------------------------------------------------
    -- BASIC INFO
    -------------------------------------------------------

    bc.batch_id,
    bc.sku,
    bc.warehouse,

    bc.purchase_date,
    bc.expiry_date,

    bc.batch_qty,

    -------------------------------------------------------
    -- SALES INFO
    -------------------------------------------------------

    ISNULL(bc.total_sold_qty,0) AS total_sku_sales,

    bc.estimated_batch_sold_qty,

    -------------------------------------------------------
    -- REMAINING QTY
    -------------------------------------------------------

    bc.batch_qty
    - bc.estimated_batch_sold_qty
    AS estimated_remaining_qty,

    -------------------------------------------------------
    -- FIXED ESTIMATED BATCH LAST SALE DATE
    -------------------------------------------------------

    CASE

        ---------------------------------------------------
        -- FULLY CONSUMED
        ---------------------------------------------------

        WHEN
            bc.batch_qty
            - bc.estimated_batch_sold_qty = 0

        AND bc.avg_daily_sales > 0

        THEN

            DATEADD(

                DAY,

                CAST(
                    bc.batch_qty /
                    bc.avg_daily_sales
                    AS INT
                ),

                bc.purchase_date
            )

        ---------------------------------------------------
        -- PARTIALLY CONSUMED
        ---------------------------------------------------

        WHEN
            bc.estimated_batch_sold_qty > 0
        AND bc.avg_daily_sales > 0

        THEN

            DATEADD(

                DAY,

                CAST(
                    bc.estimated_batch_sold_qty /
                    bc.avg_daily_sales
                    AS INT
                ),

                bc.purchase_date
            )

        ---------------------------------------------------
        -- NOT SOLD
        ---------------------------------------------------

        ELSE NULL

    END AS estimated_batch_last_sale_date,

    -------------------------------------------------------
    -- AGE DAYS
    -------------------------------------------------------

    CASE

        ---------------------------------------------------
        -- FULLY SOLD
        ---------------------------------------------------

        WHEN
            bc.batch_qty
            - bc.estimated_batch_sold_qty = 0

        AND bc.avg_daily_sales > 0

        THEN

            DATEDIFF(

                DAY,

                bc.purchase_date,

                DATEADD(

                    DAY,

                    CAST(
                        bc.batch_qty /
                        bc.avg_daily_sales
                        AS INT
                    ),

                    bc.purchase_date
                )
            )

        ---------------------------------------------------
        -- PARTIALLY SOLD
        ---------------------------------------------------

        WHEN
            bc.estimated_batch_sold_qty > 0
        AND bc.avg_daily_sales > 0

        THEN

            DATEDIFF(

                DAY,

                bc.purchase_date,

                DATEADD(

                    DAY,

                    CAST(
                        bc.estimated_batch_sold_qty /
                        bc.avg_daily_sales
                        AS INT
                    ),

                    bc.purchase_date
                )
            )

        ---------------------------------------------------
        -- ACTIVE / UNSOLD
        ---------------------------------------------------

        ELSE

            DATEDIFF(
                DAY,
                bc.purchase_date,
                cp.analysis_date
            )

    END AS age_days,

    -------------------------------------------------------
    -- EXPIRY DAYS
    -------------------------------------------------------

    CASE

        WHEN bc.expiry_date IS NULL
        THEN NULL

        ELSE
            DATEDIFF(
                DAY,
                cp.analysis_date,
                bc.expiry_date
            )

    END AS expiry_days_remaining,

    -------------------------------------------------------
    -- EXPIRY STATUS
    -------------------------------------------------------

-------------------------------------------------------
-- EXPIRY STATUS
-------------------------------------------------------

CASE

    WHEN bc.expiry_date IS NULL
    THEN 'NO EXPIRY'

    WHEN bc.expiry_date < cp.analysis_date
    THEN 'EXPIRED'

    WHEN DATEDIFF(
            DAY,
            cp.analysis_date,
            bc.expiry_date
         ) <= 30
    THEN 'NEAR EXPIRY'

    ELSE 'SAFE'

END AS expiry_status,

    -------------------------------------------------------
    -- BATCH STATUS
    -------------------------------------------------------

    CASE

        WHEN
            bc.batch_qty
            - bc.estimated_batch_sold_qty = 0
        THEN 'FULLY CONSUMED'

        WHEN
            bc.estimated_batch_sold_qty > 0
        THEN 'PARTIALLY CONSUMED'

        ELSE 'UNTOUCHED'

    END AS batch_status,

    -------------------------------------------------------
    -- INVENTORY VALUE
    -------------------------------------------------------

    bc.unit_cost,

    bc.batch_qty * bc.unit_cost
    AS inventory_value

FROM batch_calculation bc

CROSS JOIN control_panel cp

ORDER BY
    bc.sku,
    bc.purchase_date;

    -- 1. Products NULL check
SELECT * FROM dim_products
WHERE product_name IS NULL
   OR category IS NULL;

-- 2. Sales duplicate check  
SELECT COUNT(*) AS raw_sales FROM raw_sales;
SELECT COUNT(*) AS clean_sales FROM clean_sales;
SELECT COUNT(*) AS fact_sales FROM fact_sales;

-- 3. Batch duplicate check
SELECT batch_id, COUNT(*) cnt
FROM raw_inventory_batches
GROUP BY batch_id
HAVING COUNT(*) > 1
ORDER BY cnt DESC;



22.	How can inventory be categorized into age buckets?

SELECT 
    fi.sku,
    fi.warehouse,
    fi.batch_id,
    fi.purchase_date,
    DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) AS actual_days,
    
    CASE 
        WHEN DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) <= 30 THEN '0-30'
        WHEN DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) <= 60 THEN '31-60'
        WHEN DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) <= 90 THEN '61-90'
        ELSE '90+'
    END AS age_bucket,

    fi.qty
FROM fact_inventory fi
CROSS JOIN control_panel cp;




WITH sales_summary AS (
  SELECT sku,
    SUM(qty) AS total_sold,
    MAX(sale_date) AS last_sale_date, 
    MIN(sale_date) AS first_sale_date 
  FROM fact_sales
  GROUP BY sku
),
batch_ordered AS (
  SELECT 
    batch_id, sku, warehouse,
    purchase_date, expiry_date,
    qty AS batch_qty, unit_cost,
    -- Cumulative qty batch wise
    SUM(qty) OVER(
      PARTITION BY sku
      ORDER BY purchase_date
      ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
  FROM fact_inventory
),
fifo_calc AS (
  SELECT 
    bo.*,
    ss.total_sold,
    ss.last_sale_date,    
    ss.first_sale_date,
    -- FIFO sold per batch
    CASE
      -- Batch fully sold
      WHEN ss.total_sold >= bo.cumulative_qty
        THEN bo.batch_qty
      -- Batch partially sold  
      WHEN ss.total_sold > 
        bo.cumulative_qty - bo.batch_qty
        THEN ss.total_sold - 
          (bo.cumulative_qty - bo.batch_qty)
      -- Batch not sold yet
      ELSE 0
    END AS batch_sold_qty
  FROM batch_ordered bo
  LEFT JOIN sales_summary ss ON bo.sku = ss.sku
)
SELECT
  batch_id, sku, warehouse,
  purchase_date, expiry_date,
   ---------------------------------------------------
-- ESTIMATED BATCH FIRST SALE DATE
---------------------------------------------------

CASE

    WHEN batch_sold_qty > 0

    THEN

        DATEADD(

            DAY,

            CAST(

                (cumulative_qty - batch_qty) * 1.0 /

                NULLIF(

                    total_sold * 1.0 /

                    NULLIF(
                        DATEDIFF(
                            DAY,
                            first_sale_date,
                            last_sale_date
                        ),
                    0),

                0)

            AS INT),

            first_sale_date
        )

    ELSE NULL

END AS estimated_batch_first_sale_date,

---------------------------------------------------
-- ESTIMATED BATCH LAST SALE DATE
---------------------------------------------------

CASE

    WHEN batch_sold_qty > 0

    THEN

        DATEADD(

            DAY,

            CAST(

                cumulative_qty * 1.0 /

                NULLIF(

                    total_sold * 1.0 /

                    NULLIF(
                        DATEDIFF(
                            DAY,
                            first_sale_date,
                            last_sale_date
                        ),
                    0),

                0)

            AS INT),

            first_sale_date
        )

    ELSE NULL

END AS estimated_batch_last_sale_date,
  batch_qty AS purchased_qty,
  ISNULL(total_sold,0) AS total_sku_sold,
  batch_sold_qty AS sold_qty,
  batch_qty - batch_sold_qty AS remaining_qty,
  unit_cost,
  batch_qty * unit_cost AS value,
  DATEDIFF(DAY, purchase_date,
    cp.analysis_date) AS age_days,
  CASE
    WHEN DATEDIFF(DAY,purchase_date,
      cp.analysis_date) <= 30 THEN '0-30 FRESH'
    WHEN DATEDIFF(DAY,purchase_date,
      cp.analysis_date) <= 60 THEN '31-60 OK'
    WHEN DATEDIFF(DAY,purchase_date,
      cp.analysis_date) <= 90 THEN '61-90 SLOW'
    ELSE '91+ DEAD'
  END AS age_bucket,
  CASE
    WHEN expiry_date IS NULL THEN 'NO EXPIRY'
    WHEN expiry_date < cp.analysis_date 
      THEN 'EXPIRED'
    WHEN DATEDIFF(DAY,cp.analysis_date,
      expiry_date) <= 30 THEN 'NEAR EXPIRY'
    ELSE 'SAFE'
  END AS expiry_status
FROM fifo_calc
CROSS JOIN control_panel cp
ORDER BY sku, purchase_date;

23.	Which stock is considered dead (90+ days)?

SELECT 
    fi.sku,
    fi.warehouse,
    fi.purchase_date,
    SUM(fi.qty * fi.unit_cost) dead_value,
    DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) AS inventory_age_days,
    SUM(fi.qty) AS total_qty
FROM fact_inventory fi
CROSS JOIN control_panel cp
WHERE DATEDIFF(DAY, fi.purchase_date, cp.analysis_date) > 90
GROUP BY 
    fi.sku,
    fi.warehouse,
    fi.purchase_date,
    DATEDIFF(DAY, fi.purchase_date, cp.analysis_date)
ORDER BY inventory_age_days,dead_value DESC;

WITH sales_summary AS (
  SELECT sku,
    SUM(qty) AS total_sold,
    MAX(sale_date) AS last_sale_date, 
    MIN(sale_date) AS first_sale_date 
  FROM fact_sales
  GROUP BY sku
),
batch_ordered AS (
  SELECT 
    batch_id, sku, warehouse,
    purchase_date, expiry_date,
    qty AS batch_qty, unit_cost,
    -- Cumulative qty batch wise
    SUM(qty) OVER(
      PARTITION BY sku
      ORDER BY purchase_date
      ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
  FROM fact_inventory
),
fifo_calc AS (
  SELECT 
    bo.*,
    ss.total_sold,
    ss.last_sale_date,    
    ss.first_sale_date,
    -- FIFO sold per batch
    CASE
      -- Batch fully sold
      WHEN ss.total_sold >= bo.cumulative_qty
        THEN bo.batch_qty
      -- Batch partially sold  
      WHEN ss.total_sold > 
        bo.cumulative_qty - bo.batch_qty
        THEN ss.total_sold - 
          (bo.cumulative_qty - bo.batch_qty)
      -- Batch not sold yet
      ELSE 0
    END AS batch_sold_qty
  FROM batch_ordered bo
  LEFT JOIN sales_summary ss ON bo.sku = ss.sku
)
SELECT
  batch_id, sku, warehouse,
  purchase_date, expiry_date,
   ---------------------------------------------------
-- ESTIMATED BATCH FIRST SALE DATE
---------------------------------------------------

CASE

    WHEN batch_sold_qty > 0

    THEN

        DATEADD(

            DAY,

            CAST(

                (cumulative_qty - batch_qty) * 1.0 /

                NULLIF(

                    total_sold * 1.0 /

                    NULLIF(
                        DATEDIFF(
                            DAY,
                            first_sale_date,
                            last_sale_date
                        ),
                    0),

                0)

            AS INT),

            first_sale_date
        )

    ELSE NULL

END AS estimated_batch_first_sale_date,

---------------------------------------------------
-- ESTIMATED BATCH LAST SALE DATE
---------------------------------------------------

CASE

    WHEN batch_sold_qty > 0

    THEN

        DATEADD(

            DAY,

            CAST(

                cumulative_qty * 1.0 /

                NULLIF(

                    total_sold * 1.0 /

                    NULLIF(
                        DATEDIFF(
                            DAY,
                            first_sale_date,
                            last_sale_date
                        ),
                    0),

                0)

            AS INT),

            first_sale_date
        )

    ELSE NULL

END AS estimated_batch_last_sale_date,
  batch_qty AS purchased_qty,
  ISNULL(total_sold,0) AS total_sku_sold,
  batch_sold_qty AS sold_qty,
  batch_qty - batch_sold_qty AS remaining_qty,
  unit_cost,
  batch_qty * unit_cost AS value,
  DATEDIFF(DAY, purchase_date,
    cp.analysis_date) AS age_days
FROM fifo_calc
CROSS JOIN control_panel cp

 WHERE DATEDIFF(DAY,purchase_date, cp.analysis_date) > 90

ORDER BY sku, purchase_date;



24.	Which inventory is at expiry risk (<30 days)?

SELECT 
    fi.sku,
    fi.warehouse,
SUM(fi.qty) AS qty,
 SUM(fi.qty * fi.unit_cost) AS risk_value,
 MIN(fi.expiry_date) AS nearest_expiry,
 MIN(DATEDIFF(DAY, cp.analysis_date, fi.expiry_date)) AS days_to_expiry   -- 🔥 ADD
FROM fact_inventory fi
JOIN control_panel cp ON 1=1
WHERE fi.expiry_date >= cp.analysis_date
AND fi.expiry_date <= DATEADD(DAY, 30, cp.analysis_date)
GROUP BY fi.sku, fi.warehouse
ORDER BY days_to_expiry ASC;

select * from fact_inventory
where warehouse = 'WH_10' and sku='SKU0255'

select * from fact_purchases
where warehouse = 'WH_10' and sku='SKU0255'

WITH sales_summary AS (
  SELECT sku,
    SUM(qty) AS total_sold,
    MAX(sale_date) AS last_sale_date,
    MIN(sale_date) AS first_sale_date
  FROM fact_sales
  GROUP BY sku
),
batch_ordered AS (
  SELECT
    batch_id, sku, warehouse,
    purchase_date, expiry_date,
    qty AS batch_qty, unit_cost,
    SUM(qty) OVER(
      PARTITION BY sku
      ORDER BY purchase_date
      ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
  FROM fact_inventory
),
fifo_calc AS (
  SELECT
    bo.*,
    ss.total_sold,
    ss.last_sale_date,
    ss.first_sale_date,
    CASE
      WHEN ss.total_sold >= bo.cumulative_qty
        THEN bo.batch_qty
      WHEN ss.total_sold >
        bo.cumulative_qty - bo.batch_qty
        THEN ss.total_sold -
          (bo.cumulative_qty - bo.batch_qty)
      ELSE 0
    END AS batch_sold_qty
  FROM batch_ordered bo
  LEFT JOIN sales_summary ss ON bo.sku = ss.sku
)
SELECT
  batch_id, sku, warehouse,
  purchase_date,
  expiry_date,
  first_sale_date,
  last_sale_date,
  batch_qty AS purchased_qty,
  ISNULL(total_sold,0) AS total_sku_sold,
  batch_sold_qty AS sold_qty,
  batch_qty - batch_sold_qty AS remaining_qty,
  unit_cost,
  batch_qty * unit_cost AS risk_value,
  DATEDIFF(DAY, purchase_date,
    cp.analysis_date) AS age_days,
  DATEDIFF(DAY, cp.analysis_date,
    expiry_date) AS days_to_expiry    -- ← kitne din bacha
FROM fifo_calc
CROSS JOIN control_panel cp
WHERE expiry_date IS NOT NULL
  AND expiry_date >= cp.analysis_date -- ← expired nahi
  AND DATEDIFF(DAY, cp.analysis_date,
    expiry_date) <= 30                -- ← 30 din mein expire
ORDER BY sku,warehouse ASC;         -- ← urgent pehle
 

25. Which stock is already expired?

WITH sales_summary AS (
  SELECT sku,
    SUM(qty)          AS total_sold,
    MAX(sale_date)    AS last_sale_date,
    MIN(sale_date)    AS first_sale_date
  FROM fact_sales
  GROUP BY sku
),

batch_ordered AS (
  SELECT
    batch_id, sku, warehouse,
    purchase_date, expiry_date,
    qty AS batch_qty, unit_cost,
    SUM(qty) OVER(
      PARTITION BY sku
      ORDER BY purchase_date
      ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
  FROM fact_inventory
),

fifo_calc AS (
  SELECT
    bo.*,
    ss.total_sold,
    ss.last_sale_date,
    ss.first_sale_date,
    CASE
      WHEN ss.total_sold >= bo.cumulative_qty
        THEN bo.batch_qty
      WHEN ss.total_sold >
        bo.cumulative_qty - bo.batch_qty
        THEN ss.total_sold -
          (bo.cumulative_qty - bo.batch_qty)
      ELSE 0
    END AS batch_sold_qty
  FROM batch_ordered bo
  LEFT JOIN sales_summary ss ON bo.sku = ss.sku
)

SELECT
  batch_id,
  sku,
  warehouse,
  purchase_date,
  expiry_date,

  -- Estimated Batch First Sale Date
  CASE
    WHEN batch_sold_qty > 0
    THEN DATEADD(DAY,
      CAST(
        (cumulative_qty - batch_qty) * 1.0 /
        NULLIF(
          total_sold * 1.0 /
          NULLIF(
            DATEDIFF(DAY, first_sale_date, last_sale_date)
          , 0)
        , 0)
      AS INT),
      first_sale_date)
    ELSE NULL
  END AS est_batch_first_sale,

  -- Estimated Batch Last Sale Date
  CASE
    WHEN batch_sold_qty > 0
    THEN DATEADD(DAY,
      CAST(
        cumulative_qty * 1.0 /
        NULLIF(
          total_sold * 1.0 /
          NULLIF(
            DATEDIFF(DAY, first_sale_date, last_sale_date)
          , 0)
        , 0)
      AS INT),
      first_sale_date)
    ELSE NULL
  END AS est_batch_last_sale,

  batch_qty             AS purchased_qty,
  ISNULL(total_sold, 0) AS total_sku_sold,
  batch_sold_qty        AS sold_qty,
  batch_qty - batch_sold_qty AS remaining_qty,
  unit_cost,
  batch_qty * unit_cost AS risk_value,

  DATEDIFF(DAY, expiry_date,
    cp.analysis_date)   AS expired_since_days

FROM fifo_calc
CROSS JOIN control_panel cp

WHERE expiry_date IS NOT NULL
  AND expiry_date < cp.analysis_date

ORDER BY expired_since_days DESC;

26.	Which stock is slow-moving (60–90 days)?

SELECT fi.sku,fi.warehouse,
SUM(fi.qty) AS qty,
SUM(fi.qty*fi.unit_cost) AS risk_value,
AVG(DATEDIFF(DAY,fi.purchase_date,cp.analysis_date)) AS avg_days,
MAX(DATEDIFF(DAY,fi.purchase_date,cp.analysis_date)) AS max_days
FROM fact_inventory fi
JOIN control_panel cp ON 1=1
WHERE DATEDIFF(DAY,fi.purchase_date,cp.analysis_date) BETWEEN 60 AND 90
GROUP BY fi.sku,fi.warehouse
ORDER BY risk_value DESC;

WITH sales_summary AS (
  SELECT sku,
    SUM(qty) AS total_sold,
    MAX(sale_date) AS last_sale_date, 
    MIN(sale_date) AS first_sale_date 
  FROM fact_sales
  GROUP BY sku
),
batch_ordered AS (
  SELECT 
    batch_id, sku, warehouse,
    purchase_date, expiry_date,
    qty AS batch_qty, unit_cost,
    -- Cumulative qty batch wise
    SUM(qty) OVER(
      PARTITION BY sku
      ORDER BY purchase_date
      ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
  FROM fact_inventory
),
fifo_calc AS (
  SELECT 
    bo.*,
    ss.total_sold,
    ss.last_sale_date,    
    ss.first_sale_date,
    -- FIFO sold per batch
    CASE
      -- Batch fully sold
      WHEN ss.total_sold >= bo.cumulative_qty
        THEN bo.batch_qty
      -- Batch partially sold  
      WHEN ss.total_sold > 
        bo.cumulative_qty - bo.batch_qty
        THEN ss.total_sold - 
          (bo.cumulative_qty - bo.batch_qty)
      -- Batch not sold yet
      ELSE 0
    END AS batch_sold_qty
  FROM batch_ordered bo
  LEFT JOIN sales_summary ss ON bo.sku = ss.sku
)
SELECT
  batch_id, sku, warehouse,
  purchase_date, expiry_date,
   ---------------------------------------------------
-- ESTIMATED BATCH FIRST SALE DATE
---------------------------------------------------

CASE

    WHEN batch_sold_qty > 0

    THEN

        DATEADD(

            DAY,

            CAST(

                (cumulative_qty - batch_qty) * 1.0 /

                NULLIF(

                    total_sold * 1.0 /

                    NULLIF(
                        DATEDIFF(
                            DAY,
                            first_sale_date,
                            last_sale_date
                        ),
                    0),

                0)

            AS INT),

            first_sale_date
        )

    ELSE NULL

END AS estimated_batch_first_sale_date,

---------------------------------------------------
-- ESTIMATED BATCH LAST SALE DATE
---------------------------------------------------

CASE

    WHEN batch_sold_qty > 0

    THEN

        DATEADD(

            DAY,

            CAST(

                cumulative_qty * 1.0 /

                NULLIF(

                    total_sold * 1.0 /

                    NULLIF(
                        DATEDIFF(
                            DAY,
                            first_sale_date,
                            last_sale_date
                        ),
                    0),

                0)

            AS INT),

            first_sale_date
        )

    ELSE NULL

END AS estimated_batch_last_sale_date,
  batch_qty AS purchased_qty,
  ISNULL(total_sold,0) AS total_sku_sold,
  batch_sold_qty AS sold_qty,
  batch_qty - batch_sold_qty AS remaining_qty,
  unit_cost,
  batch_qty * unit_cost AS value,
  DATEDIFF(DAY, purchase_date,
    cp.analysis_date) AS age_days
FROM fifo_calc
CROSS JOIN control_panel cp
WHERE DATEDIFF(DAY, purchase_date,
  cp.analysis_date) BETWEEN 60 AND 90

ORDER BY sku, purchase_date;



27.	Which stock is fast-moving?

SELECT fs.sku,
SUM(fs.qty) AS total_sales_qty,
SUM(fs.qty*fs.selling_price) AS revenue
FROM fact_sales fs
GROUP BY fs.sku
HAVING SUM(fs.qty)>(
SELECT AVG(total_qty) FROM(
SELECT SUM(qty) total_qty FROM fact_sales GROUP BY sku)t)
ORDER BY total_sales_qty DESC;


WITH daily_sales AS (
    SELECT 
        fs.sale_date,
        fs.sku,
        SUM(fs.qty) AS daily_qty,
        SUM(fs.qty * fs.selling_price) AS daily_revenue
    FROM fact_sales fs
    GROUP BY fs.sale_date, fs.sku
),

daily_metrics AS (
    SELECT 
        *,
        AVG(daily_qty) OVER(PARTITION BY sale_date) AS avg_daily_qty,
        RANK() OVER(PARTITION BY sale_date ORDER BY daily_qty DESC) AS daily_rank
    FROM daily_sales
),

sku_summary AS (
    SELECT 
        sku,
        SUM(daily_qty) AS total_qty,
        SUM(daily_revenue) AS total_revenue,
        COUNT(DISTINCT sale_date) AS active_days,
        AVG(daily_qty) AS avg_qty_per_day,
        AVG(daily_revenue) AS avg_revenue_per_day
    FROM daily_sales
    GROUP BY sku
),

overall_avg AS (
    SELECT AVG(total_qty) AS overall_avg_qty
    FROM sku_summary
)

SELECT 
    dm.sale_date,
    dm.sku,

    -- Daily metrics
    dm.daily_qty,
    dm.daily_revenue,

    -- Flags
    CASE WHEN dm.daily_rank = 1 THEN 1 ELSE 0 END AS is_daily_top,
    CASE WHEN dm.daily_qty > dm.avg_daily_qty THEN 1 ELSE 0 END AS is_above_avg,

    -- Overall metrics
    ss.total_qty,
    ss.total_revenue,
    ss.avg_qty_per_day,
    ss.avg_revenue_per_day,
    ss.active_days,

    -- Fast moving logic
    CASE 
        WHEN ss.total_qty > oa.overall_avg_qty THEN 'FAST'
        ELSE 'SLOW'
    END AS overall_speed,

    -- Consistency
    ROUND(
        ss.active_days * 1.0 / 
        (SELECT COUNT(DISTINCT sale_date) FROM fact_sales), 
    2) AS consistency_ratio

FROM daily_metrics dm
JOIN sku_summary ss ON dm.sku = ss.sku
CROSS JOIN overall_avg oa
ORDER BY ss.total_qty DESC;


WITH wh_sales AS (
  SELECT
    sku,
    warehouse,
    SUM(qty)         AS wh_sold,
    MIN(sale_date)   AS wh_first_sale,
    MAX(sale_date)   AS wh_last_sale
  FROM fact_sales
  GROUP BY sku, warehouse
),

sku_speed AS (
  SELECT
    sku,
    SUM(qty) AS sku_total_sold,
    NTILE(3) OVER(
      ORDER BY SUM(qty) DESC
    ) AS speed_bucket
  FROM fact_sales
  GROUP BY sku
),

batch_ordered AS (
  SELECT
    batch_id, sku, warehouse,
    purchase_date, expiry_date,
    qty AS batch_qty, unit_cost,
    SUM(qty) OVER(
      PARTITION BY sku
      ORDER BY purchase_date
      ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
  FROM fact_inventory
),

fifo_calc AS (
  SELECT
    bo.*,
    sp.sku_total_sold,
    CASE sp.speed_bucket
      WHEN 1 THEN 'FAST'
      WHEN 2 THEN 'NORMAL'
      WHEN 3 THEN 'SLOW'
    END AS sku_speed,
    ws.wh_sold,
    ws.wh_first_sale,
    ws.wh_last_sale,

    -- Days purchase to first sale
    CASE
      WHEN ws.wh_first_sale IS NULL
        THEN NULL
      WHEN ws.wh_first_sale < bo.purchase_date
        THEN 0
      ELSE
        DATEDIFF(DAY,
          bo.purchase_date,
          ws.wh_first_sale)
    END AS days_to_first_sale,

    -- Selling period
    DATEDIFF(DAY,
      ws.wh_first_sale,
      ws.wh_last_sale) AS selling_period_days,

    -- WH speed
    CASE
      WHEN ws.wh_first_sale IS NULL
        THEN 'NEVER SOLD'
      WHEN ws.wh_first_sale < bo.purchase_date
        THEN 'VERY FAST'
      WHEN DATEDIFF(DAY,
        bo.purchase_date,
        ws.wh_first_sale) <= 30
        THEN 'VERY FAST'
      WHEN DATEDIFF(DAY,
        bo.purchase_date,
        ws.wh_first_sale) <= 60
        THEN 'FAST'
      WHEN DATEDIFF(DAY,
        bo.purchase_date,
        ws.wh_first_sale) <= 90
        THEN 'NORMAL'
      ELSE 'SLOW'
    END AS wh_speed,

    -- FIFO sold
    CASE
      WHEN ISNULL(sp.sku_total_sold,0)
        >= bo.cumulative_qty
        THEN bo.batch_qty
      WHEN ISNULL(sp.sku_total_sold,0)
        > bo.cumulative_qty - bo.batch_qty
        THEN ISNULL(sp.sku_total_sold,0)
          - (bo.cumulative_qty - bo.batch_qty)
      ELSE 0
    END AS batch_sold_qty

  FROM batch_ordered bo
  LEFT JOIN sku_speed sp ON bo.sku = sp.sku
  LEFT JOIN wh_sales ws
    ON bo.sku = ws.sku
    AND bo.warehouse = ws.warehouse
)

SELECT
  fc.batch_id,
  fc.sku,
  fc.warehouse,
  fc.sku_speed,
  fc.wh_speed,

  -- Purchase
  fc.purchase_date,
  fc.batch_qty           AS inventory_qty,
  fc.unit_cost,
  fc.batch_qty * fc.unit_cost AS inventory_value,

  -- Sale dates
  fc.wh_first_sale       AS first_sale_date,
  fc.wh_last_sale        AS last_sale_date,

  -- Gaps
  fc.days_to_first_sale,
  fc.selling_period_days,

  -- FIFO
  fc.batch_sold_qty      AS sold_qty,
  fc.batch_qty - fc.batch_sold_qty AS remaining_qty,
  (fc.batch_qty - fc.batch_sold_qty)
    * fc.unit_cost       AS remaining_value,

  -- Expiry
  fc.expiry_date,
  DATEDIFF(DAY,
    cp.analysis_date,
    fc.expiry_date)      AS days_to_expiry,
  CASE
    WHEN fc.expiry_date IS NULL
      THEN 'NO EXPIRY'
    WHEN fc.expiry_date < cp.analysis_date
      THEN 'EXPIRED'
    WHEN DATEDIFF(DAY,
      cp.analysis_date,
      fc.expiry_date) <= 30
      THEN 'NEAR EXPIRY'
    WHEN DATEDIFF(DAY,
      cp.analysis_date,
      fc.expiry_date) <= 90
      THEN 'EXPIRY WATCH'
    ELSE 'SAFE'
  END AS expiry_status

FROM fifo_calc fc
CROSS JOIN control_panel cp

WHERE fc.wh_speed IN ('VERY FAST', 'FAST')
  AND fc.batch_sold_qty > 0        -- ← Sirf jo bika!
  AND fc.wh_sold > 0               -- ← WH mein sale hui!

ORDER BY
  fc.sku ASC;

28.	What is the stock-to-sales ratio?

WITH sales_data AS(
SELECT sku,
SUM(qty) total_sales,
COUNT(DISTINCT sale_date) days
FROM fact_sales
GROUP BY sku
),
stock AS(
SELECT sku,SUM(qty) current_stock
FROM fact_inventory
GROUP BY sku
)

SELECT 
st.sku,
st.current_stock,
sd.total_sales,

CAST(st.current_stock*1.0/NULLIF(sd.total_sales,0) AS DECIMAL(10,2)) AS ratio,

CAST(st.current_stock*1.0/NULLIF(sd.total_sales/sd.days,0) AS DECIMAL(10,2)) AS days_of_inventory,

CASE 
WHEN st.current_stock=0 THEN 'OUT OF STOCK'
WHEN st.current_stock<=(sd.total_sales/sd.days)*7 THEN 'LOW STOCK ⚠'
WHEN st.current_stock>=(sd.total_sales/sd.days)*90 THEN 'OVERSTOCK ❌'
ELSE 'NORMAL'
END AS stock_status

FROM stock st
JOIN sales_data sd ON st.sku=sd.sku

ORDER BY days_of_inventory DESC;

WITH stock AS (
  SELECT sku,
    SUM(qty)       AS current_stock,
    AVG(unit_cost) AS avg_cost
  FROM fact_inventory
  GROUP BY sku
),
sales AS (
  SELECT sku,
    SUM(qty)                  AS total_sold,
    COUNT(DISTINCT sale_date) AS active_days,
    AVG(selling_price)        AS avg_sell_price
  FROM fact_sales
  GROUP BY sku
)
SELECT
  st.sku,
  st.current_stock,
  st.avg_cost,
  sl.total_sold,
  sl.avg_sell_price,

  -- Stock to Sales Ratio
  CAST(st.current_stock * 1.0 /
    NULLIF(sl.total_sold, 0)
  AS DECIMAL(10,2)) AS stock_to_sales_ratio,

  -- Days of inventory left
  CAST(st.current_stock * 1.0 /
    NULLIF(sl.total_sold /
      NULLIF(sl.active_days, 0), 0)
  AS DECIMAL(10,0)) AS days_of_inventory,

  -- Status
  CASE
    WHEN st.current_stock = 0
      THEN 'OUT OF STOCK'
    WHEN CAST(st.current_stock * 1.0 /
      NULLIF(sl.total_sold /
        NULLIF(sl.active_days, 0), 0)
      AS DECIMAL(10,0)) < 7
      THEN 'LOW STOCK'
    WHEN CAST(st.current_stock * 1.0 /
      NULLIF(sl.total_sold /
        NULLIF(sl.active_days, 0), 0)
      AS DECIMAL(10,0)) > 90
      THEN 'OVERSTOCK'
    ELSE 'NORMAL'
  END AS stock_status

FROM stock st
JOIN sales sl ON st.sku = sl.sku
ORDER BY days_of_inventory DESC;

29.	What is the inventory turnover ratio?

WITH stock AS (
  SELECT sku,
    AVG(qty) AS avg_stock    -- Q29 = AVG
  FROM fact_inventory
  GROUP BY sku
),
sold AS (
  SELECT sku,
    SUM(qty) AS total_sold
  FROM fact_sales
  GROUP BY sku
)
SELECT st.sku,
  st.avg_stock,
  sl.total_sold,
  CAST(sl.total_sold * 1.0 /
    NULLIF(st.avg_stock, 0)
  AS DECIMAL(10,2)) AS turnover_ratio
FROM stock st
JOIN sold sl ON st.sku = sl.sku
ORDER BY turnover_ratio DESC;



30.	Which SKUs are overstocked?

WITH stock AS (
  SELECT sku,
    SUM(qty) AS current_stock
  FROM fact_inventory
  GROUP BY sku
),
sold AS (
  SELECT sku,
    SUM(qty) AS total_sold
  FROM fact_sales
  GROUP BY sku
)
SELECT
  st.sku,
  st.current_stock,
  sl.total_sold,
  st.current_stock - sl.total_sold AS excess,
  CAST(st.current_stock * 1.0 /
    NULLIF(sl.total_sold, 0)
  AS DECIMAL(10,2)) AS ratio
FROM stock st
JOIN sold sl ON st.sku = sl.sku
WHERE st.current_stock > sl.total_sold * 2
ORDER BY excess DESC;

31.	Which SKUs are understocked?

WITH stock AS (
  SELECT sku,
    SUM(qty) AS current_stock
  FROM fact_inventory
  GROUP BY sku
),
sold AS (
  SELECT sku,
    SUM(qty)                  AS total_sold,
    COUNT(DISTINCT sale_date) AS active_days
  FROM fact_sales
  GROUP BY sku
)
SELECT
  st.sku,
  st.current_stock,
  sl.total_sold,
  CAST(sl.total_sold * 1.0 /
    NULLIF(sl.active_days, 0)
  AS DECIMAL(10,2))   AS daily_rate,
  CAST(st.current_stock * 1.0 /
    NULLIF(sl.total_sold /
      NULLIF(sl.active_days, 0), 0)
  AS DECIMAL(10,0))   AS days_left
FROM stock st
JOIN sold sl ON st.sku = sl.sku
WHERE CAST(st.current_stock * 1.0 /
    NULLIF(sl.total_sold /
      NULLIF(sl.active_days, 0), 0)
  AS DECIMAL(10,0)) < 30
ORDER BY days_left ASC;


32.	Which warehouse holds the highest inventory value?

Select warehouse,sum(qty) as total_qty, sum( qty * unit_cost)as total_value
from fact_inventory
group by warehouse
order by total_value desc

33.	In how many warehouses is each SKU available?

select sku,COUNT(distinct warehouse) as Wh_count,
STRING_AGG(warehouse,',')WH_list
from fact_inventory
group by sku
order by Wh_count desc;

SELECT
  sku,
  COUNT(DISTINCT warehouse) AS total_wh,
  SUM(CASE WHEN warehouse='WH_01' 
    THEN 1 ELSE 0 END) AS WH_01_batches,
  SUM(CASE WHEN warehouse='WH_02' 
    THEN 1 ELSE 0 END) AS WH_02_batches,
  SUM(CASE WHEN warehouse='WH_03' 
    THEN 1 ELSE 0 END) AS WH_03_batches,
  SUM(CASE WHEN warehouse='WH_04' 
    THEN 1 ELSE 0 END) AS WH_04_batches,
  SUM(CASE WHEN warehouse='WH_05' 
    THEN 1 ELSE 0 END) AS WH_05_batches,
  SUM(CASE WHEN warehouse='WH_06' 
    THEN 1 ELSE 0 END) AS WH_06_batches,
  SUM(CASE WHEN warehouse='WH_07' 
    THEN 1 ELSE 0 END) AS WH_07_batches,
  SUM(CASE WHEN warehouse='WH_08' 
    THEN 1 ELSE 0 END) AS WH_08_batches,
  SUM(CASE WHEN warehouse='WH_09' 
    THEN 1 ELSE 0 END) AS WH_09_batches,
  SUM(CASE WHEN warehouse='WH_10' 
    THEN 1 ELSE 0 END) AS WH_10_batches
FROM fact_inventory
GROUP BY sku
ORDER BY total_wh DESC;


34.	What is the supplier delivery lead time?

select supplier,purchase_date,delivery_date,
DATEDIFF(day,purchase_date,delivery_date)as Lead_time from fact_purchases
order by supplier

select COUNT(distinct supplier) from fact_purchases

SELECT
  supplier,
  COUNT(*)    AS total_orders,
  AVG(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS avg_lead_days,
  MIN(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS fastest_days,
  MAX(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS slowest_days
FROM fact_purchases
GROUP BY supplier
ORDER BY total_orders desc;

--35.	Which suppliers have late deliveries?

SELECT
  supplier,
  COUNT(*)    AS late_orders,
  AVG(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS avg_delay_days
FROM fact_purchases
WHERE DATEDIFF(DAY,purchase_date,
  delivery_date) > 10
GROUP BY supplier
HAVING COUNT(*) >=2
ORDER BY late_orders  desc;

SELECT
  AVG(DATEDIFF(DAY,
    purchase_date, delivery_date)) AS avg_lead,
  MIN(DATEDIFF(DAY,
    purchase_date, delivery_date)) AS min_lead,
  MAX(DATEDIFF(DAY,
    purchase_date, delivery_date)) AS max_lead
FROM fact_purchases;

WITH lead_stats AS (
    
    SELECT
        AVG(CAST(DATEDIFF(DAY, purchase_date, delivery_date) AS FLOAT))
            AS avg_lead,
        STDEV(DATEDIFF(DAY, purchase_date, delivery_date))
            AS stdev_lead
    FROM fact_purchases
),
supplier_performance AS (
    SELECT
        fp.supplier,
        COUNT(*)                                            AS total_orders,
        AVG(DATEDIFF(DAY, fp.purchase_date, fp.delivery_date)) AS avg_lead_days,
        MIN(DATEDIFF(DAY, fp.purchase_date, fp.delivery_date)) AS fastest_days,
        MAX(DATEDIFF(DAY, fp.purchase_date, fp.delivery_date)) AS slowest_days,
        -- Dynamic late count
        SUM(CASE
                WHEN DATEDIFF(DAY, fp.purchase_date, fp.delivery_date)
                     > (ls.avg_lead + ls.stdev_lead)
                THEN 1 ELSE 0
            END)                                            AS late_orders,
        -- Late %
        CAST(
            SUM(CASE
                    WHEN DATEDIFF(DAY, fp.purchase_date, fp.delivery_date)
                         > (ls.avg_lead + ls.stdev_lead)
                    THEN 1 ELSE 0
                END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,1))                                   AS late_pct,
        CAST(ls.avg_lead + ls.stdev_lead AS DECIMAL(10,1))  AS late_threshold
    FROM fact_purchases fp
    CROSS JOIN lead_stats ls
    GROUP BY fp.supplier, ls.avg_lead, ls.stdev_lead
)
SELECT
    supplier,
    total_orders,
    late_orders,
    avg_lead_days,
    fastest_days,
    slowest_days,
    late_pct,
    late_threshold,
    -- Rating based on dynamic performance
    CASE
        WHEN late_pct = 0    THEN 'EXCELLENT'
        WHEN late_pct <= 15  THEN 'GOOD'
        WHEN late_pct <= 30  THEN 'AVERAGE'
        ELSE                      'POOR'
    END AS supplier_rating
FROM supplier_performance
WHERE late_orders >= 1
ORDER BY late_orders DESC, late_pct DESC;


🔴 LEVEL 4 — BUSINESS (Q36–Q50) 

--36) What is the total profit (revenue - cost)? 

SELECT
    SUM(fs.qty * fs.selling_price)                           AS total_revenue,
    SUM(fs.qty * dp.cost_price)                              AS total_cost,  
    SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS total_profit,
    CAST(
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
        / NULLIF(SUM(fs.qty * fs.selling_price), 0)
    AS DECIMAL(10,2))                                         AS overall_margin_pct
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku;     


SELECT
    fs.sku,
    dp.category,
    SUM(fs.qty * fs.selling_price)                           AS revenue,
    SUM(fs.qty * dp.cost_price)                              AS cost,        
    SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS profit,
    CAST(
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
        / NULLIF(SUM(fs.qty * fs.selling_price), 0)
    AS DECIMAL(10,2))                                         AS margin_pct
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku      
GROUP BY fs.sku, dp.category
ORDER BY profit DESC;


--37) What is the profit margin percentage? 

SELECT
  fs.sku,
  SUM(fs.qty * fs.selling_price) AS revenue,
  SUM(fs.qty * fi.unit_cost)     AS cost,
  SUM(fs.qty * fs.selling_price
    - fs.qty * fi.unit_cost)     AS profit,
  CAST(
    SUM(fs.qty * fs.selling_price
      - fs.qty * fi.unit_cost) * 100.0 /
    NULLIF(SUM(fs.qty * fs.selling_price), 0)
  AS DECIMAL(10,2))              AS margin_pct
FROM fact_sales fs
JOIN fact_inventory fi
  ON fs.sku = fi.sku
GROUP BY fs.sku
ORDER BY margin_pct desc;

SELECT
    fs.sku,
    dp.category,
    SUM(fs.qty * fs.selling_price)                           AS revenue,
    SUM(fs.qty * dp.cost_price)                              AS cost,         
    SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS profit,
    CAST(
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
        / NULLIF(SUM(fs.qty * fs.selling_price), 0)
    AS DECIMAL(10,2))                                         AS margin_pct
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku      
GROUP BY fs.sku, dp.category
ORDER BY margin_pct DESC;




--38) Which SKUs have high revenue but low profit? 

With prof as(
SELECT
  fs.sku,
  SUM(fs.qty * fs.selling_price) AS revenue,
  SUM(fs.qty * fi.unit_cost)     AS cost,
  SUM(fs.qty * fs.selling_price
    - fs.qty * fi.unit_cost)     AS profit,
  CAST(
    SUM(fs.qty * fs.selling_price
      - fs.qty * fi.unit_cost) * 100.0 /
    NULLIF(SUM(fs.qty * fs.selling_price), 0)
  AS DECIMAL(10,2))              AS margin_pct
FROM fact_sales fs
JOIN fact_inventory fi
  ON fs.sku = fi.sku
GROUP BY fs.sku
)
select * from prof
where revenue> ( select avg(revenue) from prof
)
and margin_pct < 15
order by revenue desc;

WITH prof AS (
    SELECT
        fs.sku,
        dp.category,
        SUM(fs.qty * fs.selling_price)                           AS revenue,
        SUM(fs.qty * dp.cost_price)                              AS cost,     
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS profit,
        CAST(
            SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
            / NULLIF(SUM(fs.qty * fs.selling_price), 0)
        AS DECIMAL(10,2))                                         AS margin_pct
    FROM fact_sales fs
    JOIN dim_products dp ON fs.sku = dp.sku   
    GROUP BY fs.sku, dp.category
)
SELECT *
FROM prof
WHERE revenue > (SELECT AVG(revenue) FROM prof)   
  AND margin_pct < 15                             
ORDER BY revenue DESC;


--39) Which are the top profit-generating SKUs? 

SELECT top 20
  fs.sku,
  SUM(fs.qty * fs.selling_price) AS revenue,
  SUM(fs.qty * fi.unit_cost)     AS cost,
  SUM(fs.qty * fs.selling_price
    - fs.qty * fi.unit_cost)     AS profit,
  CAST(
    SUM(fs.qty * fs.selling_price
      - fs.qty * fi.unit_cost) * 100.0 /
    NULLIF(SUM(fs.qty * fs.selling_price), 0)
  AS DECIMAL(10,2))              AS margin_pct
FROM fact_sales fs
JOIN fact_inventory fi
  ON fs.sku = fi.sku
GROUP BY fs.sku
ORDER BY margin_pct desc


SELECT TOP 20
    fs.sku,
    dp.category,
    SUM(fs.qty * fs.selling_price)                           AS revenue,
    SUM(fs.qty * dp.cost_price)                              AS cost,        
    SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS profit,
    CAST(
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
        / NULLIF(SUM(fs.qty * fs.selling_price), 0)
    AS DECIMAL(10,2))                                         AS margin_pct
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku   
GROUP BY fs.sku, dp.category
ORDER BY profit DESC; 




--40) Which SKUs are loss-making? 

SELECT
  fs.sku,
  SUM(fs.qty * fs.selling_price) AS revenue,
  SUM(fs.qty * fi.unit_cost)     AS cost,
  SUM(fs.qty * fs.selling_price
    - fs.qty * fi.unit_cost)     AS profit,
  CAST(
    SUM(fs.qty * fs.selling_price
      - fs.qty * fi.unit_cost) * 100.0 /
    NULLIF(SUM(fs.qty * fs.selling_price), 0)
  AS DECIMAL(10,2))              AS margin_pct
FROM fact_sales fs
JOIN fact_inventory fi
  ON fs.sku = fi.sku
GROUP BY fs.sku
 having SUM(fs.qty * fs.selling_price
    - fs.qty * fi.unit_cost) < 0
ORDER BY margin_pct desc;

SELECT
    fs.sku,
    dp.category,
    SUM(fs.qty * fs.selling_price)                           AS revenue,
    SUM(fs.qty * dp.cost_price)                              AS cost,       
    SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS profit,
    CAST(
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
        / NULLIF(SUM(fs.qty * fs.selling_price), 0)
    AS DECIMAL(10,2))                                         AS margin_pct
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku     
GROUP BY fs.sku, dp.category
HAVING SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) < 0
ORDER BY profit ASC;    


--41) What is the total working capital in inventory? 

SELECT
  warehouse,
  SUM(qty)             AS total_qty,
  SUM(qty * unit_cost) AS working_capital
FROM fact_inventory
GROUP BY warehouse
ORDER BY working_capital DESC;


--42) Which SKUs have blocked capital (high value, low movement)? 

WITH inv AS (
  SELECT sku,
    SUM(qty)             AS total_qty,
    SUM(qty * unit_cost) AS inv_value
  FROM fact_inventory
  GROUP BY sku
),
sold AS (
  SELECT sku,
    SUM(qty) AS total_sold
  FROM fact_sales
  GROUP BY sku
),
avg_calc AS (
  SELECT
    AVG(i.inv_value)            AS avg_inv_value,
    AVG(ISNULL(s.total_sold,0)) AS avg_sold
  FROM inv i
  LEFT JOIN sold s ON i.sku = s.sku
)
SELECT
  i.sku,
  i.total_qty        AS inventory_qty,
  i.inv_value        AS inventory_value,
  ISNULL(s.total_sold,0) AS sold_qty,
  -- Blocked Capital Value
  i.inv_value - 
    (ISNULL(s.total_sold,0) * 
      i.inv_value/NULLIF(i.total_qty,0))
    AS blocked_value
FROM inv i
LEFT JOIN sold s ON i.sku = s.sku
CROSS JOIN avg_calc a
WHERE i.inv_value > a.avg_inv_value
  AND ISNULL(s.total_sold,0) < a.avg_sold
ORDER BY i.inv_value DESC;


--43) What is the warehouse-wise profitability? 

SELECT
  fs.warehouse,
  SUM(fs.qty * fs.selling_price) AS revenue,
  SUM(fs.qty * fi.unit_cost)     AS cost,
  SUM(fs.qty * fs.selling_price
    - fs.qty * fi.unit_cost)     AS profit,
  CAST(
    SUM(fs.qty * fs.selling_price
      - fs.qty * fi.unit_cost) * 100.0 /
    NULLIF(SUM(fs.qty * fs.selling_price), 0)
  AS DECIMAL(10,2))              AS margin_pct
FROM fact_sales fs
JOIN fact_inventory fi
  ON fs.sku = fi.sku
GROUP BY fs.warehouse
ORDER BY profit desc;

SELECT
    fs.warehouse,
    COUNT(DISTINCT fs.sku)                                   AS unique_skus,
    SUM(fs.qty)                                              AS qty_sold,
    SUM(fs.qty * fs.selling_price)                           AS revenue,
    SUM(fs.qty * dp.cost_price)                              AS cost,        
    SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS profit,
    CAST(
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
        / NULLIF(SUM(fs.qty * fs.selling_price), 0)
    AS DECIMAL(10,2))                                         AS margin_pct
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku     
GROUP BY fs.warehouse
ORDER BY profit DESC;


--44) What is the category-wise performance? 

SELECT
    dp.category,
    SUM(fs.qty) AS qty_sold,
    SUM(fs.qty * fs.selling_price) AS revenue,
    SUM(fs.qty * fi.unit_cost) AS cost,
    SUM(fs.qty * fs.selling_price)
      - SUM(fs.qty * fi.unit_cost) AS profit
FROM fact_sales fs
JOIN dim_products dp
    ON fs.sku = dp.sku
JOIN fact_inventory fi
    ON fs.sku = fi.sku
GROUP BY dp.category
ORDER BY revenue DESC;

SELECT
    dp.category,
    COUNT(DISTINCT fs.sku)                                   AS unique_skus,
    SUM(fs.qty)                                              AS qty_sold,
    SUM(fs.qty * fs.selling_price)                           AS revenue,
    SUM(fs.qty * dp.cost_price)                              AS cost,       
    SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price)  AS profit,
    CAST(
        SUM(fs.qty * fs.selling_price - fs.qty * dp.cost_price) * 100.0
        / NULLIF(SUM(fs.qty * fs.selling_price), 0)
    AS DECIMAL(10,2))                                         AS margin_pct
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku    

GROUP BY dp.category
ORDER BY revenue DESC;

select distinct category from dim_products;

--45) What is the demand vs supply gap? 
WITH supply AS (
  SELECT sku,
    SUM(qty) AS total_stock
  FROM fact_inventory
  GROUP BY sku
),
demand AS (
  SELECT sku,
    SUM(qty) AS total_sold,
    COUNT(DISTINCT sale_date) AS active_days,
    CAST(SUM(qty) * 1.0 /
      NULLIF(COUNT(DISTINCT sale_date), 0)
    AS DECIMAL(10,2)) AS daily_rate
  FROM fact_sales
  GROUP BY sku
)
SELECT
  s.sku,
  s.total_stock        AS supply,
  ISNULL(d.total_sold, 0) AS demand,
  s.total_stock - ISNULL(d.total_sold, 0)
    AS gap,
  CAST(s.total_stock * 1.0 /
    NULLIF(d.daily_rate, 0)
  AS DECIMAL(10,0))    AS days_of_stock,
  CASE
    WHEN d.total_sold IS NULL
      THEN 'NEVER SOLD'
    WHEN CAST(s.total_stock * 1.0 /
      NULLIF(d.daily_rate, 0)
      AS DECIMAL(10,0)) < 30
      THEN 'SHORTAGE'
    WHEN CAST(s.total_stock * 1.0 /
      NULLIF(d.daily_rate, 0)
      AS DECIMAL(10,0)) <= 90
      THEN 'BALANCED'
    ELSE 'OVERSTOCK'
  END AS status
FROM supply s
LEFT JOIN demand d ON s.sku = d.sku
ORDER BY days_of_stock ASC;

--46) Which SKUs are out of stock? 

SELECT sku, warehouse,
  SUM(qty) AS total_qty
FROM fact_inventory
GROUP BY sku, warehouse
HAVING SUM(qty) = 0;

SELECT
    fs.sku,
    dp.category,
    dp.product_name,
    SUM(fs.qty)                    AS total_ever_sold,
    SUM(fs.qty * fs.selling_price) AS total_revenue_generated,
    MAX(fs.sale_date)              AS last_sold_date
FROM fact_sales fs
JOIN dim_products dp ON fs.sku = dp.sku
WHERE fs.sku NOT IN (
    SELECT DISTINCT sku FROM fact_inventory   
)
GROUP BY fs.sku, dp.category, dp.product_name
ORDER BY total_ever_sold DESC;


--47) What are the potential lost sales due to stockouts? 

SELECT
  fs.sku,
  SUM(fs.qty)                    AS lost_demand,
  SUM(fs.qty * fs.selling_price) AS lost_revenue
FROM fact_sales fs
LEFT JOIN Fact_inventory fi
  ON fs.sku = fi.sku
WHERE fi.sku IS NULL
GROUP BY fs.sku
ORDER BY lost_revenue DESC;

WITH sales_demand AS (
    SELECT
        sku,
        SUM(qty)                          AS total_sold,
        COUNT(DISTINCT sale_date)         AS active_days,
        CAST(SUM(qty) * 1.0 /
            NULLIF(COUNT(DISTINCT sale_date), 0)
        AS DECIMAL(10,2))                 AS daily_rate
    FROM fact_sales
    GROUP BY sku
),
current_stock AS (
    SELECT sku, SUM(qty) AS stock_qty
    FROM fact_inventory
    GROUP BY sku
)
SELECT
    sd.sku,
    dp.category,
    sd.total_sold,
    sd.daily_rate,
    ISNULL(cs.stock_qty, 0)               AS current_stock,
    CAST(ISNULL(cs.stock_qty, 0) * 1.0 /
        NULLIF(sd.daily_rate, 0)
    AS DECIMAL(10,0))                     AS days_of_stock_left,
    CAST(sd.daily_rate * dp.selling_price
    AS DECIMAL(12,2))                     AS daily_revenue_at_risk,
    CASE
        WHEN ISNULL(cs.stock_qty, 0) = 0
            THEN 'OUT OF STOCK — LOSING NOW'
        WHEN ISNULL(cs.stock_qty, 0) / NULLIF(sd.daily_rate, 0) < 7
            THEN 'CRITICAL — < 7 days left'
        WHEN ISNULL(cs.stock_qty, 0) / NULLIF(sd.daily_rate, 0) < 30
            THEN 'WARNING — < 30 days left'
        ELSE 'SAFE'
    END                                   AS stockout_risk
FROM sales_demand sd
JOIN dim_products dp ON sd.sku = dp.sku
LEFT JOIN current_stock cs ON sd.sku = cs.sku
WHERE ISNULL(cs.stock_qty, 0) = 0
   OR ISNULL(cs.stock_qty, 0) / NULLIF(sd.daily_rate, 0) < 30
ORDER BY daily_revenue_at_risk DESC;

--48) Which inventory is at high risk (ageing + expiry)? 

WITH risk_calc AS (
  SELECT
    fi.batch_id,
    fi.sku,
    fi.warehouse,
    fi.purchase_date,
    fi.expiry_date,
    fi.qty,
    fi.unit_cost,
    fi.qty * fi.unit_cost AS batch_value,

    -- Age days
    DATEDIFF(DAY,
      fi.purchase_date,
      cp.analysis_date) AS age_days,

    -- Days to expiry
    CASE
      WHEN fi.expiry_date IS NULL THEN NULL
      ELSE DATEDIFF(DAY,
        cp.analysis_date,
        fi.expiry_date)
    END AS days_to_expiry

  FROM fact_inventory fi
  CROSS JOIN control_panel cp
)
SELECT
  batch_id,
  sku,
  warehouse,
  purchase_date,
  expiry_date,
  qty,
  unit_cost,
  batch_value,
  age_days,
  days_to_expiry,

  -- Risk Level
  CASE
    -- CRITICAL: Old + Expiring soon
    WHEN age_days > 90
      AND days_to_expiry IS NOT NULL
      AND days_to_expiry <= 30
      THEN 'CRITICAL'

    -- CRITICAL: Already expired
    WHEN days_to_expiry IS NOT NULL
      AND days_to_expiry < 0
      THEN 'CRITICAL - EXPIRED'

    -- HIGH: Very old stock
    WHEN age_days > 90
      THEN 'HIGH - DEAD STOCK'

    -- HIGH: Near expiry
    WHEN days_to_expiry IS NOT NULL
      AND days_to_expiry <= 30
      THEN 'HIGH - NEAR EXPIRY'

    -- MEDIUM: Slow moving
    WHEN age_days BETWEEN 60 AND 90
      THEN 'MEDIUM - SLOW'

    -- MEDIUM: Expiry watch
    WHEN days_to_expiry IS NOT NULL
      AND days_to_expiry BETWEEN 31 AND 90
      THEN 'MEDIUM - EXPIRY WATCH'

    -- SAFE
    ELSE 'SAFE'
  END AS risk_level,

  -- Financial Impact
  CASE
    WHEN age_days > 90
      AND days_to_expiry IS NOT NULL
      AND days_to_expiry <= 30
      THEN batch_value
    WHEN days_to_expiry < 0
      THEN batch_value
    ELSE 0
  END AS at_risk_value

FROM risk_calc
ORDER BY
  CASE
    WHEN risk_level = 'CRITICAL' THEN 1
    WHEN risk_level = 'CRITICAL - EXPIRED' THEN 1
    WHEN risk_level = 'HIGH - DEAD STOCK' THEN 2
    WHEN risk_level = 'HIGH - NEAR EXPIRY' THEN 2
    WHEN risk_level = 'MEDIUM - SLOW' THEN 3
    WHEN risk_level = 'MEDIUM - EXPIRY WATCH' THEN 3
    ELSE 4
  END,
  batch_value DESC;

--49) How efficient is the purchase planning? 

WITH purch AS (
  SELECT sku,
    SUM(qty)       AS purchased,
    SUM(qty * cost) AS total_spend
  FROM fact_purchases
  GROUP BY sku
),
sales AS (
  SELECT sku,
    SUM(qty) AS total_sold
  FROM fact_sales
  GROUP BY sku
)
SELECT
  p.sku,
  p.purchased,
  p.total_spend,
  s.total_sold,
  p.purchased - s.total_sold AS excess,
  CAST(s.total_sold * 100.0 /
    NULLIF(p.purchased, 0)
  AS DECIMAL(10,1)) AS sell_through_pct
FROM purch p
JOIN sales s ON p.sku = s.sku
ORDER BY sell_through_pct desc;



--50) Which suppliers perform the best? 

SELECT
  supplier,
  COUNT(*)    AS total_orders,
  AVG(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS avg_lead_days,
  MIN(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS fastest_days,
  MAX(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS slowest_days
FROM fact_purchases
GROUP BY supplier
ORDER BY total_orders desc;


SELECT
  supplier,
  COUNT(*)    AS late_orders,
  AVG(DATEDIFF(DAY,purchase_date,
    delivery_date)) AS avg_delay_days
FROM fact_purchases
WHERE DATEDIFF(DAY,purchase_date,
  delivery_date) > 10
GROUP BY supplier
HAVING COUNT(*) >=2
ORDER BY late_orders  desc;

SELECT
    supplier,

    COUNT(*) AS total_orders,

    AVG(DATEDIFF(DAY, purchase_date, delivery_date))
        AS avg_lead_days,

    MIN(DATEDIFF(DAY, purchase_date, delivery_date))
        AS fastest_days,

    MAX(DATEDIFF(DAY, purchase_date, delivery_date))
        AS slowest_days,

    SUM(
        CASE
            WHEN DATEDIFF(DAY, purchase_date, delivery_date) > 10
            THEN 1
            ELSE 0
        END
    ) AS late_orders,

    CAST(
        SUM(
            CASE
                WHEN DATEDIFF(DAY, purchase_date, delivery_date) > 10
                THEN 1
                ELSE 0
            END
        ) * 100.0
        /
        COUNT(*)
    AS DECIMAL(10,2))
    AS late_order_pct,

    CASE
        WHEN AVG(DATEDIFF(DAY,purchase_date,delivery_date)) <= 5
             AND
             SUM(
                 CASE
                     WHEN DATEDIFF(DAY,purchase_date,delivery_date) > 10
                     THEN 1
                     ELSE 0
                 END
             ) = 0
        THEN 'EXCELLENT'

        WHEN AVG(DATEDIFF(DAY,purchase_date,delivery_date)) <= 10
        THEN 'GOOD'

        WHEN AVG(DATEDIFF(DAY,purchase_date,delivery_date)) <= 15
        THEN 'AVERAGE'

        ELSE 'POOR'
    END AS supplier_rating

FROM fact_purchases

GROUP BY supplier

ORDER BY
    late_order_pct ASC,
    avg_lead_days ASC;

    WITH lead_stats AS (
    SELECT
        AVG(CAST(DATEDIFF(DAY, purchase_date, delivery_date) AS FLOAT)) AS avg_lead,
        STDEV(DATEDIFF(DAY, purchase_date, delivery_date))               AS stdev_lead
    FROM fact_purchases
),
supplier_perf AS (
    SELECT
        fp.supplier,
        COUNT(*)                                                   AS total_orders,
        AVG(DATEDIFF(DAY, fp.purchase_date, fp.delivery_date))     AS avg_lead_days,
        MIN(DATEDIFF(DAY, fp.purchase_date, fp.delivery_date))     AS fastest_days,
        MAX(DATEDIFF(DAY, fp.purchase_date, fp.delivery_date))     AS slowest_days,
        SUM(CASE
                WHEN DATEDIFF(DAY, fp.purchase_date, fp.delivery_date)
                     > (ls.avg_lead + ls.stdev_lead)
                THEN 1 ELSE 0
            END)                                                   AS late_orders,
        CAST(
            SUM(CASE
                    WHEN DATEDIFF(DAY, fp.purchase_date, fp.delivery_date)
                         > (ls.avg_lead + ls.stdev_lead)
                    THEN 1 ELSE 0
                END) * 100.0 / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2))                                          AS late_order_pct,
        CAST(ls.avg_lead AS DECIMAL(10,1))                         AS overall_avg_lead
    FROM fact_purchases fp
    CROSS JOIN lead_stats ls
    GROUP BY fp.supplier, ls.avg_lead, ls.stdev_lead
)
SELECT
    supplier,
    total_orders,
    avg_lead_days,
    fastest_days,
    slowest_days,
    late_orders,
    late_order_pct,
    overall_avg_lead,
    CASE
        WHEN late_order_pct = 0
         AND avg_lead_days <= overall_avg_lead
            THEN 'EXCELLENT'   -- no late + faster than avg
        WHEN late_order_pct <= 15
            THEN 'GOOD'
        WHEN late_order_pct <= 30
            THEN 'AVERAGE'
        ELSE
            'POOR'
    END AS supplier_rating
FROM supplier_perf
ORDER BY late_order_pct ASC, avg_lead_days ASC;





🔥 LEVEL 5 — ADVANCED (Q51–Q60) 

--51) Is there a mismatch between purchases and inventory? 

WITH purch AS (
  SELECT sku,
    SUM(qty) AS purchased
  FROM fact_purchases
  GROUP BY sku
),
inv AS (
  SELECT sku,
    SUM(qty) AS in_stock
  FROM fact_inventory
  GROUP BY sku
)
SELECT
  p.sku,
  p.purchased,
  i.in_stock,
  p.purchased - i.in_stock AS mismatch,
  CAST(
    (p.purchased - i.in_stock) * 100.0 /
    NULLIF(p.purchased, 0)
  AS DECIMAL(10,1))         AS mismatch_pct
FROM purch p
JOIN inv i ON p.sku = i.sku
WHERE p.purchased - i.in_stock <> 0
ORDER BY mismatch desc;



--52) How does sales compare with inventory flow? 

SELECT
    fp.sku,
    fp.warehouse,

    SUM(fp.qty) AS stock_in,

    ISNULL(SUM(fs.qty),0) AS stock_out,

    SUM(fp.qty)
    -
    ISNULL(SUM(fs.qty),0)
    AS net_flow

FROM fact_purchases fp

LEFT JOIN fact_sales fs
    ON fp.sku = fs.sku
   AND fp.warehouse = fs.warehouse

GROUP BY
    fp.sku,
    fp.warehouse

ORDER BY net_flow DESC;



--53) How does FIFO logic apply to inventory consumption? 

SELECT
  batch_id,
  sku,
  warehouse,
  purchase_date,
  qty,
  unit_cost,
  ROW_NUMBER() OVER(
    PARTITION BY sku
    ORDER BY purchase_date ASC
  ) AS fifo_order
FROM fact_inventory
ORDER BY sku, fifo_order;

--54) What is the profit at batch level? 

WITH sku_sales AS (
  SELECT sku,
    SUM(qty)                 AS total_sold,
    SUM(qty * selling_price) AS sku_revenue
  FROM fact_sales
  GROUP BY sku
),
batch_ordered AS (
  SELECT
    batch_id, sku, warehouse,
    purchase_date, expiry_date,
    qty AS batch_qty, unit_cost,
    SUM(qty) OVER(
      PARTITION BY sku
      ORDER BY purchase_date
      ROWS UNBOUNDED PRECEDING
    ) AS cumulative_qty
  FROM fact_inventory
),
fifo_calc AS (
  SELECT
    bo.*,
    ss.total_sold,
    ss.sku_revenue,
    CASE
      WHEN ISNULL(ss.total_sold,0)
        >= bo.cumulative_qty
        THEN bo.batch_qty
      WHEN ISNULL(ss.total_sold,0)
        > bo.cumulative_qty - bo.batch_qty
        THEN ISNULL(ss.total_sold,0)
          - (bo.cumulative_qty - bo.batch_qty)
      ELSE 0
    END AS batch_sold_qty
  FROM batch_ordered bo
  LEFT JOIN sku_sales ss ON bo.sku = ss.sku
)
SELECT
  batch_id,
  sku,
  warehouse,
  purchase_date,
  expiry_date,

  -- Inventory qty
  batch_qty        AS inventory_qty,
  unit_cost,
  batch_qty * unit_cost AS batch_cost,

  -- Sales qty FIFO
  batch_sold_qty   AS sold_qty,
  batch_qty - batch_sold_qty AS remaining_qty,

  -- Revenue proportional
  sku_revenue * (batch_sold_qty * 1.0 /
    NULLIF(total_sold, 0))
    AS batch_revenue,

  -- Profit
  sku_revenue * (batch_sold_qty * 1.0 /
    NULLIF(total_sold, 0))
    - batch_qty * unit_cost
    AS batch_profit

FROM fifo_calc
ORDER BY batch_profit DESC;

--55) How is stock movement tracked over time? 

SELECT
  sku,
  warehouse,
  movement_type,
  qty,
  movement_date,
  SUM(CASE
    WHEN movement_type = 'IN'
      THEN qty
    ELSE -qty
  END) OVER(
    PARTITION BY sku, warehouse
    ORDER BY movement_date
    ROWS UNBOUNDED PRECEDING
  ) AS running_balance

FROM (

  -- Stock IN from inventory
  SELECT
    sku,
    warehouse,
    'IN'             AS movement_type,
    qty,
    purchase_date    AS movement_date
  FROM fact_inventory

  UNION ALL

  -- Stock OUT from sales
  SELECT
    sku,
    warehouse,
    'OUT'            AS movement_type,
    qty,
    sale_date        AS movement_date
  FROM fact_sales

) AS all_movements

ORDER BY
  sku,
  warehouse,
  movement_date;


--56) What is the forecasted inventory demand? 

WITH sales_summary AS (
  SELECT
    sku,
    SUM(qty)          AS total_sold,
    MIN(sale_date)    AS first_sale,
    MAX(sale_date)    AS last_sale,

    -- Total months
    DATEDIFF(MONTH,
      MIN(sale_date),
      MAX(sale_date)) + 1
      AS total_months,

    -- Monthly avg
    CAST(SUM(qty) * 1.0 /
      NULLIF(
        DATEDIFF(MONTH,
          MIN(sale_date),
          MAX(sale_date)) + 1
      , 0)
    AS DECIMAL(10,2)) AS monthly_avg

  FROM fact_sales
  GROUP BY sku
)

SELECT
  sku,
  total_sold,
  first_sale,
  last_sale,
  total_months,
  monthly_avg,

  -- Forecast next 1 month
  CAST(monthly_avg * 1
  AS DECIMAL(10,0))   AS forecast_1_month,

  -- Forecast next 3 months
  CAST(monthly_avg * 3
  AS DECIMAL(10,0))   AS forecast_3_months,

  -- Forecast next 6 months
  CAST(monthly_avg * 6
  AS DECIMAL(10,0))   AS forecast_6_months,

  -- Forecast next 12 months
  CAST(monthly_avg * 12
  AS DECIMAL(10,0))   AS forecast_12_months

FROM sales_summary
ORDER BY monthly_avg DESC;


--57) What is the reorder point for each SKU? 

WITH daily_demand AS (
  SELECT
    sku,
    SUM(qty)                  AS total_sold,
    COUNT(DISTINCT sale_date) AS active_days,
    CAST(SUM(qty) * 1.0 /
      NULLIF(COUNT(DISTINCT sale_date), 0)
    AS DECIMAL(10,2))         AS daily_rate
  FROM fact_sales
  GROUP BY sku
),

lead_time AS (
  SELECT
    sku,
    AVG(DATEDIFF(DAY,
      purchase_date,
      delivery_date))         AS avg_lead_days
  FROM fact_purchases
  GROUP BY sku
)

SELECT
  dd.sku,
  dd.total_sold,
  dd.active_days,
  dd.daily_rate,
  lt.avg_lead_days,

  -- Reorder Point
  CAST(dd.daily_rate * lt.avg_lead_days
  AS DECIMAL(10,0))           AS reorder_point,

  -- Current stock
  fi.current_stock,

  -- Status
  CASE
    WHEN fi.current_stock <=
      CAST(dd.daily_rate * lt.avg_lead_days
      AS DECIMAL(10,0))
      THEN 'REORDER NOW!'
    ELSE 'SUFFICIENT'
  END AS stock_status

FROM daily_demand dd
JOIN lead_time lt
  ON dd.sku = lt.sku
JOIN (
  SELECT sku,
    SUM(qty) AS current_stock
  FROM fact_inventory
  GROUP BY sku
) fi ON dd.sku = fi.sku

ORDER BY reorder_point DESC;

--58) What is the required safety stock level? 

WITH daily_sales AS (
  SELECT
    sku,
    sale_date,
    SUM(qty) AS daily_qty
  FROM fact_sales
  GROUP BY sku, sale_date
),

demand_stats AS (
  SELECT
    sku,
    AVG(daily_qty)  AS avg_daily_demand,
    STDEV(daily_qty) AS stdev_demand
  FROM daily_sales
  GROUP BY sku
),

lead_time AS (
  SELECT
    sku,
    AVG(DATEDIFF(DAY,
      purchase_date,
      delivery_date)) AS avg_lead_days
  FROM fact_purchases
  GROUP BY sku
)

SELECT
  ds.sku,
  CAST(ds.avg_daily_demand
    AS DECIMAL(10,2))   AS avg_daily_demand,
  CAST(ds.stdev_demand
    AS DECIMAL(10,2))   AS stdev_demand,
  lt.avg_lead_days,

  -- Safety Stock Formula
  CAST(
    1.65
    * ds.stdev_demand
    * SQRT(lt.avg_lead_days)
  AS DECIMAL(10,0))     AS safety_stock,

  -- Reorder Point with Safety Stock
  CAST(
    (ds.avg_daily_demand * lt.avg_lead_days)
    +
    (1.65 * ds.stdev_demand
      * SQRT(lt.avg_lead_days))
  AS DECIMAL(10,0))     AS reorder_point_with_safety,

  -- Current Stock
  fi.current_stock,

  -- Status
  CASE
    WHEN fi.current_stock <=
      CAST(
        (ds.avg_daily_demand * lt.avg_lead_days)
        +
        (1.65 * ds.stdev_demand
          * SQRT(lt.avg_lead_days))
      AS DECIMAL(10,0))
      THEN 'REORDER NOW!'
    ELSE 'SUFFICIENT'
  END AS stock_status

FROM demand_stats ds
JOIN lead_time lt
  ON ds.sku = lt.sku
JOIN (
  SELECT sku,
    SUM(qty) AS current_stock
  FROM fact_inventory
  GROUP BY sku
) fi ON ds.sku = fi.sku

ORDER BY safety_stock DESC;

--59) How are SKUs classified using ABC analysis? 

WITH revenue AS (
  SELECT
    sku,
    SUM(qty * selling_price) AS total_revenue
  FROM fact_sales
  GROUP BY sku
),

cumulative AS (
  SELECT
    sku,
    total_revenue,
    SUM(total_revenue) OVER(
      ORDER BY total_revenue DESC
    ) AS cumulative_revenue,
    SUM(total_revenue) OVER() AS total_all
  FROM revenue
)

SELECT
  sku,
  total_revenue,
  CAST(total_revenue * 100.0 /
    total_all
  AS DECIMAL(10,2))       AS revenue_pct,
  CAST(cumulative_revenue * 100.0 /
    total_all
  AS DECIMAL(10,2))       AS cumulative_pct,

  -- ABC Classification
  CASE
    WHEN cumulative_revenue * 100.0 /
      total_all <= 80
      THEN 'A - STAR'
    WHEN cumulative_revenue * 100.0 /
      total_all <= 95
      THEN 'B - NORMAL'
    ELSE 'C - TAIL'
  END AS abc_class

FROM cumulative
ORDER BY total_revenue DESC;

--60) Can we trace the full lifecycle (purchase → inventory → sale)? 

WITH purchase_summary AS (
  SELECT
    sku,
    COUNT(*)              AS total_orders,
    SUM(qty)              AS total_purchased,
    AVG(cost)             AS avg_purchase_cost,
    SUM(qty * cost)       AS total_purchase_value,
    MIN(purchase_date)    AS first_purchase_date,
    MAX(delivery_date)    AS last_delivery_date
  FROM fact_purchases
  GROUP BY sku
),

inventory_summary AS (
  SELECT
    sku,
    COUNT(*)              AS total_batches,
    SUM(qty)              AS current_stock,
    AVG(unit_cost)        AS avg_unit_cost,
    SUM(qty * unit_cost)  AS stock_value,
    MIN(purchase_date)    AS oldest_batch,
    MAX(purchase_date)    AS newest_batch
  FROM fact_inventory
  GROUP BY sku
),

sales_summary AS (
  SELECT
    sku,
    SUM(qty)              AS total_sold,
    SUM(qty * selling_price) AS total_revenue,
    AVG(selling_price)    AS avg_selling_price,
    MIN(sale_date)        AS first_sale_date,
    MAX(sale_date)        AS last_sale_date,
    COUNT(DISTINCT sale_date) AS active_sale_days
  FROM fact_sales
  GROUP BY sku
)

SELECT
  -- Identity
  p.sku,

  -- Purchase Info
  p.total_orders,
  p.total_purchased,
  p.avg_purchase_cost,
  p.total_purchase_value,
  p.first_purchase_date,
  p.last_delivery_date,

  -- Inventory Info
  i.total_batches,
  i.current_stock,
  i.avg_unit_cost,
  i.stock_value,
  i.oldest_batch,
  i.newest_batch,

  -- Sales Info
  ISNULL(s.total_sold, 0)       AS total_sold,
  ISNULL(s.total_revenue, 0)    AS total_revenue,
  s.avg_selling_price,
  s.first_sale_date,
  s.last_sale_date,
  s.active_sale_days,

  -- Lifecycle Calculations
  ISNULL(p.total_purchased, 0)
    - ISNULL(s.total_sold, 0)   AS unsold_qty,

  CAST(
    ISNULL(s.total_sold, 0) * 100.0 /
    NULLIF(p.total_purchased, 0)
  AS DECIMAL(10,1))             AS sell_through_pct,

  -- Profit
  ISNULL(s.total_revenue, 0)
    - p.total_purchase_value    AS total_profit,

  CAST(
    (ISNULL(s.total_revenue, 0)
      - p.total_purchase_value) * 100.0 /
    NULLIF(s.total_revenue, 0)
  AS DECIMAL(10,1))             AS profit_margin_pct,

  -- Days from purchase to first sale
  DATEDIFF(DAY,
    p.first_purchase_date,
    s.first_sale_date)          AS days_to_first_sale,

  -- Lifecycle Status
  CASE
    WHEN s.total_sold IS NULL
      THEN 'NEVER SOLD'
    WHEN i.current_stock = 0
      THEN 'FULLY LIQUIDATED'
    WHEN CAST(
      ISNULL(s.total_sold, 0) * 100.0 /
      NULLIF(p.total_purchased, 0)
      AS DECIMAL(10,1)) >= 80
      THEN 'HIGH SELL THROUGH'
    WHEN CAST(
      ISNULL(s.total_sold, 0) * 100.0 /
      NULLIF(p.total_purchased, 0)
      AS DECIMAL(10,1)) >= 50
      THEN 'MODERATE SELL THROUGH'
    ELSE 'LOW SELL THROUGH'
  END AS lifecycle_status

FROM purchase_summary p
LEFT JOIN inventory_summary i
  ON p.sku = i.sku
LEFT JOIN sales_summary s
  ON p.sku = s.sku

ORDER BY total_profit DESC;




