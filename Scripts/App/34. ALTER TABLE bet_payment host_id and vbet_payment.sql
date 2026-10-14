IF COL_LENGTH('dbo.bet_payment', 'host_id') IS NULL
	ALTER TABLE [dbo].[bet_payment] ADD [host_id] INT NULL
GO

UPDATE [dbo].[bet_payment]
	SET [host_id] = [user_id]
	WHERE [host_id] IS NULL
GO

CREATE OR ALTER VIEW [dbo].[vbet_payment]
AS
	SELECT p.[id],
		   p.[host_id],
		   p.[user_id],
		   ISNULL(NULLIF(LTRIM(RTRIM(h.[comment])), ''), h.[name]) AS [host_name],
		   ISNULL(NULLIF(LTRIM(RTRIM(u.[comment])), ''), u.[name]) AS [user_name],
		   p.[money],
		   p.[datetime],
		   p.[clear]
	FROM [dbo].[bet_payment] p
		LEFT JOIN [dbo].[vsysuserinfo] h ON h.[id] = p.[host_id]
		LEFT JOIN [dbo].[vsysuserinfo] u ON u.[id] = p.[user_id]
GO
