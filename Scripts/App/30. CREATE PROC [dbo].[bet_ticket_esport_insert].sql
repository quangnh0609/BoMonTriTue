DROP PROC IF EXISTS [dbo].[bet_ticket_esport_insert]
GO

CREATE PROC [dbo].[bet_ticket_esport_insert]
    @user_id INT,
    @match NVARCHAR(50),
    @details XML,
    @userID INT
AS
BEGIN
    DECLARE @host INT, @admin BIT
    SELECT @host = created_by FROM bet_esport_match WHERE match_id = @match
    SELECT @admin = admin FROM vsysuserinfo WHERE id = @userID

    IF @admin = 0 AND (@host IS NULL OR @userID <> @host) AND EXISTS (
        SELECT 1 FROM vbet_esport_match WHERE match_id = @match AND status <> 2
    ) BEGIN
        SELECT 0 AS isSuccess, N'Trận Esports đã diễn ra, không thể vào cược. Liên hệ nhà cái để vào cược hộ!' AS msg
        RETURN
    END

    CREATE TABLE #ticket (
        user_id INT,
        match_id NVARCHAR(50),
        code NVARCHAR(64),
        money NUMERIC(19,0),
        [datetime] DATETIME,
        clear BIT
    )

    INSERT INTO #ticket
        SELECT @user_id,
               @match,
               a.Item.value('(code)[1]', 'NVARCHAR(64)'),
               a.Item.value('(money)[1]', 'NUMERIC(19,0)'),
               GETDATE(),
               NULL
        FROM @details.nodes('/details/item') AS a(Item)

    DELETE a
        FROM bet_ticket_esport a
        JOIN #ticket b ON b.user_id = a.user_id AND b.match_id = a.match_id

    INSERT INTO bet_ticket_esport (user_id, match_id, code, money, [datetime], clear)
        SELECT user_id, match_id, code, money, [datetime], clear
        FROM #ticket

    SELECT 1 AS isSuccess, N'Vào cược Esports thành công!' AS msg
END
GO
