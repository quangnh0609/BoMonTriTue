DROP PROC IF EXISTS [dbo].[bet_ticket_champion_insert]
GO
CREATE PROC [dbo].[bet_ticket_champion_insert]
	@userID INT,
	@season NVARCHAR(MAX),
	@time DATETIME,
	@details XML
AS
BEGIN
	SELECT TOP 0 * INTO #bet_ticket_champion FROM bet_ticket_champion
	
	INSERT INTO #bet_ticket_champion
		SELECT a.Item.value('(code)[1]', 'NVARCHAR(MAX)'), @userID
				, a.Item.value('(money)[1]', 'DECIMAL(19)')
				, GETDATE() AS datetime, NULL AS clear
			FROM @details.nodes('/details/item') AS a(Item)

	DELETE a FROM bet_ticket_champion a JOIN #bet_ticket_champion b ON a.user_id = b.user_id AND a.id = b.id
	INSERT INTO bet_ticket_champion SELECT * FROM #bet_ticket_champion

	SELECT 1 AS isSuccess, N'Vào cược thành công!' AS msg
END
GO