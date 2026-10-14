DROP VIEW IF EXISTS [dbo].[vbet_match_total]
GO
CREATE VIEW [dbo].[vbet_match_total]
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
			LEFT JOIN vsysuserinfo u ON a.user_host = u.id
GO
