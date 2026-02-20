/* ============================================================
   PROJECT: ZEPTO INVENTORY & PRODUCT PRICING ANALYSIS
   AUTHOR: Tejeendra Arragudla
   OBJECTIVE:
   - Analyze category revenue performance
   - Identify high value products
   - Understand pricing patterns
   - Generate business recommendations

   DATASET: zepto
   ============================================================ */
   
/* ============================================================
   STEP 1: DATABASE SETUP
   - Setting Up MYSQL Workbench
   - Create A New Schema
   - Creating a Table 
   ============================================================ */

CREATE DATABASE zepto_SQL_project;
USE zepto_sql_project;

/* ROWS AND COLOUMNS:
1. sku_id
2. category
3. name
4. mrp
5. discountPercent
6. availableQuantity
7. discountedSellingPrice
8. weightInGms
9. outOfStock
10.quantity
*/

CREATE TABLE zepto (
    sku_id INT NOT NULL AUTO_INCREMENT,
    category VARCHAR(120),
    name VARCHAR(150) NOT NULL,
    mrp DECIMAL(8,2),
    discountPercent DECIMAL(5,2),
    availableQuantity INT,
    discountedSellingPrice DECIMAL(8,2),
    weightInGms INT,
    outOfStock TINYINT,
    quantity INT,
    PRIMARY KEY (sku_id)
);

/* ============================================================
   STEP 2: RAW DATA VALIDATION
   - Structure CheckUp
   - Sample Data Check
   - Record Count 
   ============================================================ */

DESCRIBE zepto;

SELECT * FROM zepto
LIMIT 10;

SELECT COUNT(*)
FROM zepto;

/* ============================================================
   STEP 3: DATA CLEANING AND STANDARDIZATION
   - Null Values
   - Incorrect Values
   - Remove Invalid Records
   - Remove Duplicates
   - Create Derieved Columns
   - Rename Columns
   ============================================================ */

SELECT * FROM zepto
WHERE name IS NULL OR 
category IS NULL OR
mrp IS NULL OR 
discountPercent IS NULL OR 
discountedSellingPrice IS NULL OR 
weightInGms IS NULL OR
availableQuantity IS NULL OR
outOfStock IS NULL OR 
quantity IS NULL;

SELECT * FROM zepto
WHERE mrp = 0 OR discountedSellingPrice = 0;
-- Output: Home & Cleaning -- Cherry Blossom Liquid Shoe Polish Neutral Existed with mrp = 0 So, We Deleted It..

-- SAFE UPDATE OFF
SET SQL_SAFE_UPDATES = 0;

DELETE FROM zepto
WHERE mrp = 0;
-- Deleted MRP = 0...

UPDATE zepto
SET mrp = mrp/100.0,
discountedSellingPrice = discountedSellingPrice/100.0;

ALTER TABLE zepto
CHANGE COLUMN name product VARCHAR(150);

-- ==========================================================
-- PHASE 1 : BUSINESS INSIGHTS
-- ==========================================================

/* Exploratory Data Analysis (EDA) */

/* KPI Metrics 
   - Total Inventory Value
   - Total Number Of Products
   - Average Discount percentage
   - Total Available Stocks Available
   - Count Of outOfStock
   - Count of Instock
*/

-- Total Inventory Value

SELECT 
	SUM(discountedSellingPrice * availableQuantity) Total_Inventory_Value
FROM zepto;

-- Total Number Of Products

SELECT 
	COUNT(DISTINCT product) Total_Products
FROM zepto;

-- Average Discount percentage Of DiscountPercent of Products

SELECT 
	AVG(discountPercent) AS Average_Discount_Percentage
FROM zepto;

-- Total Available Stocks Available

SELECT 
	SUM(availableQuantity) Total_Units
FROM zepto;

-- Count Of out-Of-Stock Units

SELECT 
	COUNT(*) Count_outOfStock
FROM zepto
WHERE outOfStock = 0;

-- Total Count Of In-Stock Units

SELECT 
	COUNT(*) Count_InStock
FROM zepto
WHERE outOfStock = 1;

/* ================================================================================
                                KPI METRICS ANALYSIS
================================================================================
- Total Inventory Value        : 224,308,060 (Potential Revenue from current stock)
- Total Number Of Products     : 1,674 (Unique Items)
- Average Discount Percentage  : 7.62%
- Total Available Stocks       : 14,945 Units
- Count Of Out Of Stock        : 453 Products
- Count of In Stock            : 3,274 Products

[INSIGHT] 
Average discount is relatively low (7.6%), suggesting a stable pricing strategy. 
Roughly 12% of total listed items are currently out of stock.

[BUSINESS RECOMMENDATION] 
Prioritize restocking the 453 out-of-stock items to prevent lost sales. 
Review if the 7.6% discount is competitive enough to drive higher volume.
*/

/* CATEGORY LEVEL ANALYSIS

   - Types Of Categories
   - Count Of Products In Each Categories
   - Categories with highest-revenue
   - Category Contribution Percentage
   - Which Category has Highest Average Selling Price
   - Category has many low-stock Products
*/

-- Types Of Categories

SELECT DISTINCT category
FROM zepto;

-- Count Of Products In Each Categories

SELECT 
	COUNT(*) Products_in_each_category, category
FROM zepto
GROUP BY category
ORDER BY Products_in_each_category DESC;

-- Categories with Highest-Revenue

SELECT 
	SUM(discountedSellingPrice * availableQuantity) Highest_Revenue, category
FROM zepto
GROUP BY category
ORDER BY Highest_Revenue DESC;

-- Categories Contribution By Percentage

SELECT category, 
	SUM(discountedSellingPrice * availableQuantity) * 100.0 / SUM(SUM(discountedSellingPrice * availableQuantity)) OVER () AS contribution_pct
FROM zepto
GROUP BY category
ORDER BY contribution_pct DESC;

-- Which Categories has Highest Average Selling Price

SELECT category,
	AVG(discountedSellingPrice) AS avg_price
FROM zepto
GROUP BY category
ORDER BY avg_price DESC;

-- Categories Has Many Low-Stock Products

SELECT category, 
	COUNT(*) AS low_stock_products
FROM zepto
WHERE availableQuantity < 10
GROUP BY category
ORDER BY low_stock_products DESC;

/* ================================================================================
                            CATEGORY LEVEL ANALYSIS
================================================================================
- Types Of Categories          : Cooking Essentials, Munchies, Chocolates, Personal Care, etc.
- Count of Products            : Cooking Essentials & Munchies lead with 512 products each.
- Highest-Revenue Category     : Cooking Essentials & Munchies (33.7M each).
- Contribution Percentage      : Cooking & Munchies contribute 30% of total inventory value.
- Highest Avg Selling Price    : Paan Corner & Personal Care (~18,973).
- Many Low-Stock Products      : Cooking Essentials & Munchies (205 items < 5 units).

[INSIGHT] 
Cooking Essentials and Munchies are the primary drivers of inventory value and volume. 
Paan Corner and Personal Care have high-value items despite lower counts.

[RECOMMENDATION] 
Increase safety stock levels for Cooking Essentials, as 40% of its products are low on stock. 
Expand the high-margin 'Personal Care' category to increase overall profitability.
*/

/* PRODUCT LEVEL ANALYSIS

   - Top 5 Products in Top Category
   - Products Dominating within Each Category
   - Products Which have Highest Discount Percentage
*/

-- Top 5 Products in Top Category

SELECT *
FROM (
	SELECT
		product,
        category,
        discountedSellingPrice * availableQuantity AS Inventorty_Value,
        RANK() OVER (
			PARTITION BY category
            ORDER BY discountedSellingPrice * availableQuantity DESC
		) rnk
	FROM zepto
) t
WHERE rnk <= 5;

-- Products Dominating Within Each Category

SELECT *
FROM (
    SELECT 
        product,
        category,
        discountedSellingPrice * availableQuantity AS value,
        RANK() OVER (
            PARTITION BY category 
            ORDER BY discountedSellingPrice * availableQuantity DESC
        ) AS rnk
    FROM zepto
) t
WHERE rnk <= 3;

-- Products Which have Highest Discount Percentage

SELECT 
    product,
    category,
    (mrp - discountedSellingPrice)/mrp * 100 AS discount_pct
FROM zepto
ORDER BY discount_pct DESC
LIMIT 10;

/* ================================================================================
                            PRODUCT LEVEL ANALYSIS
================================================================================
- Top 5 (Cooking Essentials)   : Borges Olive Oil, Praakritik Ghee, Saffola Gold, Dhara Mustard Oil, Fortune Oil.
- Dominating Products          : Borges Extra Light Olive Oil (Highest revenue contribution).
- Highest Discount Products    : Dukes Waffy Wafers (51%) and Chef's Basket Pasta (50%).

[INSIGHT] 
Premium oils and ghee dominate the revenue share within the top category. 
Dukes Waffy is being aggressively cleared with >50% discounts.

[RECOMMENDATION] 
Cross-sell 'Cooking Essentials' (Oils) with 'Munchies' to leverage their combined high traffic. 
Evaluate if the 50%+ discounts on Wafers/Pasta are improving turnover or hurting margins.
*/

/* ================================================================================
                                KEY FINDINGS
===================================================================================
1. CAPITAL FOCUS: Cooking Essentials & Munchies dominate with a combined 
   stock value of ~₹6.74L (30% of total inventory).

2. PREMIUM PRICING: The store maintains strong margins, retaining 92.4% of MRP 
   on average (low 7.6% average discount).

3. REVENUE LEAK: Promotional discounts reduce potential gross revenue by 
   approx. ₹2.5L based on current stock levels.

4. STOCK ALERTS: Critical shortage in daily staples—125 products in 
   'Cooking Essentials' are down to their last 1-2 units.

5. BIG TICKETS: Premium inventory like Olive Oil and Ghee are the primary 
   capital drivers, representing the highest individual product valuations.

*/

/* SKILLS DEMONSTRATED:

   - Data Cleaning & Validation
   - Aggregations (SUM, AVG, COUNT, MIN, MAX)
   - Subqueries
   - Grouping & Filtering
   - Window Functions (RANK(),ROW_NUMBER(),DENSE_RANK())
   - Business Insight Generation
   - Strategic Recommendation Framing
*/

/* ========================================================
                    PROJECT COMPLETED
   ========================================================
*/