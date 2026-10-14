# Sao lưu SQL Server lên Google Drive

Chạy trên Windows đặt SQL Server, mỗi ngày lúc 06:00 theo múi giờ máy chủ. Giữ backup 30 ngày trên ổ cứng và Google Drive. Chưa cài đặt hay chạy trên máy chủ.

## Chuẩn bị thư mục trên server

Thực hiện trên server tại `C:\FASTFBO\TAPHOA\BoMonTriTue`; `Program` là repo, `AutoBackup` là thư mục đã tạo cùng cấp. Mở Windows PowerShell bằng **Run as administrator**. Nếu chưa có script nguồn, cập nhật repo Program trước.

```powershell
$backupHome = 'C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup'
$backupSource = 'C:\FASTFBO\TAPHOA\BoMonTriTue\Program\Scripts\Backup'
New-Item -ItemType Directory -Path $backupHome -Force | Out-Null
Copy-Item -LiteralPath "$backupSource\Backup-ToDrive.ps1" -Destination $backupHome
Copy-Item -LiteralPath "$backupSource\Register-BackupTask.ps1" -Destination $backupHome
if (-not (Test-Path -LiteralPath "$backupHome\backup.config.json")) {
    Copy-Item -LiteralPath "$backupSource\backup.config.example.json" -Destination "$backupHome\backup.config.json"
}
New-Item -ItemType Directory -Path "$backupHome\Backups" -Force | Out-Null
New-Item -ItemType Directory -Path "$backupHome\rclone" -Force | Out-Null
Set-Location -LiteralPath $backupHome
notepad .\backup.config.json
```

File mẫu đã dùng đường dẫn AutoBackup trên server. Xác nhận `SqlServer` theo instance thực tế trong SSMS. Script dùng Windows Authentication, không dùng tài khoản SQL trong web.config.

## Cài đặt

1. Chép các file trong Program\Scripts\Backup vào `C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup` trên máy chủ. Tải rclone từ https://rclone.org/downloads/ và giải nén vào `C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\rclone`.
2. Tạo một thư mục riêng trên Google Drive, ví dụ `SQLBackups/BoMonTriTue`. Trong PowerShell chạy:

   ```powershell
   C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\rclone\rclone.exe config --config C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\rclone.conf
   ```

   Tạo remote tên `gdrive`, chọn Google Drive, đăng nhập và cấp quyền tải/đọc/xóa file backup. Nếu máy chủ không có trình duyệt, dùng quy trình tại https://rclone.org/remote_setup/ để cấp quyền trên máy có trình duyệt. Nếu tự tạo OAuth client ở trạng thái Testing, token có thể hết hạn sau 7 ngày; dùng cấu hình OAuth phù hợp cho tác vụ dài hạn theo https://rclone.org/drive/#making-your-own-client-id. Không gửi token hoặc rclone.conf vào chat hay Git.
3. Sao chép `backup.config.example.json` thành `backup.config.json`. Điền instance SQL Server trên máy chủ (ví dụ `.\\SQL2019`, hoặc `.` cho default instance), đường dẫn ổ cứng và thư mục Drive. Instance trong cấu hình mẫu chỉ là ví dụ, cần xác nhận trên máy chủ. Có thể cấu hình `root_folder_id` của remote để trỏ tới thư mục Drive đã tạo, khi đó vẫn dùng một thư mục con riêng cho backup trong `DriveDestination`.
4. Tạo `C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\Backups`. Cấp quyền ghi cho tài khoản dịch vụ SQL Server và quyền đọc/ghi/xóa cho tài khoản Windows chạy tác vụ. Script dùng Windows Authentication: tài khoản chạy cần quyền BACKUP DATABASE và RESTORE VERIFYONLY (nhờ DBA cấp quyền phù hợp với phiên bản SQL Server). Tài khoản cũng cần quyền chạy batch job và truy cập mạng tới Google Drive.
5. Bảo vệ thư mục script, cấu hình và rclone.conf bằng ACL: chỉ quản trị viên và tài khoản tác vụ được sửa. rclone.conf chứa thông tin xác thực. Đảm bảo đủ dung lượng cho khoảng 30 bản full backup và các bản tồn đọng khi mất kết nối.

### Các lựa chọn khi kết nối Drive

Trong `rclone config`, chọn `n`, đặt tên remote **gdrive**, chọn backend **Google Drive** theo tên (số thứ tự có thể thay đổi). Tạo OAuth client riêng loại Desktop app trong Google Cloud, bật Google Drive API, rồi nhập client_id/client_secret của bạn. Client dùng chung của rclone sẽ ngừng hoạt động trong năm 2026; không để trống cho tác vụ dài hạn. Với tài khoản cá nhân, cấu hình consent External và chuyển sang In production để tránh token hết hạn sau 7 ngày khi ở Testing. Xem hướng dẫn tạo client ở liên kết rclone bên trên. Chọn quyền đọc/ghi/xóa backup; để trống service_account_file nếu đăng nhập Google cá nhân. Xác thực qua trình duyệt nếu server có trình duyệt. Với My Drive cá nhân, không chọn Shared Drive. Xác nhận lưu remote rồi thoát bằng `q`.

File giải nén phải nằm đúng tại `AutoBackup\rclone\rclone.exe`, không lồng thêm thư mục phiên bản. Sau khi cấu hình, tạo thư mục riêng và kiểm tra:

```powershell
Set-Location 'C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup'
.\rclone\rclone.exe version
.\rclone\rclone.exe mkdir gdrive:SQLBackups/BoMonTriTue --config .\rclone.conf
.\rclone\rclone.exe lsd gdrive:SQLBackups --config .\rclone.conf
```

Tài khoản tác vụ cần đọc/ghi rclone.conf để cập nhật token. Xem tài khoản dịch vụ SQL Server trong SQL Server Configuration Manager hoặc Services; cấp quyền thư mục bằng Properties → Security. Giữ AutoBackup ngoài thư mục web IIS.

## Kiểm tra trước khi bật lịch

Chạy bằng chính tài khoản Windows sẽ dùng cho tác vụ:

```powershell
C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\rclone\rclone.exe lsd gdrive: --config C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\rclone.conf
powershell.exe -NoProfile -File C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\Backup-ToDrive.ps1 -ConfigPath C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\backup.config.json
```

Lệnh thứ hai tạo backup thật, tải lên và áp dụng giữ 30 ngày. Kiểm tra file trên Drive và log trong thư mục `logs` của BackupDirectory. Script trả mã 1 nếu lỗi; không dọn backup khi có lỗi backup, upload hoặc xác minh upload. Các file chưa upload thành công được giữ lại và thử lại ở lần chạy sau. Chỉ tên file đúng mẫu do script tạo mới được dọn; không dùng remote root hoặc thư mục dùng chung.

Backup dùng COPY_ONLY và CHECKSUM; RESTORE VERIFYONLY kiểm tra file trước khi tải lên. Sau tải lên, so sánh MD5 từ Drive với file local. VERIFYONLY không thay thế thử phục hồi thực tế: định kỳ tải một backup xuống và restore vào DB kiểm thử riêng. Đây là full backup hằng ngày, không cung cấp phục hồi tới từng thời điểm; nếu DB dùng FULL recovery, vẫn cần quản lý transaction log backup riêng để tránh log tăng liên tục.

Chỉ đăng ký lịch sau khi chạy thử thành công, có file `.bak` trên Drive và file `.uploaded` trong thư mục Backups. Nếu lỗi, xem log và sửa trước khi tiếp tục. Với chính sách PowerShell chặn script, thêm `-ExecutionPolicy Bypass` vào lệnh chạy powershell.exe ở trên.

## Đăng ký lịch

Mở PowerShell quyền quản trị, kiểm tra múi giờ máy chủ phù hợp với giờ bạn muốn (Việt Nam/Thái Lan: UTC+07), rồi chạy:

```powershell
powershell.exe -NoProfile -File C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\Register-BackupTask.ps1 -ConfigPath C:\FASTFBO\TAPHOA\BoMonTriTue\AutoBackup\backup.config.json
```

Nhập tài khoản Windows và mật khẩu trong hộp thoại. Tác vụ chạy ngay cả khi chưa đăng nhập. Nếu bỏ lỡ 06:00 vì máy tắt, tác vụ chạy khi máy hoạt động lại. Không đăng ký đè tác vụ có cùng tên; muốn đổi cấu hình lịch, sửa tác vụ trong Task Scheduler. Lịch 06:00 dùng múi giờ máy chủ; tên file ghi giờ UTC.

Kiểm tra Task Scheduler → BoMonTriTue-Backup-ToDrive → Last Run Result phải là `0x0`, và xem log sau lần chạy đầu. Chưa tích hợp thông báo email khi lỗi. Log được giữ để chẩn đoán, chưa tự dọn log. Khi đổi mật khẩu tài khoản Windows hoặc quyền Google Drive, cập nhật thông tin và chạy kiểm tra lại.

### Kiểm tra tác vụ đã đăng ký

Nhập mật khẩu Windows của tài khoản đã chạy thử thành công, không dùng PIN Windows. Nếu chính sách PowerShell chặn script đăng ký, thêm `-ExecutionPolicy Bypass` vào lệnh powershell.exe.

Trong PowerShell quyền quản trị, chạy tác vụ thử:

```powershell
Start-ScheduledTask -TaskName 'BoMonTriTue-Backup-ToDrive'
```

Chờ hoàn tất trong Task Scheduler rồi xem kết quả:

```powershell
Get-ScheduledTask -TaskName 'BoMonTriTue-Backup-ToDrive' | Select-Object TaskName, State
Get-ScheduledTaskInfo -TaskName 'BoMonTriTue-Backup-ToDrive' | Select-Object LastRunTime, LastTaskResult, NextRunTime
```

LastTaskResult phải bằng `0`, có backup mới trên Drive và log thành công. Nếu vẫn Running, chờ tác vụ kết thúc trước khi đọc kết quả. Kiểm tra lại sau lần chạy 06:00 đầu tiên.

## Tài liệu

- https://rclone.org/drive/
- https://rclone.org/commands/rclone_copyto/
- https://learn.microsoft.com/en-us/sql/relational-databases/backup-restore/copy-only-backups-sql-server
- https://learn.microsoft.com/en-us/sql/t-sql/statements/restore-statements-verifyonly-transact-sql


