# Tracking cutoff declaration history

Prepared in the repository only; no SQL has been run.

## Data and behavior

`dbo.bet_ticket_tracking_cutoff` is an append-only history in the application: ID, cutoff date/time, UTC declaration time, declaring user ID/name snapshot, and note. The UI offers no edit/delete operation. The active row is `TOP (1) ORDER BY id DESC`, never `MAX(cutoff_at)` or declaration clock time. A later declaration may move the cutoff backwards. Concurrent application declarations are serialized by a transaction/table lock in the append procedure. Restrict direct table writes to trusted database administrators.

Cutoff values follow the application's local business time (UTC+7), matching ticket timestamps. Declaration timestamps are stored in UTC and displayed in UTC+7. A single initial history row preserves the old `20/07/2026 12:00:00` cutoff; rerunning the migration never resets existing history.

Settings exposes the active cutoff, date/time input, note and paginated declaration history to administrators. Each save inserts a row, rechecks admin rights in SQL, and redirects after success to avoid duplicate inserts on refresh. ViewState is tied to the session. No existing declaration is overwritten, including when a value is reused to restore an older cutoff.

`bet_ticket_result` reads the active declaration on every call. It uses the later of the configured cutoff and the requested report start date. Supported report formats include the existing compact `yyyyMMddHHmm`, `yyyyMMddHHmmss`, date-only `yyyyMMdd`, and SQL/ISO date/time. An uninitialized table or invalid start date raises an error rather than silently bypassing the cutoff. Settlement and optimized football/Esports modes remain unchanged. The scope remains callers of this report procedure; this does not delete tickets or hide them on unrelated screens.

## Manual deployment order

1. Review the target database and preserve a rollback copy of its current procedure.
2. Run `01_history.sql` in the application database to create/seed the table and append procedure.
3. Run the updated `../20261016_EsportTicketPopup/bet_ticket_result.sql`. This includes both popup optimizations and the history-based cutoff. Do not run this report script before creating the history table.
4. Deploy `settings.aspx` along with any pending popup/API changes.

If removing the feature, restore the previous report procedure and settings page first. Preserve the history table for audit purposes.

## Verification

The ASP.NET website was precompiled locally successfully. The existing popup regression checks and unchanged settlement/output SQL comparison passed. SQL execution and browser integration have not been tested, per the repository-only request.

After deployment, verify: non-admin cannot declare a cutoff; admin can save a later or earlier date; the highest ID is active even if its cutoff is earlier; refresh does not append a duplicate; notes are encoded; pagination works; and concurrent saves retain both rows. Compare report results with blank, earlier and later requested dates, including the compact date format from tickets.aspx. No historical ticket rows should change.
