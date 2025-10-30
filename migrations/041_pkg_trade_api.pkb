--------------------------------------------------------------------------------
-- ATLAS_PKG_TRADE_API (BODY)
-- Implementation with validation, audit, and consistent error handling
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY ATLAS_PKG_TRADE_API AS

  --------------------------------------------------------------------------
  -- Private helpers
  --------------------------------------------------------------------------
  PROCEDURE audit(p_actor IN VARCHAR2, p_action IN VARCHAR2,
                  p_entity IN VARCHAR2, p_entity_id IN NUMBER,
                  p_details IN VARCHAR2) IS
  BEGIN
    INSERT INTO ATLAS_AUDIT (ACTOR, ACTION, ENTITY, ENTITY_ID, DETAILS)
    VALUES (p_actor, p_action, p_entity, p_entity_id, p_details);
  END;

  FUNCTION norm_side(p_side IN VARCHAR2) RETURN VARCHAR2 IS
    v VARCHAR2(4) := UPPER(TRIM(p_side));
  BEGIN
    IF v NOT IN ('BUY','SELL') THEN
      RAISE_APPLICATION_ERROR(-20001,'SIDE must be BUY or SELL');
    END IF;
    RETURN v;
  END;

  PROCEDURE assert_pos_num(p_val NUMBER, p_name VARCHAR2) IS
  BEGIN
    IF p_val IS NULL OR p_val <= 0 THEN
      RAISE_APPLICATION_ERROR(-20002, p_name||' must be > 0');
    END IF;
  END;

  --------------------------------------------------------------------------
  -- Public lookups
  --------------------------------------------------------------------------
  FUNCTION get_instrument_id(p_symbol IN VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    SELECT instrument_id INTO v_id
    FROM ATLAS_INSTRUMENT WHERE SYMBOL = UPPER(TRIM(p_symbol));
    RETURN v_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20003,'Unknown instrument symbol: '||p_symbol);
  END;

  FUNCTION get_account_id(p_account_name IN VARCHAR2) RETURN NUMBER IS
    v_id NUMBER;
  BEGIN
    SELECT account_id INTO v_id
    FROM ATLAS_ACCOUNT WHERE ACCOUNT_NAME = p_account_name;
    RETURN v_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20004,'Unknown account: '||p_account_name);
  END;

  --------------------------------------------------------------------------
  -- place_trade
  --------------------------------------------------------------------------
  PROCEDURE place_trade(
    p_trade_dt   IN DATE,
    p_symbol     IN VARCHAR2,
    p_account    IN VARCHAR2,
    p_side       IN VARCHAR2,
    p_qty        IN NUMBER,
    p_price      IN NUMBER,
    p_actor      IN VARCHAR2,
    p_note       IN VARCHAR2,
    p_trade_id   OUT NUMBER
  ) IS
    v_instr_id NUMBER;
    v_acct_id  NUMBER;
    v_side     VARCHAR2(4);
  BEGIN
    -- Validate inputs
    IF p_trade_dt IS NULL OR p_trade_dt < DATE '2000-01-01' THEN
      RAISE_APPLICATION_ERROR(-20005,'TRADE_DT invalid');
    END IF;

    v_instr_id := get_instrument_id(p_symbol);
    v_acct_id  := get_account_id(p_account);
    v_side     := norm_side(p_side);
    assert_pos_num(p_qty,'QTY');
    assert_pos_num(p_price,'PRICE');

    -- Do the insert
    INSERT INTO ATLAS_TRADE
      (TRADE_DT, INSTRUMENT_ID, ACCOUNT_ID, SIDE, QTY, PRICE, ENTERED_BY, NOTE)
    VALUES
      (p_trade_dt, v_instr_id, v_acct_id, v_side, p_qty, p_price, p_actor, p_note)
    RETURNING TRADE_ID INTO p_trade_id;

    -- Audit
    audit(p_actor => p_actor,
          p_action => 'PLACE_TRADE',
          p_entity => 'ATLAS_TRADE',
          p_entity_id => p_trade_id,
          p_details => 'symbol='||p_symbol||', account='||p_account||
                       ', side='||v_side||', qty='||p_qty||', price='||p_price);
    -- Note: we do NOT COMMIT here; caller decides.
  END;

  --------------------------------------------------------------------------
  -- cancel_trade
  --------------------------------------------------------------------------
  PROCEDURE cancel_trade(
    p_trade_id   IN NUMBER,
    p_actor      IN VARCHAR2,
    p_reason     IN VARCHAR2
  ) IS
    v_exists NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_exists FROM ATLAS_TRADE WHERE TRADE_ID=p_trade_id;
    IF v_exists = 0 THEN
      RAISE_APPLICATION_ERROR(-20006,'Trade not found: '||p_trade_id);
    END IF;

    DELETE FROM ATLAS_TRADE WHERE TRADE_ID = p_trade_id;

    audit(p_actor => p_actor,
          p_action => 'CANCEL_TRADE',
          p_entity => 'ATLAS_TRADE',
          p_entity_id => p_trade_id,
          p_details => NVL(p_reason,'cancelled'));

  END;

  --------------------------------------------------------------------------
  -- Read helper
  --------------------------------------------------------------------------
  FUNCTION get_trade(p_trade_id IN NUMBER) RETURN t_trade_row IS
    v t_trade_row;
  BEGIN
    SELECT t.trade_id, t.trade_dt, i.symbol, a.account_name, t.side,
           t.qty, t.price, t.entered_by, t.note
      INTO v
      FROM ATLAS_TRADE t
      JOIN ATLAS_INSTRUMENT i ON i.instrument_id=t.instrument_id
      JOIN ATLAS_ACCOUNT   a ON a.account_id=t.account_id
     WHERE t.trade_id = p_trade_id;
    RETURN v;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20007,'Trade not found: '||p_trade_id);
  END;

END ATLAS_PKG_TRADE_API;
/
