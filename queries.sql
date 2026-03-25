-- In this SQL file, write (and comment!) the typical SQL queries users will run on your database

-- Pharmacy staff often need to quickly locate a drug by its brand or generic name.
SELECT id, brand_name, generic_name
FROM products
WHERE brand_name LIKE '%amox%'
OR generic_name LIKE '%amox%';

-- Retrieve the current quantity available for a certain drug.
SELECT p.brand_name, s.quantity_available
FROM stocks s
JOIN products p ON s.product_id = p.id
WHERE p.generic_name = 'Ibuprofen';

-- identify the top 5 products that need restocking
SELECT p.brand_name, s.quantity_available, s.reorder_level
FROM stocks s
JOIN products p ON p.id = s.product_id
WHERE s.quantity_available <= s.reorder_level
ORDER BY s.quantity_available
LIMIT 5;

-- Retrieve sales for a particular date
SELECT s.id, s.sale_date, c.name
FROM sales s
LEFT JOIN customers c ON s.customer_id = c.id
WHERE s.sale_date >= '2026-03-08'
AND s.sale_date < '2026-03-09';

-- Retrieve sales by a particular customer
SELECT s.id AS sale_id,
       s.sale_date,
       s.total_amount,
       s.payment_method
FROM sales s
JOIN customers c ON s.customer_id = c.id
WHERE c.first_name = 'John' AND c.last_name = 'Doe';