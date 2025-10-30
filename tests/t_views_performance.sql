-- =========================================================
-- A) RANGE TEST (TRADE_DT BETWEEN literal dates)
-- Run this once BEFORE indexes; save the plan output.
-- Then create indexes (060_indexes.sql) and run it again.
-- =========================================================
EXPLAIN PLAN FOR
SELECT /* RANGE_TEST */
       COUNT(*)
FROM   ATLAS_TRADE
WHERE  TRADE_DT BETWEEN DATE '2025-01-05' AND DATE '2025-01-12';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +PREDICATE'));

-- =========================================================
-- B) TRUNC() TEST (function-based predicate)
-- If you created the function-based index on TRUNC(TRADE_DT),
-- the access path should improve after indexes are in place.
-- =========================================================
EXPLAIN PLAN FOR
SELECT /* TRUNC_TEST */
       COUNT(*)
FROM   ATLAS_TRADE
WHERE  TRUNC(TRADE_DT) = DATE '2025-01-10';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +PREDICATE'));

-- =========================================================
-- C) ENRICHED REPORT (joins + date filter)
-- Shows join access paths benefiting from trade indexes.
-- =========================================================
EXPLAIN PLAN FOR
SELECT /* ENRICHED */
       t.trade_dt, i.symbol, a.account_name, t.side, t.qty, t.price
FROM   ATLAS_TRADE t
JOIN   ATLAS_INSTRUMENT i ON i.instrument_id = t.instrument_id
JOIN   ATLAS_ACCOUNT   a ON a.account_id    = t.account_id
WHERE  t.trade_dt BETWEEN DATE '2025-01-05' AND DATE '2025-01-12'
ORDER  BY t.trade_dt DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +PREDICATE'));
