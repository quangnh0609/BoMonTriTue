IF COL_LENGTH('dbo.bet_esport_game', 'first_dragon_tech_win') IS NULL
    ALTER TABLE dbo.bet_esport_game ADD first_dragon_tech_win DECIMAL(10,2) NULL
GO
IF COL_LENGTH('dbo.bet_esport_game', 'first_dragon_chemtech_win') IS NULL
    ALTER TABLE dbo.bet_esport_game ADD first_dragon_chemtech_win DECIMAL(10,2) NULL
GO
IF COL_LENGTH('dbo.bet_esport_game', 'first_dragon_wind_win') IS NULL
    ALTER TABLE dbo.bet_esport_game ADD first_dragon_wind_win DECIMAL(10,2) NULL
GO
IF COL_LENGTH('dbo.bet_esport_game', 'first_dragon_water_win') IS NULL
    ALTER TABLE dbo.bet_esport_game ADD first_dragon_water_win DECIMAL(10,2) NULL
GO
IF COL_LENGTH('dbo.bet_esport_game', 'first_dragon_fire_win') IS NULL
    ALTER TABLE dbo.bet_esport_game ADD first_dragon_fire_win DECIMAL(10,2) NULL
GO
IF COL_LENGTH('dbo.bet_esport_game', 'first_dragon_earth_win') IS NULL
    ALTER TABLE dbo.bet_esport_game ADD first_dragon_earth_win DECIMAL(10,2) NULL
GO
IF COL_LENGTH('dbo.bet_esport_game', 'result_first_dragon_type') IS NULL
    ALTER TABLE dbo.bet_esport_game ADD result_first_dragon_type NVARCHAR(10) NULL
GO
