DROP PROC IF EXISTS [dbo].[bet_ticket_champion_code]
GO
CREATE PROC [dbo].[bet_ticket_champion_code]
	@UserID INT,
	@season NVARCHAR(MAX),
	@time DATETIME
AS
BEGIN
	CREATE TABLE #data (stt INT IDENTITY(1, 1), code NVARCHAR(MAX), code_name NVARCHAR(MAX), money INT, textColor NVARCHAR(MAX), rowColor NVARCHAR(MAX))

	INSERT INTO #data
		SELECT a.id, b.team_name + ' (' + dbo.ff_NumberFormat(a.rate_win, '### ### ###.#0') + ')', 0, '', ''
			FROM bet_champion a JOIN bet_team b ON a.team = b.team
			WHERE season = @season AND time = @time
			ORDER BY a.id
	
	UPDATE a SET money = b.money
		FROM #data a JOIN bet_ticket_champion b ON a.code = b.id AND b.user_id = @UserID

	-- format
	UPDATE #data SET rowColor = 'Lavender' WHERE stt % 2 = 0

	SELECT * FROM #data ORDER BY stt
END
GO
exec bet_ticket_champion_code @season=N'UCL-2025-2026',@time=N'2026-02-18',@userID=2