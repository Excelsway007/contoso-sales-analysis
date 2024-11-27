CREATE SCHEMA contoso;
SHOW DATABASES;
USE contoso;

-- Data Exploration
SELECT distinct count(*) FROM customers_new;
DESC customers_new;
DESC sales;
DESC products;
DESC stores;
DESC exchange_rates;
SELECT * from exchange_rates;
SELECT * from sales;
SELECT * from stores;
SELECT * from products;

-- CUSTOMER INSIGHTS
-- number of customers per country and continent
SELECT continent, country, COUNT(customerkey) customer_count
FROM customers_new
GROUP BY 1,2
ORDER BY 1,2;

-- Top 5 Countries with the highest number of customers
SELECT country, COUNT(customerkey) customer_count
FROM customers_new
where customerkey is not null
GROUP BY 1
ORDER BY customer_count DESC
LIMIT 5;

-- STORES PERFORMANCE
DESC stores;
SELECT count(*) from stores
-- Total number of stores
SELECT country, count(distinct storekey) store_count
from stores
group by country
order by store_count desc;

-- Average store size in square meters for each country
SELECT country, AVG(square_meters) avg_store_size
FROM stores
where square_meters is not null
GROUP BY country
order by avg_store_size DESC;

-- Store with the largest square meters in Australia
SELECT storekey, country, square_meters store_size
FROM stores
where country = 'australia' 
order by store_size DESC
LIMIT 1;

-- SALES ANALYSIS
DESC sales;
SELECT COUNT(*) FROM sales;

-- Total quantity sold per product
SELECT s.productkey, p.product_name, SUM(s.quantity) total_qty_sold
FROM sales s
JOIN products p
on p.productkey = s.productkey
GROUP BY 1,2
ORDER BY 3 DESC;

-- Top 3 best selling products
SELECT s.productkey, p.product_name, SUM(s.quantity) total_qty_sold
FROM sales s
JOIN products p
on p.productkey = s.productkey
GROUP BY 1,2
ORDER BY total_qty_sold DESC
LIMIT 3;

-- 	Total Revenue generated from each store(sales values converted to USD using exchange rate data
DESC sales;
DESC products;
DESC stores;
DESC exchange_rates;
SELECT * from exchange_rates;
SELECT * from sales;
SELECT * from stores;
SELECT * from products;

SELECT s.currency_code, ROUND(SUM(s.quantity * p.unit_price_usd * e.exchange),2) total_revenue
FROM sales s
JOIN products p
on s.productkey = p.productkey
JOIN exchange_rates e 
on s.currency_code = e.currency
GROUP BY s.currency_code;

-- Average number of items sold per order
SELECT AVG(quantity) avg_items_per_order
FROM sales;

-- PRODUCTS ANALYSIS
SELECT count(*) FROM products;
DESC products;
SELECT * FROM products;

-- Number of unique products available in each category
SELECT count(DISTINCT subcategorykey) unique_items, category
from products
group by 2
order by unique_items;

-- Product with the highest unit price
SELECT product_name, unit_price_usd
from products
order by unit_price_usd DESC
LIMIT 1;
-- Most common color in the sales data(white)
SELECT count(color) color_count, color
from products
group by 2
order by color_count DESC
LIMIT 1;

-- CURRENCY EXCHANGE IMPACT
DESC exchange_rates;
SELECT * FROM exchange_rates;
-- Total sales revenue in each currency and its equivalent in USD
SELECT s.Currency_Code, ROUND(SUM(s.Quantity * p.Unit_Price_USD),2) total_rev, ROUND(SUM(s.Quantity * p.Unit_Price_USD * e.Exchange),2) total_rev_USD
FROM Sales s
JOIN Products p ON s.ProductKey = p.ProductKey
JOIN Exchange_Rates e ON s.Currency_Code = e.Currency
GROUP BY s.Currency_Code;

-- Date with the highest exchange rate for EUR
SELECT date, currency, MAX(exchange) highest_exchange_rate
FROM exchange_rates
WHERE currency = 'EUR'
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1;

-- CUSTOMER BEHAVIOUR
SELECT distinct count(*) FROM customers_new;
DESC customers_new;
SELECT * FROM customers_new;
-- Number of orders placed by each customer
SELECT s.customerkey, c.name, count(distinct s.order_number) order_count
FROM sales s
JOIN customers_new c
ON s.customerkey = c.customerkey
GROUP BY 1,2
ORDER BY 3 DESC;

-- Customers with more than 5 purchases
SELECT s.customerkey, c.name, count(distinct s.order_number) order_count
FROM sales s
JOIN customers_new c
ON s.customerkey = c.customerkey
GROUP BY 1,2
having order_count > 5
ORDER BY 3 ;

-- Customers whose first orders were placed in 2016
SELECT s.customerkey, c.name, MIN(str_to_date(s.order_date, '%m/%d/%Y')) first_order
FROM sales s
JOIN customers_new c
ON s.customerkey = c.customerkey
GROUP BY 1,2
HAVING year(first_order)=2016; 

-- TOP 5 COUNTRIES WITH THE HIGHEST REVENUE
SELECT sh.country, ROUND(SUM(s.quantity * p.unit_price_usd),2) total_revenue
FROM sales s
JOIN stores sh
on s.storekey = sh.storekey
JOIN products p
on s.productkey = p.productkey
GROUP BY 1
order by total_revenue DESC
LIMIT 5;
-- stored procedured
DELIMITER // 
CREATE PROCEDURE GetTop5CountrieswiththeHighestRevenue()
BEGIN 
	SELECT sh.country, ROUND(SUM(s.quantity * p.unit_price_usd),2) total_revenue
FROM sales s
JOIN stores sh
on s.storekey = sh.storekey
JOIN products p
on s.productkey = p.productkey
GROUP BY 1
order by total_revenue DESC
LIMIT 5;
END //
 DELIMITER ;

-- AMOUNT OF ORDERS VS PRODUCT QUANTITIES PER COUNTRY
SELECT sh.country, COUNT(s.order_number) total_orders, SUM(s.quantity) total_quantity
FROM sales s
JOIN stores sh
on s.storekey = sh.storekey
GROUP BY 1
ORDER BY total_orders DESC, total_quantity DESC;
-- STORED PROCEDURE
DELIMITER // 
CREATE PROCEDURE GetOrdersVSQuantityPercountry()
BEGIN 
	SELECT sh.country, COUNT(s.order_number) total_orders, SUM(s.quantity) total_quantity
FROM sales s
JOIN stores sh
on s.storekey = sh.storekey
GROUP BY 1
ORDER BY total_orders DESC, total_quantity DESC;
END //
 DELIMITER ;

-- TOP 5 PRODUCTS PER COUNTRY
DELIMITER // 
CREATE PROCEDURE GetTop5ProductsBycountry()
BEGIN 
	WITH RankedProducts AS (
 SELECT sh.country, s.productkey,p.product_name, 
    SUM(s.quantity) AS total_quantity,
	ROW_NUMBER() OVER (PARTITION BY sh.country ORDER BY SUM(s.quantity) DESC) AS ranking
    FROM sales s 
    JOIN stores sh 
    ON s.storekey = sh.storekey
    JOIN products p
    ON s.productkey = p.productkey
    GROUP BY 1,2,3
    )
    SELECT country, productkey, product_name, total_quantity 
    FROM RankedProducts
    WHERE ranking <= 5 
    ORDER BY country, total_quantity DESC;
END //
 DELIMITER ;
 
 -- MOST ACTIVE CUSTOMERS
 SELECT sh.country, s.customerkey, c.name, count(distinct s.order_number) order_count
FROM sales s
JOIN stores sh
ON sh.storekey=s.storekey
JOIN customers_new c
ON s.customerkey = c.customerkey
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 5 ;
 -- STORED PROCEDURE
 DELIMITER // 
CREATE PROCEDURE GetMostActiveCustomers()
BEGIN 
 SELECT sh.country, s.customerkey, c.name, count(distinct s.order_number) order_count
FROM sales s
JOIN stores sh
ON sh.storekey=s.storekey
JOIN customers_new c
ON s.customerkey = c.customerkey
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 5 ;
END //
 DELIMITER ;
 -- The US generates more revenue than any other country
 -- The US has more stores and process more orders than other countries
 -- The most active customers are mostly from the united kingdom and the united states
 
 -- RECOMMENDATION
 -- focus more on top selling products for each region and country.
 -- offer discounts on least selling products
 -- offer incentives to returning customers 
 -- Open more store locations in regions with low store count but high purchasing customers
 


