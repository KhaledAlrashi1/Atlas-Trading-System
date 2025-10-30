--------------------------------------------------------------------------------
-- ATLAS KPIs & Reporting Views
-- Assumes S1..S6 are in place.
--------------------------------------------------------------------------------

-- A. Month-to-date (MTD) start/end helpers (inline for readability)
--    We embed the logic directly in WHERE clauses below.

-- KPI 1: Trades per day (last 7 days rolling)
CREATE OR REPLACE VIEW ATLAS_VW_KPI_TRADES_PER_DAY_7D AS
SELECT
  TRUNC(t.trade_dt)             AS trade_day,
  COUNT(*)                      AS trades_cnt,
  SUM(t.qty)                    AS total_qty
FROM ATLAS_TRADE t
WHERE t.trade_dt >= TRUNC(SYSDATE) - 6
GROUP BY TRUNC(t.trade_dt)
ORDER BY trade_day;

-- KPI 2: Gross notional MTD by instrument (BUY positive, SELL negative)
CREATE OR REPLACE VIEW ATLAS_VW_KPI_GROSS_NOTIONAL_MTD AS
SELECT
  i.symbol,
  SUM( (CASE WHEN t.side='BUY' THEN +1 ELSE -1 END) * t.qty * t.price ) AS gross_notional_mtd
FROM ATLAS_TRADE t
JOIN ATLAS_INSTRUMENT i ON i.instrument_id = t.instrument_id
WHERE t.trade_dt >= TRUNC(SYSDATE,'MM')
  AND t.trade_dt <  ADD_MONTHS(TRUNC(SYSDATE,'MM'),1)
GROUP BY i.symbol
ORDER BY ABS(SUM( (CASE WHEN t.side='BUY' THEN +1 ELSE -1 END) * t.qty * t.price )) DESC;

-- KPI 3: Top counterparties/accounts by volume in last 30 days
CREATE OR REPLACE VIEW ATLAS_VW_KPI_TOP_ACCOUNTS_30D AS
SELECT
  a.account_name,
  COUNT(*)             AS trades_cnt,
  SUM(t.qty)           AS total_qty,
  SUM(t.qty*t.price)   AS notional_sum
FROM ATLAS_TRADE t
JOIN ATLAS_ACCOUNT a ON a.account_id = t.account_id
WHERE t.trade_dt >= TRUNC(SYSDATE) - 29
GROUP BY a.account_name
ORDER BY notional_sum DESC;

-- KPI 4: Data Quality (open issues by rule/severity) – already summarized, keep for consistency
CREATE OR REPLACE VIEW ATLAS_VW_KPI_DQ_OPEN AS
SELECT RULE_CODE, SEVERITY, OPEN_ISSUES
FROM   ATLAS_VW_DQ_SUMMARY
ORDER  BY SEVERITY, RULE_CODE;

-- KPI 5: Rolling 7-day trade count + 7-day moving average
-- Demonstrates an analytic (window) function
CREATE OR REPLACE VIEW ATLAS_VW_KPI_TRADES_7D_MA AS
WITH base AS (
  SELECT TRUNC(t.trade_dt) AS d, COUNT(*) AS trades_cnt
  FROM   ATLAS_TRADE t
  WHERE  t.trade_dt >= TRUNC(SYSDATE) - 30
  GROUP  BY TRUNC(t.trade_dt)
)
SELECT
  d,
  trades_cnt,
  AVG(trades_cnt) OVER (
    ORDER BY d
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS trades_cnt_ma7
FROM base
ORDER BY d;

--------------------------------------------------------------------------------
-- Saved “report queries” as views (for APEX or CSV export)
--------------------------------------------------------------------------------

-- Weekly summary: last full week (Mon..Sun) based on current date
CREATE OR REPLACE VIEW ATLAS_VW_RPT_WEEKLY_SUMMARY AS
SELECT
  MIN(TRUNC(t.trade_dt,'IW')) AS week_start,
  MAX(TRUNC(t.trade_dt,'IW')+6) AS week_end,
  COUNT(*)                    AS trades_cnt,
  SUM(t.qty*t.price)          AS notional_sum
FROM ATLAS_TRADE t
WHERE TRUNC(t.trade_dt,'IW') = TRUNC(SYSDATE,'IW');

-- Monthly summary (current month)
CREATE OR REPLACE VIEW ATLAS_VW_RPT_MONTHLY_SUMMARY AS
SELECT
  TRUNC(SYSDATE,'MM')                      AS month_start,
  ADD_MONTHS(TRUNC(SYSDATE,'MM'), 1) - 1   AS month_end,
  COUNT(*)                                  AS trades_cnt,
  SUM(t.qty*t.price)                        AS notional_sum
FROM ATLAS_TRADE t
WHERE t.trade_dt >= TRUNC(SYSDATE,'MM')
  AND t.trade_dt <  ADD_MONTHS(TRUNC(SYSDATE,'MM'),1);
