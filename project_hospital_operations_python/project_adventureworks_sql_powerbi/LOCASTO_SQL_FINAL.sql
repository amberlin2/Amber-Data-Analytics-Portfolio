--Amber Locasto SQL Final Project--
--SETTING UP TABLE CREATION--
DROP TABLE IF EXISTS 
    sales_order_data, 
    sales_data, 
    reseller_data, 
    customer_data, 
    product_data, 
    sales_territory_data, 
    date_data 
CASCADE;

--DATE TABLE--
CREATE TABLE date_data (
    DateKey INTEGER PRIMARY KEY,
    "Date" DATE,
    Fiscal_Year TEXT,
    Fiscal_Quarter TEXT,
    Month TEXT,
    Full_Date TEXT,
    MonthKey INTEGER
);

--PRODUCT TABLE--
CREATE TABLE product_data (
    ProductKey INTEGER PRIMARY KEY,
    SKU TEXT,
    Product TEXT,
    Standard_Cost NUMERIC(12,2),
    Color TEXT,
    List_Price NUMERIC(12,2),
    Model TEXT,
    Subcategory TEXT,
    Category TEXT
);

--RESELLER TABLE--
CREATE TABLE reseller_data (
    ResellerKey INTEGER PRIMARY KEY,
    Reseller_ID TEXT,
    Business_Type TEXT,
    Reseller TEXT,
    City TEXT,
    State_Province TEXT,
    Country_Region TEXT,
    Postal_Code TEXT
);

--CUSTOMER TABLE--
CREATE TABLE customer_data (
    CustomerKey INTEGER PRIMARY KEY,
    Customer_ID TEXT,
    Customer TEXT,
    City TEXT,
    State_Province TEXT,
    Country_Region TEXT,
    Postal_Code TEXT
);

--SALES TERRITORY TABLE--
CREATE TABLE sales_territory_data (
    SalesTerritoryKey INTEGER PRIMARY KEY,
    Region TEXT,
    Country TEXT,
    "Group" TEXT
);

--SALES TABLE--
CREATE TABLE sales_data (
    SalesOrderLineKey INTEGER PRIMARY KEY,
    ResellerKey INTEGER,
    CustomerKey INTEGER,
    ProductKey INTEGER,
    OrderDateKey INTEGER,
    DueDateKey INTEGER,
    ShipDateKey INTEGER,
    SalesTerritoryKey INTEGER,
    Order_Quantity INTEGER,
    Unit_Price NUMERIC(12,2),
    Extended_Amount NUMERIC(12,2),
    Unit_Price_Discount_Pct NUMERIC(5,2),
    Product_Standard_Cost NUMERIC(12,2),
    Total_Product_Cost NUMERIC(12,2),
    Sales_Amount NUMERIC(12,2)
);

--SALES ORDER TABLE--
CREATE TABLE sales_order_data (
    Channel TEXT,
    SalesOrderLineKey INTEGER,
    Sales_Order TEXT,
    Sales_Order_Line TEXT
);

-- ===============================
-- Verification
-- ===============================
SELECT * FROM date_data;
SELECT * FROM product_data;
SELECT * FROM reseller_data;
SELECT * FROM sales_territory_data;
SELECT * FROM sales_data;
SELECT * FROM sales_order_data;
SELECT * FROM customer_data;

--adding foreign keys after loading data--
--ALTER TABLE sales_data
--ADD FOREIGN KEY (ResellerKey) REFERENCES reseller_data(ResellerKey),
--ADD FOREIGN KEY (CustomerKey)  REFERENCES customer_data(CustomerKey),
--ADD FOREIGN KEY (ProductKey)   REFERENCES product_data(ProductKey),
--ADD FOREIGN KEY (OrderDateKey) REFERENCES date_data(DateKey),
--ADD FOREIGN KEY (DueDateKey)   REFERENCES date_data(DateKey),
--ADD FOREIGN KEY (ShipDateKey)  REFERENCES date_data(DateKey),
--ADD FOREIGN KEY (SalesTerritoryKey) REFERENCES sales_territory_data(SalesTerritoryKey);

--ALTER TABLE sales_order_data
--ADD FOREIGN KEY (SalesOrderLineKey) REFERENCES sales_data(SalesOrderLineKey);
--skipping foreign keys to keep our tables satisfied--


--CORE ANALYSIS QUESTIONS--

--Q1: Total sales by product in descending order--
EXPLAIN ANALYZE
SELECT
    p.Product,
    p.Subcategory,
    p.Category,
    ROUND(SUM(s.Sales_Amount), 2) AS total_sales
FROM sales_data s
JOIN product_data p
    ON s.ProductKey = p.ProductKey
GROUP BY p.Product, p.Subcategory, p.Category
ORDER BY total_sales DESC;

--Q2: Top 10 customers by total purchase amount--
SELECT
	c.Customer,
	ROUND(SUM(s.Sales_Amount), 2) AS total_spent
FROM sales_data s
JOIN customer_data c ON s.CustomerKey = c.CustomerKey
GROUP BY c.Customer
ORDER BY total_spent DESC
LIMIT 10;

--what data types--
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'date_data';

--looking at our years--
SELECT DISTINCT EXTRACT(YEAR FROM "Date") AS year
FROM date_data
ORDER BY year;
--2021 is latest year

SELECT 
    s.SalesOrderLineKey,
    d."Date" AS order_date,
    s.Sales_Amount
FROM sales_data s
JOIN date_data d ON s.OrderDateKey = d.DateKey
WHERE EXTRACT(YEAR FROM d."Date") = 2021
ORDER BY d."Date"
LIMIT 50;
--there is no data in 2021

--Q3: Monthly sales totals for the most recent year--
SELECT
    TO_CHAR(DATE_TRUNC('month', d."Date"), 'YYYY-MM') AS month,
    SUM(s.Sales_Amount) AS total_sales
FROM sales_data s
JOIN date_data d ON s.OrderDateKey = d.DateKey
WHERE EXTRACT(YEAR FROM d."Date") = (
    SELECT MAX(EXTRACT(YEAR FROM d2."Date"))
    FROM sales_data s2
    JOIN date_data d2 ON s2.OrderDateKey = d2.DateKey
)
GROUP BY DATE_TRUNC('month', d."Date")
ORDER BY month;
--2020 latest year

--checking the join worked(sanity)--
SELECT COUNT(*) 
FROM sales_data s
JOIN date_data d ON s.OrderDateKey = d.DateKey;
--above we join sales_data and date_data tables
--filter for only the latest year found in our dat table
--group by month
--sum the sales_amount for that month
--order our month chronologically

--sanity check
SELECT 
    d."Date"
FROM date_data d
JOIN sales_data s ON s.OrderDateKey = d.DateKey
ORDER BY d."Date"
LIMIT 200;


--Q4: sales by region--
SELECT
	strd.Region,
	ROUND(SUM(s.Sales_Amount), 2) AS total_sales
FROM sales_data s
JOIN sales_territory_data strd ON s.SalesTerritoryKey = strd.SalesTerritoryKey
GROUP BY strd.Region
ORDER BY total_sales DESC;

--Q5: Average order value per customer--
SELECT
  c.Customer,
  ROUND(AVG(s.Sales_Amount), 2) AS avg_order_value
FROM sales_data s
JOIN customer_data c ON s.CustomerKey = c.CustomerKey
GROUP BY c.Customer
ORDER BY avg_order_value DESC;


--ADVANCED ANALYTICS--

--Practicing a CTE before using it--
WITH customer_sales AS (
	SELECT * FROM customer_data
) --end CTE--
--now use CTE--
SELECT * FROM customer_sales;
--basically just a place holder to create a table containing whatever we want and call it later--

--Q1: Top 3 products per catagory--
WITH product_sales AS ( ---Using a CTE to organize data---
  SELECT
    p.Category,
    p.Product,
    SUM(s.Sales_Amount) AS total_sales
  FROM sales_data s
  JOIN product_data p ON s.ProductKey = p.ProductKey
  GROUP BY p.Category, p.Product
), --calculated the total sale by category--
ranked AS (
  SELECT *,
         DENSE_RANK() OVER (PARTITION BY Category ORDER BY total_sales DESC) AS rnk
  FROM product_sales
) -- ranked logic applied--
SELECT Category, Product, total_sales
FROM ranked
WHERE rnk <= 3
ORDER BY Category, rnk, total_sales DESC;

--running a sanity check for dates--
SELECT 
    COUNT(DISTINCT s."orderdatekey") AS distinct_order_dates,
    MIN(s."orderdatekey") AS min_order_datekey,
    MAX(s."orderdatekey") AS max_order_datekey
FROM sales_data s;

--Q2: Running cumulative total of monthly sales--
-- Cumulative monthly sales in chronological order
SELECT 
    DATE_TRUNC('month', d."Date"::date) AS month_start,
    SUM(s.Sales_Amount) AS month_sales,
    SUM(SUM(s.Sales_Amount)) OVER (
        ORDER BY DATE_TRUNC('month', d."Date"::date)
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_sales
FROM sales_data s
JOIN date_data d 
    ON s.OrderDateKey = d.DateKey
GROUP BY DATE_TRUNC('month', d."Date"::date)
ORDER BY month_start;

--unique months--
SELECT DISTINCT DATE_TRUNC('month', d."Date"::date)
FROM sales_data s
JOIN date_data d ON s.OrderDateKey = d.DateKey;

--running some sanity checks--
SELECT MIN("Date"), MAX("Date"), COUNT(*)
FROM date_data;
--range is 2017-2021

SELECT MIN(OrderDateKey), MAX(OrderDateKey)
FROM sales_data;
--min is 2020--

SELECT MIN(DateKey), MAX(DateKey)
FROM date_data;
--min is 2017

--Q3: Top 5 resellers per region by total sales--
WITH reseller_totals AS ( --CTE--
  SELECT
    t.Region,                              -- region from territory table
    r.Reseller,                            -- reseller name
    SUM(s.Sales_Amount) AS total_sales
  FROM sales_data s
  JOIN reseller_data r        ON s.ResellerKey       = r.ResellerKey
  JOIN sales_territory_data t ON s.SalesTerritoryKey = t.SalesTerritoryKey
  GROUP BY t.Region, r.Reseller
),
ranked AS (
  SELECT
    Region,
    Reseller,
    total_sales,
    DENSE_RANK() OVER (
      PARTITION BY Region
      ORDER BY total_sales DESC
    ) AS rnk
  FROM reseller_totals
)
SELECT Region, Reseller, total_sales
FROM ranked
WHERE rnk <= 5
ORDER BY Region, total_sales DESC;

--Q4: Revenue percentiles--
SELECT
  PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY s.Sales_Amount) AS p50,
  PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY s.Sales_Amount) AS p75,
  PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY s.Sales_Amount) AS p90,
  PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY s.Sales_Amount) AS p95
FROM sales_data s;

--Q5: recrusive CTE--
WITH RECURSIVE product_tree AS (

    -- Level 1: distinct categories
    SELECT 
        DISTINCT Category,
        Subcategory,
        NULL::TEXT AS Product,
        1 AS level
    FROM product_data

    UNION ALL

    -- Level 2 → Level 3: Attach products to each (category, subcategory)
    SELECT
        pt.Category,
        pt.Subcategory,
        p.Product,
        2 AS level
    FROM product_tree pt
    JOIN product_data p
        ON p.Category = pt.Category
       AND p.Subcategory = pt.Subcategory
    WHERE pt.level = 1
)

SELECT 
    level,
    Category,
    Subcategory,
    Product
FROM product_tree
ORDER BY Category, Subcategory, level, Product;

 --Q6-- 
--useful indexes--
CREATE INDEX idx_sales_productkey ON sales_data(ProductKey);
CREATE INDEX idx_sales_customerkey ON sales_data(CustomerKey);
CREATE INDEX idx_sales_resellerkey ON sales_data(ResellerKey);
CREATE INDEX idx_sales_orderdatekey ON sales_data(OrderDateKey);
CREATE INDEX idx_sales_salesterritorykey ON sales_data(SalesTerritoryKey);

 --Q7: Create a View for Monthly Sales by Region--
  --two types I will create--
 -- Logical (always fresh when queried) view
 --gives us a prebuilt monthy sales total per region--
CREATE OR REPLACE VIEW v_monthly_sales_by_region AS
SELECT
    DATE_TRUNC('month', d."Date") AS month_start,
    t.Region,
    SUM(s.Sales_Amount) AS total_sales
FROM sales_data s
JOIN date_data d
    ON s.OrderDateKey = d.DateKey
JOIN sales_territory_data t
    ON s.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY DATE_TRUNC('month', d."Date"), t.Region;

--use view--
SELECT * FROM v_monthly_sales_by_region;

--using view with filters--
SELECT *
FROM v_monthly_sales_by_region
WHERE Region = 'Northwest'
ORDER BY month_start;

--MATERIALIZED VIEW--
--stores results, faster, must be refreshed manually--
CREATE MATERIALIZED VIEW mv_monthly_sales_by_region AS
SELECT
  DATE_TRUNC('month', d."Date") AS month_start,
  strd.Region,
  SUM(s.Sales_Amount) AS total_sales
FROM sales_data s
JOIN date_data d            ON s.OrderDateKey       = d.DateKey
JOIN sales_territory_data strd ON s.SalesTerritoryKey  = strd.SalesTerritoryKey
GROUP BY DATE_TRUNC('month', d."Date"), strd.Region
WITH NO DATA; --structure first then fill--

--fill--
--useful for when we do not want to run the select yet and want to refresh or add to it first--
REFRESH MATERIALIZED VIEW mv_monthly_sales_by_region;

--view--
SELECT * FROM mv_monthly_sales_by_region;


--Q8: function to summarize sales for product/date range--
CREATE OR REPLACE FUNCTION fn_product_sales_summary(
    p_product_key INTEGER,
    p_start DATE,
    p_end DATE
)
RETURNS TABLE (
    product_name TEXT,
    total_quantity INTEGER,
    total_sales NUMERIC(12,2),
    avg_price NUMERIC(12,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.Product AS product_name,
        SUM(s.Order_Quantity)::INT AS total_quantity,
        SUM(s.Sales_Amount)::NUMERIC(12,2) AS total_sales,
        AVG(s.Unit_Price)::NUMERIC(12,2) AS avg_price
    FROM sales_data s
    JOIN product_data p ON s.ProductKey = p.ProductKey
    JOIN date_data d ON s.OrderDateKey = d.DateKey
    WHERE s.ProductKey = p_product_key
      AND d."Date" BETWEEN p_start AND p_end
    GROUP BY p.Product;
END;
$$;

--example calls--
SELECT *
FROM fn_product_sales_summary(214, '2020-06-01', '2020-12-31');


--Q9: Using ROLLUP for subtotals and grand totals--
SELECT
    t.Region,
    p.Category,
    SUM(s.Sales_Amount) AS total_sales
FROM sales_data s
JOIN product_data p ON s.ProductKey = p.ProductKey
JOIN sales_territory_data t ON s.SalesTerritoryKey = t.SalesTerritoryKey
GROUP BY ROLLUP (t.Region, p.Category)
ORDER BY t.Region, p.Category;

--Q10: Read only --
-- 1. Create the reporting user
CREATE ROLE BIalinlocasto LOGIN PASSWORD 'Rangers24!';

-- 2. Allow the user to connect to the database
GRANT CONNECT ON DATABASE adventureworks_db TO BIalinlocasto;

-- 3. Allow the user to see and use the public schema
GRANT USAGE ON SCHEMA public TO BIalinlocasto;

-- 4. Give SELECT (read-only) access to ALL existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO BIalinlocasto;

-- 5. Ensure all FUTURE tables also grant SELECT automatically
ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT ON TABLES TO BIalinlocasto;

--using this for my POWER BI access--


SELECT rolname, rolpassword IS NOT NULL AS has_password
FROM pg_authid
WHERE rolname = 'bialinlocasto';

ALTER ROLE bialinlocasto WITH PASSWORD 'Rangers24!';






--for BI tables--

CREATE TABLE stg_date_data (
    DateKey INTEGER PRIMARY KEY,
    "Date" DATE NOT NULL,
    Fiscal_Year TEXT,
    Fiscal_Quarter TEXT,
    Month TEXT,
    Full_Date TEXT,
    MonthKey INTEGER
);

CREATE TABLE stg_product_data (
    ProductKey INTEGER PRIMARY KEY,
    SKU TEXT,
    Product TEXT,
    Standard_Cost NUMERIC(12,2),
    Color TEXT,
    List_Price NUMERIC(12,2),
    Model TEXT,
    Subcategory TEXT,
    Category TEXT
);


CREATE TABLE stg_reseller_data (
    ResellerKey INTEGER PRIMARY KEY,
    Reseller_ID TEXT,
    Business_Type TEXT,
    Reseller TEXT,
    City TEXT,
    State_Province TEXT,
    Country_Region TEXT,
    Postal_Code TEXT
);


CREATE TABLE stg_customer_data (
    CustomerKey INTEGER PRIMARY KEY,
    Customer_ID TEXT,
    Customer TEXT,
    City TEXT,
    State_Province TEXT,
    Country_Region TEXT,
    Postal_Code TEXT
);


CREATE TABLE stg_sales_territory_data (
    SalesTerritoryKey INTEGER PRIMARY KEY,
    Region TEXT,
    Country TEXT,
    "Group" TEXT
);

CREATE TABLE stg_sales_data (
    SalesOrderLineKey INTEGER PRIMARY KEY,
    ResellerKey INTEGER,
    CustomerKey INTEGER,
    ProductKey INTEGER,
    OrderDateKey INTEGER,
    DueDateKey INTEGER,
    ShipDateKey INTEGER,
    SalesTerritoryKey INTEGER,
    Order_Quantity INTEGER,
    Unit_Price NUMERIC(12,2),
    Extended_Amount NUMERIC(12,2),
    Unit_Price_Discount_Pct NUMERIC(5,2),
    Product_Standard_Cost NUMERIC(12,2),
    Total_Product_Cost NUMERIC(12,2),
    Sales_Amount NUMERIC(12,2)
);


CREATE TABLE stg_sales_order_data (
    SalesOrderLineKey INTEGER PRIMARY KEY,
    Channel TEXT,
    Sales_Order TEXT,
    Sales_Order_Line TEXT
);

SELECT * FROM sales_order_data;

SELECT * FROM stg_sales_data;
