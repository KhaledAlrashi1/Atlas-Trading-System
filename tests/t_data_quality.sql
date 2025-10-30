-- A) Plant a few dirty trades (bypassing API on purpose to simulate imports)
--    Note: some may be blocked by constraints; choose ones that pass constraints
--    but still violate business DQ (e.g., future date; unknown side value via typo)
INSERT INTO ATLAS_TRADE (TRADE_DT, INSTRUMENT_ID, ACCOUNT_ID, SIDE, QTY, PRICE, ENTERED_BY, NOTE)
SELECT TRUNC(SYSDATE)+2, i.instrument_id, a.account_id, 'BUY', 10, 1, 'import@atlas', 'future date demo'
FROM ATLAS_INSTRUMENT i, ATLAS_ACCOUNT a
WHERE i.SYMBOL='AAPL' AND a.ACCOUNT_NAME='Pension Fund A';

-- Intentionally bad SIDE (will be caught by CHECK if we try to insert directly).
-- To simulate a bypass, we temporarily disable and re-enable the check in this session only:
ALTER TABLE ATLAS_TRADE DISABLE CONSTRAINT ATLAS_TRADE_CHK1;
INSERT INTO ATLAS_TRADE (TRADE_DT, INSTRUMENT_ID, ACCOUNT_ID, SIDE, QTY, PRICE, ENTERED_BY, NOTE)
SELECT DATE '2025-01-12', i.instrument_id, a.account_id, 'b', 5, 200, 'import@atlas', 'bad side demo'
FROM ATLAS_INSTRUMENT i, ATLAS_ACCOUNT a
WHERE i.SYMBOL='AAPL' AND a.ACCOUNT_NAME='Pension Fund A';
ALTER TABLE ATLAS_TRADE ENABLE CONSTRAINT ATLAS_TRADE_CHK1;

COMMIT;

-- B) Run all DQ checks
DECLARE
  v_new NUMBER;
BEGIN
  v_new := ATLAS_PKG_DQ.run_all;
  DBMS_OUTPUT.PUT_LINE('New DQ issues logged: '||v_new);
END;
/

-- C) Inspect issues and summary
SELECT ISSUE_ID, RULE_CODE, SEVERITY, ENTITY, ENTITY_ID, SUBSTR(DETAILS,1,120) details, TS
FROM   ATLAS_DQ_ISSUE
WHERE  RESOLVED_FLG='N'
ORDER  BY ISSUE_ID DESC;

SELECT * FROM ATLAS_VW_DQ_SUMMARY;

-- D) Remediate the bad SIDE issues then re-run checks
BEGIN
  ATLAS_DQ_FIX_TRD_SIDE;
END;
/

-- Mark previously found TRD_FUTURE_DT as resolved (pretend we corrected the date elsewhere)
UPDATE ATLAS_DQ_ISSUE
   SET RESOLVED_FLG='Y'
 WHERE RULE_CODE='TRD_FUTURE_DT' AND RESOLVED_FLG='N';

COMMIT;

-- Re-run DQ
DECLARE
  v_new NUMBER;
BEGIN
  v_new := ATLAS_PKG_DQ.run_all;
  DBMS_OUTPUT.PUT_LINE('New DQ issues after remediation: '||v_new);
END;
/

-- E) Updated summary
SELECT * FROM ATLAS_VW_DQ_SUMMARY;
