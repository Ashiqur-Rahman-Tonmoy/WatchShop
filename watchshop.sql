-- =====================================================================
-- WatchShop : Watch Business Data Management System
-- Group 8 | Section 3 | CSE311L Database Systems Lab | North South University
-- Database Implementation (Schema + Constraints + Sample Data)
-- Target: MySQL 8.0.16+ (CHECK constraints are enforced from 8.0.16)
-- =====================================================================

DROP DATABASE IF EXISTS watchshop;
CREATE DATABASE watchshop CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE watchshop;

-- =====================================================================
-- 1. TABLES (parents first, then children)
-- =====================================================================

-- 1. USER
CREATE TABLE `USER` (
    user_id    INT AUTO_INCREMENT,
    full_name  VARCHAR(100) NOT NULL,
    email      VARCHAR(100) NOT NULL,
    password   VARCHAR(255) NOT NULL,          -- stores a password HASH, never plain text
    phone      VARCHAR(20),
    role       ENUM('Admin','Salesperson') NOT NULL DEFAULT 'Salesperson',
    CONSTRAINT pk_user       PRIMARY KEY (user_id),
    CONSTRAINT uq_user_email UNIQUE (email)
) ENGINE=InnoDB;

-- 2. SUPPLIER
CREATE TABLE SUPPLIER (
    supplier_id   INT AUTO_INCREMENT,
    supplier_name VARCHAR(100) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    email         VARCHAR(100),
    address       VARCHAR(255),
    CONSTRAINT pk_supplier       PRIMARY KEY (supplier_id),
    CONSTRAINT uq_supplier_email UNIQUE (email)
) ENGINE=InnoDB;

-- 3. CUSTOMER
CREATE TABLE CUSTOMER (
    customer_id   INT AUTO_INCREMENT,
    customer_name VARCHAR(100) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    email         VARCHAR(100),
    address       VARCHAR(255),
    CONSTRAINT pk_customer       PRIMARY KEY (customer_id),
    CONSTRAINT uq_customer_phone UNIQUE (phone)
) ENGINE=InnoDB;

-- 4. BRAND
CREATE TABLE BRAND (
    brand_id   INT AUTO_INCREMENT,
    brand_name VARCHAR(60) NOT NULL,
    country    VARCHAR(60),
    CONSTRAINT pk_brand      PRIMARY KEY (brand_id),
    CONSTRAINT uq_brand_name UNIQUE (brand_name)
) ENGINE=InnoDB;

-- 5. CATEGORY
CREATE TABLE CATEGORY (
    category_id   INT AUTO_INCREMENT,
    category_name VARCHAR(60) NOT NULL,
    CONSTRAINT pk_category      PRIMARY KEY (category_id),
    CONSTRAINT uq_category_name UNIQUE (category_name)
) ENGINE=InnoDB;

-- 6. WATCH
CREATE TABLE WATCH (
    watch_id        INT AUTO_INCREMENT,
    model_name      VARCHAR(100) NOT NULL,
    brand_id        INT NOT NULL,
    category_id     INT NOT NULL,
    purchase_price  DECIMAL(10,2) NOT NULL,
    sale_price      DECIMAL(10,2) NOT NULL,
    stock_qty       INT NOT NULL DEFAULT 0,
    reorder_level   INT NOT NULL DEFAULT 5,
    warranty_months INT NOT NULL DEFAULT 12,
    image           VARCHAR(255),
    CONSTRAINT pk_watch          PRIMARY KEY (watch_id),
    CONSTRAINT fk_watch_brand    FOREIGN KEY (brand_id)    REFERENCES BRAND(brand_id)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_watch_category FOREIGN KEY (category_id) REFERENCES CATEGORY(category_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_watch_pprice  CHECK (purchase_price > 0),
    CONSTRAINT chk_watch_sprice  CHECK (sale_price >= purchase_price),
    CONSTRAINT chk_watch_stock   CHECK (stock_qty >= 0),
    CONSTRAINT chk_watch_reorder CHECK (reorder_level >= 0),
    CONSTRAINT chk_watch_warr    CHECK (warranty_months >= 0)
) ENGINE=InnoDB;

-- 7. PURCHASE_ORDER
CREATE TABLE PURCHASE_ORDER (
    po_id       INT AUTO_INCREMENT,
    supplier_id INT NOT NULL,
    created_by  INT NOT NULL,
    order_date  DATE NOT NULL,
    status      ENUM('Pending','Received','Cancelled') NOT NULL DEFAULT 'Pending',
    total_cost  DECIMAL(12,2) NOT NULL DEFAULT 0,
    CONSTRAINT pk_po          PRIMARY KEY (po_id),
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES SUPPLIER(supplier_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_po_user     FOREIGN KEY (created_by)  REFERENCES `USER`(user_id)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_po_total   CHECK (total_cost >= 0)
) ENGINE=InnoDB;

-- 8. PURCHASE_ITEM
CREATE TABLE PURCHASE_ITEM (
    po_item_id INT AUTO_INCREMENT,
    po_id      INT NOT NULL,
    watch_id   INT NOT NULL,
    quantity   INT NOT NULL,
    unit_cost  DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_po_item       PRIMARY KEY (po_item_id),
    CONSTRAINT fk_poi_po        FOREIGN KEY (po_id)    REFERENCES PURCHASE_ORDER(po_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_poi_watch     FOREIGN KEY (watch_id) REFERENCES WATCH(watch_id)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_poi_po_watch  UNIQUE (po_id, watch_id),
    CONSTRAINT chk_poi_qty      CHECK (quantity > 0),
    CONSTRAINT chk_poi_cost     CHECK (unit_cost > 0)
) ENGINE=InnoDB;

-- 9. SALE
CREATE TABLE SALE (
    sale_id        INT AUTO_INCREMENT,
    customer_id    INT NOT NULL,
    salesperson_id INT NOT NULL,
    sale_date      DATE NOT NULL,
    discount       DECIMAL(10,2) NOT NULL DEFAULT 0,
    total_amount   DECIMAL(12,2) NOT NULL DEFAULT 0,
    payment_status ENUM('Unpaid','Partial','Paid') NOT NULL DEFAULT 'Unpaid',
    CONSTRAINT pk_sale          PRIMARY KEY (sale_id),
    CONSTRAINT fk_sale_customer FOREIGN KEY (customer_id)    REFERENCES CUSTOMER(customer_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_sale_user     FOREIGN KEY (salesperson_id) REFERENCES `USER`(user_id)       ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_sale_disc    CHECK (discount >= 0),
    CONSTRAINT chk_sale_total   CHECK (total_amount >= 0)
) ENGINE=InnoDB;

-- 10. SALE_ITEM
CREATE TABLE SALE_ITEM (
    sale_item_id INT AUTO_INCREMENT,
    sale_id      INT NOT NULL,
    watch_id     INT NOT NULL,
    serial_no    VARCHAR(50) NOT NULL,
    quantity     INT NOT NULL DEFAULT 1,
    unit_price   DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_sale_item     PRIMARY KEY (sale_item_id),
    CONSTRAINT fk_si_sale       FOREIGN KEY (sale_id)  REFERENCES SALE(sale_id)   ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_si_watch      FOREIGN KEY (watch_id) REFERENCES WATCH(watch_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_si_serial     UNIQUE (serial_no),
    CONSTRAINT chk_si_qty       CHECK (quantity > 0),
    CONSTRAINT chk_si_price     CHECK (unit_price > 0)
) ENGINE=InnoDB;

-- 11. PAYMENT
CREATE TABLE PAYMENT (
    payment_id INT AUTO_INCREMENT,
    sale_id    INT NOT NULL,
    amount     DECIMAL(12,2) NOT NULL,
    method     ENUM('Cash','Card','bKash','Nagad','Bank Transfer') NOT NULL,
    paid_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_payment     PRIMARY KEY (payment_id),
    CONSTRAINT fk_pay_sale    FOREIGN KEY (sale_id) REFERENCES SALE(sale_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_pay_amount CHECK (amount > 0)
) ENGINE=InnoDB;

-- 12. SALE_RETURN  (1:1 with SALE_ITEM -> UNIQUE on sale_item_id)
CREATE TABLE SALE_RETURN (
    return_id     INT AUTO_INCREMENT,
    sale_item_id  INT NOT NULL,
    return_date   DATE NOT NULL,
    reason        VARCHAR(255) NOT NULL,
    refund_amount DECIMAL(10,2) NOT NULL,
    CONSTRAINT pk_return        PRIMARY KEY (return_id),
    CONSTRAINT uq_return_item   UNIQUE (sale_item_id),
    CONSTRAINT fk_ret_sale_item FOREIGN KEY (sale_item_id) REFERENCES SALE_ITEM(sale_item_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_ret_refund   CHECK (refund_amount >= 0)
) ENGINE=InnoDB;

-- 13. WARRANTY  (1:1 with SALE_ITEM -> UNIQUE on sale_item_id)
CREATE TABLE WARRANTY (
    warranty_id  INT AUTO_INCREMENT,
    sale_item_id INT NOT NULL,
    start_date   DATE NOT NULL,
    end_date     DATE NOT NULL,
    status       ENUM('Active','Expired','Claimed','Void') NOT NULL DEFAULT 'Active',
    CONSTRAINT pk_warranty      PRIMARY KEY (warranty_id),
    CONSTRAINT uq_warranty_item UNIQUE (sale_item_id),
    CONSTRAINT fk_war_sale_item FOREIGN KEY (sale_item_id) REFERENCES SALE_ITEM(sale_item_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT chk_war_dates    CHECK (end_date >= start_date)
) ENGINE=InnoDB;

-- 14. REPAIR
CREATE TABLE REPAIR (
    repair_id      INT AUTO_INCREMENT,
    warranty_id    INT NOT NULL,
    received_date  DATE NOT NULL,
    issue          VARCHAR(255) NOT NULL,
    repair_cost    DECIMAL(10,2) NOT NULL DEFAULT 0,
    status         ENUM('Received','In Progress','Completed','Delivered') NOT NULL DEFAULT 'Received',
    delivered_date DATE NULL,
    CONSTRAINT pk_repair       PRIMARY KEY (repair_id),
    CONSTRAINT fk_rep_warranty FOREIGN KEY (warranty_id) REFERENCES WARRANTY(warranty_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT chk_rep_cost    CHECK (repair_cost >= 0),
    CONSTRAINT chk_rep_dates   CHECK (delivered_date IS NULL OR delivered_date >= received_date)
) ENGINE=InnoDB;

-- Helpful indexes for frequent lookups
CREATE INDEX idx_watch_brand    ON WATCH(brand_id);
CREATE INDEX idx_sale_date      ON SALE(sale_date);
CREATE INDEX idx_payment_sale   ON PAYMENT(sale_id);

-- =====================================================================
-- 2. SAMPLE DATA
-- =====================================================================

-- USER (passwords are sample hash strings)
INSERT INTO `USER` (user_id, full_name, email, password, phone, role) VALUES
(1, 'Md Roman',          'roman@watchshop.com',    '$2y$10$Zk3hR1mQe7WnT8yUaB5vCeLq0xPz9sJdF2gH4iK6oN8pR1tV3wXyO', '01711000001', 'Admin'),
(2, 'Anika Nower Nihan', 'anika@watchshop.com',    '$2y$10$Ab4cD5eF6gH7iJ8kL9mN0oPqRsTuVwXyZ1a2B3c4D5e6F7g8H9i0J', '01711000002', 'Admin'),
(3, 'Farhan Shahriar',   'farhan@watchshop.com',   '$2y$10$Mn1oP2qR3sT4uV5wX6yZ7aB8cD9eF0gH1iJ2kL3mN4oP5qR6sT7uV', '01711000003', 'Salesperson'),
(4, 'Ashiqur Rahman',    'ashiqur@watchshop.com',  '$2y$10$Qr9sT8uV7wX6yZ5aB4cD3eF2gH1iJ0kL9mN8oP7qR6sT5uV4wX3yZ', '01711000004', 'Salesperson');

-- SUPPLIER
INSERT INTO SUPPLIER (supplier_id, supplier_name, phone, email, address) VALUES
(1, 'Casio Bangladesh Distribution', '01811000001', 'sales@casiobd.com',     'Gulshan-1, Dhaka'),
(2, 'Seiko Trade House',             '01811000002', 'info@seikotrade.com',   'Motijheel, Dhaka'),
(3, 'Citizen Time Corporation',      '01811000003', 'orders@citizentime.com','Agrabad, Chattogram'),
(4, 'Fossil Imports Ltd',            '01811000004', 'support@fossilimp.com', 'Banani, Dhaka'),
(5, 'Titan Watch Suppliers',         '01811000005', 'contact@titansupply.com','Zindabazar, Sylhet');

-- CUSTOMER
INSERT INTO CUSTOMER (customer_id, customer_name, phone, email, address) VALUES
(1, 'Rafiul Islam',     '01911000001', 'rafiul@example.com',  'Dhanmondi, Dhaka'),
(2, 'Nusrat Jahan',     '01911000002', 'nusrat@example.com',  'Uttara, Dhaka'),
(3, 'Tanvir Ahmed',     '01911000003', 'tanvir@example.com',  'Mirpur-10, Dhaka'),
(4, 'Sadia Rahman',     '01911000004', 'sadia@example.com',   'Bashundhara R/A, Dhaka'),
(5, 'Mahmudul Hasan',   '01911000005', 'mahmud@example.com',  'Khulshi, Chattogram'),
(6, 'Fariha Tabassum',  '01911000006', 'fariha@example.com',  'Mohammadpur, Dhaka'),
(7, 'Imran Hossain',    '01911000007', 'imran@example.com',   'Rajshahi Sadar, Rajshahi'),
(8, 'Shamima Akter',    '01911000008', 'shamima@example.com', 'Sylhet Sadar, Sylhet');

-- BRAND
INSERT INTO BRAND (brand_id, brand_name, country) VALUES
(1, 'Casio',   'Japan'),
(2, 'Seiko',   'Japan'),
(3, 'Citizen', 'Japan'),
(4, 'Fossil',  'USA'),
(5, 'Titan',   'India');

-- CATEGORY
INSERT INTO CATEGORY (category_id, category_name) VALUES
(1, 'Analog'),
(2, 'Digital'),
(3, 'Smartwatch'),
(4, 'Chronograph');

-- WATCH
INSERT INTO WATCH (watch_id, model_name, brand_id, category_id, purchase_price, sale_price, stock_qty, reorder_level, warranty_months, image) VALUES
(1,  'G-Shock GA-2100',        1, 2,  9500.00, 12500.00, 19, 5, 12, 'images/gshock_ga2100.jpg'),
(2,  'Casio MTP-1374',         1, 1,  4200.00,  5500.00, 19, 8, 12, 'images/casio_mtp1374.jpg'),
(3,  'Seiko 5 Sports SRPD',    2, 1, 17000.00, 21500.00,  9, 3, 24, 'images/seiko5_srpd.jpg'),
(4,  'Seiko Presage Cocktail', 2, 1, 32000.00, 39000.00,  4, 2, 24, 'images/seiko_presage.jpg'),
(5,  'Citizen Eco-Drive BM',   3, 1, 15000.00, 19000.00,  9, 3, 24, 'images/citizen_ecodrive.jpg'),
(6,  'Citizen Promaster Chrono',3,4, 24000.00, 30000.00,  5, 2, 24, 'images/citizen_promaster.jpg'),
(7,  'Fossil Grant Chrono',    4, 4, 11000.00, 14500.00, 10, 4, 12, 'images/fossil_grant.jpg'),
(8,  'Fossil Gen 6 Smart',     4, 3, 20000.00, 25500.00,  5, 3, 12, 'images/fossil_gen6.jpg'),
(9,  'Titan Edge',             5, 1,  8000.00, 10500.00, 14, 5, 12, 'images/titan_edge.jpg'),
(10, 'Titan Octane',           5, 4,  6500.00,  8500.00, 20, 5, 12, 'images/titan_octane.jpg');

-- PURCHASE_ORDER
INSERT INTO PURCHASE_ORDER (po_id, supplier_id, created_by, order_date, status, total_cost) VALUES
(1, 1, 1, '2026-08-05', 'Received', 274000.00),
(2, 2, 2, '2026-08-20', 'Received', 330000.00),
(3, 3, 1, '2026-09-10', 'Received', 294000.00),
(4, 4, 2, '2026-10-01', 'Received', 230000.00),
(5, 5, 1, '2026-11-02', 'Pending',  217500.00);

-- PURCHASE_ITEM (total_cost of each PO = SUM(quantity * unit_cost))
INSERT INTO PURCHASE_ITEM (po_item_id, po_id, watch_id, quantity, unit_cost) VALUES
(1,  1, 1,  20,  9500.00),
(2,  1, 2,  20,  4200.00),
(3,  2, 3,  10, 17000.00),
(4,  2, 4,   5, 32000.00),
(5,  3, 5,  10, 15000.00),
(6,  3, 6,   6, 24000.00),
(7,  4, 7,  10, 11000.00),
(8,  4, 8,   6, 20000.00),
(9,  5, 9,  15,  8000.00),
(10, 5, 10, 15,  6500.00);

-- SALE (total_amount = SUM(quantity*unit_price) - discount)
INSERT INTO SALE (sale_id, customer_id, salesperson_id, sale_date, discount, total_amount, payment_status) VALUES
(1, 1, 3, '2026-10-05',  500.00, 17500.00, 'Paid'),
(2, 2, 4, '2026-10-12',    0.00, 39000.00, 'Partial'),
(3, 3, 3, '2026-10-18', 1000.00, 32500.00, 'Paid'),
(4, 4, 4, '2026-10-25',    0.00, 25500.00, 'Paid'),
(5, 5, 3, '2026-11-01',  500.00, 18500.00, 'Paid'),
(6, 6, 4, '2026-11-08',    0.00, 21500.00, 'Unpaid'),
(7, 7, 3, '2026-11-10', 2000.00, 28000.00, 'Paid');

-- SALE_ITEM
INSERT INTO SALE_ITEM (sale_item_id, sale_id, watch_id, serial_no, quantity, unit_price) VALUES
(1,  1, 1,  'GS2100-0001', 1, 12500.00),
(2,  1, 2,  'MTP1374-0001',1,  5500.00),
(3,  2, 4,  'PRSG-0001',   1, 39000.00),
(4,  3, 5,  'CTZ-BM-0001', 1, 19000.00),
(5,  3, 7,  'FSL-GR-0001', 1, 14500.00),
(6,  4, 8,  'FSL-G6-0001', 1, 25500.00),
(7,  5, 9,  'TTN-ED-0001', 1, 10500.00),
(8,  5, 10, 'TTN-OC-0001', 1,  8500.00),
(9,  6, 3,  'SKO5-0001',   1, 21500.00),
(10, 7, 6,  'CTZ-PM-0001', 1, 30000.00);

-- PAYMENT
INSERT INTO PAYMENT (payment_id, sale_id, amount, method, paid_at) VALUES
(1, 1, 17500.00, 'Cash',          '2026-10-05 12:30:00'),
(2, 2, 20000.00, 'Card',          '2026-10-12 15:10:00'),
(3, 3, 32500.00, 'bKash',         '2026-10-18 17:45:00'),
(4, 4, 25500.00, 'Card',          '2026-10-25 11:20:00'),
(5, 5, 18500.00, 'Cash',          '2026-11-01 14:05:00'),
(6, 7, 28000.00, 'Bank Transfer', '2026-11-10 16:40:00'),
(7, 2, 10000.00, 'Cash',          '2026-11-05 13:15:00');

-- SALE_RETURN (sale items 5 and 8 were returned)
INSERT INTO SALE_RETURN (return_id, sale_item_id, return_date, reason, refund_amount) VALUES
(1, 5, '2026-10-30', 'Dial scratch found on delivery',          14500.00),
(2, 8, '2026-11-06', 'Customer changed mind, unused condition',  8500.00);

-- WARRANTY (one per sale item; end_date = sale date + warranty_months)
INSERT INTO WARRANTY (warranty_id, sale_item_id, start_date, end_date, status) VALUES
(1,  1,  '2026-10-05', '2027-10-05', 'Claimed'),
(2,  2,  '2026-10-05', '2027-10-05', 'Active'),
(3,  3,  '2026-10-12', '2028-10-12', 'Active'),
(4,  4,  '2026-10-18', '2028-10-18', 'Active'),
(5,  5,  '2026-10-18', '2027-10-18', 'Void'),
(6,  6,  '2026-10-25', '2027-10-25', 'Claimed'),
(7,  7,  '2026-11-01', '2027-11-01', 'Active'),
(8,  8,  '2026-11-01', '2027-11-01', 'Void'),
(9,  9,  '2026-11-08', '2028-11-08', 'Active'),
(10, 10, '2026-11-10', '2028-11-10', 'Active');

-- REPAIR
INSERT INTO REPAIR (repair_id, warranty_id, received_date, issue, repair_cost, status, delivered_date) VALUES
(1, 1, '2026-11-03', 'Backlight not working',        0.00,   'Delivered',   '2026-11-07'),
(2, 6, '2026-11-09', 'Touchscreen unresponsive',     0.00,   'In Progress', NULL),
(3, 1, '2026-11-12', 'Strap replacement (not covered)', 800.00, 'Received', NULL);

-- =====================================================================
-- 3. SAMPLE QUERIES (useful for the in-class demonstration)
-- =====================================================================

-- Q1: Full invoice view: sale, customer, salesperson, items
-- SELECT s.sale_id, c.customer_name, u.full_name AS salesperson, w.model_name, si.serial_no, si.unit_price, s.discount, s.total_amount
-- FROM SALE s
-- JOIN CUSTOMER c   ON c.customer_id = s.customer_id
-- JOIN `USER` u     ON u.user_id = s.salesperson_id
-- JOIN SALE_ITEM si ON si.sale_id = s.sale_id
-- JOIN WATCH w      ON w.watch_id = si.watch_id
-- ORDER BY s.sale_id;

-- Q2: Outstanding balance per sale
-- SELECT s.sale_id, s.total_amount, IFNULL(SUM(p.amount),0) AS paid, s.total_amount - IFNULL(SUM(p.amount),0) AS due
-- FROM SALE s LEFT JOIN PAYMENT p ON p.sale_id = s.sale_id
-- GROUP BY s.sale_id, s.total_amount;

-- Q3: Watches at or below reorder level
-- SELECT watch_id, model_name, stock_qty, reorder_level FROM WATCH WHERE stock_qty <= reorder_level;

-- Q4: Warranty and repair history
-- SELECT w.warranty_id, wt.model_name, w.status, r.issue, r.repair_cost, r.status AS repair_status
-- FROM WARRANTY w
-- JOIN SALE_ITEM si ON si.sale_item_id = w.sale_item_id
-- JOIN WATCH wt     ON wt.watch_id = si.watch_id
-- JOIN REPAIR r     ON r.warranty_id = w.warranty_id;
