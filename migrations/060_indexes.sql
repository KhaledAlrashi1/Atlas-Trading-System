--------------------------------------------------------------------------------
-- ATLAS Performance Indexes
-- Create AFTER you have data and views, so you can compare plans before/after.
--------------------------------------------------------------------------------

-- Common filters/joins: instrument, account, trade_dt
CREATE INDEX ATLAS_TRADE_I3 ON ATLAS_TRADE (TRADE_DT);
CREATE INDEX ATLAS_TRADE_I4 ON ATLAS_TRADE (INSTRUMENT_ID, TRADE_DT);

-- Function-based index for day's queries (if you often do TRUNC(trade_dt))
-- NOTE: function-based indexes require QUERY to use the SAME expression.
CREATE INDEX ATLAS_TRADE_IFBI_TRUNC_DT ON ATLAS_TRADE (TRUNC(TRADE_DT));

-- Positions: by date, then instrument/account for unique day snapshot lookups
CREATE INDEX ATLAS_POS_I3 ON ATLAS_POSITION (ASOF_DT, INSTRUMENT_ID, ACCOUNT_ID);
