using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;

// Selection validation only. Historical reads must keep joining the full catalogs.
public static class CatalogState
{
    public static void RequireActive(SqlConnection connection, SqlTransaction transaction, string season, IEnumerable<string> teams)
    {
        RequireCode(connection, transaction, false, season);
        foreach (string team in teams.Distinct(StringComparer.OrdinalIgnoreCase))
            RequireCode(connection, transaction, true, team);
    }
    private static void RequireCode(SqlConnection connection, SqlTransaction transaction, bool team, string code)
    {
        string table = team ? "bet_team" : "bet_season", column = team ? "team" : "season";
        using (var command = new SqlCommand("SELECT COUNT(1) FROM dbo." + table + " WITH (HOLDLOCK) WHERE " + column + "=@code AND is_active=1", connection, transaction))
        {
            command.Parameters.Add("@code", SqlDbType.VarChar, 128).Value = (code ?? "").Trim();
            if (Convert.ToInt32(command.ExecuteScalar()) == 0)
                throw new InvalidOperationException((team ? "Đội " : "Giải đấu ") + code + " không tồn tại hoặc đã ẩn. Vui lòng chọn bản ghi đang hoạt động.");
        }
    }
}
