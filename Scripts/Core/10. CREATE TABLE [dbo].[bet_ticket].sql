DROP TABLE IF EXISTS [dbo].[bet_ticket]
GO
CREATE TABLE [dbo].[bet_ticket](
	[user_id] [int] NOT NULL,
	[match] [varchar](16) NOT NULL,
	[code] [char](16) NOT NULL,
	[ticket] [char](1) NOT NULL,
	[money] [numeric](19, 4) NULL,
	[datetime] [datetime] NULL,
	[clear] [char](1) NULL,
 CONSTRAINT [PK_bet_ticket] PRIMARY KEY CLUSTERED 
(
	[user_id] ASC,
	[match] ASC,
	[code] ASC,
	[ticket] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


