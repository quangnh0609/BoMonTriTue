DROP PROC IF EXISTS [dbo].[bet_ticket_code]
GO
CREATE PROC [dbo].[bet_ticket_code]
	@UserID INT,
	@match NVARCHAR(MAX)
AS
BEGIN
	SELECT a.*, b.name, b.part
		INTO #match 
		FROM bet_match a JOIN bet_code b ON a.code = b.code 
		WHERE match = @match
	
	CREATE TABLE #data (stt INT IDENTITY(1, 1), code NVARCHAR(MAX), code_name NVARCHAR(MAX), money INT, textColor NVARCHAR(MAX), rowColor NVARCHAR(MAX))
	
	-- hiệp 1
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '01'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '01'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '11'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '11'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '21'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '21'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '31'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '31'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '51'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '51'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '61'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '61'

	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '41'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.D', part + '. ' + 'Hòa' + ' (' + dbo.ff_NumberFormat(draw_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '41'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + ' (' + dbo.ff_NumberFormat(way_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '41'

	-- cả trận
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '03'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '03'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '13'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '13'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '23'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '23'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '33'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '33'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '53'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '53'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '63'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '63'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '43'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.D', part + '. ' + 'Hòa' + ' (' + dbo.ff_NumberFormat(draw_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '43'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + ' (' + dbo.ff_NumberFormat(way_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '43'

	-- hiệp 2
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '02'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '02'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '12'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '12'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '22'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '22'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '32'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '32'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.O', part + '. ' + N'Tài ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '52'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.U', part + '. ' + N'Xỉu ' + REPLACE(STR(over_under, 19, 2), ' ', '') + ' ' + name, 0, '', '' FROM #match WHERE code = '52'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + CASE WHEN handicap > 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END + REPLACE(name, N'chấp', REPLACE(STR(handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '62'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + CASE WHEN handicap < 0 THEN ' +' WHEN handicap = 0 THEN ' +' ELSE ' ' END  + REPLACE(name, N'chấp', REPLACE(STR(-handicap, 19, 2), ' ', '')), 0, '', '' FROM #match WHERE code = '62'
	
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.H', part + '. ' + home + ' (' + dbo.ff_NumberFormat(home_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '42'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.D', part + '. ' + 'Hòa' + ' (' + dbo.ff_NumberFormat(draw_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '42'
	INSERT INTO #data SELECT RTRIM(LTRIM(code)) + '.W', part + '. ' + way + ' (' + dbo.ff_NumberFormat(way_win, '### ### ###.#0') + ')', 0, '', '' FROM #match WHERE code = '42'

	-- format
	UPDATE #data SET textColor = 'green' WHERE code LIKE '0%'
	UPDATE #data SET textColor = 'red' WHERE code LIKE '1%'
	UPDATE #data SET textColor = 'blue' WHERE code LIKE '2%'
	UPDATE #data SET textColor = 'brown' WHERE code LIKE '3%'
	UPDATE #data SET textColor = 'orange' WHERE code LIKE '4%'
	UPDATE #data SET textColor = 'green' WHERE code LIKE '5%'
	UPDATE #data SET textColor = 'red' WHERE code LIKE '6%'

	UPDATE #data SET rowColor = 'Lavender' WHERE code LIKE '%1.%'
	UPDATE #data SET rowColor = 'LightYellow' WHERE code LIKE '%3.%'
	UPDATE #data SET rowColor = 'LightSkyBlue' WHERE code LIKE '%2.%'
	
	-- bet_ticket
	UPDATE a SET money = b.money FROM #data a JOIN bet_ticket b ON LEFT(a.code, 2) = b.code AND RIGHT(a.code, 1) = b.ticket AND b.match = @match AND b.user_id = @UserID

	SELECT * FROM #data ORDER BY stt
END
GO
exec bet_ticket_code @match=N'460',@userID=2