
CREATE   PROC [dbo].[bet_ticket_result]
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
