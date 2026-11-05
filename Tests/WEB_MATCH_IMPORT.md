# Lấy từ web — The Odds API v4

Đặt API key trong `TheOddsApiKey` ở web.config. Nguồn: https://the-odds-api.com/liveapi/guides/v4/ ; mã market: https://the-odds-api.com/sports-odds-data/betting-markets.html .

Popup chọn một trong 7 ngày từ hôm nay theo UTC+7 và một trong 10 giải được phép. Backend kiểm tra lại cả ngày lẫn giải. Gọi `/events` cho ngày đã chọn, sau đó `/events/{id}/odds` cho mỗi trận sắp diễn ra, vùng eu, odds decimal. Cache 120 giây; tạo trận không gọi thêm API.

Luôn yêu cầu h2h, spreads, totals, h2h_h1, spreads_h1, totals_h1 và alternate_spreads_corners, alternate_totals_corners, alternate_spreads_cards, alternate_totals_cards. Không yêu cầu alternate_spreads/alternate_totals bàn thắng. API dùng tên alternate cho market góc/thẻ; adapter chọn một mốc có hai giá gần nhau nhất, không tạo mọi mốc. Với market có cả bản chính/phụ, ưu tiên bản chính trước khi so chênh lệch giá. Kèo góc/thẻ/từng hiệp phụ thuộc nguồn. Gọi từng trận tiêu tốn credits theo market/vùng trả về.

Ghép hai cửa cùng nhà cái, cùng mốc; handicap Home x với Away -x. Lưu tài/xỉu và chấp 0.9 mỗi cửa. 1X2 đủ ba cửa cùng nhà cái, làm tròn 1 số thập phân (midpoint away from zero). Không suy ra 1X2 H1 khi thiếu.

## Cấu hình H1 khi nguồn thiếu

Đã bỏ WebMatchH1Rules, WebMatchH1Ratio và WebMatchH1Step. Khi thiếu H1, lấy X = abs(FT) / 2. Phần lẻ .000/.250/.500/.750 trừ 0.25; .125/.625 trừ 0.375; .375/.875 trừ 0.125. Chặn kết quả thấp nhất ở 0 và khôi phục dấu chấp. Chỉ suy ra cho FT là bội số 0.25. Áp dụng tài/xỉu và chấp bàn thắng/góc/thẻ; giữ H1 nguồn, không suy 1X2. Xem trước ghi Suy từ FT.

Snapshot lưu session 15 phút; kiểm tra token, quyền, ID thuộc snapshot, giờ bắt đầu và trùng trận. Tạo nhiều trận trong transaction; lỗi một trận rollback cả lần tạo. Mã ổn định băm SHA256 dài 16 ký tự, tiền tố OM/OL/OT cho trận/giải/đội. Đội và giải tìm theo tên chính xác trước khi thêm. Tên khác ngôn ngữ cần đối chiếu thủ công. Ghi bet_match có tham số, trigger cập nhật bet_match_total và gán người tạo.

Đã chạy 107 assertions (ghép cặp, giá, payout, làm tròn, request ArrayList, mã, 5 ví dụ H1, ưu tiên H1 nguồn, chấp âm/0, cấu hình sai, ưu tiên kèo chính), biên dịch backend, kiểm tra cú pháp JS và nút ngày qua chuyển tháng/năm. Chưa kiểm thử tích hợp API/IIS/SQL cho thay đổi này.
