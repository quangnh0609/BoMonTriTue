--DROP TABLE [dbo].[bet_match_total]
GO
CREATE TABLE [dbo].[bet_match_total](
	[match] [varchar](16) NOT NULL,
	[season] [nvarchar](128) NULL,
	[time] [datetime] NULL,
	[home] [nvarchar](128) NULL,
	[way] [nvarchar](128) NULL,
	[user_host] [int] NULL,
	
	[h1_conner_over_under] [numeric](19, 4) NULL,
	[h1_conner_over_win] [numeric](19, 4) NULL,
	[h1_conner_under_win] [numeric](19, 4) NULL,
	[h2_conner_over_under] [numeric](19, 4) NULL,
	[h2_conner_over_win] [numeric](19, 4) NULL,
	[h2_conner_under_win] [numeric](19, 4) NULL,
	[ft_conner_over_under] [numeric](19, 4) NULL,
	[ft_conner_over_win] [numeric](19, 4) NULL,
	[ft_conner_under_win] [numeric](19, 4) NULL,

	[h1_conner_handicap] [numeric](19, 4) NULL,
	[h1_conner_home_win] [numeric](19, 4) NULL,
	[h1_conner_way_win] [numeric](19, 4) NULL,
	[h2_conner_handicap] [numeric](19, 4) NULL,
	[h2_conner_home_win] [numeric](19, 4) NULL,
	[h2_conner_way_win] [numeric](19, 4) NULL,
	[ft_conner_handicap] [numeric](19, 4) NULL,
	[ft_conner_home_win] [numeric](19, 4) NULL,
	[ft_conner_way_win] [numeric](19, 4) NULL,

	[h1_goal_over_under] [numeric](19, 4) NULL,
	[h1_goal_over_win] [numeric](19, 4) NULL,
	[h1_goal_under_win] [numeric](19, 4) NULL,
	[h2_goal_over_under] [numeric](19, 4) NULL,
	[h2_goal_over_win] [numeric](19, 4) NULL,
	[h2_goal_under_win] [numeric](19, 4) NULL,
	[ft_goal_over_under] [numeric](19, 4) NULL,
	[ft_goal_over_win] [numeric](19, 4) NULL,
	[ft_goal_under_win] [numeric](19, 4) NULL,

	[h1_goal_handicap] [numeric](19, 4) NULL,
	[h1_goal_home_win] [numeric](19, 4) NULL,
	[h1_goal_way_win] [numeric](19, 4) NULL,
	[h2_goal_handicap] [numeric](19, 4) NULL,
	[h2_goal_home_win] [numeric](19, 4) NULL,
	[h2_goal_way_win] [numeric](19, 4) NULL,
	[ft_goal_handicap] [numeric](19, 4) NULL,
	[ft_goal_home_win] [numeric](19, 4) NULL,
	[ft_goal_way_win] [numeric](19, 4) NULL,

	[h1_euro_home] [numeric](19, 4) NULL,
	[h1_euro_draw] [numeric](19, 4) NULL,
	[h1_euro_way] [numeric](19, 4) NULL,
	[h2_euro_home] [numeric](19, 4) NULL,
	[h2_euro_draw] [numeric](19, 4) NULL,
	[h2_euro_way] [numeric](19, 4) NULL,
	[ft_euro_home] [numeric](19, 4) NULL,
	[ft_euro_draw] [numeric](19, 4) NULL,
	[ft_euro_way] [numeric](19, 4) NULL,

	[h1_card_over_under] [numeric](19, 4) NULL,
	[h1_card_over_win] [numeric](19, 4) NULL,
	[h1_card_under_win] [numeric](19, 4) NULL,
	[h2_card_over_under] [numeric](19, 4) NULL,
	[h2_card_over_win] [numeric](19, 4) NULL,
	[h2_card_under_win] [numeric](19, 4) NULL,
	[ft_card_over_under] [numeric](19, 4) NULL,
	[ft_card_over_win] [numeric](19, 4) NULL,
	[ft_card_under_win] [numeric](19, 4) NULL,

	[h1_card_handicap] [numeric](19, 4) NULL,
	[h1_card_home_win] [numeric](19, 4) NULL,
	[h1_card_way_win] [numeric](19, 4) NULL,
	[h2_card_handicap] [numeric](19, 4) NULL,
	[h2_card_home_win] [numeric](19, 4) NULL,
	[h2_card_way_win] [numeric](19, 4) NULL,
	[ft_card_handicap] [numeric](19, 4) NULL,
	[ft_card_home_win] [numeric](19, 4) NULL,
	[ft_card_way_win] [numeric](19, 4) NULL,
 CONSTRAINT [PK_bet_match_total] PRIMARY KEY CLUSTERED 
(
	[match] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO


