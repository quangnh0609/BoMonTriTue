DROP PROC IF EXISTS [dbo].[bet_match_result_update]
GO
CREATE PROC [dbo].[bet_match_result_update]
	@match nvarchar(4000),
	@reset bit,
	@h1_conner_home nvarchar(4000),
	@h1_conner_way nvarchar(4000),
	@h1_goal_home nvarchar(4000),
	@h1_goal_way nvarchar(4000),
	@h1_card_home nvarchar(4000),
	@h1_card_way nvarchar(4000),
	@ft_conner_home nvarchar(4000),
	@ft_conner_way nvarchar(4000),
	@ft_goal_home nvarchar(4000),
	@ft_goal_way nvarchar(4000),
	@ft_card_home nvarchar(4000),
	@ft_card_way nvarchar(4000),
	@userID INT
AS
BEGIN
	if dbo.bet_check_right(@userID, 'bet_match_result') = '0' begin
		select 0 as isSuccess, N'Bạn không có quyền thực hiện chức năng này!' as msg
		return
	end
	
	if @reset = 0 begin
		update a set result_home = null, result_way = null from bet_match a where match = @match
		GOTO zcEnd
	end
	
	update a set result_home = case when @h1_conner_home <> '' then @h1_conner_home else null end, result_way = case when @h1_conner_way <> '' then @h1_conner_way else null end from bet_match a where match = @match and a.code in ('01', '11')
	update a set result_home = case when @ft_conner_home <> '' then @ft_conner_home else null end, result_way = case when @ft_conner_way <> '' then @ft_conner_way else null end from bet_match a where match = @match and a.code in ('02', '12', '03', '13')
	update a set result_home = case when @h1_goal_home <> '' then @h1_goal_home else null end, result_way = case when @h1_goal_way <> '' then @h1_goal_way else null end from bet_match a where match = @match and a.code in ('21', '31', '41')
	update a set result_home = case when @ft_goal_home <> '' then @ft_goal_home else null end, result_way = case when @ft_goal_way <> '' then @ft_goal_way else null end from bet_match a where match = @match and a.code in ('22', '32', '23', '33', '42', '43')
	update a set result_home = case when @h1_card_home <> '' then @h1_card_home else null end, result_way = case when @h1_card_way <> '' then @h1_card_way else null end from bet_match a where match = @match and a.code in ('51', '61')
	update a set result_home = case when @ft_card_home <> '' then @ft_card_home else null end, result_way = case when @ft_card_way <> '' then @ft_card_way else null end from bet_match a where match = @match and a.code in ('52', '62', '53', '63')
	
	zcEnd:
	select 1 as isSuccess, case when @reset = 0 then N'Xóa kết quả thành công.' else N'Cập nhật kết quả thành công!' end as msg
END
GO
exec sp_executesql N'exec bet_match_result_update @match, 1, 
					@h1_conner_home, @h1_conner_way, 
					@h1_goal_home, @h1_goal_way, 
					@h1_card_home, @h1_card_way, 
					@ft_conner_home, @ft_conner_way, 
					@ft_goal_home, @ft_goal_way, 
					@ft_card_home, @ft_card_way, 
					@userID',N'@match nvarchar(3),@h1_conner_home nvarchar(4000),@h1_conner_way nvarchar(4000),@h1_goal_home nvarchar(4000),@h1_goal_way nvarchar(4000),@h1_card_home nvarchar(2),@h1_card_way nvarchar(1),@ft_conner_home nvarchar(4000),@ft_conner_way nvarchar(4000),@ft_goal_home nvarchar(4000),@ft_goal_way nvarchar(4000),@ft_card_home nvarchar(2),@ft_card_way nvarchar(2),@userID nvarchar(1)',@match=N'825',@h1_conner_home=N'',@h1_conner_way=N'',@h1_goal_home=N'',@h1_goal_way=N'',@h1_card_home=N'10',@h1_card_way=N'8',@ft_conner_home=N'',@ft_conner_way=N'',@ft_goal_home=N'',@ft_goal_way=N'',@ft_card_home=N'19',@ft_card_way=N'20',@userID=N'2'