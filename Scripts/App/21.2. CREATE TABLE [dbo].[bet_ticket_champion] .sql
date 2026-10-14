DROP TABLE IF EXISTS [dbo].[bet_ticket_champion]
GO
CREATE TABLE [dbo].[bet_ticket_champion](
	[id] [int] NOT NULL,
	[user_id] [int] NOT NULL,
	[money] [numeric](19, 4) NULL,
	[datetime] [datetime] NULL,
	[clear] [char](1) NULL,
 CONSTRAINT [PK_bet_ticket_champion] PRIMARY KEY CLUSTERED 
(
	[id] ASC,
	[user_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


select * from [bet_ticket_champion]
select * from [bet_champion]