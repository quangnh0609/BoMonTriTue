DROP TABLE IF EXISTS [dbo].[bet_payment]
GO
CREATE TABLE [dbo].[bet_payment](
	[id] [int] IDENTITY(1, 1) NOT NULL,
	[user_id] [int] NOT NULL,
	[money] [numeric](19, 4) NULL,
	[datetime] [datetime] NULL,
	[clear] [char](1) NULL,
 CONSTRAINT [PK_bet_payment] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


