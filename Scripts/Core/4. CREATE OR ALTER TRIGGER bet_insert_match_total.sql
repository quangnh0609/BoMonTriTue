CREATE OR ALTER TRIGGER bet_match_total_insert
   ON  dbo.bet_match
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	SELECT TOP 0 * INTO #bet_match_total FROM bet_match_total
	INSERT INTO #bet_match_total (match) SELECT DISTINCT match FROM (SELECT * FROM inserted UNION ALL SELECT * FROM deleted) a

	UPDATE #bet_match_total SET season = b.season, time = b.time, home = b.home, way = b.way FROM #bet_match_total a JOIN (SELECT * FROM inserted UNION ALL SELECT * FROM deleted) b ON a.match = b.match
	UPDATE #bet_match_total SET user_host = b.user_host FROM #bet_match_total a JOIN bet_match_total b ON a.match = b.match

	UPDATE #bet_match_total SET h1_conner_over_under = over_under, h1_conner_over_win = over_win, h1_conner_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '01'
	UPDATE #bet_match_total SET h2_conner_over_under = over_under, h2_conner_over_win = over_win, h2_conner_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '02'
	UPDATE #bet_match_total SET ft_conner_over_under = over_under, ft_conner_over_win = over_win, ft_conner_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '03'

	UPDATE #bet_match_total SET h1_conner_handicap = handicap, h1_conner_home_win = home_win, h1_conner_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '11'
	UPDATE #bet_match_total SET h2_conner_handicap = handicap, h2_conner_home_win = home_win, h2_conner_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '12'
	UPDATE #bet_match_total SET ft_conner_handicap = handicap, ft_conner_home_win = home_win, ft_conner_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '13'

	UPDATE #bet_match_total SET h1_goal_over_under = over_under, h1_goal_over_win = over_win, h1_goal_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '21'
	UPDATE #bet_match_total SET h2_goal_over_under = over_under, h2_goal_over_win = over_win, h2_goal_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '22'
	UPDATE #bet_match_total SET ft_goal_over_under = over_under, ft_goal_over_win = over_win, ft_goal_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '23'

	UPDATE #bet_match_total SET h1_goal_handicap = handicap, h1_goal_home_win = home_win, h1_goal_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '31'
	UPDATE #bet_match_total SET h2_goal_handicap = handicap, h2_goal_home_win = home_win, h2_goal_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '32'
	UPDATE #bet_match_total SET ft_goal_handicap = handicap, ft_goal_home_win = home_win, ft_goal_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '33'

	UPDATE #bet_match_total SET h1_euro_home = home_win, h1_euro_draw = draw_win, h1_euro_way = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '41'
	UPDATE #bet_match_total SET h2_euro_home = home_win, h2_euro_draw = draw_win, h2_euro_way = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '42'
	UPDATE #bet_match_total SET ft_euro_home = home_win, ft_euro_draw = draw_win, ft_euro_way = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '43'

	UPDATE #bet_match_total SET h1_card_over_under = over_under, h1_card_over_win = over_win, h1_card_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '51'
	UPDATE #bet_match_total SET h2_card_over_under = over_under, h2_card_over_win = over_win, h2_card_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '52'
	UPDATE #bet_match_total SET ft_card_over_under = over_under, ft_card_over_win = over_win, ft_card_under_win = under_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '53'

	UPDATE #bet_match_total SET h1_card_handicap = handicap, h1_card_home_win = home_win, h1_card_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '61'
	UPDATE #bet_match_total SET h2_card_handicap = handicap, h2_card_home_win = home_win, h2_card_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '62'
	UPDATE #bet_match_total SET ft_card_handicap = handicap, ft_card_home_win = home_win, ft_card_way_win = way_win FROM #bet_match_total a JOIN bet_match b ON a.match = b.match AND b.code = '63'

	DELETE a FROM bet_match_total a JOIN #bet_match_total b ON a.match = b.match
	INSERT INTO bet_match_total SELECT * FROM #bet_match_total a WHERE EXISTS (SELECT 1 FROM bet_match b WHERE a.match = b.match)
END
