-- E-commerce schema for Turkish Text-to-SQL
-- Dialect: SQLite

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS returns;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;

-- Customers who have registered on the site
CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    first_name   TEXT NOT NULL,
    last_name    TEXT NOT NULL,
    email        TEXT NOT NULL UNIQUE,
    city         TEXT NOT NULL,          -- e.g. 'İstanbul', 'Sivas'
    gender       TEXT,                   -- 'F', 'M' or NULL
    birth_date   TEXT,                   -- 'YYYY-MM-DD'
    created_at   TEXT NOT NULL           -- registration date, 'YYYY-MM-DD'
);

-- Product categories; parent_id allows nesting (e.g. Elektronik > Telefon)
CREATE TABLE categories (
    category_id  INTEGER PRIMARY KEY,
    name         TEXT NOT NULL,
    parent_id    INTEGER,
    FOREIGN KEY (parent_id) REFERENCES categories(category_id)
);

-- Products for sale
CREATE TABLE products (
    product_id   INTEGER PRIMARY KEY,
    name         TEXT NOT NULL,
    brand        TEXT,
    category_id  INTEGER NOT NULL,
    price        REAL NOT NULL CHECK (price >= 0),   -- current price in TL
    stock        INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- Orders placed by customers
CREATE TABLE orders (
    order_id       INTEGER PRIMARY KEY,
    customer_id    INTEGER NOT NULL,
    order_date     TEXT NOT NULL,          -- 'YYYY-MM-DD'
    status         TEXT NOT NULL CHECK (status IN ('hazırlanıyor', 'kargoda', 'teslim edildi', 'iptal')),
    shipping_city  TEXT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Products inside each order (one order can contain many products)
CREATE TABLE order_items (
    order_item_id  INTEGER PRIMARY KEY,
    order_id       INTEGER NOT NULL,
    product_id     INTEGER NOT NULL,
    quantity       INTEGER NOT NULL CHECK (quantity > 0),
    unit_price     REAL NOT NULL,          -- price at the time of purchase
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Payments for orders
CREATE TABLE payments (
    payment_id    INTEGER PRIMARY KEY,
    order_id      INTEGER NOT NULL,
    amount        REAL NOT NULL,
    method        TEXT NOT NULL CHECK (method IN ('kredi kartı', 'havale', 'kapıda ödeme')),
    installments  INTEGER NOT NULL DEFAULT 1,   -- number of installments (taksit)
    paid_at       TEXT NOT NULL,                -- 'YYYY-MM-DD'
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- Returned items
CREATE TABLE returns (
    return_id      INTEGER PRIMARY KEY,
    order_item_id  INTEGER NOT NULL,
    reason         TEXT,
    return_date    TEXT NOT NULL,               -- 'YYYY-MM-DD'
    refund_amount  REAL NOT NULL,
    FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id)
);
