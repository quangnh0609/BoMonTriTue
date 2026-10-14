-- =============================================
-- SP lấy danh sách trận đấu Esports
-- Lọc theo đội, giải đấu, ngày, trạng thái
-- Tương tự bet_matches nhưng cho Esports
-- =============================================

DROP PROC IF EXISTS [dbo].[bet_esport_matches]
GO
CREATE PROC [dbo].[bet_esport_matches]
	@team    CHAR(16) = '',
	@season  CHAR(16) = '',
	@datefrom DATETIME = NULL,
	@dateto   DATETIME = NULL,
	@status  NVARCHAR(MAX) = '1, 2, 3, 4'
AS
BEGIN
	SELECT *
	FROM [dbo].[vbet_esport_match]
	WHERE (home = @team OR way = @team OR @team = '')
		AND (season = @season OR @season = '')
		AND (match_time >= CONVERT(DATE, @datefrom) OR @datefrom IS NULL)
		AND (match_time < DATEADD(DAY, 1, CONVERT(DATE, @dateto)) OR @dateto IS NULL)
		AND dbo.ff_Inlist(status, @status) = 1
	ORDER BY xKey, match_time DESC
END
GO
exec bet_esport_matches @team='                ',@season='                ',@datefrom=NULL,@dateto=NULL,@status=N'2'
