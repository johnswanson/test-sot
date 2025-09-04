-- METABASE_BEGIN
-- entity: model/Transform:v1
-- name: Product Performance Metrics
-- identifier: product-performance-metrics
-- description: Product sales performance with ratings and vendor analysis
-- tags:
-- - weekly
-- database: Sample Database
-- target:
--   type: table
--   name: product_performance
-- METABASE_END

SELECT 
    p.id,
    p.title,
    p.category,
    p.vendor,
    p.price,
    p.rating,
    COUNT(o.id) as total_orders,
    SUM(o.quantity) as units_sold,
    SUM(o.total) as total_revenue,
    AVG(o.total) as avg_order_value,
    COUNT(DISTINCT o.user_id) as unique_buyers,
    CASE 
        WHEN COUNT(o.id) >= 100 THEN 'top_seller'
        WHEN COUNT(o.id) >= 20 THEN 'good_seller'
        WHEN COUNT(o.id) >= 5 THEN 'average_seller'
        ELSE 'slow_seller'
    END as performance_tier
FROM PRODUCTS p
LEFT JOIN ORDERS o ON p.id = o.product_id 
    AND o.created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY p.id, p.title, p.category, p.vendor, p.price, p.rating
ORDER BY total_revenue DESC NULLS LAST;
