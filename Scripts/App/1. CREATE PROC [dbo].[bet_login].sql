DROP PROC IF EXISTS [dbo].[bet_login]
GO
CREATE PROC [dbo].[bet_login]
	@username NVARCHAR(MAX),
	@password NVARCHAR(MAX)
AS
BEGIN
	SELECT * FROM vsysuserinfo WHERE name = @username AND substring(keys, 3, 1) + substring(password, 2, len(password) - 2) + substring(keys, 2, 1) = @password
	IF EXISTS (SELECT 1 FROM vsysuserinfo WHERE name = @username AND substring(keys, 3, 1) + substring(password, 2, len(password) - 2) + substring(keys, 2, 1) = @password)
		UPDATE TAPHOA_FBOHRMSP229_Sys..userinfo2 SET s9 = GETDATE() WHERE name = @username
END