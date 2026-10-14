DROP PROC IF EXISTS [dbo].[bet_matches]
GO
CREATE PROC [dbo].[bet_matches]
	@team NVARCHAR(MAX) = '',
	@season NVARCHAR(MAX) = '',
	@datefrom DATETIME = NULL,
	@dateto DATETIME = NULL,
	@status NVARCHAR(MAX) = '1, 2, 3, 4, 5'
AS
BEGIN
	SELECT * 
		INTO #vbet_match_total
		FROM vbet_match_total 
		WHERE (home = @team OR way = @team or @team = '')
			AND (season = @season or @season = '')
			AND (CONVERT(CHAR(8), time, 112) >= @datefrom OR @datefrom IS NULL)
			AND (CONVERT(CHAR(8), time, 112) <= @dateto OR @dateto IS NULL)
			AND dbo.ff_Inlist(status, @status) = 1
		ORDER BY xKey, time desc
END
GO
exec bet_matches @team=N'',@season=N'',@datefrom=NULL,@dateto=NULL,@status=N'1,2,3,4'

