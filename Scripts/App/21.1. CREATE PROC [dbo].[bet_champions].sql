DROP PROC IF EXISTS [dbo].[bet_champions]
GO
CREATE PROC [dbo].[bet_champions]
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
			LEFT JOIN vsysuserinfo u ON a.user_host = u.id
		WHERE (a.team = @team OR @team = '')
			AND (a.season = @season OR @season = '')
			AND (a.time >= @datefrom OR @datefrom  IS NULL)
			AND (a.time <= @dateto OR @dateto IS NULL)
		ORDER BY x.status, a.time DESC, a.time_lock, a.season, a.id
END
GO
exec [bet_champions] @team=N'',@season=N'',@datefrom=NULL,@dateto=NULL

