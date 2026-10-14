DROP PROC IF EXISTS [dbo].[bet_setting]
GO
CREATE PROC [dbo].[bet_setting]
	@username NVARCHAR(MAX)
AS
BEGIN
	DECLARE @q NVARCHAR(MAX), @Key NVARCHAR(MAX)

	SET @Key = 'user_yn = ''1'''
	IF EXISTS (SELECT 1 FROM vsysuserinfo WHERE name = @username AND admin = 0)
		SET @Key = @Key + CASE WHEN @Key = '' THEN '' ELSE ' and ' END + 'name = ''' + @username + ''''

	SET @q = 'select * from vsysuserinfo where ' + @Key
	EXEC sp_executesql @q
END
GO
exec bet_setting @username=N'ADMIN'