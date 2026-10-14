DROP PROC IF EXISTS [dbo].[bet_champion_result]
GO
CREATE PROC [dbo].[bet_champion_result]
	@season nvarchar(max),
	@time datetime,
	@details xml,
	@userID int
AS
BEGIN
	SELECT LEFT(a.Item.value('(id)[1]', 'INT'), 16) AS id
		, a.Item.value('(result_win)[1]', 'BIT') AS result_win
		, a.Item.value('(result_lost)[1]', 'BIT') AS result_lost
		INTO #bet_champion
		FROM @details.nodes('/details/item') AS a(Item)
	
	if dbo.[bet_check_right](@userID, 'bet_champion_result') = '0' begin
		select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
		return
	end
	
	if not exists (select 1 from #bet_champion) begin
		select 0 as isSuccess, N'Cập nhật kết quả không thành công!' as msg
	end else begin
		update a set result_win = CASE WHEN b.result_win = 1 THEN 1 WHEN b.result_lost = 1 THEN 0 ELSE NULL END FROM bet_champion a join #bet_champion b on a.id = b.id
		select 1 as isSuccess, N'Cập nhật kết quả thành công!' as msg
	end
END
GO
exec sp_executesql N'exec bet_champion_result @season, @time, @details, @userID',N'@season nvarchar(13),@time datetime,@details nvarchar(229),@userID nvarchar(1)',@season=N'EPL-2025-2026',@time='2026-02-18 00:00:00',@details=N'<details>
  <item>
    <id>22</id>
    <result_win>1</result_win>
    <result_lost>0</result_lost>
  </item>
  <item>
    <id>23</id>
    <result_win>0</result_win>
    <result_lost>1</result_lost>
  </item>
</details>',@userID=N'2'