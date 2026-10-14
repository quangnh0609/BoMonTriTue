DROP PROC IF EXISTS [dbo].[bet_esport_match_delete]
GO
CREATE PROC [dbo].[bet_esport_match_delete]
	@match_id NVARCHAR(50),
	@userID   INT
AS
BEGIN
	SET NOCOUNT ON

	IF NOT EXISTS (SELECT 1 FROM [dbo].[vsysuserinfo] WHERE id = @userID AND admin = 1)
		AND NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id AND created_by = @userID) BEGIN
		SELECT 0 AS isSuccess, N'Khong duoc phan quyen thuc hien chuc nang nay!' AS msg
		RETURN
	END

	IF NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id) BEGIN
		SELECT 0 AS isSuccess, N'Khong tim thay tran dau!' AS msg
		RETURN
	END

	IF EXISTS (SELECT 1 FROM [dbo].[bet_ticket_esport] WHERE match_id = @match_id) BEGIN
		SELECT 0 AS isSuccess, N'Da phat sinh ve cuoc Esports, khong the huy!' AS msg
		RETURN
	END

	DELETE FROM [dbo].[bet_esport_game]  WHERE match_id = @match_id
	DELETE FROM [dbo].[bet_esport_match] WHERE match_id = @match_id

	SELECT 1 AS isSuccess, N'Xoa tran Esports thanh cong!' AS msg
END
GO
