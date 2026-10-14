DROP FUNCTION IF EXISTS [dbo].[bet_check_right]
GO
CREATE FUNCTION [dbo].[bet_check_right] (@user_id INT, @action NVARCHAR(MAX))
RETURNS BIT
AS BEGIN
	DECLARE @right BIT = 0
	
	IF EXISTS (SELECT 1 FROM vsysuserinfo WHERE id = @user_id AND admin = 1) BEGIN
		SET @right = 1
		GOTO zcEND
	END

	-- check
	IF @action = 'host' SELECT @right = 0
	IF @action IN ('bet_match_insert', 'bet_champion_insert', 'bet_champions_insert') SELECT @right = 1
	IF @action IN ('bet_match_update', 'bet_match_delete', 'bet_champion_update', 'bet_champion_delete', 'bet_champions_update', 'bet_champions_delete') SELECT @right = 1
	IF @action IN ('bet_match_result', 'bet_champion_result') SELECT @right = 1
	IF @action IN ('bet_ticket_insert', 'bet_ticket_delete', 'bet_ticket_result', 'bet_ticket_clear', 'bet_report') SELECT @right = 1
	IF @action IN ('bet_master_data', 'bet_master_data_insert', 'bet_master_data_delete', 'bet_payment_insert') SELECT @right = 0
	
	zcEND:
	RETURN @right
END
go
exec bet_check_right 2, 'host'
