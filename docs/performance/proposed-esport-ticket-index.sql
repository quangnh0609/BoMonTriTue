-- Proposed only; not executed during the audit.
-- Run against the application's BoMonTriTue database after checking existing indexes.
-- Preserve all application data and existing constraints.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO
IF DB_NAME() <> N'BoMonTriTue'
    THROW 50001, 'Select the BoMonTriTue database before running this proposal.', 1;
IF OBJECT_ID(N'dbo.bet_ticket_esport', N'U') IS NULL
    THROW 50002, 'bet_ticket_esport is missing.', 1;
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'dbo.bet_ticket_esport')
      AND name = N'IX_bet_ticket_esport_match_code'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_bet_ticket_esport_match_code
        ON dbo.bet_ticket_esport (match_id, code)
        INCLUDE ([clear]);
END;
GO
