-- =============================================
-- View tong hop thong tin tran dau Esports
-- Join bet_season, bet_team de lay ten
-- Tinh total_games va status theo match_time/result
-- =============================================

DROP VIEW IF EXISTS [dbo].[vbet_esport_match]
GO
CREATE VIEW [dbo].[vbet_esport_match]
AS
    WITH match_data AS (
        SELECT
            m.[match_id],
            m.[season],
            ISNULL(s.[season_name], m.[season]) AS [season_name],
            m.[home],
            ISNULL(th.[team_name], m.[home]) AS [home_name],
            m.[way],
            ISNULL(tw.[team_name], m.[way]) AS [way_name],
            m.[match_time],
            CASE WHEN EXISTS (
                SELECT 1
                FROM [dbo].[bet_ticket_esport] t
                CROSS APPLY (
                    SELECT
                        CHARINDEX('.', t.[code]) AS [first_dot],
                        PARSENAME(t.[code], 2) AS [market]
                ) code_info
                JOIN [dbo].[bet_esport_game] g
                    ON g.[match_id] = t.[match_id]
                    AND g.[game_no] = TRY_CAST(SUBSTRING(t.[code], 2, code_info.[first_dot] - 2) AS INT)
                WHERE t.[match_id] = m.[match_id]
                    AND code_info.[first_dot] > 2
                    AND (
                        (code_info.[market] IN ('OU', 'HC') AND (g.[result_kill_home] IS NULL OR g.[result_kill_way] IS NULL))
                        OR (code_info.[market] = 'MIN' AND g.[result_minute] IS NULL)
                        OR (code_info.[market] IN ('DOU', 'DHC') AND (g.[result_dragon_home] IS NULL OR g.[result_dragon_way] IS NULL))
                        OR (code_info.[market] = 'FD' AND g.[result_first_dragon] IS NULL)
                        OR (code_info.[market] IN ('FDT', 'FDCHEM', 'FDWIND', 'FDWATER', 'FDFIRE', 'FDEARTH') AND g.[result_first_dragon_type] IS NULL)
                        OR (code_info.[market] = 'FIRST' AND g.[result_first] IS NULL)
                        OR (code_info.[market] = 'THIRD' AND g.[result_third] IS NULL)
                        OR (code_info.[market] = 'FIVE' AND g.[result_five] IS NULL)
                        OR (code_info.[market] = 'TEN' AND g.[result_ten] IS NULL)
                        OR (code_info.[market] = 'WIN' AND g.[result_win] IS NULL)
                    )
            ) THEN 1 ELSE 0 END AS [has_pending_ticket_result],
            CASE WHEN EXISTS (
                SELECT 1
                FROM [dbo].[bet_ticket_esport] t
                WHERE t.[match_id] = m.[match_id]
                    AND ISNULL(t.[clear], 0) = 0
            ) THEN 1 ELSE 0 END AS [has_uncleared_ticket],
            (SELECT COUNT(*) FROM [dbo].[bet_esport_game] g WHERE g.[match_id] = m.[match_id]) AS [total_games],
            (SELECT COUNT(*) FROM [dbo].[bet_esport_game] g WHERE g.[match_id] = m.[match_id] AND g.[game_no] BETWEEN 1 AND 5) AS [live_game_count],
            m.[created_by],
            m.[created_by] AS [user_host],
            ISNULL(u.[comment], '') AS [host_name],
            m.[created_at],
            m.[updated_by],
            m.[updated_at]
        FROM [dbo].[bet_esport_match] m
        LEFT JOIN [dbo].[bet_season] s ON s.[season] = m.[season]
        LEFT JOIN [dbo].[bet_team] th ON th.[team] = m.[home]
        LEFT JOIN [dbo].[bet_team] tw ON tw.[team] = m.[way]
        LEFT JOIN [dbo].[vsysuserinfo] u ON u.[id] = m.[created_by]
    )
    SELECT
        [match_id],
        [season],
        [season_name],
        [home],
        [home_name],
        [way],
        [way_name],
        [match_time],
        CASE
            WHEN GETDATE() < [match_time] THEN 2
            WHEN [has_pending_ticket_result] = 1 AND GETDATE() < DATEADD(MINUTE, [live_game_count] * 30, [match_time]) THEN 1
            WHEN [has_pending_ticket_result] = 1 THEN 3
            WHEN [has_uncleared_ticket] = 1 THEN 4
            ELSE 5
        END AS [status],
        CASE
            WHEN GETDATE() < [match_time] THEN N'Sắp tới'
            WHEN [has_pending_ticket_result] = 1 AND GETDATE() < DATEADD(MINUTE, [live_game_count] * 30, [match_time]) THEN N'Trực tiếp'
            WHEN [has_pending_ticket_result] = 1 THEN N'Chờ kết quả'
            WHEN [has_uncleared_ticket] = 1 THEN N'Chưa tất toán'
            ELSE N'Kết thúc'
        END AS [statusname],
		ROW_NUMBER()OVER(ORDER BY CASE
            WHEN GETDATE() < [match_time] THEN 2
            WHEN [has_pending_ticket_result] = 1 AND GETDATE() < DATEADD(MINUTE, [live_game_count] * 30, [match_time]) THEN 1
            WHEN [has_pending_ticket_result] = 1 THEN 3
            WHEN [has_uncleared_ticket] = 1 THEN 4
            ELSE 5
        END, ABS(DATEDIFF(MINUTE, [match_time], GETDATE())), [match_id]) AS xKey,
        [total_games],
        [created_by],
        [user_host],
        [host_name],
        [created_at],
        [updated_by],
        [updated_at]
    FROM match_data
GO
