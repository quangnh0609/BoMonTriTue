DROP PROC IF EXISTS [dbo].[bet_champion_insert]
GO
CREATE PROC [dbo].[bet_champion_insert]
	@season nvarchar(max),
	@time datetime,
	@time_lock datetime,
	@details xml,
	@userID int,
	@edit bit,
	@name nvarchar(max) = NULL
AS
BEGIN
	if exists (select 1 from bet_champion a where @edit = 0 and a.season = @season and a.time = @time) begin
		select 0 as isSuccess, N'Đã có kèo này rồi!' as msg
		return
	end

	SELECT TOP 0 season, time, time_lock, name, CAST(0 AS INT) AS id, team, rate_win, result_win, user_host INTO #bet_champion FROM bet_champion
	
	INSERT INTO #bet_champion 
		SELECT @season, @time, @time_lock, @name
			, a.Item.value('(id)[1]', 'INT') AS id
			, LEFT(a.Item.value('(team)[1]', 'NVARCHAR(MAX)'), 16) AS team
			, a.Item.value('(rate)[1]', 'DECIMAL(19, 4)') AS money
			, NULL
			, @userID
			FROM @details.nodes('/details/item') AS a(Item)
	
	if @edit = 0 begin
		insert into bet_champion select season, time, time_lock, name, team, rate_win, result_win, user_host from #bet_champion
		select 1 as isSuccess, N'Tạo kèo thành công !' as msg
	end else begin
		if not exists (select 1 from vsysuserinfo where id = @userID and admin = 1)
			and not exists (select 1 from bet_champion where season = @season and time = @time and user_host = @userID) begin
			select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
			return
		end

		declare @owner int
		select top 1 @owner = user_host from bet_champion where season = @season and time = @time
		update #bet_champion set user_host = @owner

		-- danh sách kèo cược cũ
		select id, team, rate_win into #bet_champion_old from bet_champion where season = @season and time = @time

		-- kiểm tra kèo cược cũ bị xóa có phát sinh vé cược thì không cho xóa hoặc sửa tỷ lệ
		select a.*, c.user_id, b.team as tean_new, b.rate_win as rate_win_new
			into #ticket_ps
			from #bet_champion_old a left join #bet_champion b on a.id = b.id
				join bet_ticket_champion c on a.id = c.id
			where a.rate_win <> isnull(b.rate_win, 0)
		if exists (select 1 from #ticket_ps) begin
			select top 1 0 as isSuccess
					, RTRIM(ISNULL(y.comment, '')) + N' đã cược ' 
					+ ISNULL(x.team_name, a.team) + ' (' + dbo.ff_NumberFormat(a.rate_win, '### ### ###.#0') + ')' 
					+ N', không thể ' + case when rate_win_new is null then N'xóa' else N'sửa' end + N' kèo!' as msg
				from #ticket_ps a
					left join bet_team x on a.team = x.team
					left join vsysuserinfo y on a.user_id = y.id
			return
		end

		update a set time_lock = b.time_lock, name = b.name, team = b.team, rate_win = b.rate_win from bet_champion a join #bet_champion b on a.id = b.id
		delete a from bet_champion a where season = @season and time = @time and not exists (select 1 from #bet_champion b where a.id = b.id)
		insert into bet_champion select season, time, time_lock, name, team, rate_win, result_win, user_host from #bet_champion a where not exists (select 1 from bet_champion b where a.id = b.id)
		select 1 as isSuccess, N'Sửa kèo thành công!' as msg
	end
END
