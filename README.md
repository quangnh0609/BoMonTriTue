# Bộ Môn Trí Tuệ

ASP.NET Web Site / .NET Framework 4.x, SQL Server. Chạy trên IIS với Application Pool .NET CLR v4.0, Integrated; trang mặc định default.aspx. Không dùng dotnet build, npm hoặc Python.

web.config hiện kết nối QUANGNH\SQL2019, database BoMonTriTue. Tài khoản ứng dụng nằm trong dbo.userinfo2 nội bộ App. Cấu hình chứa mật khẩu kết nối, không xuất lên remote công khai.

Chức năng: đăng nhập, trang chủ, trận đấu, esports, vé cược, kèo chung cuộc, chép bài, phép thuật, đội, mùa giải, cài đặt và đổi mật khẩu. Giao diện dùng Tailwind/Font Awesome qua CDN.

Scripts/ quản lý cấu trúc và migration; xem Scripts/Audit/README.md để biết phạm vi DB đã đối chiếu và thay đổi ngày 2026-10-14. Databases/ chứa bản DB/backup do người dùng chuẩn bị. docs/CODEMAP.md và docs/codemap.json ghi luồng tài khoản hiện tại.

Repo gốc Program_Web không bị sửa mã nguồn. Bản mới đã bỏ luồng transfer.aspx/DeleteHost.aspx và control ucAddMatch2.ascx không dùng; giữ bet_host trong phạm vi DB theo yêu cầu.

## Cấu hình khi clone repository

Sao chép web.config.example thành web.config và điền thông tin kết nối SQL Server của bạn. web.config và thư mục Databases/ được bỏ qua bởi Git; các script cấu trúc và migration trong Scripts/ vẫn được quản lý phiên bản.
