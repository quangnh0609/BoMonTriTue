DROP PROC IF EXISTS [dbo].[bet_ticket_clear]
GO
CREATE PROC [dbo].[bet_ticket_clear]
	@match NVARCHAR(MAX),
	@user_id INT,
	@code NVARCHAR(MAX),
	@ticket NVARCHAR(MAX),
	@userID INT
AS
BEGIN
	set @match = rtrim(ltrim(isnull(@match, '')))
	set @code = rtrim(ltrim(isnull(@code, '')))
	set @ticket = rtrim(ltrim(isnull(@ticket, '')))

	declare @admin bit
	select @admin = admin from vsysuserinfo where id = @userID

	if isnull(@admin, 0) = 0
		and not exists (select 1 from bet_match_total where match = @match and user_host = @userID)
		and not exists (select 1 from bet_esport_match where match_id = @match and created_by = @userID)
		and not exists (select 1 from bet_champion where user_host = @userID and id = try_cast(right(@match, 6) as int))
		and not exists (select 1 from bet_champion where user_host = @userID and season + convert(varchar(128), time, 112) + '000000' = @match) begin
		select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
		return
	end

	if @match = '' and @code = '' and @user_id = 0 begin
		select 0 as isSuccess, N'Không thanh toán dòng này' as msg
		return
	end else if @match <> '' and @code <> '' and exists (select 1 from bet_ticket_esport where match_id = @match and code = @code and user_id = @user_id) begin
		update a
			set clear = case when isnull(clear, 0) = 1 then 0 else 1 end
			from bet_ticket_esport a
			where a.match_id = @match and a.code = @code and a.user_id = @user_id
				and exists (
					select 1
					from bet_esport_game g
					cross apply (select CHARINDEX('.', a.code) as first_dot, PARSENAME(a.code, 2) as market) c
					where g.match_id = a.match_id
						and c.first_dot > 2
						and g.game_no = TRY_CAST(SUBSTRING(a.code, 2, c.first_dot - 2) as int)
						and (
							(c.market in ('OU', 'HC') and g.result_kill_home is not null and g.result_kill_way is not null)
							or (c.market = 'MIN' and g.result_minute is not null)
							or (c.market in ('DOU', 'DHC') and g.result_dragon_home is not null and g.result_dragon_way is not null)
							or (c.market = 'FD' and g.result_first_dragon is not null)
							or (c.market in ('FDT', 'FDCHEM', 'FDWIND', 'FDWATER', 'FDFIRE', 'FDEARTH') and g.result_first_dragon_type is not null)
							or (c.market = 'FIRST' and g.result_first is not null)
							or (c.market = 'THIRD' and g.result_third is not null)
							or (c.market = 'FIVE' and g.result_five is not null)
							or (c.market = 'TEN' and g.result_ten is not null)
							or (c.market = 'WIN' and g.result_win is not null)
						)
				)
	end else if @match = '' and @code = '' and @user_id <> 0 begin
		update a set clear = 1 from bet_ticket a where a.user_id = @user_id and exists (select 1 from bet_match b where a.match = b.match and a.code = b.code and b.result_home is not null)
		update a set clear = 1
			from bet_ticket_esport a
			where a.user_id = @user_id
				and exists (
					select 1
					from bet_esport_game g
					cross apply (select CHARINDEX('.', a.code) as first_dot, PARSENAME(a.code, 2) as market) c
					where g.match_id = a.match_id
						and c.first_dot > 2
						and g.game_no = TRY_CAST(SUBSTRING(a.code, 2, c.first_dot - 2) as int)
						and (
							(c.market in ('OU', 'HC') and g.result_kill_home is not null and g.result_kill_way is not null)
							or (c.market = 'MIN' and g.result_minute is not null)
							or (c.market in ('DOU', 'DHC') and g.result_dragon_home is not null and g.result_dragon_way is not null)
							or (c.market = 'FD' and g.result_first_dragon is not null)
							or (c.market in ('FDT', 'FDCHEM', 'FDWIND', 'FDWATER', 'FDFIRE', 'FDEARTH') and g.result_first_dragon_type is not null)
							or (c.market = 'FIRST' and g.result_first is not null)
							or (c.market = 'THIRD' and g.result_third is not null)
							or (c.market = 'FIVE' and g.result_five is not null)
							or (c.market = 'TEN' and g.result_ten is not null)
							or (c.market = 'WIN' and g.result_win is not null)
						)
				)
		update a set clear = 1 from bet_ticket_champion a where a.user_id = @user_id and exists (select 1 from bet_champion b where a.id = b.id and b.result_win is not null)
		update bet_payment set clear = 1 where user_id = @user_id
	end else if @match <> '' and @code = '' and @user_id <> 0 begin
		update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end from bet_ticket a where a.match = @match and a.user_id = @user_id and exists (select 1 from bet_match b where a.match = b.match and a.code = b.code and b.result_home is not null)
		update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end
			from bet_ticket_esport a
			where a.match_id = @match and a.user_id = @user_id
				and exists (
					select 1
					from bet_esport_game g
					cross apply (select CHARINDEX('.', a.code) as first_dot, PARSENAME(a.code, 2) as market) c
					where g.match_id = a.match_id
						and c.first_dot > 2
						and g.game_no = TRY_CAST(SUBSTRING(a.code, 2, c.first_dot - 2) as int)
						and (
							(c.market in ('OU', 'HC') and g.result_kill_home is not null and g.result_kill_way is not null)
							or (c.market = 'MIN' and g.result_minute is not null)
							or (c.market in ('DOU', 'DHC') and g.result_dragon_home is not null and g.result_dragon_way is not null)
							or (c.market = 'FD' and g.result_first_dragon is not null)
							or (c.market in ('FDT', 'FDCHEM', 'FDWIND', 'FDWATER', 'FDFIRE', 'FDEARTH') and g.result_first_dragon_type is not null)
							or (c.market = 'FIRST' and g.result_first is not null)
							or (c.market = 'THIRD' and g.result_third is not null)
							or (c.market = 'FIVE' and g.result_five is not null)
							or (c.market = 'TEN' and g.result_ten is not null)
							or (c.market = 'WIN' and g.result_win is not null)
						)
				)
	end else if @code <> '00' begin
		if exists (select 1 from bet_match_total where match = @match)
			update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end from bet_ticket a where a.match = @match and a.code = @code and a.user_id = @user_id and exists (select 1 from bet_match b where a.match = b.match and a.code = b.code and b.result_home is not null)
		else if cast(right(@match, 6) as int) <> 0
			update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end from bet_ticket_champion a where a.id = cast(right(@match, 6) as int) and a.user_id = @user_id and exists (select 1 from bet_champion b where a.id = b.id and b.result_win is not null)			
		else
			update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end from bet_ticket_champion a join bet_champion b on a.id = b.id where b.season + convert(varchar(128), b.time, 112) + '000000' = @match and a.user_id = @user_id and b.result_win is not null
	end else
		update bet_payment set clear = case when isnull(clear, 0) = 1 then 0 else 1 end where id = @match and user_id = @user_id

	select 1 as isSuccess, N'Thanh toán thành công!' as msg
END
--GO
--exec bet_ticket_clear @match=N'',@user_id=2,@code=N'                ',@ticket=N' ',@userID=N'2'
