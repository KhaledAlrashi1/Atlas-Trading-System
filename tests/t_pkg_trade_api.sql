-- 1) Happy path: place a trade
DECLARE
  v_id NUMBER;
BEGIN
  ATLAS_PKG_TRADE_API.place_trade(
    p_trade_dt => DATE '2025-01-11',
    p_symbol   => 'AAPL',
    p_account  => 'Pension Fund A',
    p_side     => 'buy',      -- mixed case accepted
    p_qty      => 25,
    p_price    => 190.55,
    p_actor    => 'tester@atlas',
    p_note     => 'unit test',
    p_trade_id => v_id
  );
  DBMS_OUTPUT.PUT_LINE('Placed trade id='||v_id);
END;
/
-- Verify persisted row (no commit yet)
SELECT trade_id, trade_dt, side, qty, price FROM ATLAS_TRADE
ORDER BY trade_id DESC FETCH FIRST 1 ROWS ONLY;

-- 2) Error path: bad side
BEGIN
  ATLAS_PKG_TRADE_API.place_trade(
    p_trade_dt => SYSDATE,
    p_symbol   => 'AAPL',
    p_account  => 'Pension Fund A',
    p_side     => 'HOLD',
    p_qty      => 1,
    p_price    => 1,
    p_actor    => 'tester@atlas',
    p_note     => NULL,
    p_trade_id => :id
  );
END;
/
-- Expect: ORA-20001 SIDE must be BUY or SELL

-- 3) Cancel the last trade (commit the insert first)
COMMIT;
DECLARE
  v_last_id NUMBER;
BEGIN
  SELECT MAX(trade_id) INTO v_last_id FROM ATLAS_TRADE;
  ATLAS_PKG_TRADE_API.cancel_trade(v_last_id, 'tester@atlas', 'test cancel');
END;
/
-- Verify deletion and audit
SELECT * FROM ATLAS_TRADE WHERE TRADE_ID = (SELECT MAX(TRADE_ID) FROM ATLAS_TRADE);
SELECT ACTOR, ACTION, ENTITY, ENTITY_ID, DETAILS
FROM ATLAS_AUDIT
ORDER BY AUDIT_ID DESC FETCH FIRST 5 ROWS ONLY;
