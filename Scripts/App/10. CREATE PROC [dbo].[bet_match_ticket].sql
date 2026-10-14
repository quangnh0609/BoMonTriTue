DROP PROC IF EXISTS [dbo].[bet_match_ticket]
GO
CREATE PROC [dbo].[bet_match_ticket]
	@match nvarchar(4000)
AS
BEGIN
	declare @home nvarchar(max), @way nvarchar(max)
	declare @h1_conner_home int, @h1_conner_way int, @ft_conner_home int, @ft_conner_way int
		  , @h1_goal_home int, @h1_goal_way int, @ft_goal_home int, @ft_goal_way int
		  , @h1_card_home int, @h1_card_way int, @ft_card_home int, @ft_card_way int
	
	select @home = home, @way = way from vbet_match_total where match = @match
	select @h1_conner_home = a.result_home, @h1_conner_way = a.result_way from bet_match a where a.match = @match and code = '01'
	select @ft_conner_home = a.result_home, @ft_conner_way = a.result_way from bet_match a where a.match = @match and code = '03'
	select @h1_goal_home = a.result_home, @h1_goal_way = a.result_way from bet_match a where a.match = @match and code = '21'
	select @ft_goal_home = a.result_home, @ft_goal_way = a.result_way from bet_match a where a.match = @match and code = '23'
	select @h1_card_home = a.result_home, @h1_card_way = a.result_way from bet_match a where a.match = @match and code = '51'
	select @ft_card_home = a.result_home, @ft_card_way = a.result_way from bet_match a where a.match = @match and code = '53'

	select @home as home, @way as way
		 , @h1_conner_home as h1_conner_home, @h1_conner_way as h1_conner_way
		 , @ft_conner_home as ft_conner_home, @ft_conner_way as ft_conner_way
		 , @h1_goal_home as h1_goal_home, @h1_goal_way as h1_goal_way
		 , @ft_goal_home as ft_goal_home, @ft_goal_way as ft_goal_way
		 , @h1_card_home as h1_card_home, @h1_card_way as h1_card_way
		 , @ft_card_home as ft_card_home, @ft_card_way as ft_card_way
END
go
exec sp_executesql N'exec bet_match_ticket @match',N'@match nvarchar(3)',@match=N'449'