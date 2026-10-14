# Database scope sau cleanup — 2026-10-14

Server QUANGNH\SQL2019. Database duy nhất ứng dụng cần: BoMonTriTue.

## Giữ lại

14 bảng: bet_champion, bet_code, bet_esport_game, bet_esport_match, bet_host, bet_match, bet_match_total, bet_payment, bet_season, bet_team, bet_ticket, bet_ticket_champion, bet_ticket_esport, userinfo2.

4 view: vbet_esport_match, vbet_match_total, vbet_match_total_for_web, vbet_payment.

29 stored procedure, 3 function, trigger bet_match_total_insert và các constraint/index đi kèm: xem Keep-objects.csv. CSV đã bỏ vsysuserinfo, không còn đối tượng Sys.

## Đã xóa theo xác nhận

Toàn bộ object ngoài danh sách cần giữ trong App, bao gồm bet_team2, bet_ticket2, bet_ticket_result2 và vsysuserinfo. Database TAPHOA_FBOHRMSP229_Sys cũng đã xóa. Tài khoản vẫn ở App.dbo.userinfo2, không cần Sys.

Objects-outside-scope.csv là bản audit lịch sử trước cleanup, không đại diện inventory hiện tại. Danh sách xóa chính xác và kiểm chứng trước/sau nằm trong ../Migrations/20261014_Cleanup/.

## Kiểm chứng

Backup App/Sys qua RESTORE VERIFYONLY. Dọn App trong transaction; kiểm tra đúng 71 object còn lại và số dòng của 14 bảng không đổi trước commit. View nghiệp vụ và function quyền đọc được; WebForms biên dịch thành công. Chưa kiểm thử đầy đủ qua trình duyệt.

Scripts/App, Core, System là lịch sử. Muốn xuất cấu trúc hiện tại, lấy trực tiếp từ DB App sau cleanup, giữ cả identity, collation, index và constraint.
