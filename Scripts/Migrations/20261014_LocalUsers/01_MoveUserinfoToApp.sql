-- Server: QUANGNH\SQL2019. Keep Sys source intact. Run once on the restored App DB.
USE [TAPHOA_FBOHRMSP229_App];
GO
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.userinfo2') IS NOT NULL THROW 50001, 'dbo.userinfo2 already exists; refusing overwrite', 1;
SELECT * INTO dbo.userinfo2 FROM TAPHOA_FBOHRMSP229_Sys.dbo.userinfo2 WITH (TABLOCKX, HOLDLOCK);
DECLARE @identityCurrent numeric(38,0) = IDENT_CURRENT('TAPHOA_FBOHRMSP229_Sys.dbo.userinfo2');
DECLARE @reseed nvarchar(200) = N'DBCC CHECKIDENT (''dbo.userinfo2'', RESEED, ' + CONVERT(nvarchar(50), @identityCurrent) + N') WITH NO_INFOMSGS';
EXEC sys.sp_executesql @reseed;
ALTER TABLE dbo.userinfo2 ADD CONSTRAINT PK_userinfo2 PRIMARY KEY CLUSTERED ([name]);
ALTER TABLE dbo.userinfo2 ADD CONSTRAINT [DF_userinfo2_comment2] DEFAULT ('') FOR [comment2];
GO
CREATE OR ALTER PROC [dbo].[bet_match_insert]
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

	insert into #bet_match select top 1 match, season, @time, home, way, '71', null, null, null, 0, 1, 1, null, null, null from #input

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
		if not exists (select 1 from dbo.userinfo2 where id = @userID and admin = 1)
			and not exists (select 1 from bet_match_total b join #bet_match x on b.match = x.match where b.user_host = @userID) begin
			select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
			return
		end
	
		declare @user_host int
		select top 1 @user_host = b.user_host from bet_match_total b join #bet_match x on b.match = x.match
		
		delete a from bet_match a join #bet_match b on a.match = b.match
		insert into bet_match select * from #bet_match

		update bet_match_total set user_host = @user_host where match = (select top 1 match from #bet_match)
		
		select 1 as isSuccess, N'Sửa trận thành công!' as msg
	end
END

GO
CREATE OR ALTER VIEW [dbo].[vbet_esport_match]
AS
    WITH match_data AS (
        SELECT
            m.[match_id],
            m.[season],
            ISNULL(s.[season_name], m.[season]) AS [season_name],
            m.[home],
            ISNULL(th.[team_name], m.[home]) AS [home_name],
            m.[way],
            ISNULL(tw.[team_name], m.[way]) AS [way_name],
            m.[match_time],
            CASE WHEN EXISTS (
                SELECT 1
                FROM [dbo].[bet_ticket_esport] t
                CROSS APPLY (
                    SELECT
                        CHARINDEX('.', t.[code]) AS [first_dot],
                        PARSENAME(t.[code], 2) AS [market]
                ) code_info
                JOIN [dbo].[bet_esport_game] g
                    ON g.[match_id] = t.[match_id]
                    AND g.[game_no] = TRY_CAST(SUBSTRING(t.[code], 2, code_info.[first_dot] - 2) AS INT)
                WHERE t.[match_id] = m.[match_id]
                    AND code_info.[first_dot] > 2
                    AND (
                        (code_info.[market] IN ('OU', 'HC') AND (g.[result_kill_home] IS NULL OR g.[result_kill_way] IS NULL))
                        OR (code_info.[market] = 'MIN' AND g.[result_minute] IS NULL)
                        OR (code_info.[market] IN ('DOU', 'DHC') AND (g.[result_dragon_home] IS NULL OR g.[result_dragon_way] IS NULL))
                        OR (code_info.[market] = 'FD' AND g.[result_first_dragon] IS NULL)
                        OR (code_info.[market] IN ('FDT', 'FDCHEM', 'FDWIND', 'FDWATER', 'FDFIRE', 'FDEARTH') AND g.[result_first_dragon_type] IS NULL)
                        OR (code_info.[market] = 'FIRST' AND g.[result_first] IS NULL)
                        OR (code_info.[market] = 'THIRD' AND g.[result_third] IS NULL)
                        OR (code_info.[market] = 'FIVE' AND g.[result_five] IS NULL)
                        OR (code_info.[market] = 'TEN' AND g.[result_ten] IS NULL)
                        OR (code_info.[market] = 'WIN' AND g.[result_win] IS NULL)
                    )
            ) THEN 1 ELSE 0 END AS [has_pending_ticket_result],
            CASE WHEN EXISTS (
                SELECT 1
                FROM [dbo].[bet_ticket_esport] t
                WHERE t.[match_id] = m.[match_id]
                    AND ISNULL(t.[clear], 0) = 0
            ) THEN 1 ELSE 0 END AS [has_uncleared_ticket],
            (SELECT COUNT(*) FROM [dbo].[bet_esport_game] g WHERE g.[match_id] = m.[match_id]) AS [total_games],
            (SELECT COUNT(*) FROM [dbo].[bet_esport_game] g WHERE g.[match_id] = m.[match_id] AND g.[game_no] BETWEEN 1 AND 5) AS [live_game_count],
            m.[created_by],
            m.[created_by] AS [user_host],
            ISNULL(u.[comment], '') AS [host_name],
            m.[created_at],
            m.[updated_by],
            m.[updated_at]
        FROM [dbo].[bet_esport_match] m
        LEFT JOIN [dbo].[bet_season] s ON s.[season] = m.[season]
        LEFT JOIN [dbo].[bet_team] th ON th.[team] = m.[home]
        LEFT JOIN [dbo].[bet_team] tw ON tw.[team] = m.[way]
        LEFT JOIN dbo.userinfo2 u ON u.[id] = m.[created_by]
    )
    SELECT
        [match_id],
        [season],
        [season_name],
        [home],
        [home_name],
        [way],
        [way_name],
        [match_time],
        CASE
            WHEN GETDATE() < [match_time] THEN 2
            WHEN [has_pending_ticket_result] = 1 AND GETDATE() < DATEADD(MINUTE, [live_game_count] * 30, [match_time]) THEN 1
            WHEN [has_pending_ticket_result] = 1 THEN 3
            WHEN [has_uncleared_ticket] = 1 THEN 4
            ELSE 5
        END AS [status],
        CASE
            WHEN GETDATE() < [match_time] THEN N'Sắp tới'
            WHEN [has_pending_ticket_result] = 1 AND GETDATE() < DATEADD(MINUTE, [live_game_count] * 30, [match_time]) THEN N'Trực tiếp'
            WHEN [has_pending_ticket_result] = 1 THEN N'Chờ kết quả'
            WHEN [has_uncleared_ticket] = 1 THEN N'Chưa tất toán'
            ELSE N'Kết thúc'
        END AS [statusname],
		ROW_NUMBER()OVER(ORDER BY CASE
            WHEN GETDATE() < [match_time] THEN 2
            WHEN [has_pending_ticket_result] = 1 AND GETDATE() < DATEADD(MINUTE, [live_game_count] * 30, [match_time]) THEN 1
            WHEN [has_pending_ticket_result] = 1 THEN 3
            WHEN [has_uncleared_ticket] = 1 THEN 4
            ELSE 5
        END, ABS(DATEDIFF(MINUTE, [match_time], GETDATE())), [match_id]) AS xKey,
        [total_games],
        [created_by],
        [user_host],
        [host_name],
        [created_at],
        [updated_by],
        [updated_at]
    FROM match_data

GO
CREATE OR ALTER VIEW dbo.vsysuserinfo AS SELECT * FROM dbo.userinfo2;
GO
CREATE OR ALTER PROC [dbo].[bet_login]
	@username NVARCHAR(MAX),
	@password NVARCHAR(MAX)
AS
BEGIN
	SELECT * FROM dbo.userinfo2 WHERE name = @username AND substring(keys, 3, 1) + substring(password, 2, len(password) - 2) + substring(keys, 2, 1) = @password
	IF EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE name = @username AND substring(keys, 3, 1) + substring(password, 2, len(password) - 2) + substring(keys, 2, 1) = @password)
		UPDATE dbo.userinfo2 SET s9 = GETDATE() WHERE name = @username
END

GO
CREATE OR ALTER PROC [dbo].[bet_setting]
	@username NVARCHAR(MAX)
AS
BEGIN
	DECLARE @q NVARCHAR(MAX), @Key NVARCHAR(MAX)

	SET @Key = 'user_yn = ''1'''
	IF EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE name = @username AND admin = 0)
		SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'name = ''' + @username + ''''

	SET @q = 'select * from dbo.userinfo2 where ' + @Key
	EXEC sp_executesql @q
END

GO
CREATE OR ALTER VIEW [dbo].[vbet_payment]
AS
	SELECT a.id, a.user_host AS host_id, b.comment AS host_name, a.user_id, c.comment AS user_name, a.money/1000 AS money, a.datetime, a.clear
		FROM bet_payment a JOIN dbo.userinfo2 b ON user_host = b.id JOIN dbo.userinfo2 c ON a.user_id = c.id

GO
CREATE OR ALTER PROC [dbo].[bet_ticket_clear]
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
	select @admin = admin from dbo.userinfo2 where id = @userID

	if isnull(@admin, 0) = 0 and @match <> ''
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
		update a set clear = 1 
			from bet_ticket a 
			where a.user_id = @user_id 
				and exists (select 1 from bet_match b where a.match = b.match and a.code = b.code and b.result_home is not null)
				and exists (select 1 from vbet_match_total c where a.match = c.match and (c.user_host = @userID or @admin = 1))
				 and isnull(clear, 0) = 0
		
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
				and exists (select 1 from vbet_esport_match c where a.match_id = c.match_id and (c.user_host = @userID or @admin = 1))
				and isnull(clear, 0) = 0

		update a set clear = 1 
			from bet_ticket_champion a 
			where a.user_id = @user_id 
				and exists (select 1 from bet_champion b where a.id = b.id and b.result_win is not null and (user_host = @userID or @admin = 1))
				and isnull(clear, 0) = 0

		update bet_payment set clear = 1 where user_id = @user_id and (user_host = @userID or @admin = 1) and isnull(clear, 0) = 0
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
				and isnull(clear, 0) = 0

	end else if @code <> '00' begin
		if exists (select 1 from bet_match_total where match = @match)
			update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end from bet_ticket a where a.match = @match and a.code = @code and a.user_id = @user_id and exists (select 1 from bet_match b where a.match = b.match and a.code = b.code and b.result_home is not null)
		else if cast(right(@match, 6) as int) <> 0
			update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end from bet_ticket_champion a where a.id = cast(right(@match, 6) as int) and a.user_id = @user_id and exists (select 1 from bet_champion b where a.id = b.id and b.result_win is not null)			
		else
			update a set clear = case when isnull(clear, 0) = 1 then 0 else 1 end from bet_ticket_champion a join bet_champion b on a.id = b.id where b.season + convert(varchar(128), b.time, 112) + '000000' = @match and a.user_id = @user_id and b.result_win is not null
	end else
		update bet_payment set clear = case when isnull(clear, 0) = 1 then 0 else 1 end where id = @match and user_id = @user_id and (user_host = @userID or @admin = 1) and isnull(clear, 0) = 0

	select 1 as isSuccess, N'Thanh toán thành công!' as msg
END

GO
CREATE OR ALTER PROC [dbo].[bet_ticket_delete]
	@match NVARCHAR(MAX),
	@user_id INT,
	@code NVARCHAR(MAX),
	@ticket NVARCHAR(MAX),
	@userID INT
AS
BEGIN
	declare @admin bit
	select @admin = admin from dbo.userinfo2 where id = @userID

	if @admin = 0 and dbo.[bet_check_right](@userID, 'bet_ticket_delete') = '0' begin
		select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
		return
	end

	if @match = '' or @code = '' begin
		select 0 as isSuccess, N'Không xóa dòng này' as msg
		return
	end

	if exists (select 1 from bet_ticket_esport where match_id = @match and code = @code and user_id = @user_id) begin
		if @admin = 0 and exists (select 1 from vbet_esport_match where match_id = @match and status <> 2)
			and not exists (select 1 from bet_esport_match where match_id = @match and created_by = @userID) begin
			select 0 as isSuccess, N'Trận Esports đã diễn ra, không thể xóa vé cược. Liên hệ nhà cái để xóa vé cược hộ!' as msg
			return
		end

		delete bet_ticket_esport where match_id = @match and code = @code and user_id = @user_id
		select 1 AS isSuccess, N'Xóa thành công!' as msg
		return
	end

	if @admin = 0 and exists (select 1 from bet_match where match = @match and code = @code and (result_home is not null or result_way is not null) )
		and not exists (select 1 from bet_match_total where match = @match and user_host = @userID) begin
		select 0 as isSuccess, N'Đã vào kết quả, không xóa vé cược. Liên hệ nhà cái để xóa vé cược hộ!' as msg
		return
	end

	if @admin = 0 and exists (select 1 from vbet_match_total where match = @match and status <> '2')
		and not exists (select 1 from bet_match_total where match = @match and user_host = @userID) begin
		select 0 as isSuccess, N'Trận đấu đã diễn ra, không thể xóa vé cược. Liên hệ nhà cái để xóa vé cược hộ!' as msg
		return
	end

	if @code <> '00'
		delete bet_ticket where match = @match and code = @code and ticket = @ticket and user_id = @user_id
	else 
		delete bet_payment where id = @match and user_id = @user_id
	
	select 1 AS isSuccess, N'Xóa thành công!' as msg
END

GO
CREATE OR ALTER PROC [dbo].[bet_champion_insert]
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
		if not exists (select 1 from dbo.userinfo2 where id = @userID and admin = 1)
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
					left join dbo.userinfo2 y on a.user_id = y.id
			return
		end

		update a set time_lock = b.time_lock, name = b.name, team = b.team, rate_win = b.rate_win from bet_champion a join #bet_champion b on a.id = b.id
		delete a from bet_champion a where season = @season and time = @time and not exists (select 1 from #bet_champion b where a.id = b.id)
		insert into bet_champion select season, time, time_lock, name, team, rate_win, result_win, user_host from #bet_champion a where not exists (select 1 from bet_champion b where a.id = b.id)
		select 1 as isSuccess, N'Sửa kèo thành công!' as msg
	end
END

GO
CREATE OR ALTER PROC [dbo].[bet_champions]
	@team NVARCHAR(MAX) = '',
	@season NVARCHAR(MAX) = '',
	@datefrom DATETIME = NULL,
	@dateto DATETIME = NULL
AS
BEGIN
	SELECT a.season, a.time, a.time_lock, MAX(a.name) AS name, MAX(a.user_host) AS user_host, CASE WHEN DATEDIFF(MINUTE, time_lock, GETDATE()) <= 0 THEN 1 ELSE 2 END AS status
		INTO #bet_champion
		FROM bet_champion a
		WHERE (a.team = @team OR @team = '')
			AND (a.season = @season OR @season = '')
			AND (a.time >= @datefrom OR @datefrom  IS NULL)
			AND (a.time <= @dateto OR @dateto IS NULL)
			AND EXISTS (SELECT 1 FROM bet_ticket_champion x WHERE a.id = x.id AND ISNULL(x.clear, 0) = 0 OR a.time_lock >= GETDATE())
		GROUP BY a.season, a.time, a.time_lock
	
	SELECT a.id, a.season, ISNULL(b.season_name, '') AS season_name, a.time, a.time_lock, x.name, a.team, ISNULL(c.team_name, '') AS team_name, a.rate_win, a.result_win, a.user_host, ISNULL(u.comment, '') AS host_name
			, x.status
		FROM bet_champion a
			JOIN bet_season b ON a.season = b.season
			JOIN bet_team c ON a.team = c.team
			JOIN #bet_champion x ON a.season = x.season AND a.time = x.time
			LEFT JOIN dbo.userinfo2 u ON a.user_host = u.id
		WHERE (a.team = @team OR @team = '')
			AND (a.season = @season OR @season = '')
			AND (a.time >= @datefrom OR @datefrom  IS NULL)
			AND (a.time <= @dateto OR @dateto IS NULL)
		ORDER BY x.status, a.time DESC, a.time_lock, a.season, a.id
	
END

GO
CREATE OR ALTER PROC [dbo].[bet_ucChangePass]
	@currentUser NVARCHAR(MAX),
	@currentPass NVARCHAR(MAX),
	@targetUser NVARCHAR(MAX),
	@newPass NVARCHAR(MAX)
AS
BEGIN
	DECLARE @q NVARCHAR(MAX), @Key NVARCHAR(MAX)

	-- Kiểm tra pass user thực hiện
	IF NOT EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE name = @currentUser AND substring(keys, 3, 1) + substring(password, 2, len(password) - 2)  + substring(keys, 2, 1) = @currentPass) BEGIN
		SELECT 0 as success, N'Mật khẩu hiện tại không chính xác' AS msg
		RETURN
	END ELSE BEGIN
		UPDATE dbo.userinfo2 SET password = @newPass, keys = left(keys, 1) + right(@newPass, 1) + left(@newPass, 1) + right(keys, 3) WHERE name = @targetUser
		SELECT 1 as success, N'Cập nhật mật khẩu thành công' AS msg
		RETURN
	END
END

GO
CREATE OR ALTER FUNCTION [dbo].[bet_check_right] (@user_id INT, @action NVARCHAR(MAX))
RETURNS BIT
AS BEGIN
	DECLARE @right BIT = 0
	
	IF EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE id = @user_id AND admin = 1) BEGIN
		SET @right = 1
		GOTO zcEND
	END

	-- check
	IF @action = 'host' SELECT @right = 0
	IF @action IN ('bet_match_insert', 'bet_champion_insert', 'bet_champions_insert') SELECT @right = 1
	IF @action IN ('bet_match_update', 'bet_match_delete', 'bet_champion_update', 'bet_champion_delete', 'bet_champions_update', 'bet_champions_delete') SELECT @right = 1
	IF @action IN ('bet_match_result', 'bet_champion_result') SELECT @right = 1
	IF @action IN ('bet_ticket_insert', 'bet_ticket_delete', 'bet_ticket_result', 'bet_ticket_clear', 'bet_report') SELECT @right = 1
	IF @action IN ('bet_master_data', 'bet_master_data_insert', 'bet_master_data_delete', 'bet_payment_insert') SELECT @right = 0
	
	zcEND:
	RETURN @right
END

GO
CREATE OR ALTER PROC [dbo].[bet_match_delete]
	@match nvarchar(4000),
	@userID int
AS
BEGIN
	if not exists (select 1 from dbo.userinfo2 where id = @userID and admin = 1)
		and not exists (select 1 from bet_match_total where match = @match and user_host = @userID) begin
		select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
		return
	end
	
	if exists (select 1 from bet_ticket a where a.match = @match) begin
		select 0 as isSuccess, N'Đã phát sinh vé cược, không thể hủy!' as msg
		return
	end
	
	delete a from bet_match a where a.match = @match
	select 1 as isSuccess, N'Hủy trận thành công!' as msg
END

GO
CREATE OR ALTER PROC [dbo].[bet_esport_match_delete]
	@match_id NVARCHAR(50),
	@userID   INT
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE id = @userID AND admin = 1)
		AND NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id AND created_by = @userID) BEGIN
		SELECT 0 AS isSuccess, N'Khong duoc phan quyen thuc hien chuc nang nay!' AS msg
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id) BEGIN
		SELECT 0 AS isSuccess, N'Khong tim thay tran dau!' AS msg
		RETURN
	END

	IF EXISTS (SELECT 1 FROM [dbo].[bet_ticket_esport] WHERE match_id = @match_id) BEGIN
		SELECT 0 AS isSuccess, N'Da phat sinh ve cuoc Esports, khong the huy!' AS msg
		RETURN
	END

	DELETE FROM [dbo].[bet_esport_game]  WHERE match_id = @match_id
	DELETE FROM [dbo].[bet_esport_match] WHERE match_id = @match_id

	SELECT 1 AS isSuccess, N'Xoa tran Esports thanh cong!' AS msg
END

GO
CREATE OR ALTER PROC [dbo].[bet_ticket_result]
	@user_id INT,
	@match NVARCHAR(MAX),
	@season NVARCHAR(MAX),
	@type CHAR(1), -- 0 - detail, 1 - total by money, 2 - total by rate of win
	@clear CHAR(1), -- 0 - not yet clear, 1 - clear, 2 - all
	@result CHAR(1), -- 0 no, 1 - yes, 2 - all
	@df NVARCHAR(MAX),
	@dt NVARCHAR(MAX),
	@zcInssert NVARCHAR(MAX) = '',
	@isChampion BIT = 0
AS
BEGIN
	if isnull(@df, '') = '' or @df <= '20260720 12:00:00' set @df = '20260720 12:00:00'
	
	-- Declare
	DECLARE @q NVARCHAR(MAX), @Key NVARCHAR(MAX), @Key_champion NVARCHAR(MAX), @Key_payment NVARCHAR(MAX)

	-- Struct
	SELECT TOP 0 0 AS systotal, a.user_id, CAST('' AS NVARCHAR(MAX)) AS match, b.season, b.home, b.way, b.time, a.code, a.ticket, a.money
			, b.over_under, b.over_win, b.under_win, b.handicap, b.home_win, b.way_win, b.draw_win
			, b.result_home, b.result_way, result_home AS result_dif
			, CAST(0 AS CHAR(1)) AS result, a.money AS rate_win, a.money AS money_win, a.money AS balance, a.money AS fee, a.clear
			, CAST(0 AS NUMERIC(9, 2)) AS count_of_ticket, CAST(0 AS NUMERIC(9, 2)) AS count_of_win
		INTO #report 
		FROM bet_ticket a, bet_match b

	ALTER TABLE #report ALTER COLUMN code NVARCHAR(MAX)
	ALTER TABLE #report ALTER COLUMN ticket NVARCHAR(MAX)
	
	-- Key
	SET @Key = '1=1'
	IF @user_id > 0 SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'a.user_id = ''' + REPLACE(STR(@user_id), ' ', '') + ''''
	IF @match <> '' SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + '(a.match = ''' + @match + ''' or c.name like ''%' + @match + '%'')'
	IF @season <> '' SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'b.season = ''' + @season + ''''
	IF @clear <> '2' SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'isnull(a.clear, 0) = ''' + @clear + ''''
	IF @result <> '2' SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'case when result_home is null then 0 else 1 end = ''' + @result + ''''
	IF ISNULL(@df, '') <> '' SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'replace(replace(replace(convert(varchar(max), b.time, 120), ''-'', ''''), '' '', ''''), '':'', '''') >= ''' + replace(replace(replace(@df, '-', ''), ' ', ''), ':', '') + ''''
	IF ISNULL(@dt, '') <> '' SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'replace(replace(replace(convert(varchar(max), b.time, 120), ''-'', ''''), '' '', ''''), '':'', '''') <= ''' + replace(replace(replace(@dt, '-', ''), ' ', ''), ':', '') + ''''
	
	SET @Key_champion = '1=1'
	IF @user_id > 0 SET @Key_champion = @Key_champion + CASE WHEN @Key_champion = '' THEN '' ELSE ' and ' END + 'a.user_id = ''' + REPLACE(STR(@user_id), ' ', '') + ''''
	IF @match <> '' SET @Key_champion = @Key_champion + CASE WHEN @Key_champion = '' THEN '' ELSE ' and ' END + '1=0'
	IF @season <> '' SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'a.season = ''' + @season + ''''
	IF @clear <> '2' SET @Key_champion = @Key_champion + CASE WHEN @Key_champion = '' THEN '' ELSE ' and ' END + 'isnull(a.clear, 0) = ''' + @clear + ''''
	IF @result <> '2' SET @Key_champion = @Key_champion + CASE WHEN @Key_champion = '' THEN '' ELSE ' and ' END + 'case when result_win is null then 0 else 1 end = ''' + @result + ''''
	IF ISNULL(@df, '') <> '' SET @Key_champion = @Key_champion + CASE WHEN @Key_champion = '' THEN '' ELSE ' and ' END + 'replace(replace(replace(convert(varchar(max), b.time_lock, 120), ''-'', ''''), '' '', ''''), '':'', '''') >= ''' + replace(replace(replace(@df, '-', ''), ' ', ''), ':', '') + ''''
	IF ISNULL(@dt, '') <> '' SET @Key_champion = @Key_champion + CASE WHEN @Key_champion = '' THEN '' ELSE ' and ' END + 'replace(replace(replace(convert(varchar(max), b.time_lock, 120), ''-'', ''''), '' '', ''''), '':'', '''') <= ''' + replace(replace(replace(@dt, '-', ''), ' ', ''), ':', '') + ''''

	SET @Key_payment = '1=1'
	IF @user_id > 0 SET @Key_payment = @Key_payment + CASE WHEN @Key_payment = '' THEN '' ELSE ' and ' END + 'a.user_id = ''' + REPLACE(STR(@user_id), ' ', '') + ''''
		ELSE IF @user_id = 0 SET @Key_payment = @Key_payment + CASE WHEN @Key_payment = '' THEN '' ELSE ' and ' END + 'isnull(a.clear, 0) = ''0'''
	IF @match <> '' SET @Key_payment = @Key_payment + CASE WHEN @Key_payment = '' THEN '' ELSE ' and ' END + '1=0'
	IF @season <> '' SET @Key_payment = @Key_payment + CASE WHEN @Key_payment = '' THEN '' ELSE ' and ' END + '1=0'
	IF @clear <> '2' SET @Key_payment = @Key_payment + CASE WHEN @Key_payment = '' THEN '' ELSE ' and ' END + 'isnull(a.clear, 0) = ''' + @clear + ''''
	IF ISNULL(@df, '') <> '' SET @Key_payment = @Key_payment + CASE WHEN @Key_payment = '' THEN '' ELSE ' and ' END + 'replace(replace(replace(convert(varchar(max), a.datetime, 120), ''-'', ''''), '' '', ''''), '':'', '''') >= ''' + replace(replace(replace(@df, '-', ''), ' ', ''), ':', '') + ''''
	IF ISNULL(@dt, '') <> '' SET @Key_payment = @Key_payment + CASE WHEN @Key_payment = '' THEN '' ELSE ' and ' END + 'replace(replace(replace(convert(varchar(max), a.datetime, 120), ''-'', ''''), '' '', ''''), '':'', '''') <= ''' + replace(replace(replace(@dt, '-', ''), ' ', ''), ':', '') + ''''
	
	IF @isChampion = 1 BEGIN
		SET @Key = '1=0'
		SET @Key_payment = '1=0'
	END

	-- data ticket match
	SET @q = 'insert into #report'
	SET @q = @q + CHAR(13) + 'select 0, a.user_id, a.match, b.season, b.home, b.way, b.time, a.code, a.ticket, a.money'
	SET @q = @q + CHAR(13) + ', b.over_under, b.over_win, b.under_win, b.handicap, b.home_win, b.way_win, b.draw_win'
	SET @q = @q + CHAR(13) + ', b.result_home, b.result_way, 0'
	SET @q = @q + CHAR(13) + ', '''', 0, 0, 0, 0, a.clear'
	SET @q = @q + CHAR(13) + ', NULL, NULL'
	SET @q = @q + CHAR(13) + 'from bet_ticket a join bet_match b on a.match = b.match and a.code = b.code'
	SET @q = @q + CHAR(13) + 'join vbet_match_total c on a.match = c.match'
	SET @q = @q + CHAR(13) + 'where ' + @Key
	EXEC sp_executesql @q
	
	-- data ticket champion
	SET @q = 'insert into #report'
	SET @q = @q + CHAR(13) + 'select 0, a.user_id, right(space(16) + season, 16) + convert(varchar(128), b.time, 112) + replace(str(a.id, 6), '' '', ''0''), b.season, b.team, '''', b.time, ''46'', ''H'', a.money'
	SET @q = @q + CHAR(13) + ', NULL, NULL, NULL, NULL, b.rate_win, NULL, NULL'
	SET @q = @q + CHAR(13) + ', b.result_win, 0, 0'
	SET @q = @q + CHAR(13) + ', '''', 0, 0, 0, 0, a.clear'
	SET @q = @q + CHAR(13) + ', NULL, NULL'
	SET @q = @q + CHAR(13) + 'from bet_ticket_champion a join bet_champion b on a.id = b.id'
	SET @q = @q + CHAR(13) + 'where ' + @Key_champion
	EXEC sp_executesql @q

	-- Payment
	SET @q = 'insert into #report'
	SET @q = @q + CHAR(13) + 'select 0, a.user_id, a.id, '''', '''', '''', a.datetime, ''00'', '''', a.money'
	SET @q = @q + CHAR(13) + ', null, null, null, null, null, null, null'
	SET @q = @q + CHAR(13) + ', null, null, 0'
	SET @q = @q + CHAR(13) + ', '''', 1, 0, a.money, 0, a.clear'
	SET @q = @q + CHAR(13) + ', 0, 0'
	SET @q = @q + CHAR(13) + 'from bet_payment a'
	SET @q = @q + CHAR(13) + 'where ' + @Key_payment
	EXEC sp_executesql @q

	-- data ticket esports
	-- Esports is loaded into #report before settlement and totals so it follows the same pipeline as matches/champions.
	INSERT INTO #report (
			systotal, user_id, match, season, home, way, time, code, ticket, money,
			over_under, over_win, under_win, handicap, home_win, way_win, draw_win,
			result_home, result_way, result_dif, result, rate_win, money_win, balance, fee, clear,
			count_of_ticket, count_of_win
		)
		SELECT 0, t.user_id, t.match_id, m.season, ISNULL(h.team_name, m.home), ISNULL(w.team_name, m.way), m.match_time, t.code,
			   PARSENAME(t.code, 1), t.money,
			   CASE market.market
				   WHEN 'OU' THEN g.ou_line
				   WHEN 'MIN' THEN g.minute_line
				   WHEN 'DOU' THEN g.dragon_ou_line
				   ELSE NULL END,
			   CASE market.market
				   WHEN 'OU' THEN g.ou_over_win
				   WHEN 'MIN' THEN g.minute_over_win
				   WHEN 'DOU' THEN g.dragon_ou_over_win
				   ELSE NULL END,
			   CASE market.market
				   WHEN 'OU' THEN g.ou_under_win
				   WHEN 'MIN' THEN g.minute_under_win
				   WHEN 'DOU' THEN g.dragon_ou_under_win
				   ELSE NULL END,
			   CASE market.market
				   WHEN 'HC' THEN g.hc_line
				   WHEN 'DHC' THEN g.dragon_hc_line
				   ELSE NULL END,
			   CASE market.market
				   WHEN 'HC' THEN g.hc_home_win
				   WHEN 'DHC' THEN g.dragon_hc_home_win
				   WHEN 'FD' THEN g.first_dragon_home_win
				   WHEN 'FDT' THEN g.first_dragon_tech_win
				   WHEN 'FDCHEM' THEN g.first_dragon_chemtech_win
				   WHEN 'FDWIND' THEN g.first_dragon_wind_win
				   WHEN 'FDWATER' THEN g.first_dragon_water_win
				   WHEN 'FDFIRE' THEN g.first_dragon_fire_win
				   WHEN 'FDEARTH' THEN g.first_dragon_earth_win
				   WHEN 'FIRST' THEN g.first_home_win
				   WHEN 'THIRD' THEN g.third_home_win
				   WHEN 'FIVE' THEN g.five_home_win
				   WHEN 'TEN' THEN g.ten_home_win
				   WHEN 'WIN' THEN g.win_home_win
				   ELSE NULL END,
			   CASE market.market
				   WHEN 'HC' THEN g.hc_way_win
				   WHEN 'DHC' THEN g.dragon_hc_way_win
				   WHEN 'FD' THEN g.first_dragon_way_win
				   WHEN 'FIRST' THEN g.first_way_win
				   WHEN 'THIRD' THEN g.third_way_win
				   WHEN 'FIVE' THEN g.five_way_win
				   WHEN 'TEN' THEN g.ten_way_win
				   WHEN 'WIN' THEN g.win_way_win
				   ELSE NULL END,
			   NULL,
			   CASE market.market
				   WHEN 'OU' THEN g.result_kill_home
				   WHEN 'HC' THEN g.result_kill_home
				   WHEN 'MIN' THEN g.result_minute
				   WHEN 'DOU' THEN g.result_dragon_home
				   WHEN 'DHC' THEN g.result_dragon_home
				   ELSE NULL END,
			   CASE market.market
				   WHEN 'OU' THEN g.result_kill_way
				   WHEN 'HC' THEN g.result_kill_way
				   WHEN 'DOU' THEN g.result_dragon_way
				   WHEN 'DHC' THEN g.result_dragon_way
				   ELSE 0 END,
			   0,
			   CASE
				   WHEN market.market = 'FD' AND g.result_first_dragon IS NOT NULL THEN CASE WHEN g.result_first_dragon = 'draw' THEN 'D' WHEN PARSENAME(t.code, 1) = 'H' AND g.result_first_dragon = 'home' OR PARSENAME(t.code, 1) = 'W' AND g.result_first_dragon = 'way' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FDT' AND g.result_first_dragon_type IS NOT NULL THEN CASE WHEN g.result_first_dragon_type = 'draw' THEN 'D' WHEN g.result_first_dragon_type = 'tech' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FDCHEM' AND g.result_first_dragon_type IS NOT NULL THEN CASE WHEN g.result_first_dragon_type = 'draw' THEN 'D' WHEN g.result_first_dragon_type = 'chemtech' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FDWIND' AND g.result_first_dragon_type IS NOT NULL THEN CASE WHEN g.result_first_dragon_type = 'draw' THEN 'D' WHEN g.result_first_dragon_type = 'wind' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FDWATER' AND g.result_first_dragon_type IS NOT NULL THEN CASE WHEN g.result_first_dragon_type = 'draw' THEN 'D' WHEN g.result_first_dragon_type = 'water' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FDFIRE' AND g.result_first_dragon_type IS NOT NULL THEN CASE WHEN g.result_first_dragon_type = 'draw' THEN 'D' WHEN g.result_first_dragon_type = 'fire' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FDEARTH' AND g.result_first_dragon_type IS NOT NULL THEN CASE WHEN g.result_first_dragon_type = 'draw' THEN 'D' WHEN g.result_first_dragon_type = 'earth' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FIRST' AND g.result_first IS NOT NULL THEN CASE WHEN g.result_first = 'draw' THEN 'D' WHEN PARSENAME(t.code, 1) = 'H' AND g.result_first = 'home' OR PARSENAME(t.code, 1) = 'W' AND g.result_first = 'way' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'THIRD' AND g.result_third IS NOT NULL THEN CASE WHEN g.result_third = 'draw' THEN 'D' WHEN PARSENAME(t.code, 1) = 'H' AND g.result_third = 'home' OR PARSENAME(t.code, 1) = 'W' AND g.result_third = 'way' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'FIVE' AND g.result_five IS NOT NULL THEN CASE WHEN g.result_five = 'draw' THEN 'D' WHEN PARSENAME(t.code, 1) = 'H' AND g.result_five = 'home' OR PARSENAME(t.code, 1) = 'W' AND g.result_five = 'way' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'TEN' AND g.result_ten IS NOT NULL THEN CASE WHEN g.result_ten = 'draw' THEN 'D' WHEN PARSENAME(t.code, 1) = 'H' AND g.result_ten = 'home' OR PARSENAME(t.code, 1) = 'W' AND g.result_ten = 'way' THEN 'W' ELSE 'L' END
				   WHEN market.market = 'WIN' AND g.result_win IS NOT NULL THEN CASE WHEN g.result_win = 'draw' THEN 'D' WHEN PARSENAME(t.code, 1) = 'H' AND g.result_win = 'home' OR PARSENAME(t.code, 1) = 'W' AND g.result_win = 'way' THEN 'W' ELSE 'L' END
				   ELSE '' END,
			   0, 0, 0, 0, t.clear, NULL, NULL
			FROM bet_ticket_esport t
				JOIN bet_esport_match m ON m.match_id = t.match_id
				JOIN bet_esport_game g ON g.match_id = t.match_id AND g.game_no = TRY_CAST(SUBSTRING(t.code, 2, CHARINDEX('.', t.code) - 2) AS INT)
				LEFT JOIN bet_team h ON h.team = m.home
				LEFT JOIN bet_team w ON w.team = m.way
				CROSS APPLY (SELECT TRY_CAST(SUBSTRING(t.code, 2, CHARINDEX('.', t.code) - 2) AS INT) AS game_no,
									PARSENAME(t.code, 2) AS market) market
			WHERE (@user_id <= 0 OR t.user_id = @user_id)
				AND (@match = '' OR t.match_id = @match OR ISNULL(h.team_name, m.home) + ' vs ' + ISNULL(w.team_name, m.way) LIKE '%' + @match + '%')
				AND (@season = '' OR m.season = @season)
				AND (@clear = '2' OR ISNULL(t.clear, 0) = TRY_CAST(@clear AS BIT))
				AND (ISNULL(@df, '') = '' OR REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(MAX), m.match_time, 120), '-', ''), ' ', ''), ':', '') >= REPLACE(REPLACE(REPLACE(@df, '-', ''), ' ', ''), ':', ''))
				AND (ISNULL(@dt, '') = '' OR REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(MAX), m.match_time, 120), '-', ''), ' ', ''), ':', '') <= REPLACE(REPLACE(REPLACE(@dt, '-', ''), ' ', ''), ':', ''))
	
	-- result
	UPDATE #report SET result_dif = CASE WHEN ticket IN ('O', 'U') THEN result_home + result_way - over_under ELSE result_home + handicap - result_way END
	UPDATE #report SET result = 'W' WHERE ((ticket IN ('O', 'H') AND result_dif > 0) OR (ticket IN ('U', 'W') AND result_dif < 0)) AND code NOT LIKE '4%'
	UPDATE #report SET result = 'L' WHERE ((ticket IN ('O', 'H') AND result_dif < 0) OR (ticket IN ('U', 'W') AND result_dif > 0)) AND code NOT LIKE '4%'
	UPDATE #report SET result = 'D' WHERE result_dif = 0 AND code NOT LIKE '4%'

	UPDATE #report SET result = 'W' WHERE ((ticket = 'H' AND result_home > result_way) OR (ticket = 'D' AND result_home = result_way) OR (ticket = 'W' AND result_home < result_way)) AND code LIKE '4%'
	UPDATE #report SET result = 'L' WHERE ((ticket = 'H' AND result_home <= result_way) OR (ticket = 'D' AND result_home <> result_way) OR (ticket = 'W' AND result_home >= result_way)) AND code LIKE '4%'

	IF @result <> '2'
		DELETE #report
			WHERE code LIKE 'G%.%'
				AND CASE WHEN ISNULL(result, '') = '' THEN '0' ELSE '1' END <> @result

	-- rate, money
	UPDATE #report SET rate_win = CASE result WHEN 'L' THEN -1
											  WHEN 'D' THEN 0
											  WHEN 'W' THEN (CASE ticket WHEN 'O' THEN over_win
																		 WHEN 'U' THEN under_win
																		 WHEN 'H' THEN home_win - CASE WHEN code LIKE '4%' THEN 1
																										 WHEN code LIKE 'G%.%' AND PARSENAME(code, 2) IN ('FD', 'FDT', 'FDCHEM', 'FDWIND', 'FDWATER', 'FDFIRE', 'FDEARTH', 'FIRST', 'THIRD', 'FIVE', 'TEN', 'WIN') AND home_win > 0 THEN 1
																										 ELSE 0 END
																		 WHEN 'W' THEN way_win - CASE WHEN code LIKE '4%' THEN 1
																									   WHEN code LIKE 'G%.%' AND PARSENAME(code, 2) IN ('FD', 'FDT', 'FDCHEM', 'FDWIND', 'FDWATER', 'FDFIRE', 'FDEARTH', 'FIRST', 'THIRD', 'FIVE', 'TEN', 'WIN') AND way_win > 0 THEN 1
																									   ELSE 0 END
																		 WHEN 'D' THEN draw_win - CASE WHEN code NOT LIKE '4%' THEN 0 ELSE 1 END END)
											  ELSE NULL END
		WHERE code <> '00'
	UPDATE #report SET money_win = money * rate_win * CASE WHEN ABS(result_dif) = 0.25 THEN 0.5 ELSE 1 END
					 , balance = case when clear = 1 then 0 else money * rate_win * CASE WHEN ABS(result_dif) = 0.25 THEN 0.5 ELSE 1 END end
					 , fee = money * case when code not in ('41', '42', '43') and result = 'W' then (1 - rate_win) else 0 end * CASE WHEN ABS(result_dif) = 0.25 THEN 0.5 ELSE 1 END
					 , rate_win = rate_win * CASE WHEN ABS(result_dif) = 0.25 THEN 0.5 ELSE 1 END
		WHERE code <> '00'
	
	-- count_of_ticket, count_of_win
	UPDATE #report SET count_of_ticket = 1, count_of_win = CASE WHEN result = 'W' THEN 1 ELSE 0 END WHERE code <> '00'

	-- host
	IF @type <> 0 AND (@user_id = 0 OR @user_id = '-1') BEGIN
		INSERT INTO #report
			SELECT a.systotal, c.user_host, a.match, a.season, a.home, a.way, a.time, a.code, a.ticket, a.money
					, a.over_under, a.over_win, a.under_win, a.handicap, a.home_win, a.way_win, a.draw_win, a.result_home, a.result_way, a.result_dif
					, CASE a.result WHEN 'W' THEN 'L' WHEN 'L' THEN 'W' ELSE a.result END, - a.rate_win, - a.money_win, - a.balance, 0, a.clear
					, a.count_of_ticket, CASE a.count_of_win WHEN 1 THEN 0 WHEN 0 THEN 1 END
				FROM #report a 
					JOIN bet_match_total c ON a.match = c.match
				WHERE a.systotal = '0' AND a.code <> '46' AND a.code NOT LIKE 'G%.%' AND c.user_host IS NOT NULL

		INSERT INTO #report
			SELECT a.systotal, c.created_by, a.match, a.season, a.home, a.way, a.time, a.code, a.ticket, a.money
					, a.over_under, a.over_win, a.under_win, a.handicap, a.home_win, a.way_win, a.draw_win, a.result_home, a.result_way, a.result_dif
					, CASE a.result WHEN 'W' THEN 'L' WHEN 'L' THEN 'W' ELSE a.result END, - a.rate_win, - a.money_win, - a.balance, 0, a.clear
					, a.count_of_ticket, CASE a.count_of_win WHEN 1 THEN 0 WHEN 0 THEN 1 END
				FROM #report a 
					JOIN bet_esport_match c ON a.match = c.match_id
				WHERE a.systotal = '0' AND a.code LIKE 'G%.%' AND c.created_by IS NOT NULL

		INSERT INTO #report
			SELECT a.systotal, c.user_host, a.match, a.season, a.home, a.way, a.time, a.code, a.ticket, a.money
					, a.over_under, a.over_win, a.under_win, a.handicap, a.home_win, a.way_win, a.draw_win, a.result_home, a.result_way, a.result_dif
					, CASE a.result WHEN 'W' THEN 'L' WHEN 'L' THEN 'W' ELSE a.result END, - a.rate_win, - a.money_win, - a.balance, 0, a.clear
					, a.count_of_ticket, CASE a.count_of_win WHEN 1 THEN 0 WHEN 0 THEN 1 END
				FROM #report a 
					JOIN bet_champion c ON c.id = TRY_CAST(RIGHT(a.match, 6) AS INT)
				WHERE a.systotal = '0' AND a.code = '46' AND c.user_host IS NOT NULL
		
		INSERT INTO #report
		SELECT a.systotal, b.user_host, a.match, a.season, a.home, a.way, a.time, a.code, a.ticket, a.money
					, a.over_under, a.over_win, a.under_win, a.handicap, a.home_win, a.way_win, a.draw_win, a.result_home, a.result_way, a.result_dif
					, CASE a.result WHEN 'W' THEN 'L' WHEN 'L' THEN 'W' ELSE a.result END, - a.rate_win, - a.money_win, - a.balance, 0, a.clear
					, a.count_of_ticket, CASE a.count_of_win WHEN 1 THEN 0 WHEN 0 THEN 1 END
				FROM #report a JOIN bet_payment b ON b.id = TRY_CAST(a.match AS INT) AND a.code = '00'
	END

	-- total by user_id + match
	INSERT INTO #report
		SELECT 1, user_id, match, MAX(season), MAX(home), MAX(way), MAX(time), '', '', SUM(money), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, SUM(money_win), SUM(balance), SUM(fee), NULL, SUM(count_of_ticket), SUM(count_of_win)
			FROM #report
			WHERE systotal = 0 AND code <> '00' AND code <> '46'
			GROUP BY user_id, match

	INSERT INTO #report
		SELECT 1, user_id, season + convert(varchar(128), time, 112) + '000000', season, '', '', time, MAX(code), '', SUM(money), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, SUM(money_win), SUM(balance), SUM(fee), NULL, SUM(count_of_ticket), SUM(count_of_win)
			FROM #report
			WHERE systotal = 0 AND code = '46'
			GROUP BY user_id, season, time

	-- total by user_id
	INSERT INTO #report
		SELECT 2, user_id, '', '', '', '', NULL, '', '', SUM(money), NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, SUM(money_win), SUM(balance), SUM(fee), NULL, SUM(count_of_ticket), SUM(count_of_win)
			FROM #report
			WHERE systotal = 0
			GROUP BY user_id
	
	IF @type <> '0' DELETE #report WHERE systotal < (SELECT MAX(systotal) FROM #report)

	IF NOT EXISTS (SELECT 1 FROM #report)
		INSERT INTO #report
			SELECT 0, 0, '', '', '', '', NULL, '', '', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, 0, 0, NULL, NULL, NULL
	
	-- if only one match then delete row by match
	IF EXISTS (SELECT 1 FROM #report WHERE match <> '' HAVING COUNT(DISTINCT match) = 1)
		DELETE #report WHERE match <> '' AND code = ''
	IF EXISTS (SELECT 1 FROM #report WHERE match <> '' AND code = '46' AND ticket = '' HAVING COUNT(DISTINCT match) = 1)
		DELETE #report WHERE match <> '' AND code = '46' AND ticket = '' 

	-- Result
	SELECT a.systotal, a.user_id, CASE a.systotal WHEN '0' THEN (CASE WHEN a.code LIKE 'G%.%' THEN N'Esports' WHEN a.code = '46' THEN e.name ELSE b.name END) WHEN '1' THEN (CASE WHEN a.code = '46' THEN a.season ELSE ISNULL(d.name, a.home + ' vs ' + a.way) END) WHEN '2' THEN c.comment ELSE N'Tổng' END AS name, b.part
			, a.match, a.season, a.home, a.way, a.code, a.time, a.ticket
			, CASE a.ticket WHEN 'O' THEN N'Tài' WHEN 'U' THEN N'Xỉu' WHEN 'H' THEN N'Chủ' WHEN 'W' THEN N'Khách' WHEN 'D' THEN N'Hòa' ELSE N'' END AS ticket_name
			, a.result, CASE a.result WHEN 'W' THEN N'Thắng' WHEN 'D' THEN N'Hòa' WHEN 'L' THEN N'Thua' ELSE N'' END AS result_name
			, a.money, a.rate_win, a.money_win, a.balance, a.fee, a.clear, count_of_ticket, count_of_win, CASE WHEN count_of_ticket = 0 THEN 0 ELSE CAST(100 * count_of_win / count_of_ticket AS NUMERIC(5, 2)) END AS rate_of_win
			, a.over_under, a.over_win, a.under_win, a.handicap, a.home_win, a.way_win, a.draw_win, a.result_home, a.result_way, a.result_dif
			, CASE a.systotal WHEN '0' THEN '0' ELSE N'1' END AS rowBold
			, CASE a.result WHEN 'W' THEN N'#009900' WHEN 'D' THEN N'#FF00FF' WHEN 'L' THEN N'#FF0000' ELSE N'#000000' END AS textColor
			, CAST('' AS NVARCHAR(128)) AS rowColor
		INTO #result
		FROM #report a LEFT JOIN bet_code b ON a.code = b.code
					   LEFT JOIN dbo.userinfo2 c ON a.user_id = c.id
					   LEFT JOIN vbet_match_total d ON a.match = d.match
					   LEFT JOIN bet_champion e ON a.match = right(space(16) + e.season, 16) + convert(varchar(128), e.time, 112) + replace(str(e.id, 6), ' ', '0')

	-- ticket name
	ALTER TABLE #result ALTER COLUMN ticket_name NVARCHAR(MAX)
	ALTER TABLE #result ALTER COLUMN code NVARCHAR(MAX)
	ALTER TABLE #result ALTER COLUMN ticket NVARCHAR(MAX)
	UPDATE #result SET ticket_name = CASE WHEN code = '46' OR code = '71' THEN '' ELSE part + '. ' END 
								   + CASE WHEN ticket IN ('O', 'U') THEN ticket_name + ' ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name
										  WHEN code = '71' AND ticket = 'H' THEN home + N' giao bóng'
										  WHEN code = '71' AND ticket = 'W' THEN way + N' giao bóng'
										  WHEN ticket = 'H' AND handicap > 0 AND handicap IS NOT NULL THEN home + ' +' + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', ''))
										  WHEN ticket = 'H' AND handicap = 0 AND handicap IS NOT NULL THEN home + REPLACE(name, N'chấp', N' +0')
										  WHEN ticket = 'H' AND handicap < 0 AND handicap IS NOT NULL THEN home + ' ' + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', ''))
										  WHEN ticket = 'W' AND handicap < 0 AND handicap IS NOT NULL THEN way + ' +' + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', ''))
										  WHEN ticket = 'W' AND handicap = 0 AND handicap IS NOT NULL THEN way + REPLACE(name, N'chấp', N' +0')
										  WHEN ticket = 'W' AND handicap > 0 AND handicap IS NOT NULL THEN way + ' ' + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')) 
										  WHEN code = '46' THEN home + ' ' + name + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')' 
										  WHEN ticket = 'H' AND handicap IS NULL THEN home + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')'
										  WHEN ticket = 'D' AND handicap IS NULL THEN N'Hòa' + ' (' + dbo.ff_NumberFormat(draw_win, '### ### ###.#0') + ')'
										  WHEN ticket = 'W' AND handicap IS NULL THEN way + ' (' + dbo.ff_NumberFormat(way_win, '### ### ###.#0') + ')' END
		WHERE systotal = 0 AND code <> '00'	
	
	UPDATE #result SET name = N'Làm phép', ticket_name = N'Làm phép' WHERE code = '00'
	UPDATE #result SET ticket_name = name WHERE systotal <> 0

	UPDATE r SET name = N'Esports',
				 part = CASE WHEN market.game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), market.game_no) END,
				 ticket_name = CASE WHEN market.game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), market.game_no) END + '. '
				 + CASE
					 WHEN market.market = 'OU' AND r.ticket = 'O' THEN N'Tài ' + REPLACE(STR(g.ou_line, 19, 2), ' ', '') + CASE WHEN market.game_no = 6 THEN N' game' ELSE N' kill' END
					 WHEN market.market = 'OU' AND r.ticket = 'U' THEN N'Xỉu ' + REPLACE(STR(g.ou_line, 19, 2), ' ', '') + CASE WHEN market.game_no = 6 THEN N' game' ELSE N' kill' END
					 WHEN market.market = 'HC' AND r.ticket = 'H' THEN r.home + CASE WHEN g.hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(g.hc_line, 19, 2), ' ', '') + CASE WHEN market.game_no = 6 THEN N' game' ELSE N' kill' END
					 WHEN market.market = 'HC' AND r.ticket = 'W' THEN r.way + CASE WHEN g.hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-g.hc_line, 19, 2), ' ', '') + CASE WHEN market.game_no = 6 THEN N' game' ELSE N' kill' END
					 WHEN market.market = 'MIN' AND r.ticket = 'O' THEN N'Tài ' + REPLACE(STR(g.minute_line, 19, 2), ' ', '') + N' phút'
					 WHEN market.market = 'MIN' AND r.ticket = 'U' THEN N'Xỉu ' + REPLACE(STR(g.minute_line, 19, 2), ' ', '') + N' phút'
					 WHEN market.market = 'DOU' AND r.ticket = 'O' THEN N'Tài ' + REPLACE(STR(g.dragon_ou_line, 19, 2), ' ', '') + N' rồng'
					 WHEN market.market = 'DOU' AND r.ticket = 'U' THEN N'Xỉu ' + REPLACE(STR(g.dragon_ou_line, 19, 2), ' ', '') + N' rồng'
					 WHEN market.market = 'DHC' AND r.ticket = 'H' THEN r.home + CASE WHEN g.dragon_hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(g.dragon_hc_line, 19, 2), ' ', '') + N' rồng'
					 WHEN market.market = 'DHC' AND r.ticket = 'W' THEN r.way + CASE WHEN g.dragon_hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-g.dragon_hc_line, 19, 2), ' ', '') + N' rồng'
					 WHEN market.market = 'FD' AND r.ticket = 'H' THEN N'Rồng đầu ' + r.home + ' (' + dbo.ff_NumberFormat(g.first_dragon_home_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FD' AND r.ticket = 'W' THEN N'Rồng đầu ' + r.way + ' (' + dbo.ff_NumberFormat(g.first_dragon_way_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FDT' THEN N'Rồng đầu công nghệ (' + dbo.ff_NumberFormat(g.first_dragon_tech_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FDCHEM' THEN N'Rồng đầu hóa kỹ (' + dbo.ff_NumberFormat(g.first_dragon_chemtech_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FDWIND' THEN N'Rồng đầu gió (' + dbo.ff_NumberFormat(g.first_dragon_wind_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FDWATER' THEN N'Rồng đầu nước (' + dbo.ff_NumberFormat(g.first_dragon_water_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FDFIRE' THEN N'Rồng đầu lửa (' + dbo.ff_NumberFormat(g.first_dragon_fire_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FDEARTH' THEN N'Rồng đầu đất (' + dbo.ff_NumberFormat(g.first_dragon_earth_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FIRST' AND r.ticket = 'H' THEN N'Mạng đầu ' + r.home + ' (' + dbo.ff_NumberFormat(g.first_home_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FIRST' AND r.ticket = 'W' THEN N'Mạng đầu ' + r.way + ' (' + dbo.ff_NumberFormat(g.first_way_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'THIRD' AND r.ticket = 'H' THEN N'3 mạng đầu ' + r.home + ' (' + dbo.ff_NumberFormat(g.third_home_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'THIRD' AND r.ticket = 'W' THEN N'3 mạng đầu ' + r.way + ' (' + dbo.ff_NumberFormat(g.third_way_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FIVE' AND r.ticket = 'H' THEN N'5 mạng đầu ' + r.home + ' (' + dbo.ff_NumberFormat(g.five_home_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'FIVE' AND r.ticket = 'W' THEN N'5 mạng đầu ' + r.way + ' (' + dbo.ff_NumberFormat(g.five_way_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'TEN' AND r.ticket = 'H' THEN N'10 mạng đầu ' + r.home + ' (' + dbo.ff_NumberFormat(g.ten_home_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'TEN' AND r.ticket = 'W' THEN N'10 mạng đầu ' + r.way + ' (' + dbo.ff_NumberFormat(g.ten_way_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'WIN' AND r.ticket = 'H' THEN r.home + N' win (' + dbo.ff_NumberFormat(g.win_home_win, '### ### ###.#0') + ')'
					 WHEN market.market = 'WIN' AND r.ticket = 'W' THEN r.way + N' win (' + dbo.ff_NumberFormat(g.win_way_win, '### ### ###.#0') + ')'
					 ELSE r.code END
		FROM #result r
			JOIN bet_esport_game g ON g.match_id = r.match AND g.game_no = TRY_CAST(SUBSTRING(r.code, 2, CHARINDEX('.', r.code) - 2) AS INT)
			CROSS APPLY (SELECT TRY_CAST(SUBSTRING(r.code, 2, CHARINDEX('.', r.code) - 2) AS INT) AS game_no, PARSENAME(r.code, 2) AS market) market
		WHERE r.systotal = 0 AND r.code LIKE 'G%.%'

	-- rowColor
	UPDATE #result SET rowColor = CASE systotal WHEN '0' THEN (CASE ISNULL(clear, 0) WHEN 0 THEN '#FFFFFF' ELSE '#FFFFE0' END) WHEN '1' THEN '#0099FF' ELSE '#FF3333' END

	-- 1000 vnd
	UPDATE #result SET money = money / 1000, money_win = money_win / 1000, balance = balance / 1000, fee = fee / 1000
	
	-- View
	WHILE NOT EXISTS (SELECT 1 FROM #result WHERE systotal = 0) BEGIN
		UPDATE #result SET systotal = systotal - 1
	END
	
	IF @zcInssert <> ''
		EXEC sp_executesql @zcInssert
	ELSE 
		SELECT a.*
			FROM #result a 
			ORDER BY a.user_id, a.time, RIGHT(SPACE(128) + LTRIM(RTRIM(a.match)), 128), a.systotal DESC
				, CASE WHEN a.code LIKE 'G%.%' THEN TRY_CAST(SUBSTRING(a.code, 2, CHARINDEX('.', a.code) - 2) AS INT) END
				, CASE WHEN a.code LIKE 'G%.%' THEN
					CASE PARSENAME(a.code, 2)
						WHEN 'OU' THEN CASE PARSENAME(a.code, 1) WHEN 'O' THEN 10 WHEN 'U' THEN 11 ELSE 19 END
						WHEN 'HC' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 20 WHEN 'W' THEN 21 ELSE 29 END
						WHEN 'MIN' THEN CASE PARSENAME(a.code, 1) WHEN 'O' THEN 30 WHEN 'U' THEN 31 ELSE 39 END
						WHEN 'DOU' THEN CASE PARSENAME(a.code, 1) WHEN 'O' THEN 40 WHEN 'U' THEN 41 ELSE 49 END
						WHEN 'DHC' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 50 WHEN 'W' THEN 51 ELSE 59 END
						WHEN 'FD' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 60 WHEN 'W' THEN 61 ELSE 69 END
						WHEN 'FDT' THEN 62
						WHEN 'FDCHEM' THEN 63
						WHEN 'FDWIND' THEN 64
						WHEN 'FDWATER' THEN 65
						WHEN 'FDFIRE' THEN 66
						WHEN 'FDEARTH' THEN 67
						WHEN 'FIRST' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 70 WHEN 'W' THEN 71 ELSE 79 END
						WHEN 'THIRD' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 80 WHEN 'W' THEN 81 ELSE 89 END
						WHEN 'FIVE' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 90 WHEN 'W' THEN 91 ELSE 99 END
						WHEN 'TEN' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 100 WHEN 'W' THEN 101 ELSE 109 END
						WHEN 'WIN' THEN CASE PARSENAME(a.code, 1) WHEN 'H' THEN 110 WHEN 'W' THEN 111 ELSE 119 END
						ELSE 999
					END
				END
				, CASE WHEN a.code LIKE '71%' THEN 0 ELSE 1 END
				, CASE WHEN a.code NOT LIKE 'G%.%' THEN RIGHT(RTRIM(a.code), 1) ELSE '' END
				, CASE WHEN a.code NOT LIKE 'G%.%' THEN LEFT(a.code, 1) ELSE '' END
END

GO
CREATE OR ALTER PROC [dbo].[bet_esport_match_save]
	@match_id   NVARCHAR(50)  = NULL,
	@edit       BIT           = 0,
	@season     NVARCHAR(100),
	@home       NVARCHAR(200),
	@way        NVARCHAR(200),
	@match_time DATETIME,
	@userID     INT
AS
BEGIN
	SET NOCOUNT ON

	IF @edit = 1
		AND NOT EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE id = @userID AND admin = 1)
		AND NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id AND created_by = @userID) BEGIN
		SELECT 0 AS isSuccess, N'Khong duoc phan quyen thuc hien chuc nang nay!' AS msg, NULL AS match_id
		RETURN
	END

	IF ISNULL(@season, '') = '' BEGIN
		SELECT 0 AS isSuccess, N'Vui long chon giai dau!' AS msg, NULL AS match_id
		RETURN
	END
	IF ISNULL(@home, '') = '' BEGIN
		SELECT 0 AS isSuccess, N'Vui long chon doi 1!' AS msg, NULL AS match_id
		RETURN
	END
	IF ISNULL(@way, '') = '' BEGIN
		SELECT 0 AS isSuccess, N'Vui long chon doi 2!' AS msg, NULL AS match_id
		RETURN
	END
	IF @home = @way BEGIN
		SELECT 0 AS isSuccess, N'Doi 1 va Doi 2 khong duoc trung nhau!' AS msg, NULL AS match_id
		RETURN
	END

	IF @edit = 0 BEGIN
		IF EXISTS (
			SELECT 1 FROM [dbo].[bet_esport_match]
			WHERE season = @season AND home = @home AND way = @way
				AND CONVERT(VARCHAR(64), match_time, 120) = CONVERT(VARCHAR(64), @match_time, 120)
		) BEGIN
			SELECT 0 AS isSuccess, N'Da co tran dau Esports nay roi!' AS msg, NULL AS match_id
			RETURN
		END

		DECLARE @newId NVARCHAR(50)
		SELECT @newId = 'E' + CAST(
			ISNULL(MAX(TRY_CAST(SUBSTRING(match_id, 2, LEN(match_id)) AS INT)), 0) + 1
		AS NVARCHAR(20))
		FROM [dbo].[bet_esport_match]
		WHERE match_id LIKE 'E%'

		INSERT INTO [dbo].[bet_esport_match]
			(match_id, season, home, way, match_time, created_by, created_at)
		VALUES
			(@newId, @season, @home, @way, @match_time, @userID, GETDATE())

		SELECT 1 AS isSuccess, N'Tao tran Esports thanh cong!' AS msg, @newId AS match_id
	END
	ELSE BEGIN
		IF NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id) BEGIN
			SELECT 0 AS isSuccess, N'Khong tim thay tran dau!' AS msg, NULL AS match_id
			RETURN
		END

		UPDATE [dbo].[bet_esport_match]
		SET season     = @season,
			home       = @home,
			way        = @way,
			match_time = @match_time,
			updated_by = @userID,
			updated_at = GETDATE()
		WHERE match_id = @match_id

		SELECT 1 AS isSuccess, N'Cap nhat tran Esports thanh cong!' AS msg, @match_id AS match_id
	END
END

GO
CREATE OR ALTER PROC [dbo].[bet_champion_delete]
	@season nvarchar(4000),
	@time datetime,
	@userID int
AS
BEGIN
	if not exists (select 1 from dbo.userinfo2 where id = @userID and admin = 1)
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
CREATE OR ALTER PROC [dbo].[bet_ticket_match]
	@userID INT
AS
BEGIN
	DECLARE @admin BIT
	
	SELECT @admin = admin FROM dbo.userinfo2 WHERE id = @userID
	
	IF @admin = 1
		SELECT * FROM vbet_match_total ORDER BY time DESC, xKey
	ELSE 
		SELECT * FROM vbet_match_total WHERE status = '2' OR user_host = @userID ORDER BY time DESC, xKey
END

GO
CREATE OR ALTER PROC [dbo].[bet_ticket_user]
	@userID INT
AS
BEGIN
	DECLARE @admin BIT
	SELECT @admin = admin FROM dbo.userinfo2 WHERE id = @userID
	
	IF @admin = 1
		OR EXISTS (SELECT 1 FROM bet_match_total WHERE user_host = @userID)
		OR EXISTS (SELECT 1 FROM bet_esport_match WHERE created_by = @userID)
		SELECT * FROM dbo.userinfo2 WHERE user_yn = 1 ORDER BY name
	ELSE 
		SELECT * FROM dbo.userinfo2 WHERE id = @userID ORDER BY name
END

GO

CREATE OR ALTER PROC [dbo].[bet_ticket_esport_insert]
    @user_id INT,
    @match NVARCHAR(50),
    @details XML,
    @userID INT
AS
BEGIN
    DECLARE @host INT, @admin BIT
    SELECT @host = created_by FROM bet_esport_match WHERE match_id = @match
    SELECT @admin = admin FROM dbo.userinfo2 WHERE id = @userID

    IF @admin = 0 AND (@host IS NULL OR @userID <> @host) AND EXISTS (
        SELECT 1 FROM vbet_esport_match WHERE match_id = @match AND status <> 2
    ) BEGIN
        SELECT 0 AS isSuccess, N'Trận Esports đã diễn ra, không thể vào cược. Liên hệ nhà cái để vào cược hộ!' AS msg
        RETURN
    END

    CREATE TABLE #ticket (
        user_id INT,
        match_id NVARCHAR(50),
        code NVARCHAR(64),
        money NUMERIC(19,0),
        [datetime] DATETIME,
        clear BIT
    )

    INSERT INTO #ticket
        SELECT @user_id,
               @match,
               a.Item.value('(code)[1]', 'NVARCHAR(64)'),
               a.Item.value('(money)[1]', 'NUMERIC(19,0)'),
               GETDATE(),
               NULL
        FROM @details.nodes('/details/item') AS a(Item)

    DELETE a
        FROM bet_ticket_esport a
        JOIN #ticket b ON b.user_id = a.user_id AND b.match_id = a.match_id

    INSERT INTO bet_ticket_esport (user_id, match_id, code, money, [datetime], clear)
        SELECT user_id, match_id, code, money, [datetime], clear
        FROM #ticket

    SELECT 1 AS isSuccess, N'Vào cược Esports thành công!' AS msg
END

GO
CREATE OR ALTER PROC [dbo].[bet_ticket_insert]
	@user_id INT,
	@match NVARCHAR(MAX),
	@details XML,
	@userID INT
AS
BEGIN
	SELECT TOP 0 * INTO #bet_ticket FROM bet_ticket
	
	DECLARE @host INT, @admin BIT
	SELECT @host = user_host FROM bet_match_total WHERE match = @match
	SELECT @admin = admin FROM dbo.userinfo2 WHERE id = @userID
	
	IF @admin = 0 AND (@host IS NULL OR @userID <> @host) AND EXISTS (SELECT 1 FROM vbet_match_total WHERE match = @match AND status <> '2') BEGIN
		SELECT 0 AS isSuccess, N'Trận đấu đã diễn ra, không thể vào cược. Liên hệ nhà cái để vào cược hộ!' AS msg
		RETURN
	END

	INSERT INTO #bet_ticket 
		SELECT @user_id, @match, LEFT(a.Item.value('(code)[1]', 'NVARCHAR(MAX)'), 2) AS code
				, RIGHT(a.Item.value('(code)[1]', 'NVARCHAR(MAX)'), 1) AS ticket
				, a.Item.value('(money)[1]', 'DECIMAL(19)') AS money
				, GETDATE() AS datetime, NULL AS clear
			FROM @details.nodes('/details/item') AS a(Item)

	DELETE a FROM bet_ticket a JOIN #bet_ticket b ON a.user_id = b.user_id AND a.match = b.match
	INSERT INTO bet_ticket SELECT * FROM #bet_ticket

	SELECT 1 AS isSuccess, N'Vào cược thành công!' AS msg
END

GO
CREATE OR ALTER PROC [dbo].[bet_table]
AS
BEGIN
	create table #data (user_id int, match nvarchar(max), code nvarchar(max), money_win numeric(19, 2), balance numeric(19, 2), fee numeric(19, 2))
	select top 0 user_id, money_win, money_win as rate_of_win, balance, fee into #table from #data

	-- data
	exec [bet_ticket_result] '', '', '', 1, 2, 2, '', '', 'insert #data select user_id, match, code, money_win, balance, fee from #result where systotal = 0'
	insert into #table select distinct user_id, 0, 0, 0, 0 from #data

	-- lãi/lỗ
	update a set money_win = isnull(b.money_win, 0), balance = isnull(b.balance, 0), fee = isnull(b.fee, 0)
		from #table a 
			join (select user_id, sum(money_win) as money_win, sum(balance) as balance, sum(fee) as fee from #data where code <> '00' group by user_id) b on a.user_id = b.user_id
	
	select row_number()over(order by a.money_win desc) as stt, a.*, b.comment as name 
		from #table a left join dbo.userinfo2 b on a.user_id = b.id
	
	drop table if exists #data, #table
END

GO
CREATE OR ALTER VIEW [dbo].[vbet_match_total]
AS
	SELECT a.match, a.season, a.time, a.home, a.way, a.user_host, ISNULL(u.comment, '') AS host_name, a.home + ' - ' + a.way AS name
			, CASE WHEN h1_conner_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h1_conner_over_under, '### ### ###.#0') END AS h1_conner_over_under
			, CASE WHEN h2_conner_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h2_conner_over_under, '### ### ###.#0') END AS h2_conner_over_under
			, CASE WHEN ft_conner_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(ft_conner_over_under, '### ### ###.#0') END AS ft_conner_over_under
			, CASE WHEN h1_conner_handicap IS NULL THEN '___' ELSE CASE WHEN h1_conner_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(h1_conner_handicap, '### ### ###.#0') END AS h1_conner_handicap
			, CASE WHEN h2_conner_handicap IS NULL THEN '___' ELSE CASE WHEN h2_conner_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(h2_conner_handicap, '### ### ###.#0') END AS h2_conner_handicap
			, CASE WHEN ft_conner_handicap IS NULL THEN '___' ELSE CASE WHEN ft_conner_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(ft_conner_handicap, '### ### ###.#0') END AS ft_conner_handicap
			
			, CASE WHEN h1_goal_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h1_goal_over_under, '### ### ###.#0') END AS h1_goal_over_under
			, CASE WHEN h2_goal_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h2_goal_over_under, '### ### ###.#0') END AS h2_goal_over_under
			, CASE WHEN ft_goal_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(ft_goal_over_under, '### ### ###.#0') END AS ft_goal_over_under
			, CASE WHEN h1_goal_handicap IS NULL THEN '___' ELSE CASE WHEN h1_goal_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(h1_goal_handicap, '### ### ###.#0') END AS h1_goal_handicap
			, CASE WHEN h2_goal_handicap IS NULL THEN '___' ELSE CASE WHEN h2_goal_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(h2_goal_handicap, '### ### ###.#0') END AS h2_goal_handicap
			, CASE WHEN ft_goal_handicap IS NULL THEN '___' ELSE CASE WHEN ft_goal_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(ft_goal_handicap, '### ### ###.#0') END AS ft_goal_handicap
			
			, CASE WHEN h1_card_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h1_card_over_under, '### ### ###.#0') END AS h1_card_over_under
			, CASE WHEN h2_card_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h2_card_over_under, '### ### ###.#0') END AS h2_card_over_under
			, CASE WHEN ft_card_over_under IS NULL THEN '___' ELSE dbo.ff_NumberFormat(ft_card_over_under, '### ### ###.#0') END AS ft_card_over_under
			, CASE WHEN h1_card_handicap IS NULL THEN '___' ELSE CASE WHEN h1_card_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(h1_card_handicap, '### ### ###.#0') END AS h1_card_handicap
			, CASE WHEN h2_card_handicap IS NULL THEN '___' ELSE CASE WHEN h2_card_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(h2_card_handicap, '### ### ###.#0') END AS h2_card_handicap
			, CASE WHEN ft_card_handicap IS NULL THEN '___' ELSE CASE WHEN ft_card_handicap > 0 THEN '+' ELSE '' END + dbo.ff_NumberFormat(ft_card_handicap, '### ### ###.#0') END AS ft_card_handicap
			
			, CASE WHEN h1_euro_home IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h1_euro_home, '### ### ###.#0') END AS h1_euro_home
			, CASE WHEN h2_euro_home IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h2_euro_home, '### ### ###.#0') END AS h2_euro_home
			, CASE WHEN ft_euro_home IS NULL THEN '___' ELSE dbo.ff_NumberFormat(ft_euro_home, '### ### ###.#0') END AS ft_euro_home
			, CASE WHEN h1_euro_draw IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h1_euro_draw, '### ### ###.#0') END AS h1_euro_draw
			, CASE WHEN h2_euro_draw IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h2_euro_draw, '### ### ###.#0') END AS h2_euro_draw
			, CASE WHEN ft_euro_draw IS NULL THEN '___' ELSE dbo.ff_NumberFormat(ft_euro_draw, '### ### ###.#0') END AS ft_euro_draw
			, CASE WHEN h1_euro_way IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h1_euro_way, '### ### ###.#0') END AS h1_euro_way
			, CASE WHEN h2_euro_way IS NULL THEN '___' ELSE dbo.ff_NumberFormat(h2_euro_way, '### ### ###.#0') END AS h2_euro_way
			, CASE WHEN ft_euro_way IS NULL THEN '___' ELSE dbo.ff_NumberFormat(ft_euro_way, '### ### ###.#0') END AS ft_euro_way
			, CASE WHEN GETDATE() BETWEEN a.time AND DATEADD(MINUTE, 120, a.time) THEN 1 
				   WHEN GETDATE() < a.time THEN 2 
				   ELSE CASE WHEN EXISTS (SELECT 1 FROM bet_match x JOIN bet_ticket y ON x.match = y.match AND x.code = y.code WHERE a.match = x.match AND result_home IS NULL) AND EXISTS (SELECT 1 FROM bet_ticket x WHERE a.match = x.match) THEN 3 
							 WHEN EXISTS (SELECT 1 FROM bet_ticket x WHERE a.match = x.match AND ISNULL(x.clear, 0) = 0) THEN 4 
							 ELSE 5 END END AS status
			, CASE WHEN GETDATE() BETWEEN a.time AND DATEADD(MINUTE, 120, a.time) THEN N'Trực tiếp' 
				   WHEN GETDATE() < a.time THEN N'Sắp tới' 
				   ELSE CASE WHEN EXISTS (SELECT 1 FROM bet_match x JOIN bet_ticket y ON x.match = y.match AND x.code = y.code WHERE a.match = x.match AND result_home IS NULL) AND EXISTS (SELECT 1 FROM bet_ticket x WHERE a.match = x.match) THEN N'Chờ kết quả' 
										   WHEN EXISTS (SELECT 1 FROM bet_ticket x WHERE a.match = x.match AND ISNULL(x.clear, 0) = 0) THEN N'Chưa tất toán' 
										   ELSE N'Kết thúc' 
										   END 
				   END AS statusname
			, ABS(DATEDIFF(MINUTE, a.time, GETDATE())) AS statusorder
			, ROW_NUMBER()OVER(ORDER BY CASE WHEN GETDATE() BETWEEN a.time AND DATEADD(MINUTE, 120, a.time) THEN 1 WHEN GETDATE() < a.time THEN 2 ELSE 3 END, ABS(DATEDIFF(MINUTE, a.time, GETDATE())), a.match) AS xKey
			, h1_conner_over_win, h1_conner_under_win
			, h2_conner_over_win, h2_conner_under_win
			, ft_conner_over_win, ft_conner_under_win
			, h1_conner_home_win, h1_conner_way_win
			, h2_conner_home_win, h2_conner_way_win
			, ft_conner_home_win, ft_conner_way_win
			
			, h1_goal_over_win, h1_goal_under_win
			, h2_goal_over_win, h2_goal_under_win
			, ft_goal_over_win, ft_goal_under_win
			, h1_goal_home_win, h1_goal_way_win
			, h2_goal_home_win, h2_goal_way_win
			, ft_goal_home_win, ft_goal_way_win

			, h1_card_over_win, h1_card_under_win
			, h2_card_over_win, h2_card_under_win
			, ft_card_over_win, ft_card_under_win
			, h1_card_home_win, h1_card_way_win
			, h2_card_home_win, h2_card_way_win
			, ft_card_home_win, ft_card_way_win
		FROM bet_match_total a
			LEFT JOIN dbo.userinfo2 u ON a.user_host = u.id

GO
DECLARE @source nvarchar(max), @target nvarchar(max);
SELECT @source = (SELECT * FROM TAPHOA_FBOHRMSP229_Sys.dbo.userinfo2 ORDER BY id FOR XML PATH('row'), BINARY BASE64);
SELECT @target = (SELECT * FROM dbo.userinfo2 ORDER BY id FOR XML PATH('row'), BINARY BASE64);
IF @source <> @target OR @source IS NULL OR @target IS NULL THROW 50002, 'User copy verification failed', 1;
IF EXISTS (SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.objects o ON o.object_id=d.referencing_id WHERE (o.name LIKE 'bet[_]%' OR o.name LIKE 'vbet[_]%' OR o.name='vsysuserinfo') AND d.referenced_database_name='TAPHOA_FBOHRMSP229_Sys' AND o.name NOT IN ('bet_host_history','bet_host_transfer','bet_ticket_result2','bet_table2')) THROW 50003, 'Unexpected Sys dependency remains', 1;
COMMIT TRANSACTION;
GO
