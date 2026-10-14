# BoMonTriTue Code Map

## Authentication

login.aspx -> dbo.bet_login -> dbo.userinfo2 (App DB).
Global.asax -> App_Code/AuthSession.cs -> dbo.userinfo2.
settings.aspx -> dbo.bet_setting -> dbo.userinfo2.
ucChangePass.ascx -> dbo.bet_ucChangePass -> dbo.userinfo2.
Các page/control kiểm tra admin hoặc danh sách người dùng truy vấn trực tiếp dbo.userinfo2.

vsysuserinfo và database TAPHOA_FBOHRMSP229_Sys đã được xóa sau cleanup. Tất cả luồng tài khoản của repo dùng dbo.userinfo2 trong App.

## Database scope

Xem Scripts/Audit/README.md và Keep-objects.csv. Giữ bet_host theo yêu cầu; bet_team2, bet_ticket2, bet_ticket_result2 ngoài phạm vi xuất.
Migration chuyển userinfo2 và module SQL: Scripts/Migrations/20261014_LocalUsers/.
Các script Scripts/App, Core, System là lịch sử; không chạy cả bộ để tạo lại trạng thái hiện tại.

Cleanup đã chạy: Scripts/Migrations/20261014_Cleanup/. Inventory hiện tại: 14 table, 4 view, 29 stored procedure, 3 function, 1 trigger, cùng index/constraint.


Database hiện tại: BoMonTriTue trên QUANGNH\SQL2019; đã đổi tên từ DB App ngày 2026-10-14. Script trong Scripts/Migrations/20261014_RenameDatabase/.
