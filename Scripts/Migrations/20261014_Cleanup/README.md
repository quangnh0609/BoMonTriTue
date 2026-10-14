# Cleanup hoàn tất — 2026-10-14

Server QUANGNH\SQL2019, database TAPHOA_FBOHRMSP229_App.

Người dùng xác nhận xóa các đối tượng ngoài phạm vi repo, kể cả thành phần ERP và database TAPHOA_FBOHRMSP229_Sys, sau khi đã được thông báo phạm vi 12.676 bảng dư.

## Kết quả

- Giữ 14 bảng, 4 view, 29 stored procedure, 3 scalar function, 1 trigger và constraint/index đi kèm (71 object trong sys.objects).
- Giữ bet_host, userinfo2 và toàn bộ dữ liệu trong 14 bảng. Số dòng trước/sau bằng nhau; view nghiệp vụ và function kiểm tra quyền được truy vấn thử trước commit.
- Đã xóa các object ngoài danh sách, gồm bet_team2, bet_ticket2, bet_ticket_result2 và view tương thích vsysuserinfo.
- Đã xóa database TAPHOA_FBOHRMSP229_Sys sau khi bước dọn App commit thành công.
- App.bak và Sys.bak trong Databases/ đã qua RESTORE VERIFYONLY trước khi thực hiện và vẫn được giữ nguyên.

## File kiểm chứng

- Removed-objects.csv: danh sách object đã xóa, bao gồm constraint biến mất cùng bảng.
- Preserved-system-constraints.csv: hai constraint của bảng metadata hệ thống dtproperties, giữ nguyên và không tính vào 71 object nghiệp vụ.
- Retained-identities.json: ID và loại của 71 object còn lại.
- Before-table-counts.csv, After-table-counts.csv: số dòng của 14 bảng trước/sau.
- 02_RemoveUnusedAppObjects.sql, 03_DropSysDatabase.sql: script đã thực thi có kiểm soát; không chạy lại.
- Before-removed-module-definitions.sql.txt: định nghĩa module trước khi xóa; không phải bộ backup dữ liệu.

## Giới hạn

Chưa kiểm thử toàn bộ nghiệp vụ qua trình duyệt. Filegroup/file vật lý và dung lượng trống DB App chưa thu gọn; việc xóa object không tự làm nhỏ MDF/NDF. Không thay đổi database khác ngoài App và Sys đã nêu. Script lịch sử trong Scripts/App, Core, System có thể nhắc đối tượng đã xóa; không chạy nguyên bộ để khởi tạo lại DB hiện tại.

Hai backup có trước migration chuyển userinfo2 sang App. Phục hồi trạng thái trước cleanup cần xem xét cả backup và migration 20261014_LocalUsers. Không chạy lại migration chuyển tài khoản trên DB hiện tại.
