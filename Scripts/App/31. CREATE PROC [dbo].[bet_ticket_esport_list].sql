DROP PROC IF EXISTS [dbo].[bet_ticket_esport_list]
GO

CREATE PROC [dbo].[bet_ticket_esport_list]
    @user_id INT = -1,
    @match NVARCHAR(MAX) = '',
    @season NVARCHAR(MAX) = '',
    @type CHAR(1) = '0',
    @clear CHAR(1) = '0',
    @result CHAR(1) = '2',
    @df NVARCHAR(MAX) = NULL,
    @dt NVARCHAR(MAX) = NULL
AS
BEGIN
    SELECT
        t.user_id,
        t.match_id AS match,
        t.code,
        CAST('' AS NVARCHAR(16)) AS ticket,
        t.money,
        CAST(0 AS NUMERIC(19, 2)) AS money_win,
        CAST(0 AS NUMERIC(19, 2)) AS fee,
        CAST('' AS NVARCHAR(MAX)) AS result_name,
        CAST('' AS NVARCHAR(MAX)) AS textColor,
        CAST('' AS NVARCHAR(MAX)) AS rowColor,
        CAST('' AS NVARCHAR(MAX)) AS rowBold,
        t.clear,
        t.[datetime],
        m.season,
        m.match_time,
        ISNULL(h.team_name, m.home) AS home_name,
        ISNULL(w.team_name, m.way) AS way_name,
        TRY_CAST(SUBSTRING(t.code, 2, CHARINDEX('.', t.code) - 2) AS INT) AS game_no,
        PARSENAME(REPLACE(t.code, '.', '.'), 2) AS market,
        PARSENAME(REPLACE(t.code, '.', '.'), 1) AS side
    INTO #ticket
    FROM bet_ticket_esport t
    JOIN bet_esport_match m ON m.match_id = t.match_id
    LEFT JOIN bet_team h ON h.team = m.home
    LEFT JOIN bet_team w ON w.team = m.way
    WHERE (@user_id = -1 OR t.user_id = @user_id)
        AND (@match = '' OR t.match_id = @match OR ISNULL(h.team_name, m.home) + ' vs ' + ISNULL(w.team_name, m.way) LIKE '%' + @match + '%')
        AND (@season = '' OR m.season = @season)
        AND (@clear = '2' OR ISNULL(t.clear, 0) = TRY_CAST(@clear AS BIT))
        AND (@result IN ('0', '2'))
        AND (@df IS NULL OR CONVERT(CHAR(8), t.[datetime], 112) + REPLACE(CONVERT(CHAR(5), t.[datetime], 108), ':', '') >= @df)
        AND (@dt IS NULL OR CONVERT(CHAR(8), t.[datetime], 112) + REPLACE(CONVERT(CHAR(5), t.[datetime], 108), ':', '') <= @dt)

    SELECT e.user_id,
           e.match,
           e.code,
           e.ticket,
           CASE WHEN e.game_no = 6 THEN 'BO x' ELSE 'Game ' + CONVERT(VARCHAR(10), e.game_no) END
             + '. '
             + CASE
                 WHEN e.market = 'OU' AND e.side = 'O' THEN N'Tài ' + REPLACE(STR(g.ou_line, 19, 2), ' ', '') + CASE WHEN e.game_no = 6 THEN N' game' ELSE N' kill' END
                 WHEN e.market = 'OU' AND e.side = 'U' THEN N'Xỉu ' + REPLACE(STR(g.ou_line, 19, 2), ' ', '') + CASE WHEN e.game_no = 6 THEN N' game' ELSE N' kill' END
                 WHEN e.market = 'HC' AND e.side = 'H' THEN e.home_name + CASE WHEN g.hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(g.hc_line, 19, 2), ' ', '') + CASE WHEN e.game_no = 6 THEN N' game' ELSE N' kill' END
                 WHEN e.market = 'HC' AND e.side = 'W' THEN e.way_name + CASE WHEN g.hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-g.hc_line, 19, 2), ' ', '') + CASE WHEN e.game_no = 6 THEN N' game' ELSE N' kill' END
                 WHEN e.market = 'MIN' AND e.side = 'O' THEN N'Tài ' + REPLACE(STR(g.minute_line, 19, 2), ' ', '') + N' phút'
                 WHEN e.market = 'MIN' AND e.side = 'U' THEN N'Xỉu ' + REPLACE(STR(g.minute_line, 19, 2), ' ', '') + N' phút'
                 WHEN e.market = 'DOU' AND e.side = 'O' THEN N'Tài ' + REPLACE(STR(g.dragon_ou_line, 19, 2), ' ', '') + N' rồng'
                 WHEN e.market = 'DOU' AND e.side = 'U' THEN N'Xỉu ' + REPLACE(STR(g.dragon_ou_line, 19, 2), ' ', '') + N' rồng'
                 WHEN e.market = 'DHC' AND e.side = 'H' THEN e.home_name + CASE WHEN g.dragon_hc_line >= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(g.dragon_hc_line, 19, 2), ' ', '') + N' rồng'
                 WHEN e.market = 'DHC' AND e.side = 'W' THEN e.way_name + CASE WHEN g.dragon_hc_line <= 0 THEN ' +' ELSE ' ' END + REPLACE(STR(-g.dragon_hc_line, 19, 2), ' ', '') + N' rồng'
                 WHEN e.market = 'FD' AND e.side = 'H' THEN N'Rồng đầu ' + e.home_name + ' (' + dbo.ff_NumberFormat(g.first_dragon_home_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'FD' AND e.side = 'W' THEN N'Rồng đầu ' + e.way_name + ' (' + dbo.ff_NumberFormat(g.first_dragon_way_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'FIRST' AND e.side = 'H' THEN N'Mạng đầu ' + e.home_name + ' (' + dbo.ff_NumberFormat(g.first_home_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'FIRST' AND e.side = 'W' THEN N'Mạng đầu ' + e.way_name + ' (' + dbo.ff_NumberFormat(g.first_way_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'THIRD' AND e.side = 'H' THEN N'3 mạng đầu ' + e.home_name + ' (' + dbo.ff_NumberFormat(g.third_home_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'THIRD' AND e.side = 'W' THEN N'3 mạng đầu ' + e.way_name + ' (' + dbo.ff_NumberFormat(g.third_way_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'FIVE' AND e.side = 'H' THEN N'5 mạng đầu ' + e.home_name + ' (' + dbo.ff_NumberFormat(g.five_home_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'FIVE' AND e.side = 'W' THEN N'5 mạng đầu ' + e.way_name + ' (' + dbo.ff_NumberFormat(g.five_way_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'TEN' AND e.side = 'H' THEN N'10 mạng đầu ' + e.home_name + ' (' + dbo.ff_NumberFormat(g.ten_home_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'TEN' AND e.side = 'W' THEN N'10 mạng đầu ' + e.way_name + ' (' + dbo.ff_NumberFormat(g.ten_way_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'WIN' AND e.side = 'H' THEN e.home_name + N' win (' + dbo.ff_NumberFormat(g.win_home_win, '### ### ###.#0') + ')'
                 WHEN e.market = 'WIN' AND e.side = 'W' THEN e.way_name + N' win (' + dbo.ff_NumberFormat(g.win_way_win, '### ### ###.#0') + ')'
                 ELSE e.code
               END AS ticket_name,
           e.money,
           e.money_win,
           e.fee,
           e.result_name,
           e.textColor,
           e.rowColor,
           e.rowBold,
           e.game_no,
           CAST('esport' AS NVARCHAR(16)) AS ticket_type
    INTO #detail
    FROM #ticket e
    JOIN bet_esport_game g ON g.match_id = e.match AND g.game_no = e.game_no

    IF @type = '1'
        SELECT match,
               user_id,
               CAST('' AS NVARCHAR(64)) AS code,
               CAST('' AS NVARCHAR(16)) AS ticket,
               N'Esports. ' + home_name + ' vs ' + way_name AS ticket_name,
               SUM(money) AS money,
               CAST(0 AS NUMERIC(19, 2)) AS money_win,
               CAST(0 AS NUMERIC(19, 2)) AS fee,
               CAST('' AS NVARCHAR(MAX)) AS result_name,
               CAST('' AS NVARCHAR(MAX)) AS textColor,
               CAST('' AS NVARCHAR(MAX)) AS rowColor,
               CAST('' AS NVARCHAR(MAX)) AS rowBold,
               CAST('esport' AS NVARCHAR(16)) AS ticket_type
        FROM #ticket
        GROUP BY match, user_id, home_name, way_name
        ORDER BY match DESC, user_id
    ELSE
        SELECT *
        FROM #detail
        ORDER BY match DESC, user_id, game_no, code
END
GO
