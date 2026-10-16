# Esports ticket popup — 2026-10-16

Prepared in the repository only. The migration has NOT been executed against SQL Server.

## Change

`bet_ticket_result.sql` adds optional `@exactEsportMatch BIT = 0` to the current procedure definition captured during the investigation. It preserves the current date cutoff, settlement, totals, formatting and output order. Do not deploy the historical `Scripts/Core` definition in its place.

The Esports popup sends `ticketType: 'esport'`; `GetTicketList.aspx` then passes `@exactEsportMatch = 1`. In this mode the procedure skips football, champion and payment inserts and filters by exact `t.match_id`. Statement-level `OPTION (RECOMPILE)` lets SQL simplify the optional predicates before choosing an access path. Existing callers omit the parameter and retain the general search behavior. The existing match_id index is expected to serve this query; no new index is included.

## Deployment order (manual, not performed)

1. Compare the captured procedure with the target database definition to preserve any intervening changes; retain a rollback copy.
2. Apply `bet_ticket_result.sql` to the intended application database.
3. Deploy `GetTicketList.aspx`, `ucTicketMatch.ascx` and `esports.aspx` together. The new Esports request requires the added SQL parameter, so deploy SQL first.

## Verification

Local checks passed for the popup's Esports request, reload after ticket actions, resetting the mode when opening football, and routing champion tickets to their existing endpoint. The settlement/output portion of the migration was compared byte-for-byte with the captured live definition (apart from the final GO batch separator). `git diff --check` passed.

SQL compilation, execution plans and before/after timings of the new version have NOT been tested against a database, in accordance with the repository-only request. After deployment, compare every returned field with the previous procedure for E551 (1 ticket), E550 (144 tickets), E549 (82 tickets), an empty match, and settled/cleared tickets including BO x. Check exact-match index use and repeat timings; do not assume a measured improvement before these checks.

Before-change measurements: E551 1156.7 / 546.1 / 525.9 ms; E550 841.9 / 549.5 / 600.6 ms; E549 633.5 / 593.4 / 600.0 ms. E550's actual plan scanned all 27,829 Esports tickets; the Esports insert took 476 ms and the football insert took 55 ms. These are SQL call timings, not browser timings.
