-- ============================================================================
-- Capstone Project 1: Global Logistics & Delivery Control Tower
-- Relational Schema & Data Generation Script
-- Target Engine: SQLite / DBeaver
-- ============================================================================

-- Clean up existing tables
DROP TABLE IF EXISTS fact_shipments;
DROP TABLE IF EXISTS fact_purchase_orders;
DROP TABLE IF EXISTS dim_destinations;
DROP TABLE IF EXISTS dim_carriers;
DROP TABLE IF EXISTS dim_suppliers;

-- 1. Dimension: Suppliers
CREATE TABLE dim_suppliers (
    supplier_id     VARCHAR(10) PRIMARY KEY,
    supplier_name   VARCHAR(100) NOT NULL,
    country         VARCHAR(50) NOT NULL,
    supplier_tier   VARCHAR(20) NOT NULL
);

INSERT INTO dim_suppliers (supplier_id, supplier_name, country, supplier_tier) VALUES
('SUP-001', 'Apex Industrial Valves', 'Canada', 'Tier 1'),
('SUP-002', 'Borealis Steel Inc.', 'Canada', 'Tier 1'),
('SUP-003', 'Pacific Polymer Solutions', 'USA', 'Tier 2'),
('SUP-004', 'Global Pipe & Equipment', 'USA', 'Tier 1'),
('SUP-005', 'Nordic Pump Systems', 'Germany', 'Tier 2');

-- 2. Dimension: Logistics Carriers
CREATE TABLE dim_carriers (
    carrier_id      VARCHAR(10) PRIMARY KEY,
    carrier_name    VARCHAR(100) NOT NULL,
    transport_mode  VARCHAR(30) NOT NULL -- Rail, Long-haul Truck, Ocean, Air
);

INSERT INTO dim_carriers (carrier_id, carrier_name, transport_mode) VALUES
('CAR-101', 'Canadian National Rail Logistics', 'Rail'),
('CAR-102', 'Trans-Canada Freightways', 'Long-haul Truck'),
('CAR-103', 'Western Pacific Logistics', 'Long-haul Truck'),
('CAR-104', 'Global Ocean Shipping Co', 'Ocean'),
('CAR-105', 'Northern Cargo Express', 'Air');

-- 3. Dimension: Receiving Destinations
CREATE TABLE dim_destinations (
    destination_id  VARCHAR(10) PRIMARY KEY,
    facility_name   VARCHAR(100) NOT NULL,
    city            VARCHAR(50) NOT NULL,
    province_state  VARCHAR(50) NOT NULL
);

INSERT INTO dim_destinations (destination_id, facility_name, city, province_state) VALUES
('DEST-01', 'Calgary Central Logistics Hub', 'Calgary', 'Alberta'),
('DEST-02', 'Edmonton Industrial Depot', 'Edmonton', 'Alberta'),
('DEST-03', 'Vancouver Distribution Terminal', 'Vancouver', 'British Columbia'),
('DEST-04', 'Saskatoon Regional Warehouse', 'Saskatoon', 'Saskatchewan');

-- 4. Fact: Purchase Orders (Procurement Stream)
CREATE TABLE fact_purchase_orders (
    po_id                   VARCHAR(15) PRIMARY KEY,
    supplier_id             VARCHAR(10) NOT NULL,
    po_date                 DATE NOT NULL,
    promised_delivery_date  DATE NOT NULL,
    item_category           VARCHAR(50) NOT NULL,
    order_qty               INT NOT NULL,
    unit_cost_cad           REAL NOT NULL,
    FOREIGN KEY (supplier_id) REFERENCES dim_suppliers(supplier_id)
);

INSERT INTO fact_purchase_orders (po_id, supplier_id, po_date, promised_delivery_date, item_category, order_qty, unit_cost_cad) VALUES
('PO-2026-001', 'SUP-001', '2026-01-05', '2026-01-20', 'Valves & Fittings', 500, 120.00),
('PO-2026-002', 'SUP-002', '2026-01-08', '2026-01-25', 'Structural Steel', 1200, 85.50),
('PO-2026-003', 'SUP-003', '2026-01-10', '2026-02-01', 'Chemical Polymers', 3000, 45.00),
('PO-2026-004', 'SUP-004', '2026-01-12', '2026-02-05', 'Piping Systems', 800, 210.00),
('PO-2026-005', 'SUP-005', '2026-01-15', '2026-02-20', 'Heavy Machinery', 15, 12500.00),
('PO-2026-006', 'SUP-001', '2026-01-20', '2026-02-10', 'Valves & Fittings', 750, 118.00),
('PO-2026-007', 'SUP-002', '2026-01-22', '2026-02-08', 'Structural Steel', 2000, 82.00),
('PO-2026-008', 'SUP-004', '2026-02-01', '2026-02-25', 'Piping Systems', 600, 215.00),
('PO-2026-009', 'SUP-003', '2026-02-05', '2026-02-28', 'Chemical Polymers', 4000, 42.50),
('PO-2026-010', 'SUP-005', '2026-02-10', '2026-03-15', 'Heavy Machinery', 10, 12800.00);

-- 5. Fact: Shipments (Fulfillment & Logistics Stream)
CREATE TABLE fact_shipments (
    shipment_id          VARCHAR(15) PRIMARY KEY,
    po_id                VARCHAR(15) NOT NULL,
    carrier_id           VARCHAR(10) NOT NULL,
    destination_id       VARCHAR(10) NOT NULL,
    ship_date            DATE NOT NULL,
    actual_delivery_date DATE NOT NULL,
    shipped_qty          INT NOT NULL,
    weight_tons          REAL NOT NULL,
    distance_miles       INT NOT NULL,
    freight_cost_cad     REAL NOT NULL,
    FOREIGN KEY (po_id) REFERENCES fact_purchase_orders(po_id),
    FOREIGN KEY (carrier_id) REFERENCES dim_carriers(carrier_id),
    FOREIGN KEY (destination_id) REFERENCES dim_destinations(destination_id)
);

INSERT INTO fact_shipments (shipment_id, po_id, carrier_id, destination_id, ship_date, actual_delivery_date, shipped_qty, weight_tons, distance_miles, freight_cost_cad) VALUES
('SHP-9001', 'PO-2026-001', 'CAR-102', 'DEST-01', '2026-01-15', '2026-01-19', 500, 12.5, 450, 2200.00),  -- OTIF: Perfect
('SHP-9002', 'PO-2026-002', 'CAR-101', 'DEST-02', '2026-01-18', '2026-01-28', 1200, 48.0, 620, 5800.00),  -- OTIF: LATE
('SHP-9003', 'PO-2026-003', 'CAR-103', 'DEST-03', '2026-01-20', '2026-02-01', 2800, 30.0, 1100, 7400.00), -- OTIF: SHORT (2800 vs 3000)
('SHP-9004', 'PO-2026-004', 'CAR-102', 'DEST-01', '2026-01-25', '2026-02-04', 800, 22.0, 850, 4100.00),   -- OTIF: Perfect
('SHP-9005', 'PO-2026-005', 'CAR-104', 'DEST-03', '2026-01-22', '2026-02-26', 15, 65.0, 5200, 28500.00),  -- OTIF: LATE (Ocean delay)
('SHP-9006', 'PO-2026-006', 'CAR-105', 'DEST-02', '2026-02-05', '2026-02-08', 750, 18.0, 500, 6200.00),   -- Expedited Air Freight
('SHP-9007', 'PO-2026-007', 'CAR-101', 'DEST-04', '2026-01-28', '2026-02-06', 2000, 80.0, 780, 8900.00),  -- OTIF: Perfect
('SHP-9008', 'PO-2026-008', 'CAR-103', 'DEST-01', '2026-02-15', '2026-02-27', 550, 15.0, 850, 3800.00),   -- OTIF: LATE & SHORT
('SHP-9009', 'PO-2026-009', 'CAR-102', 'DEST-03', '2026-02-18', '2026-02-27', 4000, 40.0, 1100, 8200.00),  -- OTIF: Perfect
('SHP-9010', 'PO-2026-010', 'CAR-104', 'DEST-03', '2026-02-18', '2026-03-20', 10, 45.0, 5200, 24000.00);  -- OTIF: LATE