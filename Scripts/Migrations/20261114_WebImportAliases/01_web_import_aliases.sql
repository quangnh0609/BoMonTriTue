-- Run in the application's BoMonTriTue database before deploying the updated importer.
-- Existing display names are preserved. Do not backfill: their original values cannot be inferred.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.bet_team', 'the_odds_api_name') IS NULL
    ALTER TABLE dbo.bet_team ADD the_odds_api_name nvarchar(128) NULL;
IF COL_LENGTH('dbo.bet_team', 'api_football_name') IS NULL
    ALTER TABLE dbo.bet_team ADD api_football_name nvarchar(128) NULL;
IF COL_LENGTH('dbo.bet_season', 'the_odds_api_name') IS NULL
    ALTER TABLE dbo.bet_season ADD the_odds_api_name nvarchar(128) NULL;
IF COL_LENGTH('dbo.bet_season', 'api_football_name') IS NULL
    ALTER TABLE dbo.bet_season ADD api_football_name nvarchar(128) NULL;
COMMIT TRANSACTION;
