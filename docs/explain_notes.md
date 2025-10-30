# Explain Notes

## RANGE_TEST (TRADE_DT BETWEEN)
- Before: full table scan on ATLAS_TRADE (~N rows)
- After: INDEX RANGE SCAN on ATLAS_TRADE_I3
- Rows (Actual) dropped from ~… to ~…
- Reason: predicate became index-friendly; date column indexed.

## TRUNC_TEST (TRUNC(TRADE_DT) = :v_day)
- Before: full table scan
- After: INDEX RANGE SCAN on ATLAS_TRADE_IFBI_TRUNC_DT (function-based)
- Caveat: only beneficial if TRUNC is a common pattern; otherwise prefer SARGable `between` with midnight boundaries.

## ENRICHED (joins + date)
- Observed: nested loops with index access on join columns after indexes created.
- Note: composite (INSTRUMENT_ID, TRADE_DT) helps combined filtering.
