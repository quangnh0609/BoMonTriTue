DROP PROC IF EXISTS [dbo].[bet_match_delete]
GO
CREATE PROC [dbo].[bet_match_delete]
	@match nvarchar(4000),
	@userID int
AS
BEGIN
	if not exists (select 1 from vsysuserinfo where id = @userID and admin = 1)
		and not exists (select 1 from bet_match_total where match = @match and user_host = @userID) begin
		select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
		return
	end
	
	if exists (select 1 from bet_ticket a where a.match = @match) begin
		select 0 as isSuccess, N'Đã phát sinh vé cược, không thể hủy!' as msg
		return
	end
	
	delete a from bet_match a where a.match = @match
	select 1 as isSuccess, N'Hủy trận thành công!' as msg
END
