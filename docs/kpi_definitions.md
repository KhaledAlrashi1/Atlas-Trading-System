# KPI Definitions (Atlas Investment Demo)

> Cadence: update weekly (Mon) and monthly (1st business day). Owner: Junior System Analyst.

## KPI 1 — Trades per day (7D)
- **Purpose:** activity & capacity signal for the desk.
- **Definition:** count of trades grouped by trade_day over last 7 days.
- **SQL source:** `ATLAS_VW_KPI_TRADES_PER_DAY_7D`
- **Notes:** source of truth = `ATLAS_TRADE.trade_dt`

## KPI 2 — Gross Notional MTD by Instrument
- **Purpose:** concentration/risk awareness by instrument.
- **Definition:** `SUM(sign*qty*price)` this month.
- **SQL source:** `ATLAS_VW_KPI_GROSS_NOTIONAL_MTD`
- **Caveat:** proxy for P&L (we’re not valuing positions here).

## KPI 3 — Top Accounts (30D)
- **Purpose:** relationship/trading focus.
- **Definition:** last 30d `trades_cnt`, `total_qty`, `notional_sum`.
- **SQL source:** `ATLAS_VW_KPI_TOP_ACCOUNTS_30D`

## KPI 4 — Open DQ Issues
- **Purpose:** governance health.
- **Definition:** open issues grouped by `RULE_CODE`, `SEVERITY`.
- **SQL source:** `ATLAS_VW_KPI_DQ_OPEN`

## KPI 5 — Trades 7D Moving Average
- **Purpose:** trend smoothing for ops planning.
- **Definition:** 7-day MA over daily trade counts.
- **SQL source:** `ATLAS_VW_KPI_TRADES_7D_MA`
