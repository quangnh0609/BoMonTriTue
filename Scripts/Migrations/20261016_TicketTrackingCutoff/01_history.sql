-- Repository only: deploy manually before the updated bet_ticket_result script.
SET XACT_ABORT ON;
BEGIN TRANSACTION;
IF OBJECT_ID(N'dbo.bet_ticket_tracking_cutoff', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.bet_ticket_tracking_cutoff (
        id BIGINT IDENTITY(1,1) NOT NULL
            CONSTRAINT PK_bet_ticket_tracking_cutoff PRIMARY KEY CLUSTERED,
        cutoff_at DATETIME2(0) NOT NULL,
        declared_at_utc DATETIME2(0) NOT NULL
            CONSTRAINT DF_bet_ticket_tracking_cutoff_declared DEFAULT SYSUTCDATETIME(),
        declared_by INT NULL,
        declared_by_name NVARCHAR(128) NOT NULL,
        note NVARCHAR(500) NOT NULL
    );
END;
-- Preserve the previous behavior on first deployment. Never reset existing history.
IF NOT EXISTS (SELECT 1 FROM dbo.bet_ticket_tracking_cutoff WITH (TABLOCKX, HOLDLOCK))
    INSERT dbo.bet_ticket_tracking_cutoff (cutoff_at, declared_by, declared_by_name, note)
    VALUES (CONVERT(DATETIME2(0), '2026-07-20T12:00:00', 126), NULL, N'Hệ thống', N'Khởi tạo từ mốc theo dõi cũ');
COMMIT;
GO

CREATE OR ALTER PROC dbo.bet_ticket_tracking_cutoff_append
    @cutoff_at DATETIME2(0),
    @user_id INT,
    @note NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    IF @cutoff_at IS NULL THROW 50003, 'A tracking cutoff is required.', 1;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @actor NVARCHAR(128);
        SELECT @actor = name FROM dbo.userinfo2 WHERE id = @user_id AND admin = 1;
        IF @actor IS NULL THROW 50004, 'Only administrators can declare a tracking cutoff.', 1;
        -- Serialize declarations so later successful declarations get larger IDs.
        DECLARE @last_id BIGINT;
        SELECT TOP (1) @last_id = id
        FROM dbo.bet_ticket_tracking_cutoff WITH (TABLOCKX, HOLDLOCK)
        ORDER BY id DESC;
        INSERT dbo.bet_ticket_tracking_cutoff (cutoff_at, declared_by, declared_by_name, note)
        VALUES (@cutoff_at, @user_id, @actor, ISNULL(@note, N''));
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO
