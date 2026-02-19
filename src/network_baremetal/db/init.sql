CREATE DATABASE IF NOT EXISTS hw_shop;
USE hw_shop;

CREATE TABLE cpus (
    cpu_id INT AUTO_INCREMENT PRIMARY KEY,
    brand VARCHAR(50),
    model VARCHAR(100),
    cores INT,
    stock INT,
    price DECIMAL(10,2)
);

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    cpu_id INT,
    customer_name VARCHAR(100),
    quantity INT,
    order_date DATE,
    total_price DECIMAL(10,2),
    FOREIGN KEY (cpu_id) REFERENCES cpus(cpu_id)
);

CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    country VARCHAR(50)
);

CREATE TABLE cpu_supplier (
    cpu_id INT,
    supplier_id INT,
    supply_price DECIMAL(10,2),
    PRIMARY KEY(cpu_id, supplier_id),
    FOREIGN KEY (cpu_id) REFERENCES cpus(cpu_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

INSERT INTO cpus (brand, model, cores, stock, price) VALUES
('Intel', 'i9-13900K', 24, 32, 589.99),
('AMD', 'Ryzen 9 7950X', 16, 32, 699.99),
('Intel', 'i5-13600K', 14, 20, 319.99),
('AMD', 'Ryzen 5 7600X', 6, 12, 249.99);

INSERT INTO orders (cpu_id, customer_name, quantity, order_date, total_price) VALUES
(1, 'Alice', 2, '2026-02-01', 1179.98),
(2, 'Bob', 1, '2026-02-05', 699.99),
(3, 'Charlie', 3, '2026-02-07', 959.97),
(4, 'Diana', 1, '2026-02-10', 249.99);

INSERT INTO suppliers (name, country) VALUES
('Intel Inc.', 'USA'),
('AMD Inc.', 'USA'),
('TechSource', 'Germany'),
('ChipWorld', 'China');

INSERT INTO cpu_supplier (cpu_id, supplier_id, supply_price) VALUES
(1,1,400.00),
(2,2,450.00),
(3,1,200.00),
(4,2,150.00),
(1,3,410.00);
