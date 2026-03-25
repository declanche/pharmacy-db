-- In this SQL file, write (and comment!) the schema of your database, including the CREATE TABLE, CREATE INDEX, CREATE VIEW, etc. statements that compose it
 CREATE TABLE IF NOT EXISTS categories (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE,
    "description" TEXT
 );

 CREATE TABLE IF NOT EXISTS manufacturers (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE
 );

 CREATE TABLE IF NOT EXISTS presentations (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE,
    "icon_url" TEXT
 );

 CREATE TABLE IF NOT EXISTS products (
    "id" INTEGER PRIMARY KEY,
    "brand_name" TEXT NOT NULL,
    "generic_name" TEXT NOT NULL,
    "presentation_id" INTEGER NOT NULL,
    "dosage" TEXT,
    "pack_size" TEXT,
    "category_id" INTEGER NOT NULL,
    "manufacturer_id" INTEGER NOT NULL,
    "current_price" REAL NOT NULL,
    FOREIGN KEY("presentation_id") REFERENCES presentations("id"),
    FOREIGN KEY("category_id") REFERENCES categories("id"),
    FOREIGN KEY("manufacturer_id") REFERENCES manufacturers("id")
 );

CREATE TABLE IF NOT EXISTS "batches" (
    "id" INTEGER PRIMARY KEY,
    "product_id" INTEGER NOT NULL,
    "batch_number" TEXT NOT NULL,
    "quantity_received" INTEGER NOT NULL,
    "quantity_available" INTEGER NOT NULL,
    "received_date" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiry_date" TEXT NOT NULL,
    UNIQUE("product_id", "batch_number"),
    FOREIGN KEY("product_id") REFERENCES products("id")
);

CREATE TABLE IF NOT EXISTS "suppliers" (
    "id" INTEGER PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE,
    "contact_info" TEXT
);

CREATE TABLE IF NOT EXISTS "purchases" (
    "id" INTEGER PRIMARY KEY,
    "supplier_id" INTEGER NOT NULL,
    "purchase_date" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("supplier_id") REFERENCES suppliers("id")
);

CREATE TABLE IF NOT EXISTS "purchase_items" (
    "id" INTEGER PRIMARY KEY,
    "purchase_id" INTEGER NOT NULL,
    "batch_id" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "cost_price" REAL NOT NULL,
    FOREIGN KEY("purchase_id") REFERENCES purchases("id"),
    FOREIGN KEY("batch_id") REFERENCES batches("id")
);

CREATE TABLE IF NOT EXISTS "stocks" (
    "id" INTEGER PRIMARY KEY,
    "product_id" INTEGER NOT NULL UNIQUE,
    "quantity" INTEGER NOT NULL DEFAULT 0,
    "reorder_level" INTEGER NOT NULL,
    "last_updated" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY("product_id") REFERENCES products("id")
);

CREATE TABLE IF NOT EXISTS "customers" (
    "id" INTEGER PRIMARY KEY,
    "first_name" TEXT NOT NULL,
    "last_name" TEXT NOT NULL,
    "phone_number" TEXT,
    "email" TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS "sales" (
    "id" INTEGER PRIMARY KEY,
    "customer_id" INTEGER NOT NULL,
    "sale_date" TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "total_amount" REAL NOT NULL,
    "payment_method" TEXT NOT NULL 
    CHECK(payment_method IN ('cash', 'card', 'mobile_money')),
    FOREIGN KEY("customer_id") REFERENCES customers("id")
);

CREATE TABLE IF NOT EXISTS "sale_items" (
    "id" INTEGER PRIMARY KEY,
    "sale_id" INTEGER NOT NULL,
    "batch_id" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "selling_price" REAL NOT NULL,
    FOREIGN KEY("sale_id") REFERENCES "sales"("id"),
    FOREIGN KEY("batch_id") REFERENCES "batches"("id")
);

CREATE INDEX index_products_brand_name
ON products(brand_name);

CREATE INDEX index_products_generic_name
ON products(generic_name);

CREATE INDEX index_sale_items_sale
ON sale_items(sale_id);

CREATE VIEW low_stock_products AS
SELECT
    p.id,
    p.brand_name,
    s.quantity,
    s.reorder_level
FROM stocks s
JOIN products p ON s.product_id = p.id
WHERE s.quantity <= s.reorder_level;

CREATE VIEW expired_batches AS
SELECT
    b.id,
    p.brand_name,
    b.batch_number,
    b.expiry_date
FROM batches b
JOIN products p ON b.product_id = p.id
WHERE date(b.expiry_date) < date('now');

CREATE TRIGGER update_stock_after_batch_insert
AFTER INSERT ON "batches"
BEGIN
    UPDATE stocks
    SET quantity = quantity + NEW.quantity_received
    WHERE product_id = NEW.product_id;
END;

CREATE VIEW sales_details AS
SELECT
    s.id AS sale_id,
    s.sale_date,
    p.brand_name,
    b.batch_number,
    si.quantity,
    si.selling_price,
    (si.quantity * si.selling_price) AS total_line_value
FROM sale_items si
JOIN sales s ON si.sale_id = s.id
JOIN batches b ON si.batch_id = b.id
JOIN products p ON b.product_id = p.id;

CREATE VIEW product_sales_summary AS
SELECT
    p.brand_name,
    SUM(si.quantity) AS total_units_sold,
    SUM(si.quantity * si.selling_price) AS total_revenue
FROM sale_items si
JOIN batches b ON si.batch_id = b.id
JOIN products p ON b.product_id = p.id
GROUP BY p.id;