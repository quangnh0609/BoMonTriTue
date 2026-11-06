SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF COL_LENGTH('dbo.bet_team', 'is_active') IS NULL
    ALTER TABLE dbo.bet_team ADD is_active bit NOT NULL CONSTRAINT DF_bet_team_is_active DEFAULT (1) WITH VALUES;
IF COL_LENGTH('dbo.bet_season', 'is_active') IS NULL
    ALTER TABLE dbo.bet_season ADD is_active bit NOT NULL CONSTRAINT DF_bet_season_is_active DEFAULT (1) WITH VALUES;
COMMIT TRANSACTION;
