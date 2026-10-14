DROP PROC IF EXISTS [dbo].[bet_ticket_copy]
GO
CREATE PROC [dbo].[bet_ticket_copy]
	@user_id INT
AS
BEGIN
	SELECT b.*, c.name, c.part, a.ticket, a.money
		INTO #ticket
		FROM bet_ticket a 
			JOIN bet_match b ON a.match = b.match AND a.code = b.code 
			JOIN bet_code c ON a.code = c.code
			JOIN vbet_match_total d ON a.match = d.match AND d.status = '2'
		WHERE a.user_id = @user_id
	
	CREATE TABLE #data (id INT IDENTITY(1, 1), stt INT, match NVARCHAR(MAX), code NVARCHAR(MAX), code_name NVARCHAR(MAX), money INT, textColor NVARCHAR(MAX), rowColor NVARCHAR(MAX))
	
	-- hiệp 1
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '01' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '01' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '11' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '11' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '21' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '21' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '31' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '31' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '51' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '51' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '61' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '61' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '41' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.D', part + '. ' + 'Hòa' + ' (' + dbo.ff_NumberFormat(draw_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '41' AND ticket = 'D'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + ' (' + dbo.ff_NumberFormat(way_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '41' AND ticket = 'W'

	-- cả trận
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '03' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '03' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '13' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '13' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '23' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '23' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '33' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '33' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '53' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '53' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '63' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '63' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '43' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.D', part + '. ' + 'Hòa' + ' (' + dbo.ff_NumberFormat(draw_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '43' AND ticket = 'D'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + ' (' + dbo.ff_NumberFormat(way_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '43' AND ticket = 'W'

	-- hiệp 2
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '02' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '02' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '12' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '12' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '22' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '22' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '32' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '32' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '52' AND ticket = 'O'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, money, '', '' FROM #ticket WHERE code = '52' AND ticket = 'U'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '62' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), money, '', '' FROM #ticket WHERE code = '62' AND ticket = 'W'
	
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.H', part + '. ' + home + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '42' AND ticket = 'H'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.D', part + '. ' + 'Hòa' + ' (' + dbo.ff_NumberFormat(draw_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '42' AND ticket = 'D'
	INSERT INTO #data SELECT 0, match, RTRIM(LTRIM(code)) + '.W', part + '. ' + way + ' (' + dbo.ff_NumberFormat(way_win, '### ### ###.#0') + ')', money, '', '' FROM #ticket WHERE code = '42' AND ticket = 'W'

	-- esports
	SELECT t.match_id,
		   t.code,
		   t.money,
		   g.game_no,
		   ISNULL(h.team_name, m.home) AS home_name,
		   ISNULL(w.team_name, m.way) AS way_name,
		   g.ou_line, g.hc_line, g.minute_line, g.dragon_ou_line, g.dragon_hc_line,
		   g.first_dragon_home_win, g.first_dragon_way_win,
		   g.first_dragon_tech_win, g.first_dragon_chemtech_win, g.first_dragon_wind_win, g.first_dragon_water_win,
		   g.first_dragon_fire_win, g.first_dragon_earth_win,
		   g.first_home_win, g.first_way_win,
		   g.third_home_win, g.third_way_win,
		   g.five_home_win, g.five_way_win,
		   g.ten_home_win, g.ten_way_win,
		   g.win_home_win, g.win_way_win,
		   code_info.market,
		   PARSENAME(t.code, 1) AS ticket
		INTO #esport_ticket
		FROM bet_ticket_esport t
			JOIN bet_esport_match m ON m.match_id = t.match_id
			JOIN bet_esport_game g ON g.match_id = t.match_id
			CROSS APPLY (
				SELECT CHARINDEX('.', t.code) AS first_dot,
					   PARSENAME(t.code, 2) AS market
			) code_info
			LEFT JOIN bet_team h ON h.team = m.home
			LEFT JOIN bet_team w ON w.team = m.way
		WHERE t.user_id = @user_id
			AND GETDATE() < m.match_time
			AND code_info.first_dot > 2
			AND g.game_no = TRY_CAST(SUBSTRING(t.code, 2, code_info.first_dot - 2) AS INT)

	INSERT INTO #data
		SELECT 0, match_id, code,
			   CASE market
					WHEN 'OU' THEN CASE WHEN game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), game_no) END
						+ CASE ticket WHEN 'O' THEN N'. Tài ' ELSE N'. Xỉu ' END
						+ REPLACE(STR(ou_line, 19, 2), ' ', '')
						+ CASE WHEN game_no = 6 THEN N' game' ELSE N' kill' END
					WHEN 'HC' THEN CASE WHEN game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), game_no) END + '. '
						+ CASE ticket WHEN 'H' THEN home_name + CASE WHEN hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(hc_line, 19, 2), ' ', '')
									  ELSE way_name + CASE WHEN hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-hc_line, 19, 2), ' ', '') END
						+ CASE WHEN game_no = 6 THEN N' game' ELSE N' kill' END
					WHEN 'MIN' THEN 'G' + CONVERT(VARCHAR(10), game_no)
						+ CASE ticket WHEN 'O' THEN N'. Tài ' ELSE N'. Xỉu ' END
						+ REPLACE(STR(minute_line, 19, 2), ' ', '') + N' phút'
					WHEN 'DOU' THEN 'G' + CONVERT(VARCHAR(10), game_no)
						+ CASE ticket WHEN 'O' THEN N'. Tài ' ELSE N'. Xỉu ' END
						+ REPLACE(STR(dragon_ou_line, 19, 2), ' ', '') + N' rồng'
					WHEN 'DHC' THEN 'G' + CONVERT(VARCHAR(10), game_no) + '. '
						+ CASE ticket WHEN 'H' THEN home_name + CASE WHEN dragon_hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(dragon_hc_line, 19, 2), ' ', '')
									  ELSE way_name + CASE WHEN dragon_hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-dragon_hc_line, 19, 2), ' ', '') END
						+ N' rồng'
					WHEN 'FD' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu '
						+ CASE ticket WHEN 'H' THEN home_name + ' (' + dbo.ff_NumberFormat(first_dragon_home_win, '### ### ###.#0') + ')'
									  ELSE way_name + ' (' + dbo.ff_NumberFormat(first_dragon_way_win, '### ### ###.#0') + ')' END
					WHEN 'FDT' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu công nghệ (' + dbo.ff_NumberFormat(first_dragon_tech_win, '### ### ###.#0') + ')'
					WHEN 'FDCHEM' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu hóa kỹ (' + dbo.ff_NumberFormat(first_dragon_chemtech_win, '### ### ###.#0') + ')'
					WHEN 'FDWIND' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu gió (' + dbo.ff_NumberFormat(first_dragon_wind_win, '### ### ###.#0') + ')'
					WHEN 'FDWATER' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu nước (' + dbo.ff_NumberFormat(first_dragon_water_win, '### ### ###.#0') + ')'
					WHEN 'FDFIRE' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu lửa (' + dbo.ff_NumberFormat(first_dragon_fire_win, '### ### ###.#0') + ')'
					WHEN 'FDEARTH' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu đất (' + dbo.ff_NumberFormat(first_dragon_earth_win, '### ### ###.#0') + ')'
					WHEN 'FIRST' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. Mạng đầu '
						+ CASE ticket WHEN 'H' THEN home_name + ' (' + dbo.ff_NumberFormat(first_home_win, '### ### ###.#0') + ')'
									  ELSE way_name + ' (' + dbo.ff_NumberFormat(first_way_win, '### ### ###.#0') + ')' END
					WHEN 'THIRD' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. 3 mạng đầu '
						+ CASE ticket WHEN 'H' THEN home_name + ' (' + dbo.ff_NumberFormat(third_home_win, '### ### ###.#0') + ')'
									  ELSE way_name + ' (' + dbo.ff_NumberFormat(third_way_win, '### ### ###.#0') + ')' END
					WHEN 'FIVE' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. 5 mạng đầu '
						+ CASE ticket WHEN 'H' THEN home_name + ' (' + dbo.ff_NumberFormat(five_home_win, '### ### ###.#0') + ')'
									  ELSE way_name + ' (' + dbo.ff_NumberFormat(five_way_win, '### ### ###.#0') + ')' END
					WHEN 'TEN' THEN 'G' + CONVERT(VARCHAR(10), game_no) + N'. 10 mạng đầu '
						+ CASE ticket WHEN 'H' THEN home_name + ' (' + dbo.ff_NumberFormat(ten_home_win, '### ### ###.#0') + ')'
									  ELSE way_name + ' (' + dbo.ff_NumberFormat(ten_way_win, '### ### ###.#0') + ')' END
					WHEN 'WIN' THEN 'G' + CONVERT(VARCHAR(10), game_no) + '. '
						+ CASE ticket WHEN 'H' THEN home_name + N' win (' + dbo.ff_NumberFormat(win_home_win, '### ### ###.#0') + ')'
									  ELSE way_name + N' win (' + dbo.ff_NumberFormat(win_way_win, '### ### ###.#0') + ')' END
					ELSE code END,
			   money, '', ''
		FROM #esport_ticket

	-- format
	UPDATE #data SET rowColor = 'Lavender' WHERE code LIKE '%1.%'
	UPDATE #data SET rowColor = 'LightYellow' WHERE code LIKE '%3.%'
	UPDATE #data SET rowColor = 'LightSkyBlue' WHERE code LIKE '%2.%'
	UPDATE #data
		SET rowColor = CASE WHEN TRY_CAST(SUBSTRING(code, 2, CHARINDEX('.', code) - 2) AS INT) % 2 = 1 THEN 'Lavender' ELSE 'LightYellow' END
		WHERE code LIKE 'G%.%.%'

	UPDATE #data SET textColor = 'green' WHERE code LIKE '%.OU.%'
	UPDATE #data SET textColor = 'red' WHERE code LIKE '%.HC.%'
	UPDATE #data SET textColor = 'blue' WHERE code LIKE '%.MIN.%'
	UPDATE #data SET textColor = 'brown' WHERE code LIKE '%.DOU.%'
	UPDATE #data SET textColor = 'orange' WHERE code LIKE '%.DHC.%'
	UPDATE #data SET textColor = 'green' WHERE code LIKE '%.FD.%'
	UPDATE #data SET textColor = 'purple' WHERE code LIKE '%.WIN.%'
    UPDATE #data SET textColor = '#0284c7' WHERE code LIKE '%.FDT.%'
    UPDATE #data SET textColor = '#4d7c0f' WHERE code LIKE '%.FDCHEM.%'
    UPDATE #data SET textColor = '#0d9488' WHERE code LIKE '%.FDWIND.%'
    UPDATE #data SET textColor = '#2563eb' WHERE code LIKE '%.FDWATER.%'
    UPDATE #data SET textColor = '#ea580c' WHERE code LIKE '%.FDFIRE.%'
    UPDATE #data SET textColor = '#b45309' WHERE code LIKE '%.FDEARTH.%'
	UPDATE #data SET textColor = 'red' WHERE textColor = ''

	--UPDATE #data SET rowColor = 'Lavender' WHERE game_no % 2 = 1
	--UPDATE #data SET rowColor = 'LightYellow' WHERE game_no % 2 = 0
	
	-- Total by match
	UPDATE a SET stt = b.stt
		FROM #data a JOIN (SELECT ROW_NUMBER()OVER(ORDER BY match, id) AS stt, match, code FROM #data) b ON a.match = b.match AND a.code = b.code

	INSERT INTO #data
		SELECT b.stt, a.match, '', c.home + ' vs ' + c.way, SUM(money), 'Red', 'LightGreen'
			FROM #data a 
				JOIN (SELECT match, MIN(stt) AS stt FROM #data GROUP BY match) b ON a.match = b.match
				JOIN vbet_match_total c ON a.match = c.match
			GROUP BY b.stt, a.match, c.home, c.way

	INSERT INTO #data
		SELECT b.stt, a.match, '', ISNULL(h.team_name, c.home) + ' vs ' + ISNULL(w.team_name, c.way), SUM(money), 'Red', 'LightGreen'
			FROM #data a
				JOIN (SELECT match, MIN(stt) AS stt FROM #data GROUP BY match) b ON a.match = b.match
				JOIN bet_esport_match c ON a.match = c.match_id
				LEFT JOIN bet_team h ON h.team = c.home
				LEFT JOIN bet_team w ON w.team = c.way
			GROUP BY b.stt, a.match, ISNULL(h.team_name, c.home), ISNULL(w.team_name, c.way)

	SELECT * FROM #data
	ORDER BY stt,
		CASE WHEN code = '' THEN 0 ELSE 1 END,
		CASE WHEN code LIKE 'G%.%.%' THEN TRY_CAST(SUBSTRING(code, 2, CHARINDEX('.', code) - 2) AS INT) ELSE NULL END,
		CASE PARSENAME(code, 2)
			WHEN 'OU' THEN 10
			WHEN 'HC' THEN 20
			WHEN 'MIN' THEN 30
			WHEN 'DOU' THEN 40
			WHEN 'DHC' THEN 50
			WHEN 'FD' THEN 60
			WHEN 'FDT' THEN 62
			WHEN 'FDCHEM' THEN 63
			WHEN 'FDWIND' THEN 64
			WHEN 'FDWATER' THEN 65
			WHEN 'FDFIRE' THEN 66
			WHEN 'FDEARTH' THEN 67
			WHEN 'FIRST' THEN 70
			WHEN 'THIRD' THEN 80
			WHEN 'FIVE' THEN 90
			WHEN 'TEN' THEN 100
			WHEN 'WIN' THEN 110
			ELSE NULL
		END,
		code
END
GO
exec [bet_ticket_copy] 2
