-- =============================================
-- Tables for Esports match and game odds
-- Recreate with DROP IF EXISTS pattern
-- =============================================

DROP TABLE IF EXISTS [dbo].[bet_esport_game]
GO
DROP TABLE IF EXISTS [dbo].[bet_esport_match]
GO

CREATE TABLE [dbo].[bet_esport_match] (
    [match_id]    NVARCHAR(50)  NOT NULL,
    [season]      NVARCHAR(100) NOT NULL,
    [home]        NVARCHAR(200) NOT NULL,
    [way]         NVARCHAR(200) NOT NULL,
    [match_time]  DATETIME      NOT NULL,
    [created_by]  INT           NULL,
    [created_at]  DATETIME      NOT NULL DEFAULT GETDATE(),
    [updated_by]  INT           NULL,
    [updated_at]  DATETIME      NULL,
    CONSTRAINT [PK_bet_esport_match] PRIMARY KEY CLUSTERED ([match_id] ASC)
)
GO

CREATE TABLE [dbo].[bet_esport_game] (
    [id]                INT           NOT NULL IDENTITY(1,1),
    [match_id]          NVARCHAR(50)  NOT NULL,
    [game_no]           INT           NOT NULL, -- 1..6 (Game 1..5 + BO x)

    -- Over/Under kills (or over/under game count for BO x)
    [ou_line]           DECIMAL(10,2) NULL,
    [ou_over_win]       DECIMAL(10,2) NULL,
    [ou_under_win]      DECIMAL(10,2) NULL,

    -- Handicap kills (or game handicap for BO x)
    [hc_line]           DECIMAL(10,2) NULL,
    [hc_home_win]       DECIMAL(10,2) NULL,
    [hc_way_win]        DECIMAL(10,2) NULL,

    -- Over/Under minutes
    [minute_line]       DECIMAL(10,2) NULL,
    [minute_over_win]   DECIMAL(10,2) NULL,
    [minute_under_win]  DECIMAL(10,2) NULL,

    -- Dragon markets
    [dragon_ou_line]        DECIMAL(10,2) NULL,
    [dragon_ou_over_win]    DECIMAL(10,2) NULL,
    [dragon_ou_under_win]   DECIMAL(10,2) NULL,
    [dragon_hc_line]        DECIMAL(10,2) NULL,
    [dragon_hc_home_win]    DECIMAL(10,2) NULL,
    [dragon_hc_way_win]     DECIMAL(10,2) NULL,
    [first_dragon_home_win] DECIMAL(10,2) NULL,
    [first_dragon_way_win]  DECIMAL(10,2) NULL,
    [first_dragon_tech_win] DECIMAL(10,2) NULL,
    [first_dragon_chemtech_win] DECIMAL(10,2) NULL,
    [first_dragon_wind_win] DECIMAL(10,2) NULL,
    [first_dragon_water_win] DECIMAL(10,2) NULL,
    [first_dragon_fire_win] DECIMAL(10,2) NULL,
    [first_dragon_earth_win] DECIMAL(10,2) NULL,

    -- Milestone bets
    [first_home_win]    DECIMAL(10,2) NULL,
    [first_way_win]     DECIMAL(10,2) NULL,
    [third_home_win]    DECIMAL(10,2) NULL,
    [third_way_win]     DECIMAL(10,2) NULL,
    [five_home_win]     DECIMAL(10,2) NULL,
    [five_way_win]      DECIMAL(10,2) NULL,
    [ten_home_win]      DECIMAL(10,2) NULL,
    [ten_way_win]       DECIMAL(10,2) NULL,
    [win_home_win]      DECIMAL(10,2) NULL,
    [win_way_win]       DECIMAL(10,2) NULL,

    -- Actual results
    [result_kill_home]  DECIMAL(10,3) NULL,
    [result_kill_way]   DECIMAL(10,3) NULL,
    [result_minute]     DECIMAL(10,3) NULL,
    [result_dragon_home] DECIMAL(10,3) NULL,
    [result_dragon_way]  DECIMAL(10,3) NULL,
    [result_first_dragon] NVARCHAR(10) NULL,
    [result_first_dragon_type] NVARCHAR(10) NULL,
    [result_first]      NVARCHAR(10)  NULL,
    [result_third]      NVARCHAR(10)  NULL,
    [result_five]       NVARCHAR(10)  NULL,
    [result_ten]        NVARCHAR(10)  NULL,
    [result_win]        NVARCHAR(10)  NULL,

    CONSTRAINT [PK_bet_esport_game] PRIMARY KEY CLUSTERED ([id] ASC),
    CONSTRAINT [FK_bet_esport_game_match] FOREIGN KEY ([match_id])
        REFERENCES [dbo].[bet_esport_match]([match_id]) ON DELETE CASCADE,
    CONSTRAINT [UQ_bet_esport_game] UNIQUE ([match_id], [game_no])
)
GO
