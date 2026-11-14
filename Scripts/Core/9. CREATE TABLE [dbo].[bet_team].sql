DROP TABLE IF EXISTS [dbo].[bet_team]
GO
CREATE TABLE [dbo].[bet_team](
	[team] [char](16) NOT NULL,
	[team_name] [nvarchar](128) NOT NULL,
	[the_odds_api_name] [nvarchar](128) NULL,
	[api_football_name] [nvarchar](128) NULL,
	[is_active] [bit] NOT NULL CONSTRAINT [DF_bet_team_is_active] DEFAULT (1),
 CONSTRAINT [PK_bet_team] PRIMARY KEY CLUSTERED 
(
	[team] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
