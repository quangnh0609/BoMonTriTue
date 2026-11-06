# Active cho đội và giải đấu

Chạy `01_catalog_active.sql` trên database ứng dụng trước khi triển khai code. Migration có thể chạy lại, bổ sung `is_active bit NOT NULL DEFAULT 1` vào `bet_team` và `bet_season`, giữ toàn bộ bản ghi cũ active. Đã áp dụng trên database BoMonTriTue trong môi trường hiện tại.

Admin vào danh mục Đội/Mùa giải, bấm **Ẩn** hoặc **Kích hoạt**. Bản ghi ẩn vẫn nằm trong danh mục để quản lý; tên và mã không bị thay đổi. Không lọc active trong các join hiển thị hoặc bộ lọc lịch sử. Đã tính cả dữ liệu chung cuộc khi kiểm tra mã có phát sinh để tránh xóa/đổi mã đang được tham chiếu.

Bộ chọn khi thêm/sửa/copy trận bóng đá, esports, kèo chung cuộc chỉ nhận active. Luồng web cũng tìm tên chính xác, LIKE và chọn tay trong danh sách active. Kiểm tra trùng mã khi tạo mới vẫn xét cả bản ghi inactive; không tái sử dụng mã đã ẩn cho đội/giải khác.

Backend SaveMatch, SaveEsport, SaveChampion (thêm/sửa kèo) và WebMatches kiểm tra active ngay trong transaction trước khi ghi; giữ read lock tới khi kết thúc giao dịch, tránh lọt mã đã bị ẩn từ một tab khác. Khi sửa dữ liệu đang dùng mã đã ẩn, phải chọn lại mã active để lưu. Luồng nhập kết quả và dữ liệu lịch sử không bị kiểm tra active, nên vẫn xử lý được trận/kèo cũ.

Kiểm tra: 9 trang server được biên dịch với các control khai báo; test popup đối chiếu đội chạy đạt. `Program/Tests/CatalogStateIntegrationTests.cs` chạy trực tiếp SQL, thử inactive/active/mã không tồn tại, giữ tên cũ và số trận lịch sử. Mọi thay đổi trạng thái trong kiểm thử đều rollback, không ẩn mã thật. Chưa chạy kiểm thử giao diện IIS bằng trình duyệt.
