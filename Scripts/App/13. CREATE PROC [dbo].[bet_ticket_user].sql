DROP PROC IF EXISTS [dbo].[bet_ticket_user]
GO
CREATE PROC [dbo].[bet_ticket_user]
	@userID INT
AS
BEGIN
	DECLARE @admin BIT
	SELECT @admin = admin FROM vsysuserinfo WHERE id = @userID
	
	IF @admin = 1
		OR EXISTS (SELECT 1 FROM bet_match_total WHERE user_host = @userID)
		OR EXISTS (SELECT 1 FROM bet_esport_match WHERE created_by = @userID)
		SELECT * FROM vsysuserinfo WHERE user_yn = 1 ORDER BY name
	ELSE 
		SELECT * FROM vsysuserinfo WHERE id = @userID ORDER BY name
END
