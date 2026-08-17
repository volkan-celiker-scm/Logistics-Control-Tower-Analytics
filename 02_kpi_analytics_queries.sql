-- Query 1: Carrier OTIF Benchmark & Performance Breakdown
WITH shipment_otif_base AS (
    SELECT 
        s.shipment_id,
        s.po_id,
        sup.supplier_name,
        c.carrier_name,
        d.facility_name,
        po.order_qty,
        s.shipped_qty,
        po.promised_delivery_date,
        s.actual_delivery_date,
        -- On-Time Flag: 1 if actual <= promised, else 0
        CASE 
            WHEN julianday(s.actual_delivery_date) <= julianday(po.promised_delivery_date) THEN 1 
            ELSE 0 
        END AS is_on_time,
        -- In-Full Flag: 1 if shipped >= ordered, else 0
        CASE 
            WHEN s.shipped_qty >= po.order_qty THEN 1 
            ELSE 0 
        END AS is_in_full
    FROM fact_shipments s
    JOIN fact_purchase_orders po ON s.po_id = po.po_id
    JOIN dim_suppliers sup ON po.supplier_id = sup.supplier_id
    JOIN dim_carriers c ON s.carrier_id = c.carrier_id
    JOIN dim_destinations d ON s.destination_id = d.destination_id
)
SELECT 
    carrier_name,
    COUNT(shipment_id) AS total_shipments,
    SUM(is_on_time) AS on_time_shipments,
    SUM(is_in_full) AS in_full_shipments,
    SUM(CASE WHEN is_on_time = 1 AND is_in_full = 1 THEN 1 ELSE 0 END) AS otif_shipments,
    ROUND(AVG(is_on_time) * 100, 1) || '%' AS on_time_rate,
    ROUND(AVG(is_in_full) * 100, 1) || '%' AS in_full_rate,
    ROUND(AVG(CASE WHEN is_on_time = 1 AND is_in_full = 1 THEN 1.0 ELSE 0.0 END) * 100, 1) || '%' AS otif_rate
FROM shipment_otif_base
GROUP BY carrier_name
ORDER BY AVG(CASE WHEN is_on_time = 1 AND is_in_full = 1 THEN 1.0 ELSE 0.0 END) DESC;



-- Query 2: Freight Cost Efficiency & Carrier Mode Ranking
WITH freight_metrics AS (
    SELECT 
        s.shipment_id,
        c.carrier_name,
        c.transport_mode,
        s.weight_tons,
        s.distance_miles,
        s.freight_cost_cad,
        CAST(julianday(s.actual_delivery_date) - julianday(s.ship_date) AS INT) AS actual_transit_days,
        ROUND(s.freight_cost_cad / (s.weight_tons * s.distance_miles), 4) AS cost_per_ton_mile
    FROM fact_shipments s
    JOIN dim_carriers c ON s.carrier_id = c.carrier_id
)
SELECT 
    shipment_id,
    carrier_name,
    transport_mode,
    actual_transit_days,
    freight_cost_cad,
    cost_per_ton_mile,
    -- Benchmark: Mode Average Cost per Ton-Mile
    ROUND(AVG(cost_per_ton_mile) OVER (PARTITION BY transport_mode), 4) AS mode_avg_cost_per_ton_mile,
    -- Rank carriers by cost efficiency within their transport mode
    DENSE_RANK() OVER (PARTITION BY transport_mode ORDER BY cost_per_ton_mile ASC) AS mode_cost_rank
FROM freight_metrics
ORDER BY transport_mode, mode_cost_rank;