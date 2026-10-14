DROP PROC IF EXISTS [dbo].[bet_match_insert]
GO
CREATE PROC [dbo].[bet_match_insert]
	@match nvarchar(4000),
	@season nvarchar(4000),
	@time datetime,
	@home nvarchar(4000),
	@way nvarchar(4000),
	@details xml,
	@userID int,
	@edit bit = 0
AS
BEGIN
	declare @h1_conner_over_under nvarchar(4000),
	@ft_conner_over_under nvarchar(4000),
	@h2_conner_over_under nvarchar(4000),
	@h1_conner_handicap nvarchar(4000),
	@ft_conner_handicap nvarchar(4000),
	@h2_conner_handicap nvarchar(4000),
	
	@h1_goal_over_under nvarchar(4000),
	@ft_goal_over_under nvarchar(4000),
	@h2_goal_over_under nvarchar(4000),
	@h1_goal_handicap nvarchar(4000),
	@ft_goal_handicap nvarchar(4000),
	@h2_goal_handicap nvarchar(4000),

	@h1_card_over_under nvarchar(4000),
	@ft_card_over_under nvarchar(4000),
	@h2_card_over_under nvarchar(4000),
	@h1_card_handicap nvarchar(4000),
	@ft_card_handicap nvarchar(4000),
	@h2_card_handicap nvarchar(4000),
	
	@h1_euro_home nvarchar(4000),
	@ft_euro_home nvarchar(4000),
	@h2_euro_home nvarchar(4000),
	@h1_euro_draw nvarchar(4000),
	@ft_euro_draw nvarchar(4000),
	@h2_euro_draw nvarchar(4000),
	@h1_euro_way nvarchar(4000),
	@ft_euro_way nvarchar(4000),
	@h2_euro_way nvarchar(4000),
	
	@h1_conner_over_win nvarchar(4000),
	@ft_conner_over_win nvarchar(4000),
	@h2_conner_over_win nvarchar(4000),
	@h1_conner_under_win nvarchar(4000),
	@ft_conner_under_win nvarchar(4000),
	@h2_conner_under_win nvarchar(4000),
	@h1_conner_home_win nvarchar(4000),
	@ft_conner_home_win nvarchar(4000),
	@h2_conner_home_win nvarchar(4000),
	@h1_conner_way_win nvarchar(4000),
	@ft_conner_way_win nvarchar(4000),
	@h2_conner_way_win nvarchar(4000),
	
	@h1_goal_over_win nvarchar(4000),
	@ft_goal_over_win nvarchar(4000),
	@h2_goal_over_win nvarchar(4000),
	@h1_goal_under_win nvarchar(4000),
	@ft_goal_under_win nvarchar(4000),
	@h2_goal_under_win nvarchar(4000),
	@h1_goal_home_win nvarchar(4000),
	@ft_goal_home_win nvarchar(4000),
	@h2_goal_home_win nvarchar(4000),
	@h1_goal_way_win nvarchar(4000),
	@ft_goal_way_win nvarchar(4000),
	@h2_goal_way_win nvarchar(4000),

	@h1_card_over_win nvarchar(4000),
	@ft_card_over_win nvarchar(4000),
	@h2_card_over_win nvarchar(4000),
	@h1_card_under_win nvarchar(4000),
	@ft_card_under_win nvarchar(4000),
	@h2_card_under_win nvarchar(4000),
	@h1_card_home_win nvarchar(4000),
	@ft_card_home_win nvarchar(4000),
	@h2_card_home_win nvarchar(4000),
	@h1_card_way_win nvarchar(4000),
	@ft_card_way_win nvarchar(4000),
	@h2_card_way_win nvarchar(4000)

	select a.Item.value('(col)[1]', 'NVARCHAR(MAX)') as col
			, TRY_CAST(a.Item.value('(h1)[1]', 'NVARCHAR(MAX)') AS DECIMAL(19,2)) as h1
			, TRY_CAST(a.Item.value('(ft)[1]', 'NVARCHAR(MAX)') AS DECIMAL(19,2)) as ft
			, TRY_CAST(a.Item.value('(h2)[1]', 'NVARCHAR(MAX)') AS DECIMAL(19,2)) as h2
		into #detail
		from @details.nodes('/details/item') AS a(Item)

	select @h1_conner_over_under = h1, @ft_conner_over_under = ft, @h2_conner_over_under = h2 from #detail where col = 'conner_over_under'
	select @h1_conner_handicap = h1, @ft_conner_handicap = ft, @h2_conner_handicap = h2 from #detail where col = 'conner_handicap'
	select @h1_goal_over_under = h1, @ft_goal_over_under = ft, @h2_goal_over_under = h2 from #detail where col = 'goal_over_under'
	select @h1_goal_handicap = h1, @ft_goal_handicap = ft, @h2_goal_handicap = h2 from #detail where col = 'goal_handicap'
	select @h1_card_over_under = h1, @ft_card_over_under = ft, @h2_card_over_under = h2 from #detail where col = 'card_over_under'
	select @h1_card_handicap = h1, @ft_card_handicap = ft, @h2_card_handicap = h2 from #detail where col = 'card_handicap'

	select @h1_euro_home = h1, @ft_euro_home = ft, @h2_euro_home = h2 from #detail where col = 'euro_home'
	select @h1_euro_way = h1, @ft_euro_way = ft, @h2_euro_way = h2 from #detail where col = 'euro_way'
	select @h1_euro_draw = h1, @ft_euro_draw = ft, @h2_euro_draw = h2 from #detail where col = 'euro_draw'
	
	select @h1_conner_over_win = h1, @ft_conner_over_win = ft, @h2_conner_over_win = h2 from #detail where col = 'conner_over_win'
	select @h1_conner_under_win = h1, @ft_conner_under_win = ft, @h2_conner_under_win = h2 from #detail where col = 'conner_under_win'
	select @h1_conner_home_win = h1, @ft_conner_home_win = ft, @h2_conner_home_win = h2 from #detail where col = 'conner_home_win'
	select @h1_conner_way_win = h1, @ft_conner_way_win = ft, @h2_conner_way_win = h2 from #detail where col = 'conner_way_win'

	select @h1_goal_over_win = h1, @ft_goal_over_win = ft, @h2_goal_over_win = h2 from #detail where col = 'goal_over_win'
	select @h1_goal_under_win = h1, @ft_goal_under_win = ft, @h2_goal_under_win = h2 from #detail where col = 'goal_under_win'
	select @h1_goal_home_win = h1, @ft_goal_home_win = ft, @h2_goal_home_win = h2 from #detail where col = 'goal_home_win'
	select @h1_goal_way_win = h1, @ft_goal_way_win = ft, @h2_goal_way_win = h2 from #detail where col = 'goal_way_win'
	
	select @h1_card_over_win = h1, @ft_card_over_win = ft, @h2_card_over_win = h2 from #detail where col = 'card_over_win'
	select @h1_card_under_win = h1, @ft_card_under_win = ft, @h2_card_under_win = h2 from #detail where col = 'card_under_win'
	select @h1_card_home_win = h1, @ft_card_home_win = ft, @h2_card_home_win = h2 from #detail where col = 'card_home_win'
	select @h1_card_way_win = h1, @ft_card_way_win = ft, @h2_card_way_win = h2 from #detail where col = 'card_way_win'

	if @match is null select @match = ''
	
	if isnull(@h1_conner_over_win, '') = '' select @h1_conner_over_win = '0.90'
	if isnull(@h2_conner_over_win, '') = '' select @h2_conner_over_win = '0.90'
	if isnull(@ft_conner_over_win, '') = '' select @ft_conner_over_win = '0.90'

	if isnull(@h1_conner_under_win, '') = '' select @h1_conner_under_win = '0.90'
	if isnull(@h2_conner_under_win, '') = '' select @h2_conner_under_win = '0.90'
	if isnull(@ft_conner_under_win, '') = '' select @ft_conner_under_win = '0.90'

	if isnull(@h1_conner_home_win, '') = '' select @h1_conner_home_win = '0.90'
	if isnull(@h2_conner_home_win, '') = '' select @h2_conner_home_win = '0.90'
	if isnull(@ft_conner_home_win, '') = '' select @ft_conner_home_win = '0.90'

	if isnull(@h1_conner_way_win, '') = '' select @h1_conner_way_win = '0.90'
	if isnull(@h2_conner_way_win, '') = '' select @h2_conner_way_win = '0.90'
	if isnull(@ft_conner_way_win, '') = '' select @ft_conner_way_win = '0.90'
	
	if isnull(@h1_goal_over_win, '') = '' select @h1_goal_over_win = '0.90'
	if isnull(@h2_goal_over_win, '') = '' select @h2_goal_over_win = '0.90'
	if isnull(@ft_goal_over_win, '') = '' select @ft_goal_over_win = '0.90'

	if isnull(@h1_goal_under_win, '') = '' select @h1_goal_under_win = '0.90'
	if isnull(@h2_goal_under_win, '') = '' select @h2_goal_under_win = '0.90'
	if isnull(@ft_goal_under_win, '') = '' select @ft_goal_under_win = '0.90'

	if isnull(@h1_goal_home_win, '') = '' select @h1_goal_home_win = '0.90'
	if isnull(@h2_goal_home_win, '') = '' select @h2_goal_home_win = '0.90'
	if isnull(@ft_goal_home_win, '') = '' select @ft_goal_home_win = '0.90'

	if isnull(@h1_goal_way_win, '') = '' select @h1_goal_way_win = '0.90'
	if isnull(@h2_goal_way_win, '') = '' select @h2_goal_way_win = '0.90'
	if isnull(@ft_goal_way_win, '') = '' select @ft_goal_way_win = '0.90'

	if isnull(@h1_card_over_win, '') = '' select @h1_card_over_win = '0.90'
	if isnull(@h2_card_over_win, '') = '' select @h2_card_over_win = '0.90'
	if isnull(@ft_card_over_win, '') = '' select @ft_card_over_win = '0.90'

	if isnull(@h1_card_under_win, '') = '' select @h1_card_under_win = '0.90'
	if isnull(@h2_card_under_win, '') = '' select @h2_card_under_win = '0.90'
	if isnull(@ft_card_under_win, '') = '' select @ft_card_under_win = '0.90'

	if isnull(@h1_card_home_win, '') = '' select @h1_card_home_win = '0.90'
	if isnull(@h2_card_home_win, '') = '' select @h2_card_home_win = '0.90'
	if isnull(@ft_card_home_win, '') = '' select @ft_card_home_win = '0.90'

	if isnull(@h1_card_way_win, '') = '' select @h1_card_way_win = '0.90'
	if isnull(@h2_card_way_win, '') = '' select @h2_card_way_win = '0.90'
	if isnull(@ft_card_way_win, '') = '' select @ft_card_way_win = '0.90'
	
	select @match as match, @season as season, @time as time, @home as home, @way as way
			, @h1_conner_over_under as h1_conner_over_under, @ft_conner_over_under as ft_conner_over_under, @h2_conner_over_under as h2_conner_over_under
			, @h1_conner_handicap as h1_conner_handicap, @ft_conner_handicap as ft_conner_handicap, @h2_conner_handicap as h2_conner_handicap
			, @h1_goal_over_under as h1_goal_over_under, @ft_goal_over_under as ft_goal_over_under, @h2_goal_over_under as h2_goal_over_under
			, @h1_goal_handicap as h1_goal_handicap, @ft_goal_handicap as ft_goal_handicap, @h2_goal_handicap as h2_goal_handicap
			, @h1_card_over_under as h1_card_over_under, @ft_card_over_under as ft_card_over_under, @h2_card_over_under as h2_card_over_under
			, @h1_card_handicap as h1_card_handicap, @ft_card_handicap as ft_card_handicap, @h2_card_handicap as h2_card_handicap
			, @h1_euro_home as h1_euro_home, @ft_euro_home as ft_euro_home, @h2_euro_home as h2_euro_home
			, @h1_euro_draw as h1_euro_draw, @ft_euro_draw as ft_euro_draw, @h2_euro_draw as h2_euro_draw
			, @h1_euro_way as h1_euro_way, @ft_euro_way as ft_euro_way, @h2_euro_way as h2_euro_way
			, @h1_conner_over_win as h1_conner_over_win, @ft_conner_over_win as ft_conner_over_win, @h2_conner_over_win as h2_conner_over_win
			, @h1_conner_under_win as h1_conner_under_win, @ft_conner_under_win as ft_conner_under_win, @h2_conner_under_win as h2_conner_under_win
			, @h1_conner_home_win as h1_conner_home_win, @ft_conner_home_win as ft_conner_home_win, @h2_conner_home_win as h2_conner_home_win
			, @h1_conner_way_win as h1_conner_way_win, @ft_conner_way_win as ft_conner_way_win, @h2_conner_way_win as h2_conner_way_win
			, @h1_goal_over_win as h1_goal_over_win, @ft_goal_over_win as ft_goal_over_win, @h2_goal_over_win as h2_goal_over_win
			, @h1_goal_under_win as h1_goal_under_win, @ft_goal_under_win as ft_goal_under_win, @h2_goal_under_win as h2_goal_under_win
			, @h1_goal_home_win as h1_goal_home_win, @ft_goal_home_win as ft_goal_home_win, @h2_goal_home_win as h2_goal_home_win
			, @h1_goal_way_win as h1_goal_way_win, @ft_goal_way_win as ft_goal_way_win, @h2_goal_way_win as h2_goal_way_win
			, @h1_card_over_win as h1_card_over_win, @ft_card_over_win as ft_card_over_win, @h2_card_over_win as h2_card_over_win
			, @h1_card_under_win as h1_card_under_win, @ft_card_under_win as ft_card_under_win, @h2_card_under_win as h2_card_under_win
			, @h1_card_home_win as h1_card_home_win, @ft_card_home_win as ft_card_home_win, @h2_card_home_win as h2_card_home_win
			, @h1_card_way_win as h1_card_way_win, @ft_card_way_win as ft_card_way_win, @h2_card_way_win as h2_card_way_win
			, @userID as user_id, @edit as edit_yn
		into #input

	if exists (select 1 from #input a join bet_match_total b on a.edit_yn = 0 and a.season = b.season and a.home = b.home and a.way = b.way and b.time = @time) begin
		select 0 as isSuccess, N'Đã có trận đấu này rồi!' as msg
		return
	end
	
	select top 0 * into #bet_match from bet_match

	insert into #bet_match select match, season, @time, home, way, '01', h1_conner_over_under, h1_conner_over_win, h1_conner_under_win, null, null, null, null, null, null from #input where h1_conner_over_under <> ''
	insert into #bet_match select match, season, @time, home, way, '02', h2_conner_over_under, h2_conner_over_win, h2_conner_under_win, null, null, null, null, null, null from #input where h2_conner_over_under <> ''
	insert into #bet_match select match, season, @time, home, way, '03', ft_conner_over_under, ft_conner_over_win, ft_conner_under_win, null, null, null, null, null, null from #input where ft_conner_over_under <> ''

	insert into #bet_match select match, season, @time, home, way, '11', null, null, null, h1_conner_handicap, h1_conner_home_win, h1_conner_way_win, null, null, null from #input where h1_conner_handicap <> ''
	insert into #bet_match select match, season, @time, home, way, '12', null, null, null, h2_conner_handicap, h1_conner_home_win, h1_conner_way_win, null, null, null from #input where h2_conner_handicap <> ''
	insert into #bet_match select match, season, @time, home, way, '13', null, null, null, ft_conner_handicap, h1_conner_home_win, h1_conner_way_win, null, null, null from #input where ft_conner_handicap <> ''

	insert into #bet_match select match, season, @time, home, way, '21', h1_goal_over_under, h1_goal_over_win, h1_goal_under_win, null, null, null, null, null, null from #input where h1_goal_over_under <> ''
	insert into #bet_match select match, season, @time, home, way, '22', h2_goal_over_under, h2_goal_over_win, h2_goal_under_win, null, null, null, null, null, null from #input where h2_goal_over_under <> ''
	insert into #bet_match select match, season, @time, home, way, '23', ft_goal_over_under, ft_goal_over_win, ft_goal_under_win, null, null, null, null, null, null from #input where ft_goal_over_under <> ''

	insert into #bet_match select match, season, @time, home, way, '31', null, null, null, h1_goal_handicap, h1_goal_home_win, h1_goal_way_win, null, null, null from #input where h1_goal_handicap <> ''
	insert into #bet_match select match, season, @time, home, way, '32', null, null, null, h2_goal_handicap, h2_goal_home_win, h2_goal_way_win, null, null, null from #input where h2_goal_handicap <> ''
	insert into #bet_match select match, season, @time, home, way, '33', null, null, null, ft_goal_handicap, ft_goal_home_win, ft_goal_way_win, null, null, null from #input where ft_goal_handicap <> ''

	insert into #bet_match select match, season, @time, home, way, '51', h1_card_over_under, h1_card_over_win, h1_card_under_win, null, null, null, null, null, null from #input where h1_card_over_under <> ''
	insert into #bet_match select match, season, @time, home, way, '52', h2_card_over_under, h2_card_over_win, h2_card_under_win, null, null, null, null, null, null from #input where h2_card_over_under <> ''
	insert into #bet_match select match, season, @time, home, way, '53', ft_card_over_under, ft_card_over_win, ft_card_under_win, null, null, null, null, null, null from #input where ft_card_over_under <> ''

	insert into #bet_match select match, season, @time, home, way, '61', null, null, null, h1_card_handicap, h1_card_home_win, h1_card_way_win, null, null, null from #input where h1_card_handicap <> ''
	insert into #bet_match select match, season, @time, home, way, '62', null, null, null, h2_card_handicap, h1_card_home_win, h1_card_way_win, null, null, null from #input where h2_card_handicap <> ''
	insert into #bet_match select match, season, @time, home, way, '63', null, null, null, ft_card_handicap, h1_card_home_win, h1_card_way_win, null, null, null from #input where ft_card_handicap <> ''

	insert into #bet_match select match, season, @time, home, way, '41', null, null, null, null, h1_euro_home, h1_euro_way, null, null, h1_euro_draw from #input where h1_euro_home <> ''
	insert into #bet_match select match, season, @time, home, way, '42', null, null, null, null, h2_euro_home, h2_euro_way, null, null, h2_euro_draw from #input where h2_euro_home <> ''
	insert into #bet_match select match, season, @time, home, way, '43', null, null, null, null, ft_euro_home, ft_euro_way, null, null, ft_euro_draw from #input where ft_euro_home <> ''

	update #bet_match set over_win = '0.90' where over_win = 0
	update #bet_match set under_win = '0.90' where under_win = 0
	update #bet_match set home_win = '0.90' where home_win = 0
	update #bet_match set way_win = '0.90' where way_win = 0

	if exists (select 1 from #bet_match where match = '') begin
		update #bet_match set match = (select max(try_cast(match as int)) + 1 from bet_match where try_cast(match as int) is not null)
		insert into bet_match select * from #bet_match
		update bet_match_total set user_host = @userID where match = (select top 1 match from #bet_match)
		select 1 as isSuccess, N'Tạo trận thành công !' as msg
	end else begin
		if not exists (select 1 from vsysuserinfo where id = @userID and admin = 1)
			and not exists (select 1 from bet_match_total b join #bet_match x on b.match = x.match where b.user_host = @userID) begin
			select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
			return
		end
	
		delete a from bet_match a join #bet_match b on a.match = b.match
		insert into bet_match select * from #bet_match
		select 1 as isSuccess, N'Sửa trận thành công!' as msg
	end
END
go
exec bet_match_insert @match=N'826',@season=N'SERIA-2025-2026',@time='2026-05-30 01:45:00',@home=N'AAS',@way=N'ACM',@details=N'<details>
  <item>
    <col>conner_over_under</col>
    <h1>4.50</h1>
    <ft>8.50</ft>
    <h2></h2>
  </item>
  <item>
    <col>conner_handicap</col>
    <h1>-0.50</h1>
    <ft>-0.50</ft>
    <h2></h2>
  </item>
  <item>
    <col>goal_over_under</col>
    <h1>1.00</h1>
    <ft>2.50</ft>
    <h2></h2>
  </item>
  <item>
    <col>goal_handicap</col>
    <h1>0.00</h1>
    <ft>0.00</ft>
    <h2></h2>
  </item>
  <item>
    <col>card_over_under</col>
    <h1>10.00</h1>
    <ft>12.00</ft>
    <h2></h2>
  </item>
  <item>
    <col>card_handicap</col>
    <h1>2.00</h1>
    <ft>3.00</ft>
    <h2></h2>
  </item>
  <item>
    <col>euro_home</col>
    <h1>3.00</h1>
    <ft>2.50</ft>
    <h2></h2>
  </item>
  <item>
    <col>euro_draw</col>
    <h1>2.20</h1>
    <ft>3.20</ft>
    <h2></h2>
  </item>
  <item>
    <col>euro_way</col>
    <h1>3.40</h1>
    <ft>2.80</ft>
    <h2></h2>
  </item>
  <item>
    <col>conner_over_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>conner_under_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>conner_home_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>conner_way_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>goal_over_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>goal_under_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>goal_home_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>goal_way_win</col>
    <h1>0.90</h1>
    <ft>0.90</ft>
    <h2></h2>
  </item>
  <item>
    <col>card_over_win</col>
    <h1></h1>
    <ft></ft>
    <h2></h2>
  </item>
  <item>
    <col>card_under_win</col>
    <h1></h1>
    <ft></ft>
    <h2></h2>
  </item>
  <item>
    <col>card_home_win</col>
    <h1></h1>
    <ft></ft>
    <h2></h2>
  </item>
  <item>
    <col>card_way_win</col>
    <h1></h1>
    <ft></ft>
    <h2></h2>
  </item>
</details>',@userID=N'2',@edit=1
