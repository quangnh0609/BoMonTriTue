# Football and Esports ticket popups — 2026-10-16

Prepared in the repository only. The migration has NOT been executed against SQL Server.

## Change

`bet_ticket_result.sql` adds optional `@exactEsportMatch BIT = 0` and `@exactFootballMatch BIT = 0` to the current procedure definition captured during the investigation. It preserves the current date cutoff, settlement, totals, formatting and output order. Do not deploy the historical `Scripts/Core` definition in its place.

The Esports popup sends `ticketType: 'esport'`; `GetTicketList.aspx` then passes `@exactEsportMatch = 1`. In this mode the procedure skips football, champion and payment inserts and filters by exact `t.match_id`. Statement-level `OPTION (RECOMPILE)` lets SQL simplify the optional predicates before choosing an access path. Existing callers omit the parameter and retain the general search behavior. The existing match_id index is expected to serve this query; no new index is included.

## Deployment order (manual, not performed)

The script now also reads the configurable tracking cutoff history. First apply `../20261016_TicketTrackingCutoff/01_history.sql`; see that folder's README. The old hard-coded cutoff is seeded once into history and then replaced by the latest declaration by ID.

1. Compare the captured procedure with the target database definition to preserve any intervening changes; retain a rollback copy.
2. Apply `bet_ticket_result.sql` to the intended application database.
3. Deploy `GetTicketList.aspx`, `ucTicketMatch.ascx`, `esports.aspx` and `matches.aspx` together. Both optimized popup requests require the added SQL parameters, so deploy SQL first. If the earlier Esports-only script was already applied, reapply this updated script before deploying the football change.

## Verification

Local checks passed for the popup's Esports request, reload after ticket actions, resetting the mode when opening football, and routing champion tickets to their existing endpoint. The settlement/output portion of the migration was compared byte-for-byte with the captured live definition (apart from the final GO batch separator). `git diff --check` passed.

SQL compilation, execution plans and before/after timings of the new version have NOT been tested against a database, in accordance with the repository-only request. After deployment, compare every returned field with the previous procedure for E551 (1 ticket), E550 (144 tickets), E549 (82 tickets), an empty match, and settled/cleared tickets including BO x. Check exact-match index use and repeat timings; do not assume a measured improvement before these checks.

Before-change measurements: E551 1156.7 / 546.1 / 525.9 ms; E550 841.9 / 549.5 / 600.6 ms; E549 633.5 / 593.4 / 600.0 ms. E550's actual plan scanned all 27,829 Esports tickets; the Esports insert took 476 ms and the football insert took 55 ms. These are SQL call timings, not browser timings.

## Football extension

The local `openTicketMatchModal` override in `matches.aspx` sets `ticketType: football`; reloads after delete/clear retain it. The API sends `@exactFootballMatch = 1` only for that explicit type. The football insert binds the exact ID through `sp_executesql` (`a.match = @popupMatch`), joins `bet_match_total` for match existence instead of the status/name view, and omits the champion, payment and Esports source queries. Normal report callers still use the existing name search and all source queries. Settlement, totals and output below `-- result` are unchanged.

Run the local regression checks with `node Scripts/Migrations/20261016_EsportTicketPopup/verify-popup.cjs` from the Program directory. These exercise the actual shared popup JavaScript plus the football override and compare settlement/output SQL with the captured baseline. They do not connect to SQL. After deployment, verify football tickets with results, without results, cleared/uncleared, quarter handicaps, an empty match and IDs that also appear in match names. Actual SQL performance and returned-field equivalence still require database testing.
