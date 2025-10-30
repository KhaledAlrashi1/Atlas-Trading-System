-- Ensure server output is on (UI toggle). We'll capture plans via DISPLAY_CURSOR.

-- A) Range predicate (SARGable): TRADE_DT between dates
VARIABLE v_start DATE
VARIABLE v_end   DATE
EXEC :v_start := DATE '2025-01-05';
EXEC :v_end   := DATE '2025-01-12';

-- run once BEFORE indexes (comment out after you create indexes to compare)
SELECT /* RANGE_TEST */ COUNT(*)
FROM ATLAS_TRADE
WHERE TRADE_DT BETWEEN :v_start AND :v_end;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- B) Day predicate with TRUNC (uses function-based index if present)
VARIABLE v_day DATE
EXEC :v_day := DATE '2025-01-10';

SELECT /* TRUNC_TEST */ COUNT(*)
FROM ATLAS_TRADE
WHERE TRUNC(TRADE_DT) = :v_day;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- C) Enriched reporting query (should prefer INDEX on joins + date)
SELECT /* ENRICHED */ t.trade_dt, i.symbol, a.account_name, t.side, t.qty, t.price
FROM ATLAS_TRADE t
JOIN ATLAS_INSTRUMENT i ON i.instrument_id = t.instrument_id
JOIN ATLAS_ACCOUNT   a ON a.account_id    = t.account_id
WHERE t.trade_dt BETWEEN :v_start AND :v_end
ORDER BY t.trade_dt DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));
