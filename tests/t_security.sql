-- 1) Assume analyst role
BEGIN
  ATLAS_SEC_CTX.assume_user('analyst@atlas');
END;
/
-- Place trade should succeed
DECLARE v_id NUMBER; BEGIN
  ATLAS_PKG_TRADE_API_SEC.place_trade(
    p_trade_dt => DATE '2025-01-12',
    p_symbol   => 'AAPL',
    p_account  => 'Pension Fund A',
    p_side     => 'BUY',
    p_qty      => 10,
    p_price    => 191.00,
    p_note     => 'by analyst',
    p_trade_id => v_id
  );
  DBMS_OUTPUT.PUT_LINE('Analyst placed trade id='||v_id);
END;
/
-- Cancel should fail for analyst (expect ORA-20112)
BEGIN
  ATLAS_PKG_TRADE_API_SEC.cancel_trade( (SELECT MAX(trade_id) FROM ATLAS_TRADE), 'test' );
END;
/
-- 2) Assume admin role
BEGIN
  ATLAS_SEC_CTX.assume_user('admin@atlas');
END;
/
-- Cancel should now succeed
BEGIN
  ATLAS_PKG_TRADE_API_SEC.cancel_trade( (SELECT MAX(trade_id) FROM ATLAS_TRADE), 'admin cancel' );
END;
/
-- 3) Show recent audit rows
SELECT ACTOR, ACTION, ENTITY, ENTITY_ID, DETAILS
FROM ATLAS_AUDIT
ORDER BY AUDIT_ID DESC FETCH FIRST 5 ROWS ONLY;
