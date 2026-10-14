DROP PROC IF EXISTS [dbo].[bet_ucChangePass]
GO
CREATE PROC [dbo].[bet_ucChangePass]
	@currentUser NVARCHAR(MAX),
	@currentPass NVARCHAR(MAX),
	@targetUser NVARCHAR(MAX),
	@newPass NVARCHAR(MAX)
AS
BEGIN
	DECLARE @q NVARCHAR(MAX), @Key NVARCHAR(MAX)

	-- Kiểm tra pass user thực hiện
	IF NOT EXISTS (SELECT 1 FROM vsysuserinfo WHERE name = @currentUser AND substring(keys, 3, 1) + substring(password, 2, len(password) - 2)  + substring(keys, 2, 1) = @currentPass) BEGIN
		SELECT 0 as success, N'Mật khẩu hiện tại không chính xác' AS msg
		RETURN
	END ELSE BEGIN
		UPDATE vsysuserinfo SET password = @newPass, keys = left(keys, 1) + right(@newPass, 1) + left(@newPass, 1) + right(keys, 3) WHERE name = @targetUser
		SELECT 1 as success, N'Cập nhật mật khẩu thành công' AS msg
		RETURN
	END
END