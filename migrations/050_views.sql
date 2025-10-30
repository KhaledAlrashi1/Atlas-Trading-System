--------------------------------------------------------------------------------
-- ATLAS Reporting Views: enriched & KPI-friendly
--------------------------------------------------------------------------------

-- Enriched trades (business-friendly columns)
CREATE OR REPLACE VIEW ATLAS_VW_TRADES_ENRICHED AS
SELECT
  t.trade_id,
  t.trade_dt,
  i.symbol,
  i.instrument_type,
  i.currency_code,
  a.account_name,
  a.region_code,
  t.side,
  t.qty,
  t.price,
  (CASE WHEN t.side='BUY' THEN +1 ELSE -1 END) * t.qty * t.price AS signed_notional,
  t.entered_by,
  t.note
FROM ATLAS_TRADE t
JOIN ATLAS_INSTRUMENT i ON i.instrument_id = t.instrument_id
JOIN ATLAS_ACCOUNT   a ON a.account_id    = t.account_id;

-- Latest positions, with instrument/account names
CREATE OR REPLACE VIEW ATLAS_VW_POSITIONS_LATEST AS
SELECT
  p.position_id,
  p.asof_dt,
  i.symbol,
  a.account_name,
  a.region_code,
  p.qty
FROM ATLAS_POSITION p
JOIN ATLAS_INSTRUMENT i ON i.instrument_id = p.instrument_id
JOIN ATLAS_ACCOUNT   a ON a.account_id     = p.account_id;

-- KPI: P&L by instrument this month (simple demo using signed notionals)
-- (In reality P&L requires cost/market; here we use trade notionals as a proxy.)
CREATE OR REPLACE VIEW ATLAS_VW_KPI_PNL_BY_INSTRUMENT_MTD AS
SELECT
  i.symbol,
  SUM( (CASE WHEN t.side='BUY' THEN +1 ELSE -1 END) * t.qty * t.price ) AS gross_notional_mtd
FROM ATLAS_TRADE t
JOIN ATLAS_INSTRUMENT i ON i.instrument_id = t.instrument_id
WHERE TRUNC(t.trade_dt, 'MM') = TRUNC(SYSDATE, 'MM')
GROUP BY i.symbol;

-- KPI: trades per day (7-day rolling window)
CREATE OR REPLACE VIEW ATLAS_VW_KPI_TRADES_PER_DAY_7D AS
SELECT
  TRUNC(t.trade_dt) AS trade_day,
  COUNT(*)          AS trades_cnt,
  SUM(t.qty)        AS total_qty
FROM ATLAS_TRADE t
WHERE t.trade_dt >= TRUNC(SYSDATE) - 6
GROUP BY TRUNC(t.trade_dt)
ORDER BY trade_day;
