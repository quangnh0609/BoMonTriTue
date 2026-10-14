USE [TAPHOA_FBOHRMSP229_App]
GO
/****** Object:  StoredProcedure [dbo].[bet_print]    Script Date: 24/05/2026 09:45:03 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[bet_print]
AS
BEGIN
	select match, season_name as season
		, isnull(b.team_name, a.home) + '<br />' + 'vs' + '<br />' + isnull(c.team_name, a.way) as name
		, isnull(b.team_name, a.home) as home, isnull(c.team_name, a.way) as way
		, a.host_name
		--, a.name
		, convert(varchar(5), time, 108) + '  ' + convert(varchar(10), time, 105) as time 
		, a.xKey
		, h1_conner_over_under, h2_conner_over_under, ft_conner_over_under
		, h1_conner_handicap, h2_conner_handicap, ft_conner_handicap
		, h1_goal_over_under, h2_goal_over_under, ft_goal_over_under
		, h1_goal_handicap, h2_goal_handicap, ft_goal_handicap
		, h1_euro_home, h2_euro_home, ft_euro_home
		, h1_euro_draw, h2_euro_draw, ft_euro_draw
		, h1_euro_way, h2_euro_way, ft_euro_way
		, ''
		  + case when h1_conner_over_under <> '___' or h2_conner_over_under <> '___' or ft_conner_over_under <> '___' then '<br />' + N'Tài góc' else '' end
		  + case when h1_conner_handicap <> '___' or h2_conner_handicap <> '___' or ft_conner_handicap <> '___' then '<br />' + N'Góc (chủ nhà)' else '' end 
		  
		  + case when h1_goal_over_under <> '___' or h2_goal_over_under <> '___' or ft_goal_over_under <> '___' then '<br />' + N'Tài bàn' else '' end 
		  + case when h1_goal_handicap <> '___' or h2_goal_handicap <> '___' or ft_goal_handicap <> '___' then '<br />' + N'Bàn (chủ nhà)' else '' end 
		  
		  + case when h1_card_over_under <> '___' or h2_card_over_under <> '___' or ft_card_over_under <> '___' then '<br />' + N'Tài thẻ' else '' end
		  + case when h1_card_handicap <> '___' or h2_card_handicap <> '___' or ft_card_handicap <> '___' then '<br />' + N'Thẻ (chủ nhà)' else '' end 
		  
		  + case when h1_euro_home <> '___' or h2_euro_home <> '___' or ft_euro_home <> '___' then '<br />' + b.team_name else '' end 
		  + case when h1_euro_draw <> '___' or h2_euro_draw <> '___' or ft_euro_draw <> '___' then '<br />' +  N'Hòa' else '' end 
		  + case when h1_euro_way <> '___' or h2_euro_way <> '___' or ft_euro_way <> '___' then '<br />' + c.team_name else '' end as col_label
		
		, case when h1_conner_over_under <> '___' or h1_conner_handicap <> '___' or h1_goal_over_under <> '___' or h1_goal_handicap <> '___' or h1_card_over_under <> '___' or h1_card_handicap <> '___' or h1_euro_home <> '___' or h1_euro_draw <> '___' or h1_euro_way <> '___' then N'Hiệp 1' else '' end
		  
		  + case when h1_conner_over_under <> '___' or h2_conner_over_under <> '___' or ft_conner_over_under <> '___' then '<br />' + h1_conner_over_under else '' end
		  + case when h1_conner_handicap <> '___' or h2_conner_handicap <> '___' or ft_conner_handicap <> '___' then '<br />' + h1_conner_handicap else '' end 
		  
		  + case when h1_goal_over_under <> '___' or h2_goal_over_under <> '___' or ft_goal_over_under <> '___' then '<br />' + h1_goal_over_under else '' end 
		  + case when h1_goal_handicap <> '___' or h2_goal_handicap <> '___' or ft_goal_handicap <> '___' then '<br />' + h1_goal_handicap else '' end 
		  
		  + case when h1_card_over_under <> '___' or h2_card_over_under <> '___' or ft_card_over_under <> '___' then '<br />' + h1_card_over_under else '' end
		  + case when h1_card_handicap <> '___' or h2_card_handicap <> '___' or ft_card_handicap <> '___' then '<br />' + h1_card_handicap else '' end 
		  
		  + case when h1_euro_home <> '___' or h2_euro_home <> '___' or ft_euro_home <> '___' then '<br />' + h1_euro_home else '' end 
		  + case when h1_euro_draw <> '___' or h2_euro_draw <> '___' or ft_euro_draw <> '___' then '<br />' +  h1_euro_draw else '' end 
		  + case when h1_euro_way <> '___' or h2_euro_way <> '___' or ft_euro_way <> '___' then '<br />' + h1_euro_way else '' end as col_h1
		
		, case when h2_conner_over_under <> '___' or h2_conner_handicap <> '___' or h2_goal_over_under <> '___' or h2_goal_handicap <> '___' or h2_card_over_under <> '___' or h2_card_handicap <> '___' or h2_euro_home <> '___' or h2_euro_draw <> '___' or h2_euro_way <> '___' then N'Hiệp 2' else '' end
		  
		  + case when h1_conner_over_under <> '___' or h2_conner_over_under <> '___' or ft_conner_over_under <> '___' then '<br />' + h2_conner_over_under else '' end
		  + case when h1_conner_handicap <> '___' or h2_conner_handicap <> '___' or ft_conner_handicap <> '___' then '<br />' + h2_conner_handicap else '' end 
		  
		  + case when h1_goal_over_under <> '___' or h2_goal_over_under <> '___' or ft_goal_over_under <> '___' then '<br />' + h2_goal_over_under else '' end 
		  + case when h1_goal_handicap <> '___' or h2_goal_handicap <> '___' or ft_goal_handicap <> '___' then '<br />' + h2_goal_handicap else '' end 
		  
		  + case when h1_card_over_under <> '___' or h2_card_over_under <> '___' or ft_card_over_under <> '___' then '<br />' + h2_card_over_under else '' end
		  + case when h1_card_handicap <> '___' or h2_card_handicap <> '___' or ft_card_handicap <> '___' then '<br />' + h2_card_handicap else '' end 
		  
		  + case when h1_euro_home <> '___' or h2_euro_home <> '___' or ft_euro_home <> '___' then '<br />' + h2_euro_home else '' end 
		  + case when h1_euro_draw <> '___' or h2_euro_draw <> '___' or ft_euro_draw <> '___' then '<br />' +  h2_euro_draw else '' end 
		  + case when h1_euro_way <> '___' or h2_euro_way <> '___' or ft_euro_way <> '___' then '<br />' + h2_euro_way else '' end as col_h2
		
		, case when ft_conner_over_under <> '___' or ft_conner_handicap <> '___' or ft_goal_over_under <> '___' or ft_goal_handicap <> '___' or ft_card_over_under <> '___' or ft_card_handicap <> '___' or ft_euro_home <> '___' or ft_euro_draw <> '___' or ft_euro_way <> '___' then N'Cả trận' else '' end
		  
		  + case when h1_conner_over_under <> '___' or h2_conner_over_under <> '___' or ft_conner_over_under <> '___' then '<br />' + ft_conner_over_under else '' end
		  + case when h1_conner_handicap <> '___' or h2_conner_handicap <> '___' or ft_conner_handicap <> '___' then '<br />' + ft_conner_handicap else '' end 
		  
		  + case when h1_goal_over_under <> '___' or h2_goal_over_under <> '___' or ft_goal_over_under <> '___' then '<br />' + ft_goal_over_under else '' end 
		  + case when h1_goal_handicap <> '___' or h2_goal_handicap <> '___' or ft_goal_handicap <> '___' then '<br />' + ft_goal_handicap else '' end 
		  
		  + case when h1_card_over_under <> '___' or h2_card_over_under <> '___' or ft_card_over_under <> '___' then '<br />' + ft_card_over_under else '' end
		  + case when h1_card_handicap <> '___' or h2_card_handicap <> '___' or ft_card_handicap <> '___' then '<br />' + ft_card_handicap else '' end 
		  
		  + case when h1_euro_home <> '___' or h2_euro_home <> '___' or ft_euro_home <> '___' then '<br />' + ft_euro_home else '' end 
		  + case when h1_euro_draw <> '___' or h2_euro_draw <> '___' or ft_euro_draw <> '___' then '<br />' +  ft_euro_draw else '' end 
		  + case when h1_euro_way <> '___' or h2_euro_way <> '___' or ft_euro_way <> '___' then '<br />' + ft_euro_way else '' end as col_ft
	into #bet_print
	from vbet_match_total a 
		left join bet_team b on a.home = b.team
		left join bet_team c on a.way = c.team
		left join bet_season d on a.season = d.season
	where status = '2'
	
	select * 
		from #bet_print a
		order by a.xKey, a.time desc
END
GO
EXEC bet_print
