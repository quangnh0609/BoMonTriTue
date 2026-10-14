DROP PROC IF EXISTS [dbo].[bet_ticket_delete]
GO
CREATE PROC [dbo].[bet_ticket_delete]
	@match NVARCHAR(MAX),
	@user_id INT,
	@code NVARCHAR(MAX),
	@ticket NVARCHAR(MAX),
	@userID INT
AS
BEGIN
	declare @admin bit
	select @admin = admin from vsysuserinfo where id = @userID

	if @admin = 0 and dbo.[bet_check_right](@userID, 'bet_ticket_delete') = '0' begin
		select 0 as isSuccess, N'Không được phân quyền thực hiện chức năng này!' as msg
		return
	end

	if @match = '' or @code = '' begin
		select 0 as isSuccess, N'Không xóa dòng này' as msg
		return
	end

	if exists (select 1 from bet_ticket_esport where match_id = @match and code = @code and user_id = @user_id) begin
		if @admin = 0 and exists (select 1 from vbet_esport_match where match_id = @match and status <> 2)
			and not exists (select 1 from bet_esport_match where match_id = @match and created_by = @userID) begin
			select 0 as isSuccess, N'Trận Esports đã diễn ra, không thể xóa vé cược. Liên hệ nhà cái để xóa vé cược hộ!' as msg
			return
		end

		delete bet_ticket_esport where match_id = @match and code = @code and user_id = @user_id
		select 1 AS isSuccess, N'Xóa thành công!' as msg
		return
	end

	if @admin = 0 and exists (select 1 from bet_match where match = @match and code = @code and (result_home is not null or result_way is not null) ) begin
		select 0 as isSuccess, N'Đã vào kết quả, không xóa vé cược!' as msg
		return
	end

	if @admin = 0 and exists (select 1 from vbet_match_total where match = @match and status <> '2')
		and not exists (select 1 from bet_match_total where match = @match and user_host = @userID) begin
		select 0 as isSuccess, N'Trận đấu đã diễn ra, không thể xóa vé cược. Liên hệ nhà cái để xóa vé cược hộ!' as msg
		return
	end

	if @code <> '00'
		delete bet_ticket where match = @match and code = @code and ticket = @ticket and user_id = @user_id
	else 
		delete bet_payment where id = @match and user_id = @user_id
	
	select 1 AS isSuccess, N'Xóa thành công!' as msg
END
