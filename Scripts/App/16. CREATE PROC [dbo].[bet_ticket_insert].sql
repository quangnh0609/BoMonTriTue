DROP PROC IF EXISTS [dbo].[bet_ticket_insert]
GO
CREATE PROC [dbo].[bet_ticket_insert]
	@user_id INT,
	@match NVARCHAR(MAX),
	@details XML,
	@userID INT
AS
BEGIN
	SELECT TOP 0 * INTO #bet_ticket FROM bet_ticket
	
	DECLARE @host INT, @admin BIT
	SELECT @host = user_host FROM bet_match_total WHERE match = @match
	SELECT @admin = admin FROM vsysuserinfo WHERE id = @userID
	
	IF @admin = 0 AND (@host IS NULL OR @userID <> @host) AND EXISTS (SELECT 1 FROM vbet_match_total WHERE match = @match AND status <> '2') BEGIN
		SELECT 0 AS isSuccess, N'Trận đấu đã diễn ra, không thể vào cược. Liên hệ nhà cái để vào cược hộ!' AS msg
		RETURN
	END

	INSERT INTO #bet_ticket 
		SELECT @user_id, @match, LEFT(a.Item.value('(code)[1]', 'NVARCHAR(MAX)'), 2) AS code
				, RIGHT(a.Item.value('(code)[1]', 'NVARCHAR(MAX)'), 1) AS ticket
				, a.Item.value('(money)[1]', 'DECIMAL(19)') AS money
				, GETDATE() AS datetime, NULL AS clear
			FROM @details.nodes('/details/item') AS a(Item)

	DELETE a FROM bet_ticket a JOIN #bet_ticket b ON a.user_id = b.user_id AND a.match = b.match
	INSERT INTO bet_ticket SELECT * FROM #bet_ticket

	SELECT 1 AS isSuccess, N'Vào cược thành công!' AS msg
END
