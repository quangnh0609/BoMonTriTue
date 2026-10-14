IF COL_LENGTH('dbo.bet_match_total', 'user_host') IS NULL
	ALTER TABLE [dbo].[bet_match_total] ADD [user_host] INT NULL
GO

IF COL_LENGTH('dbo.bet_champion', 'user_host') IS NULL
	ALTER TABLE [dbo].[bet_champion] ADD [user_host] INT NULL
GO
