# Rà soát hiệu năng esport — 14/10/2026

## Kết luận

Điểm nghẽn được xác nhận nằm ở truy vấn danh sách `dbo.bet_esport_matches`, đặc biệt các truy vấn tương quan trên `dbo.bet_ticket_esport` trong `dbo.vbet_esport_match`. Kế hoạch thực thi thực tế được lưu trong `esport-list-before.sqlplan` cùng thư mục.

Đợt kiểm tra chỉ đọc database và mã nguồn, không thay đổi schema hoặc nghiệp vụ. Không đo được thời gian toàn trang qua trình duyệt: chưa xác định URL ứng dụng, và công cụ đọc cấu hình IIS báo thiếu quyền. Các số bên dưới là thời gian gọi SQL và đọc toàn bộ kết quả bằng SqlDataAdapter, không phải thời gian render trang.

## Dữ liệu và phép đo

Database đang cấu hình trong web.config: BoMonTriTue. Số dòng: 14.425 match, 549 esport match, 2.210 esport game, 27.829 esport ticket.

Hai thủ tục danh sách dùng cùng bộ lọc trạng thái `1, 2, 3, 4`, các bộ lọc khác để mặc định, chạy 6 lần liên tiếp mỗi thủ tục trên cùng connection. Không xóa cache hoặc cập nhật statistics. Các phép đo phụ chạy sau danh sách và có thể chịu ảnh hưởng tải server/cache; chưa đủ mẫu để suy ra percentile.

| Truy vấn | Số dòng trả về | Thời gian ms |
| --- | ---: | --- |
| bet_matches, 6 lần | 34 | 1671,4; 1551,8; 1541,0; 1610,5; 1590,6; 1550,8 |
| bet_esport_matches, 6 lần | 8 | 6484,6; 15345,5; 6079,1; 5896,8; 6197,5; 6516,1 |
| Lấy game của trận mới nhất | 6 | 8,7 |
| SELECT DISTINCT code theo trận mới nhất | 1 | 4,0 |
| Lấy thông tin sửa trận qua vbet_esport_match | 1 | 726,1 |
| Danh sách esport của bootstrap admin qua view | 549 | 864,3 |
| Danh sách cùng thông tin tên/đội/thời gian qua bảng và join trực tiếp | 549 | 79,9 |
| bet_ticket_esport_code, trận mới nhất có vé | 144 | 279,3 |
| bet_ticket_result, toàn bộ người chơi của trận đó | 2 | 925,3 |

Median danh sách: match 1571,2 ms; esport 6341,1 ms, khoảng 4 lần. Một lần esport tăng tới 15,3 giây; chưa xác định nguyên nhân riêng của biến động đó.

## Bằng chứng từ kế hoạch thực thi thực tế

Hai Clustered Index Scan trên bet_ticket_esport:

| Nhánh scan | Actual executions | Actual rows read | Actual logical reads | Actual elapsed ms |
| --- | ---: | ---: | ---: | ---: |
| 1 | 549 | 15.278.121 | 208.071 | 2975 |
| 2 | 549 | 15.150.399 | 206.351 | 2917 |

Tổng cộng hơn 30 triệu dòng được đọc để trả 8 trận. Primary key hiện tại của bet_ticket_esport là `(user_id, match_id, code)`; không có index bắt đầu bằng match_id. Các nhánh tìm vé theo match_id phải scan thay vì seek hiệu quả.

bet_esport_game đã có unique index `(match_id, game_no)`, phù hợp với truy vấn lấy game. Không có bằng chứng cần thêm index tương tự trên bảng game.

Thủ tục bet_esport_matches đang chạy trong DB có `SELECT TOP 10`, khác script lịch sử trong Scripts/App vốn không có TOP. ROW_NUMBER của view xếp toàn bộ tập trận theo trạng thái và khoảng cách thời gian; actual plan cho thấy 549 trận vẫn được xử lý ở các nhánh scan. Không chạy lại script lịch sử để sửa hiệu năng.

## Phạm vi màn hình

1. **Danh sách esport / lọc:** `esports.aspx/FilterMatchHeaders` gọi thủ tục chậm trên. Sau đó IntersectionObserver gọi `GetMatchGames` riêng cho từng trận gần vùng nhìn thấy: 1 request danh sách + N request chi tiết. Không phải tất cả trận đều tải ngay. Match dùng một request FilterMatches. Các request bổ sung tăng độ trễ mạng nhưng phép đo SQL cho thấy danh sách là ưu tiên đầu tiên.
2. **Sửa / sao chép trận:** GetMatchData lấy `SELECT * FROM vbet_esport_match WHERE match_id=@match` rồi lấy game. View chứa việc tính trạng thái/xếp hạng mà form chủ yếu cần thông tin trận và kèo. Cân nhắc đọc trực tiếp bảng với join tên đội/giải, sau khi kiểm tra đủ các trường form cần.
3. **Mở kết quả:** GetResultData đọc thông tin trận trực tiếp, lấy distinct code theo trận, rồi lấy game (3 lượt SQL tuần tự). Nhánh code cũng hưởng lợi từ index match_id. Không đo toàn bộ endpoint hoặc thao tác lưu kết quả vì chúng cần phiên đăng nhập / có ghi dữ liệu.
4. **Mở popup vào cược:** GetTicketBootstrap tải cả match và esport theo tuần tự trước khi phía client tiếp tục. Danh sách esport dùng view và `ORDER BY match_time DESC, xKey`. Trường hợp admin có thể đọc trực tiếp bảng/join để tránh tính trạng thái; điều kiện status=2 cho người thường tương ứng trận chưa tới giờ, cần giữ nguyên quy tắc phân quyền và thứ tự trước khi thay.
5. **Màn hình tickets:** LoadMatches tải toàn bộ danh sách match và esport vào dropdown, không phân trang. Phần esport chỉ dùng tên, đội, giờ, giải và không cần status/xKey. Optimizer có thể loại bỏ biểu thức view không dùng; cần đo actual plan của truy vấn UNION trước khi kết luận phần này chịu cùng chi phí như danh sách esport.
6. **Vé cược theo trận:** ucTicketMatch dùng GetTicketList -> bet_ticket_result cho cả match và esport. Phép đo cho một trận có vé là 925,3 ms; cần thêm mẫu trận nhiều vé trước khi đánh giá toàn diện. bet_ticket_esport_code lấy 144 mã kèo trong 279,3 ms ở một mẫu.

## Thứ tự tối ưu đề xuất

1. Thêm nonclustered index `bet_ticket_esport(match_id, code) INCLUDE(clear)` để phục vụ kiểm tra trạng thái, distinct code và lấy vé theo trận. File SQL đề xuất đi kèm chưa được chạy. Kiểm tra dung lượng, tải ghi và index trùng trước khi triển khai; đo lại actual rows read/logical reads và 6 lần danh sách sau khi thêm.
2. Nếu còn chậm, tổng hợp trạng thái vé/game theo match một lần, tránh lặp parsing code và tính EXISTS. Giữ nguyên các trạng thái 1–5 và quy tắc kết quả; so sánh kết quả trước/sau trên toàn bộ trận, bao gồm BO x/game 6.
3. Giảm request kèo bằng endpoint theo lô các trận đang hiển thị. Chỉ trả các trường gameDetailHtml sử dụng, giữ lazy loading. Không chuyển sang tải toàn bộ game của mọi trận chỉ để giảm request.
4. Tách truy vấn thông tin form/bootstrap khỏi view trạng thái khi không cần; kiểm chứng phân quyền admin/chủ trận/người thường và thứ tự danh sách.
5. Đo Network timing thực tế cho danh sách, kèo, sửa, kết quả và vé trên cùng thiết bị/mạng. Tách TTFB, tải payload và render DOM; so sánh lần đầu/lần lặp, bộ lọc rộng/hẹp, trận nhiều/ít vé.

Không đưa ra cam kết thời gian sau tối ưu vì chưa triển khai hoặc benchmark phiên bản thay đổi.

## Cập nhật sau khi thêm index theo xác nhận của người dùng

Đã chạy script index đề xuất trên database được cấu hình. Đo lại 6 lần cùng bộ lọc, mỗi lần trả 8 trận: 470,2; 335,1; 322,4; 268,1; 234,0; 316,9 ms. Trung vị 319,65 ms, giảm khoảng 95% so với 6341,05 ms trước đó (nhanh hơn khoảng 20 lần trong phép đo này).

Actual plan sau thay đổi lưu tại `esport-list-after.sqlplan`. Hai nhánh truy cập bảng vé chuyển sang Index Seek: nhánh 1 thực thi 1362 lần, đọc 67.448 dòng và 3081 logical reads; nhánh 2 thực thi 549 lần, đọc 27.208 dòng và 1239 logical reads. Tổng dòng đọc giảm từ 30.428.520 xuống 94.656; logical reads giảm từ 414.422 xuống 4320. Không thay đổi dữ liệu vé hoặc logic trạng thái. Chưa kiểm chứng thời gian toàn trang qua trình duyệt.
