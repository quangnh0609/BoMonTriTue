DROP PROC IF EXISTS [dbo].[bet_esport_match_save]
GO
CREATE PROC [dbo].[bet_esport_match_save]
	@match_id   NVARCHAR(50)  = NULL,
	@edit       BIT           = 0,
	@season     NVARCHAR(100),
	@home       NVARCHAR(200),
	@way        NVARCHAR(200),
	@match_time DATETIME,
	@userID     INT
AS
BEGIN
	SET NOCOUNT ON

	IF @edit = 1
		AND NOT EXISTS (SELECT 1 FROM [dbo].[vsysuserinfo] WHERE id = @userID AND admin = 1)
		AND NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id AND created_by = @userID) BEGIN
		SELECT 0 AS isSuccess, N'Khong duoc phan quyen thuc hien chuc nang nay!' AS msg, NULL AS match_id
		RETURN
	END

	IF ISNULL(@season, '') = '' BEGIN
		SELECT 0 AS isSuccess, N'Vui long chon giai dau!' AS msg, NULL AS match_id
		RETURN
	END
	IF ISNULL(@home, '') = '' BEGIN
		SELECT 0 AS isSuccess, N'Vui long chon doi 1!' AS msg, NULL AS match_id
		RETURN
	END
	IF ISNULL(@way, '') = '' BEGIN
		SELECT 0 AS isSuccess, N'Vui long chon doi 2!' AS msg, NULL AS match_id
		RETURN
	END
	IF @home = @way BEGIN
		SELECT 0 AS isSuccess, N'Doi 1 va Doi 2 khong duoc trung nhau!' AS msg, NULL AS match_id
		RETURN
	END

	IF @edit = 0 BEGIN
		IF EXISTS (
			SELECT 1 FROM [dbo].[bet_esport_match]
			WHERE season = @season AND home = @home AND way = @way
				AND CONVERT(VARCHAR(64), match_time, 120) = CONVERT(VARCHAR(64), @match_time, 120)
		) BEGIN
			SELECT 0 AS isSuccess, N'Da co tran dau Esports nay roi!' AS msg, NULL AS match_id
			RETURN
		END

		DECLARE @newId NVARCHAR(50)
		SELECT @newId = 'E' + CAST(
			ISNULL(MAX(TRY_CAST(SUBSTRING(match_id, 2, LEN(match_id)) AS INT)), 0) + 1
		AS NVARCHAR(20))
		FROM [dbo].[bet_esport_match]
		WHERE match_id LIKE 'E%'

		INSERT INTO [dbo].[bet_esport_match]
			(match_id, season, home, way, match_time, created_by, created_at)
		VALUES
			(@newId, @season, @home, @way, @match_time, @userID, GETDATE())

		SELECT 1 AS isSuccess, N'Tao tran Esports thanh cong!' AS msg, @newId AS match_id
	END
	ELSE BEGIN
		IF NOT EXISTS (SELECT 1 FROM [dbo].[bet_esport_match] WHERE match_id = @match_id) BEGIN
			SELECT 0 AS isSuccess, N'Khong tim thay tran dau!' AS msg, NULL AS match_id
			RETURN
		END

		UPDATE [dbo].[bet_esport_match]
		SET season     = @season,
			home       = @home,
			way        = @way,
			match_time = @match_time,
			updated_by = @userID,
			updated_at = GETDATE()
		WHERE match_id = @match_id

		SELECT 1 AS isSuccess, N'Cap nhat tran Esports thanh cong!' AS msg, @match_id AS match_id
	END
END
GO
