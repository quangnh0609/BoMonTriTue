# Database

Các script SQL được lấy nguyên trạng từ repo Program_Web, dành cho SQL Server:

- Core/: bảng và view nền tảng, trigger, quyền và thủ tục tính vé.
- App/: table, view, stored procedure nghiệp vụ và script ALTER bổ sung.
- System/: Sys.sql và các định nghĩa hệ thống có sẵn trong nguồn.

Đã bỏ hai bản sao lưu bet_ticket_result và ba stored procedure chuyển giao nhà cái đã ngừng dùng. Giữ bảng bet_host vì các đối tượng SQL khác có thể còn phụ thuộc.

Đây là bộ script hiện có, chưa được xác minh là bộ khởi tạo hoàn chỉnh trên database trống. Không chạy toàn bộ theo thứ tự tên file: số thứ tự chỉ có ý nghĩa trong nhóm gốc, nhiều script chứa nhiều đối tượng và có phụ thuộc chéo. Cần rà soát đối tượng hệ thống, tạo bảng trước, sau đó view/function, stored procedure/trigger và các ALTER theo phụ thuộc thực tế. Kiểm tra USE/tên database trước khi chạy.

Chưa thực thi các script lên SQL Server; database đang dùng không bị thay đổi.
