--------------------------------------------------------------------------------
-- LiveSQL-safe RBAC simulation using application context + secure wrapper
--------------------------------------------------------------------------------

-- 1) Simple user directory (demo purposes)
CREATE TABLE ATLAS_APP_USER (
  USERNAME     VARCHAR2(60) PRIMARY KEY,
  ROLE_NAME    VARCHAR2(20) NOT NULL,   -- ADMIN, ANALYST, AUDITOR
  REGION_CODE  VARCHAR2(8)  NOT NULL    -- used later for RLS
);

MERGE INTO ATLAS_APP_USER u
USING (SELECT 'admin@atlas'   usr, 'ADMIN'   role, 'KWT' region FROM dual
       UNION ALL SELECT 'analyst@atlas', 'ANALYST','KWT' FROM dual
       UNION ALL SELECT 'auditor@atlas', 'AUDITOR','EMEA' FROM dual) s
ON (u.USERNAME = s.usr)
WHEN NOT MATCHED THEN
  INSERT (USERNAME, ROLE_NAME, REGION_CODE) VALUES (s.usr, s.role, s.region);

-- 2) Application context + setter package
CREATE OR REPLACE CONTEXT ATLAS_CTX USING ATLAS_SEC_CTX;

CREATE OR REPLACE PACKAGE ATLAS_SEC_CTX AS
  PROCEDURE assume_user(p_username IN VARCHAR2);
  FUNCTION  role RETURN VARCHAR2;
  FUNCTION  region RETURN VARCHAR2;
END ATLAS_SEC_CTX;
/

CREATE OR REPLACE PACKAGE BODY ATLAS_SEC_CTX AS
  PROCEDURE assume_user(p_username IN VARCHAR2) IS
    v_role   VARCHAR2(20);
    v_region VARCHAR2(8);
  BEGIN
    SELECT role_name, region_code INTO v_role, v_region
    FROM ATLAS_APP_USER WHERE username = p_username;
    DBMS_SESSION.SET_CONTEXT('ATLAS_CTX','USERNAME', p_username);
    DBMS_SESSION.SET_CONTEXT('ATLAS_CTX','ROLE',     v_role);
    DBMS_SESSION.SET_CONTEXT('ATLAS_CTX','REGION',   v_region);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20100,'Unknown app user: '||p_username);
  END;
  FUNCTION role RETURN VARCHAR2 IS
  BEGIN
    RETURN SYS_CONTEXT('ATLAS_CTX','ROLE');
  END;
  FUNCTION region RETURN VARCHAR2 IS
  BEGIN
    RETURN SYS_CONTEXT('ATLAS_CTX','REGION');
  END;
END ATLAS_SEC_CTX;
/

-- 3) Secure wrapper over your existing API that enforces role checks
-- Policy: ANALYST can place trades, cannot cancel; ADMIN can do both; AUDITOR none.
CREATE OR REPLACE PACKAGE ATLAS_PKG_TRADE_API_SEC AS
  PROCEDURE place_trade(
    p_trade_dt IN DATE, p_symbol IN VARCHAR2, p_account IN VARCHAR2,
    p_side IN VARCHAR2, p_qty IN NUMBER, p_price IN NUMBER,
    p_note IN VARCHAR2 DEFAULT NULL, p_trade_id OUT NUMBER
  );
  PROCEDURE cancel_trade(p_trade_id IN NUMBER, p_reason IN VARCHAR2 DEFAULT 'cancelled');
END ATLAS_PKG_TRADE_API_SEC;
/

CREATE OR REPLACE PACKAGE BODY ATLAS_PKG_TRADE_API_SEC AS
  PROCEDURE assert_can(p_action IN VARCHAR2) IS
    r VARCHAR2(20) := ATLAS_SEC_CTX.role;
  BEGIN
    IF r IS NULL THEN
      RAISE_APPLICATION_ERROR(-20110,'No role set. Call ATLAS_SEC_CTX.assume_user first.');
    END IF;
    IF p_action = 'PLACE' AND r NOT IN ('ADMIN','ANALYST') THEN
      RAISE_APPLICATION_ERROR(-20111,'Role '||r||' cannot place trades');
    ELSIF p_action = 'CANCEL' AND r <> 'ADMIN' THEN
      RAISE_APPLICATION_ERROR(-20112,'Only ADMIN can cancel trades');
    END IF;
  END;
  PROCEDURE place_trade(
    p_trade_dt IN DATE, p_symbol IN VARCHAR2, p_account IN VARCHAR2,
    p_side IN VARCHAR2, p_qty IN NUMBER, p_price IN NUMBER,
    p_note IN VARCHAR2, p_trade_id OUT NUMBER
  ) IS
  BEGIN
    assert_can('PLACE');
    ATLAS_PKG_TRADE_API.place_trade(
      p_trade_dt => p_trade_dt, p_symbol => p_symbol, p_account => p_account,
      p_side => p_side, p_qty => p_qty, p_price => p_price,
      p_actor => SYS_CONTEXT('ATLAS_CTX','USERNAME'),
      p_note => p_note, p_trade_id => p_trade_id
    );
  END;
  PROCEDURE cancel_trade(p_trade_id IN NUMBER, p_reason IN VARCHAR2) IS
  BEGIN
    assert_can('CANCEL');
    ATLAS_PKG_TRADE_API.cancel_trade(
      p_trade_id => p_trade_id,
      p_actor    => SYS_CONTEXT('ATLAS_CTX','USERNAME'),
      p_reason   => p_reason
    );
  END;
END ATLAS_PKG_TRADE_API_SEC;
/
