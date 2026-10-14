DROP PROC IF EXISTS [dbo].[bet_ticket_match]
GO
CREATE PROC [dbo].[bet_ticket_match]
	@userID INT
AS
BEGIN
	DECLARE @admin BIT
	
	SELECT @admin = admin FROM vsysuserinfo WHERE id = @userID
	
	IF @admin = 1
		SELECT * FROM vbet_match_total ORDER BY time DESC, xKey
	ELSE 
		SELECT * FROM vbet_match_total WHERE status = '2' OR user_host = @userID ORDER BY time DESC, xKey
END
GO
exec [bet_ticket_match] 2
