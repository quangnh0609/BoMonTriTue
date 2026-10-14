DROP TABLE IF EXISTS [dbo].[bet_match]
GO
CREATE TABLE [dbo].[bet_match](
	[match] [varchar](16) NOT NULL,
	[season] [nvarchar](128) NULL,
	[time] [datetime] NULL,
	[home] [nvarchar](128) NULL,
	[way] [nvarchar](128) NULL,
	[code] [char](16) NOT NULL,
	[over_under] [numeric](19, 4) NULL,
	[over_win] [numeric](19, 4) NULL,
	[under_win] [numeric](19, 4) NULL,
	[handicap] [numeric](19, 4) NULL,
	[home_win] [numeric](19, 4) NULL,
	[way_win] [numeric](19, 4) NULL,
	[result_home] [numeric](19, 4) NULL,
	[result_way] [numeric](19, 4) NULL,
	[draw_win] [numeric](19, 4) NULL,
 CONSTRAINT [PK_bet_match] PRIMARY KEY CLUSTERED 
(
	[match] ASC,
	[code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


