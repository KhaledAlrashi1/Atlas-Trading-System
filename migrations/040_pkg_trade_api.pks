--------------------------------------------------------------------------------
-- ATLAS_PKG_TRADE_API (SPEC)
-- Public API for safe trade operations + helper lookups
--------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE ATLAS_PKG_TRADE_API AS

  -- Typed record for returning enriched trade info
  TYPE t_trade_row IS RECORD (
    trade_id        ATLAS_TRADE.TRADE_ID%TYPE,
    trade_dt        ATLAS_TRADE.TRADE_DT%TYPE,
    symbol          ATLAS_INSTRUMENT.SYMBOL%TYPE,
    account_name    ATLAS_ACCOUNT.ACCOUNT_NAME%TYPE,
    side            ATLAS_TRADE.SIDE%TYPE,
    qty             ATLAS_TRADE.QTY%TYPE,
    price           ATLAS_TRADE.PRICE%TYPE,
    entered_by      ATLAS_TRADE.ENTERED_BY%TYPE,
    note            ATLAS_TRADE.NOTE%TYPE
  );

  -- Lookup helpers (good for UI and tests)
  FUNCTION get_instrument_id(p_symbol IN VARCHAR2) RETURN NUMBER;
  FUNCTION get_account_id   (p_account_name IN VARCHAR2) RETURN NUMBER;

  -- Business operations
  PROCEDURE place_trade(
    p_trade_dt   IN DATE,
    p_symbol     IN VARCHAR2,
    p_account    IN VARCHAR2,
    p_side       IN VARCHAR2,
    p_qty        IN NUMBER,
    p_price      IN NUMBER,
    p_actor      IN VARCHAR2,
    p_note       IN VARCHAR2 DEFAULT NULL,
    p_trade_id   OUT NUMBER
  );

  PROCEDURE cancel_trade(
    p_trade_id   IN NUMBER,
    p_actor      IN VARCHAR2,
    p_reason     IN VARCHAR2 DEFAULT 'cancelled'
  );

  -- Read helper (returns one trade enriched)
  FUNCTION get_trade(p_trade_id IN NUMBER) RETURN t_trade_row;

END ATLAS_PKG_TRADE_API;
/
