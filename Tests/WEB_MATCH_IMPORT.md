# Lấy từ web — The Odds API v4

## Chọn nguồn API

Bấm Lấy từ web để chọn The Odds API hoặc API-Football trước khi lọc ngày/giải. The Odds API giữ cơ chế cũ. Mỗi nguồn có key, cache và hạn mức riêng; đổi nguồn xóa danh sách/lựa chọn, backend kiểm tra nguồn khớp snapshot.

API-Football: thêm `<add key="ApiFootballKey" value="YOUR_API_FOOTBALL_KEY" />` vào appSettings trong web.config trên máy chủ. Dùng key trực tiếp từ https://dashboard.api-football.com/ (header x-apisports-key, base URL https://v3.football.api-sports.io/), không dùng key RapidAPI. Không cần migration DB mới cho thay đổi này; vẫn cần áp dụng các migration có sẵn của hệ thống.

API-Football lấy danh mục từ /leagues (cache 6 giờ), chỉ giữ các giải tương ứng với 14 giải The Odds API, cùng tên hiển thị và thứ tự. Đối chiếu chính xác tên giải và quốc gia để lấy ID thật, không hiển thị giải khác hoặc chọn nhầm giải trùng tên. Giải thiếu hoặc có kết quả đối chiếu không rõ ràng sẽ không được đưa vào danh sách, rồi /fixtures?date=...&timezone=Asia/Bangkok cho từng ngày được chọn. Chỉ giữ đúng giải, ngày UTC+7 và trạng thái NS chưa bắt đầu. Lấy danh sách cũng tính lượt gọi API-Football. Khi chọn trận và bấm Lấy kèo và tạo, gọi /odds?fixture=...&page=... chỉ cho các trận được chọn, đọc hết phân trang. Cache lịch/kèo 120 giây; giữ kèo trong snapshot 15 phút để bước đối chiếu không gọi lại. Giãn request theo X-RateLimit-Limit (mặc định 10/phút); nhiều trận sẽ cần chờ lâu hơn. Kiểm tra errors kể cả HTTP 200; quyền mùa giải và dữ liệu kèo phụ thuộc gói tài khoản.

Adapter dùng allowlist tên market cho 1X2, Asian Handicap, Goals Over/Under và một số kèo góc/thẻ/từng hiệp khi nguồn có. Không dùng European handicap, team totals, booking points hoặc định dạng mốc không nhận diện. Hai cửa phải cùng nhà cái, cùng mốc tổng/hai dấu chấp đối nhau. Tái sử dụng giá 0.9, làm tròn 1X2, cách chọn mốc và quy tắc suy H1. Không có kèo phù hợp thì báo tên trận trước transaction, chưa tạo trận nào. ID mới có tiền tố nguồn trước khi băm; cơ chế đối chiếu và kiểm tra trùng giải/đội/giờ giữ như cũ.

Tài liệu: https://www.api-football.com/documentation-v3 ; https://www.api-football.com/news/post/how-to-get-started-with-api-football-the-complete-beginners-guide ; https://www.api-football.com/news/post/how-ratelimit-works .

Kiểm tra: Tests/ApiFootballImportTests.cs; Tests/web-match-selection.test.cjs với WEB_MATCH_TEST_SOURCE=the-odds-api và api-football; Tests/web-match-team-dialog.test.cjs cho đội và giải. Chưa kiểm thử trực tiếp API-Football khi chưa cấu hình key hoặc tạo trận trên IIS/SQL.

## Luồng The Odds API

Đặt API key trong `TheOddsApiKey` ở web.config. Nguồn: https://the-odds-api.com/liveapi/guides/v4/ ; mã market: https://the-odds-api.com/sports-odds-data/betting-markets.html .

Popup chọn một hoặc nhiều ngày trong 7 ngày từ hôm nay theo UTC+7 và một trong 14 giải được phép, gồm UEFA Nations League, Euro, FIFA World Cup và Cúp bóng đá châu Phi (AFCON). Mã giải theo danh mục https://the-odds-api.com/sports-odds-data/sports-apis.html ; dữ liệu trận phụ thuộc lịch thi đấu và nguồn API. Backend kiểm tra lại cả ngày lẫn giải. Lọc chỉ gọi `/events` trong khoảng ngày nhỏ nhất–lớn nhất rồi giữ đúng các ngày đã chọn theo UTC+7; chưa lấy kèo và không tốn credits danh sách. Danh sách hiển thị cả giờ và ngày. Khi bấm Lấy kèo và tạo, chỉ gọi `/events/{id}/odds` cho các trận được chọn, vùng eu, odds decimal, trước khi mở transaction SQL. Cache API 120 giây; kèo đã lấy được giữ trong snapshot 15 phút để bước đối chiếu đội/giải không gọi lại. Nếu một trận chưa có kèo phù hợp thì báo tên trận và chưa tạo trận nào; người dùng bỏ chọn để tiếp tục.

Luôn yêu cầu h2h, spreads, totals, h2h_h1, spreads_h1, totals_h1 và alternate_spreads_corners, alternate_totals_corners, alternate_spreads_cards, alternate_totals_cards. Không yêu cầu alternate_spreads/alternate_totals bàn thắng. API dùng tên alternate cho market góc/thẻ; adapter chọn một mốc có hai giá gần nhau nhất, không tạo mọi mốc. Với market có cả bản chính/phụ, ưu tiên bản chính trước khi so chênh lệch giá. Kèo góc/thẻ/từng hiệp phụ thuộc nguồn. Gọi từng trận tiêu tốn credits theo market/vùng trả về.

Ghép hai cửa cùng nhà cái, cùng mốc; handicap Home x với Away -x. Lưu tài/xỉu và chấp 0.9 mỗi cửa. 1X2 đủ ba cửa cùng nhà cái, làm tròn 1 số thập phân (midpoint away from zero). Không suy ra 1X2 H1 khi thiếu.

## Cấu hình H1 khi nguồn thiếu

Đã bỏ WebMatchH1Rules, WebMatchH1Ratio và WebMatchH1Step. Khi thiếu H1, lấy X = abs(FT) / 2. Phần lẻ .000/.250/.500/.750 trừ 0.25; .125/.625 trừ 0.375; .375/.875 trừ 0.125. Chặn kết quả thấp nhất ở 0 và khôi phục dấu chấp. Chỉ suy ra cho FT là bội số 0.25. Áp dụng tài/xỉu và chấp bàn thắng/góc/thẻ; giữ H1 nguồn, không suy 1X2. Xem trước ghi Suy từ FT.

Snapshot lưu session 15 phút; kiểm tra token, quyền, ID thuộc snapshot, giờ bắt đầu và trùng trận. Tạo nhiều trận trong transaction; lỗi một trận rollback cả lần tạo. Mã ổn định băm SHA256 dài 16 ký tự, tiền tố OM cho trận (không băm mã đội/giải). Đội và giải tìm theo tên chính xác trước khi thêm. Tên khác ngôn ngữ cần đối chiếu thủ công. Ghi bet_match có tham số, trigger cập nhật bet_match_total và gán người tạo.

Đã chạy 108 assertions (ghép cặp, giá, payout, làm tròn, request ArrayList, mã, 5 ví dụ H1, ưu tiên H1 nguồn, chấp âm/0, cấu hình sai, ưu tiên kèo chính), biên dịch backend, kiểm tra cú pháp JS và nút ngày qua chuyển tháng/năm. Chưa kiểm thử tích hợp API/IIS/SQL cho thay đổi này.

## Đối chiếu đội và giải trước khi tạo

Không tạo hoặc tìm mã OT/OL. Tìm trực tiếp team_name trong bet_team và season_name trong bet_season (đây là các cột name thực tế của schema). Tìm chính xác bằng SQL = trước; nếu nhiều bản ghi thì lấy bản ghi đầu ORDER BY mã. Nếu không khớp, tìm tên bằng LIKE %tên nguồn% và escape các ký tự wildcard của tên nguồn. Không tự ghép kết quả LIKE, kể cả chỉ có một kết quả: popup hiển thị các gợi ý để chọn. Nếu không có gợi ý, mở toàn bộ danh sách để tìm/chọn thủ công; khi có gợi ý vẫn có nút chuyển sang toàn bộ danh sách.

Có thể chọn tạo mới với mã tự nhập 1–16 ký tự. Không tự tạo mã đội/giải. Khi chọn bản ghi có sẵn, UPDATE tên của nó thành tên API trong cùng transaction với tạo trận; giữ mã. Đây là cách ghi nhớ lựa chọn cho lần sau (không dùng bảng alias). Đổi tên có tác động tên hiển thị của bản ghi trên hệ thống. Chỉ ghi khi đã giải quyết hết tất cả đội và giải; lỗi tạo trận rollback cả đổi tên và tạo mới. Từ chối chọn hai tên nguồn khác nhau cho cùng một bản ghi trong một lần nhập.

Test UI: node Program/Tests/web-match-team-dialog.test.cjs; đặt WEB_MATCH_TEST_KIND=giải để kiểm tra luồng giải tương tự. Đã kiểm tra khởi tạo danh sách bằng gợi ý LIKE, chuyển sang chọn thủ công, tìm không dấu/theo mã, yêu cầu nhập mã mới, chọn bản ghi có sẵn, biên dịch backend và 108 assertions. Chưa kiểm thử tích hợp SQL cho luồng này.
