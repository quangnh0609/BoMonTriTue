DROP PROC IF EXISTS [dbo].[bet_ticket_esport_code]
GO

CREATE PROC [dbo].[bet_ticket_esport_code]
    @userID INT,
    @match NVARCHAR(50)
AS
BEGIN
    SELECT g.*, ISNULL(h.team_name, m.home) AS home_name, ISNULL(w.team_name, m.way) AS way_name
        INTO #game
        FROM bet_esport_game g
        JOIN bet_esport_match m ON m.match_id = g.match_id
        LEFT JOIN bet_team h ON h.team = m.home
        LEFT JOIN bet_team w ON w.team = m.way
        WHERE g.match_id = @match

    CREATE TABLE #data (
        stt INT IDENTITY(1, 1),
        game_no INT,
        market_order INT,
        code NVARCHAR(64),
        code_name NVARCHAR(MAX),
        money NUMERIC(19,0),
        textColor NVARCHAR(MAX),
        rowColor NVARCHAR(MAX)
    )

    INSERT INTO #data SELECT game_no, 10, 'G' + CONVERT(VARCHAR(10), game_no) + '.OU.O', CASE WHEN game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), game_no) END + N'. Tài ' + REPLACE(STR(ou_line, 19, 2), ' ', '') + CASE WHEN game_no = 6 THEN N' game' ELSE N' kill' END, 0, '', '' FROM #game WHERE ou_line IS NOT NULL
    INSERT INTO #data SELECT game_no, 11, 'G' + CONVERT(VARCHAR(10), game_no) + '.OU.U', CASE WHEN game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), game_no) END + N'. Xỉu ' + REPLACE(STR(ou_line, 19, 2), ' ', '') + CASE WHEN game_no = 6 THEN N' game' ELSE N' kill' END, 0, '', '' FROM #game WHERE ou_line IS NOT NULL
    INSERT INTO #data SELECT game_no, 20, 'G' + CONVERT(VARCHAR(10), game_no) + '.HC.H', CASE WHEN game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), game_no) END + '. ' + home_name + CASE WHEN hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(hc_line, 19, 2), ' ', '') + CASE WHEN game_no = 6 THEN N' game' ELSE N' kill' END, 0, '', '' FROM #game WHERE hc_line IS NOT NULL
    INSERT INTO #data SELECT game_no, 21, 'G' + CONVERT(VARCHAR(10), game_no) + '.HC.W', CASE WHEN game_no = 6 THEN 'BO x' ELSE 'G' + CONVERT(VARCHAR(10), game_no) END + '. ' + way_name + CASE WHEN hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-hc_line, 19, 2), ' ', '') + CASE WHEN game_no = 6 THEN N' game' ELSE N' kill' END, 0, '', '' FROM #game WHERE hc_line IS NOT NULL

    INSERT INTO #data SELECT game_no, 30, 'G' + CONVERT(VARCHAR(10), game_no) + '.MIN.O', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Tài ' + REPLACE(STR(minute_line, 19, 2), ' ', '') + N' phút', 0, '', '' FROM #game WHERE game_no <> 6 AND minute_line IS NOT NULL
    INSERT INTO #data SELECT game_no, 31, 'G' + CONVERT(VARCHAR(10), game_no) + '.MIN.U', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Xỉu ' + REPLACE(STR(minute_line, 19, 2), ' ', '') + N' phút', 0, '', '' FROM #game WHERE game_no <> 6 AND minute_line IS NOT NULL

    INSERT INTO #data SELECT game_no, 40, 'G' + CONVERT(VARCHAR(10), game_no) + '.DOU.O', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Tài ' + REPLACE(STR(dragon_ou_line, 19, 2), ' ', '') + N' rồng', 0, '', '' FROM #game WHERE game_no <> 6 AND dragon_ou_line IS NOT NULL
    INSERT INTO #data SELECT game_no, 41, 'G' + CONVERT(VARCHAR(10), game_no) + '.DOU.U', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Xỉu ' + REPLACE(STR(dragon_ou_line, 19, 2), ' ', '') + N' rồng', 0, '', '' FROM #game WHERE game_no <> 6 AND dragon_ou_line IS NOT NULL
    INSERT INTO #data SELECT game_no, 50, 'G' + CONVERT(VARCHAR(10), game_no) + '.DHC.H', 'G' + CONVERT(VARCHAR(10), game_no) + '. ' + home_name + CASE WHEN dragon_hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(dragon_hc_line, 19, 2), ' ', '') + N' rồng', 0, '', '' FROM #game WHERE game_no <> 6 AND dragon_hc_line IS NOT NULL
    INSERT INTO #data SELECT game_no, 51, 'G' + CONVERT(VARCHAR(10), game_no) + '.DHC.W', 'G' + CONVERT(VARCHAR(10), game_no) + '. ' + way_name + CASE WHEN dragon_hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-dragon_hc_line, 19, 2), ' ', '') + N' rồng', 0, '', '' FROM #game WHERE game_no <> 6 AND dragon_hc_line IS NOT NULL

    INSERT INTO #data SELECT game_no, 60, 'G' + CONVERT(VARCHAR(10), game_no) + '.FD.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu ' + home_name + ' (' + dbo.ff_NumberFormat(first_dragon_home_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_home_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 61, 'G' + CONVERT(VARCHAR(10), game_no) + '.FD.W', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu ' + way_name + ' (' + dbo.ff_NumberFormat(first_dragon_way_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_way_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 62, 'G' + CONVERT(VARCHAR(10), game_no) + '.FDT.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu công nghệ (' + dbo.ff_NumberFormat(first_dragon_tech_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_tech_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 63, 'G' + CONVERT(VARCHAR(10), game_no) + '.FDCHEM.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu hóa kỹ (' + dbo.ff_NumberFormat(first_dragon_chemtech_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_chemtech_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 64, 'G' + CONVERT(VARCHAR(10), game_no) + '.FDWIND.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu gió (' + dbo.ff_NumberFormat(first_dragon_wind_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_wind_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 65, 'G' + CONVERT(VARCHAR(10), game_no) + '.FDWATER.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu nước (' + dbo.ff_NumberFormat(first_dragon_water_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_water_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 66, 'G' + CONVERT(VARCHAR(10), game_no) + '.FDFIRE.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu lửa (' + dbo.ff_NumberFormat(first_dragon_fire_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_fire_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 67, 'G' + CONVERT(VARCHAR(10), game_no) + '.FDEARTH.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Rồng đầu đất (' + dbo.ff_NumberFormat(first_dragon_earth_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_dragon_earth_win IS NOT NULL

    INSERT INTO #data SELECT game_no, 70, 'G' + CONVERT(VARCHAR(10), game_no) + '.FIRST.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Mạng đầu ' + home_name + ' (' + dbo.ff_NumberFormat(first_home_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_home_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 71, 'G' + CONVERT(VARCHAR(10), game_no) + '.FIRST.W', 'G' + CONVERT(VARCHAR(10), game_no) + N'. Mạng đầu ' + way_name + ' (' + dbo.ff_NumberFormat(first_way_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND first_way_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 80, 'G' + CONVERT(VARCHAR(10), game_no) + '.THIRD.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. 3 mạng đầu ' + home_name + ' (' + dbo.ff_NumberFormat(third_home_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND third_home_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 81, 'G' + CONVERT(VARCHAR(10), game_no) + '.THIRD.W', 'G' + CONVERT(VARCHAR(10), game_no) + N'. 3 mạng đầu ' + way_name + ' (' + dbo.ff_NumberFormat(third_way_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND third_way_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 90, 'G' + CONVERT(VARCHAR(10), game_no) + '.FIVE.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. 5 mạng đầu ' + home_name + ' (' + dbo.ff_NumberFormat(five_home_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND five_home_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 91, 'G' + CONVERT(VARCHAR(10), game_no) + '.FIVE.W', 'G' + CONVERT(VARCHAR(10), game_no) + N'. 5 mạng đầu ' + way_name + ' (' + dbo.ff_NumberFormat(five_way_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND five_way_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 100, 'G' + CONVERT(VARCHAR(10), game_no) + '.TEN.H', 'G' + CONVERT(VARCHAR(10), game_no) + N'. 10 mạng đầu ' + home_name + ' (' + dbo.ff_NumberFormat(ten_home_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND ten_home_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 101, 'G' + CONVERT(VARCHAR(10), game_no) + '.TEN.W', 'G' + CONVERT(VARCHAR(10), game_no) + N'. 10 mạng đầu ' + way_name + ' (' + dbo.ff_NumberFormat(ten_way_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND ten_way_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 110, 'G' + CONVERT(VARCHAR(10), game_no) + '.WIN.H', 'G' + CONVERT(VARCHAR(10), game_no) + '. ' + home_name + N' win (' + dbo.ff_NumberFormat(win_home_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND win_home_win IS NOT NULL
    INSERT INTO #data SELECT game_no, 111, 'G' + CONVERT(VARCHAR(10), game_no) + '.WIN.W', 'G' + CONVERT(VARCHAR(10), game_no) + '. ' + way_name + N' win (' + dbo.ff_NumberFormat(win_way_win, '### ### ###.#0') + ')', 0, '', '' FROM #game WHERE game_no <> 6 AND win_way_win IS NOT NULL

    UPDATE d
        SET money = t.money
        FROM #data d
        JOIN bet_ticket_esport t ON t.match_id = @match AND t.user_id = @userID AND t.code = d.code

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

    UPDATE #data SET rowColor = 'Lavender' WHERE game_no % 2 = 1
    UPDATE #data SET rowColor = 'LightYellow' WHERE game_no % 2 = 0

    SELECT * FROM #data ORDER BY game_no, market_order, stt
END
GO
exec bet_ticket_esport_code @match=N'E33',@userID=9
