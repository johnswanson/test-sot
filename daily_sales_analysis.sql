-- METABASE_BEGIN
-- entity: model/Transform:v1
-- name: Daily Sales Analysis
-- identifier: daily-sales-analysis
-- description: Daily sales metrics with product category breakdown
-- tags:
-- - daily
-- database: Sample Database
-- target:
--   type: table
--   name: daily_sales_summary
-- METABASE_END

SELECT 
    DATE(o.created_at) as sale_date,
    p.category,
    COUNT(o.id) as total_orders,
    SUM(o.quantity) as total_quantity,
    SUM(o.subtotal) as gross_revenue,
    SUM(o.tax) as total_tax,
    SUM(o.total) as net_revenue,
    SUM(o.discount) as total_discounts,
    AVG(o.total) as avg_order_value,
    COUNT(DISTINCT o.user_id) as unique_customers
FROM ORDERS o
JOIN PRODUCTS p ON o.product_id = p.id
WHERE o.created_at >= CURRENT_DATE - INTERVAL '90 days'
GROUP BY DATE(o.created_at), p.category
ORDER BY sale_date DESC, net_revenue DESC;
