DROP PROC IF EXISTS [dbo].[bet_champion_delete]
GO
CREATE PROC [dbo].[bet_champion_delete]
	@season nvarchar(4000),
	@time datetime,
	@userID int
AS
BEGIN
	if not exists (select 1 from vsysuserinfo where id = @userID and admin = 1)
		and not exists (select 1 from bet_champion where season = @season and time = @time and user_host = @userID) begin
		select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
		return
	end
	/*
	if exists (select 1 from bet_ticket a where a.user_id = @season) begin
		select 0 as isSuccess, N'Đã phát sinh vé cược, không thể hủy!' as msg
		return
	end
	*/
	delete a from bet_champion a where a.season = @season and a.time = @time
	select 1 as isSuccess, N'Hủy kèo thành công!' as msg
END
GO
exec sp_executesql N'exec bet_champion_delete @season, @time, @userID',N'@season nvarchar(15),@time datetime,@userID nvarchar(1)',@season=N'U23 châu Á 2026',@time='2026-03-18 00:00:00',@userID=N'2'
