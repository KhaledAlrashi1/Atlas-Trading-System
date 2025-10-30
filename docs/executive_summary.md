# Executive Summary — Atlas KPIs (Week of <YYYY-MM-DD>)

**Highlights**
- Activity rose/fell by X% w/w; 7-day MA is N.N trades/day.
- MTD gross notional concentrated in <SYMBOL1>, <SYMBOL2>.
- Top accounts (30d): <ACCT1>, <ACCT2>, <ACCT3>.
- Open DQ issues: <N> (most frequent: <RULE_CODE>).

**Details**
- **Trades per day (7d):** (paste small table or screenshot)
- **Gross Notional MTD:** (paste table from `ATLAS_VW_KPI_GROSS_NOTIONAL_MTD`)
- **Top Accounts 30d:** (top 5 by notional)
- **DQ Summary:** from `ATLAS_VW_KPI_DQ_OPEN`

**Notes / Actions**
- [ ] Investigate <RULE_CODE> spikes with data owner.
- [ ] Validate <SYMBOL> large swings; confirm if rebalancing.
- [ ] Consider index on <COLUMN> if query runtime > X sec on prod data.
