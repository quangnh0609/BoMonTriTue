# Lấy từ web — The Odds API v4

## Chọn nguồn API

Bấm Lấy từ web để chọn The Odds API hoặc API-Football trước khi lọc ngày/giải. The Odds API giữ cơ chế cũ. Mỗi nguồn có key, cache và hạn mức riêng; đổi nguồn xóa danh sách/lựa chọn, backend kiểm tra nguồn khớp snapshot.

API-Football: thêm `<add key="ApiFootballKey" value="YOUR_API_FOOTBALL_KEY" />` vào appSettings trong web.config trên máy chủ. Dùng key trực tiếp từ https://dashboard.api-football.com/ (header x-apisports-key, base URL https://v3.football.api-sports.io/), không dùng key RapidAPI. Trước khi triển khai bản mới, chạy Scripts/Migrations/20261114_WebImportAliases/01_web_import_aliases.sql trên DB ứng dụng để thêm các cột tên riêng theo nguồn.

API-Football lấy danh mục từ /leagues (cache 6 giờ), chỉ giữ các giải tương ứng với 14 giải The Odds API, cùng tên hiển thị và thứ tự. Đối chiếu chính xác tên giải và quốc gia để lấy ID thật, không hiển thị giải khác hoặc chọn nhầm giải trùng tên. Giải thiếu hoặc có kết quả đối chiếu không rõ ràng sẽ không được đưa vào danh sách, rồi /fixtures?date=...&timezone=Asia/Bangkok cho từng ngày được chọn. Chỉ giữ đúng giải, ngày UTC+7 và trạng thái NS chưa bắt đầu. Lấy danh sách cũng tính lượt gọi API-Football. Khi chọn trận và bấm Xem trước kèo, gọi /odds?fixture=...&page=... chỉ cho các trận được chọn, đọc hết phân trang. Màn xem trước hiển thị mọi kèo sẽ lưu, gồm bảng nhập giống Tạo trận, chỉ H1/FT, gồm mốc/giá hai cửa, 1X2, cờ suy H1 và giao bóng mặc định. Mỗi trận là một bảng riêng, có thể chỉnh nhiều trận trong cùng lần nhập. Rate ẩn mặc định, nút Rate ẩn/hiện các dòng giá; có thể nhập dấu chấm hoặc phẩy. Ô chấp dùng inputMode=text để bàn phím điện thoại có dấu âm; các ô tài/xỉu và Rate vẫn dùng bàn phím thập phân. H1 và FT sửa độc lập. Xóa mốc để bỏ kèo hoặc để trống đủ ba giá để bỏ 1X2, giữ giao bóng H1. Xác nhận mới tạo; backend kiểm tra previewToken và đúng tập ID đã xem, kiểm tra edits của đúng tất cả ID đã xem. Máy chủ xác thực toàn bộ batch trước khi thay dữ liệu session/ghi SQL, chỉ chấp nhận mã H1/FT và giao bóng H1, loại mốc sai bội số 0.25/giá không hợp lệ/H2/trùng mã/trận ngoài lựa chọn. Giá tài-xỉu và chấp được lưu đúng giá người dùng sửa, không gán đè 0.9. Không gọi lại API sau chỉnh sửa. Tạo tất cả trận trong transaction chung. Cache lịch/kèo 120 giây; giữ kèo trong snapshot 15 phút để bước đối chiếu không gọi lại. Giãn request theo X-RateLimit-Limit (mặc định 10/phút); nhiều trận sẽ cần chờ lâu hơn. Kiểm tra errors kể cả HTTP 200; quyền mùa giải và dữ liệu kèo phụ thuộc gói tài khoản.

Adapter dùng allowlist tên market cho 1X2, Asian Handicap, Goals Over/Under và một số kèo góc/thẻ/từng hiệp khi nguồn có. Không dùng European handicap, team totals, booking points hoặc định dạng mốc không nhận diện. Hai cửa phải cùng nhà cái. API-Football dùng cùng dấu mốc HOME cho hai nhãn Home/Away (đã đối chiếu dữ liệu thực tế ngày 14/11/2026); adapter ghép cùng mốc nguồn rồi đổi dấu mốc Away trước khi đưa vào bộ chọn kèo chung. Không ghép Home +x với Away -x trong dữ liệu thô của API-Football. Nhận diện Cards Asian Handicap; bỏ toàn bộ market H2 theo yêu cầu. Tái sử dụng giá 0.9, làm tròn 1X2, cách chọn mốc và quy tắc suy H1. Không có kèo phù hợp thì báo tên trận trước transaction, chưa tạo trận nào. ID mới có tiền tố nguồn trước khi băm; cơ chế đối chiếu và kiểm tra trùng giải/đội/giờ giữ như cũ.

Tài liệu: https://www.api-football.com/documentation-v3 ; https://www.api-football.com/news/post/how-to-get-started-with-api-football-the-complete-beginners-guide ; https://www.api-football.com/news/post/how-ratelimit-works .

Kiểm tra: Tests/ApiFootballImportTests.cs; Tests/web-match-selection.test.cjs với WEB_MATCH_TEST_SOURCE=the-odds-api và api-football; Tests/web-match-team-dialog.test.cjs cho đội và giải. Đã đọc một trang kèo thực tế và phát lại 10 trận, kiểm tra 40 lựa chọn chấp với các cặp cùng mốc từ nguồn. Chưa tạo trận trên IIS/SQL.

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

Migration 20261114_WebImportAliases thêm the_odds_api_name và api_football_name (nvarchar(128), nullable) vào cả dbo.bet_team và dbo.bet_season. Không tự khôi phục hoặc ghi đè team_name/season_name đã có. Không backfill tên API từ tên chính vì không có bằng chứng về nguồn của các tên đã lưu.

Tìm chính xác bằng mã, tên chính và tên của cả hai API. Chỉ tự ghép nếu đúng một kết quả; nhiều kết quả thì hỏi chọn, không lấy tùy ý bản ghi đầu. Gợi ý LIKE tìm trên cả bốn trường, escape wildcard. Ô tìm thủ công tìm toàn bộ danh sách theo mã/tên/cả hai alias, không chỉ trong gợi ý ban đầu; vẫn hỗ trợ không dấu. Popup Thêm/Sửa trận cũng nhận hai alias trong dữ liệu danh mục và tìm theo chúng.

Chọn bản ghi có sẵn chỉ UPDATE cột tên của API đang dùng, giữ nguyên mã/tên chính và tên của API còn lại. Bản ghi mới có tên chính khởi tạo từ nguồn cùng alias tương ứng. Mọi cập nhật alias và tạo mới nằm chung transaction với tạo trận; thiếu đối chiếu hoặc lỗi thì không ghi dở. Từ chối hai tên nguồn khác nhau trỏ cùng mã trong một lần nhập. Nếu DB chưa có các cột mới, importer báo rõ migration cần chạy; danh sách chọn thủ công vẫn nạp được với alias rỗng.

Test UI: node Program/Tests/web-match-team-dialog.test.cjs; đặt WEB_MATCH_TEST_KIND=giải để kiểm tra luồng giải tương tự. Đã kiểm tra khởi tạo danh sách bằng gợi ý LIKE, chuyển sang chọn thủ công, tìm không dấu/theo mã, yêu cầu nhập mã mới, chọn bản ghi có sẵn, biên dịch backend và 108 assertions. Chưa kiểm thử tích hợp SQL cho luồng này.

Kiểm tra mới: 32 assertions WebMatchEditsTests kiểm tra sửa nhiều trận, giá tài/xỉu, dấu phẩy, rollback trước mutate và từ chối H2/dữ liệu sai; 117 assertions WebMatchImportTests; 30 assertions ApiFootballImportTests; Tests/Run-WebMatchPreviewTests.ps1 chạy 14 assertions từ code ASPX thực tế với biên SQL được chặn (xem trước không ghi DB, không cho tạo khi chưa xem/khác token/khác ID/hết hạn/khác nguồn; The Odds API không bắt buộc preview). Các test JS kiểm tra hiển thị hai dấu chấp, kèo suy FT, 1X2 và tìm theo alias của cả hai nguồn.

Đối chiếu Kosovo–Israel (fixture 1528971, 14/11/2026): Bet365 trả cả -0.75 (2.05/1.75) và -0.5 (1.80/1.95). Quy tắc độ cân giá hiện chọn -0.5, không chứng minh đây là main line. Theo yêu cầu người dùng, không bổ sung giao diện chọn mốc/nhà cái hoặc hiển thị giá nguồn. Giữ bước xem trước/chỉnh sửa trực tiếp các kèo sẽ tạo; có thể sửa mốc -0.5 thành -0.75 tại đây.


## Khôi phục khi điện thoại ngủ và giảm chờ trang

Mỗi thao tác có operationId ngẫu nhiên. WebMatchOperations lưu receipt kết quả trong cache 2 giờ theo người dùng/phiên. Khi mất mạng hoặc kết nối cũ bị treo sau tắt/mở màn hình, trang chờ visible/online rồi hỏi status của đúng lượt cũ. Pending còn chạy được hỏi tiếp (không tính là lỗi kết nối, tối đa 35 phút); lỗi mạng liên tiếp giới hạn 12 lần. Chỉ retry thao tác đọc một lần nếu máy chủ xác nhận không có receipt. Không tự phát lại create khi chưa biết kết quả; thông báo kiểm tra danh sách trận, giữ các ô đã sửa. Receipt thành công không bị ghi đè bởi lỗi gửi phản hồi sau commit. Cache không bền qua IIS recycle/eviction; khi mất receipt của create phải kiểm tra danh sách, không suy đoán thất bại để tự tạo lại.

WebMatches.aspx dùng EnableSessionState=ReadOnly. Token, snapshot và lựa chọn của importer nằm trong WebMatchState riêng, không ghi ASP.NET Session. Chỉ các thao tác import cùng phạm vi dùng SyncRoot riêng; status không lấy khóa này. Lấy kèo lâu không giữ khóa phiên đăng nhập khiến home.aspx/matches.aspx phải chờ. Người dùng có FormsAuth hợp lệ nhưng phiên cũ đã mất được xác thực lại ID qua DB mà không sửa session read-only; AuthSession bỏ qua việc ghi phục hồi ở request read-only. Chỉ mở endpoint không tự gọi API bóng đá khi vào Trang chủ/Trận đấu.

Trang Trận đấu không dựng toàn bộ DOM dropdown đội/giải lúc window load; dựng khi mở hoặc tìm. Không đọc/serialize lại toàn bộ catalog trong partial postback, vẫn nạp khi tải đầy đủ để giữ dữ liệu tên/alias mới nhất. Thay đổi này không cần migration DB mới.

Kiểm tra bổ sung: Tests/web-match-mobile-recovery.test.cjs (sleep/wake, offline, stale connection, pending dài, không lặp create); Tests/WebMatchOperationsTests.cs (receipt và chống replay); Tests/WebMatchStateTests.cs (khóa riêng/phạm vi tách biệt/status không chờ); Tests/web-match-page-performance.test.cjs (read-only, không ghi session import, lazy dropdown); Tests/web-match-selection.test.cjs (Rate mặc định ẩn, toggle, bàn phím dấu âm, nhiều trận). Chưa đo latency thực tế trên IIS/điện thoại.
