DROP TABLE IF EXISTS [dbo].[bet_champion]
GO
CREATE TABLE [dbo].[bet_champion](
	[id] INT IDENTITY(1, 1),
	[season] [nvarchar](128) NULL,
	[time] [datetime] NULL,
	[time_lock] [datetime] NULL,
	[name] [nvarchar](1024) NULL,
	[team] [varchar](16) NULL,
	[rate_win] [numeric](19, 4) NULL,
	[result_win] [bit],
	[user_host] [int] NULL,
 CONSTRAINT [PK_bet_champion] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
