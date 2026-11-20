using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

public static class MatchResultSave
{
    public static readonly Dictionary<string, string[]> Markets = new Dictionary<string, string[]>
    {
        { "h1_conner", new[] { "01", "11" } },
        { "ft_conner", new[] { "02", "12", "03", "13" } },
        { "h1_goal", new[] { "21", "31", "41" } },
        { "ft_goal", new[] { "22", "32", "23", "33", "42", "43" } },
        { "h1_card", new[] { "51", "61" } },
        { "ft_card", new[] { "52", "62", "53", "63" } }
    };

    public static bool SupportsServe(SqlConnection conn, SqlTransaction tx)
    {
        using (var cmd = new SqlCommand(@"SELECT COUNT(*) FROM sys.parameters
WHERE object_id = OBJECT_ID(N'dbo.bet_match_result_update') AND name = '@serve_result'", conn, tx))
            return Convert.ToInt32(cmd.ExecuteScalar()) != 0;
    }

    public static Dictionary<string, object> Run(SqlConnection conn, SqlTransaction tx, string match,
        object userId, Dictionary<string, object> values, bool supportsServe)
    {
        using (var cmd = new SqlCommand("dbo.bet_match_result_update", conn, tx))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@match", match);
            cmd.Parameters.AddWithValue("@reset", true);
            foreach (string market in Markets.Keys)
            {
                cmd.Parameters.AddWithValue("@" + market + "_home", WebMatchImport.Str(values, market + "_home"));
                cmd.Parameters.AddWithValue("@" + market + "_way", WebMatchImport.Str(values, market + "_way"));
            }
            if (supportsServe) cmd.Parameters.AddWithValue("@serve_result", WebMatchImport.Str(values, "serve_result"));
            cmd.Parameters.AddWithValue("@userID", userId);
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                    return new Dictionary<string, object> {
                        { "isSuccess", reader["isSuccess"] == DBNull.Value ? 0 : Convert.ToInt32(reader["isSuccess"]) },
                        { "msg", reader["msg"] == DBNull.Value ? "Có lỗi xảy ra" : reader["msg"].ToString() }
                    };
            }
        }
        return new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", "Stored procedure không trả về kết quả" } };
    }
}
