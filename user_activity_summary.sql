-- METABASE_BEGIN
-- entity: model/Transform:v1
-- name: User Activity Summary
-- identifier: user-activity-summary
-- description: Daily rollup of user activity including logins, queries, and dashboard views
-- tags:
-- - daily
-- - weekly
-- database: AppDB
-- target:
--   type: table
--   name: PUBLIC.user_activity_daily
-- METABASE_END

WITH daily_logins AS (
  SELECT 
    user_id,
    timestamp::date as activity_date,
    COUNT(*) as login_count
  FROM login_history 
  WHERE timestamp >= CURRENT_DATE - INTERVAL '90 days'
  GROUP BY user_id, timestamp::date
),
daily_views AS (
  SELECT 
    user_id,
    timestamp::date as activity_date,
    COUNT(*) as total_views,
    COUNT(DISTINCT CASE WHEN model = 'card' THEN model_id END) as unique_cards_viewed,
    COUNT(DISTINCT CASE WHEN model = 'dashboard' THEN model_id END) as unique_dashboards_viewed,
    SUM(CASE WHEN has_access = false THEN 1 ELSE 0 END) as access_denied_count
  FROM view_log
  WHERE timestamp >= CURRENT_DATE - INTERVAL '90 days'
  GROUP BY user_id, timestamp::date
),
user_info AS (
  SELECT 
    id as user_id,
    email,
    first_name,
    last_name,
    is_active,
    is_superuser
  FROM core_user
)
SELECT 
  COALESCE(dl.activity_date, dv.activity_date) as activity_date,
  COALESCE(dl.user_id, dv.user_id) as user_id,
  ui.email,
  ui.first_name,
  ui.last_name,
  ui.is_active,
  ui.is_superuser,
  COALESCE(dl.login_count, 0) as login_count,
  COALESCE(dv.total_views, 0) as total_views,
  COALESCE(dv.unique_cards_viewed, 0) as unique_cards_viewed,
  COALESCE(dv.unique_dashboards_viewed, 0) as unique_dashboards_viewed,
  COALESCE(dv.access_denied_count, 0) as access_denied_count,
  CASE 
    WHEN COALESCE(dl.login_count, 0) = 1 AND COALESCE(dv.total_views, 0) = 0 THEN 'Inactive'
    WHEN COALESCE(dv.total_views, 0) >= 10 THEN 'High Activity'
    WHEN COALESCE(dv.total_views, 0) >= 3 THEN 'Medium Activity'  
    ELSE 'Low Activity'
  END as activity_level
FROM daily_logins dl
FULL OUTER JOIN daily_views dv ON dl.user_id = dv.user_id AND dl.activity_date = dv.activity_date
LEFT JOIN user_info ui ON COALESCE(dl.user_id, dv.user_id) = ui.user_id
WHERE ui.is_active = true
ORDER BY activity_date DESC, total_views DESC;
