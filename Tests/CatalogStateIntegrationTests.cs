using System;
using System.Data.SqlClient;
using System.Xml;

// Compile alongside App_Code/CatalogState.cs. Changes are always rolled back.
public static class CatalogStateIntegrationTests
{
    static void Check(bool condition, string message) { if (!condition) throw new Exception(message); }
    static object Scalar(SqlConnection c, SqlTransaction tx, string sql, string code)
    {
        using (var cmd = new SqlCommand(sql, c, tx))
        { if (code != null) cmd.Parameters.AddWithValue("@code", code); return cmd.ExecuteScalar(); }
    }
    static void Rejected(SqlConnection c, SqlTransaction tx, string season, string team)
    {
        bool rejected = false;
        try { CatalogState.RequireActive(c, tx, season, new[] { team }); }
        catch (InvalidOperationException) { rejected = true; }
        Check(rejected, "Inactive/missing selection must be rejected.");
    }
    public static int Main()
    {
        var config = new XmlDocument(); config.Load("Program/web.config");
        var builder = new SqlConnectionStringBuilder(config.SelectSingleNode("/configuration/connectionStrings/add[@name='MyDbConn']").Attributes["connectionString"].Value);
        builder.ConnectTimeout = 5;
        using (var c = new SqlConnection(builder.ConnectionString))
        {
            c.Open();
            using (var tx = c.BeginTransaction())
            {
                try
                {
                    string team = Convert.ToString(Scalar(c, tx, "SELECT TOP 1 RTRIM(team) FROM dbo.bet_team WHERE is_active=1 ORDER BY team", null));
                    string season = Convert.ToString(Scalar(c, tx, "SELECT TOP 1 RTRIM(season) FROM dbo.bet_season WHERE is_active=1 ORDER BY season", null));
                    Check(team != "" && season != "", "Need active catalog records for integration test.");
                    var teamName = Scalar(c, tx, "SELECT team_name FROM dbo.bet_team WHERE team=@code", team);
                    var seasonName = Scalar(c, tx, "SELECT season_name FROM dbo.bet_season WHERE season=@code", season);
                    var historicalRows = Scalar(c, tx, "SELECT COUNT_BIG(*) FROM dbo.bet_match", null);
                    CatalogState.RequireActive(c, tx, season, new[] { team });
                    Scalar(c, tx, "UPDATE dbo.bet_team SET is_active=0 WHERE team=@code; SELECT 1", team);
                    Rejected(c, tx, season, team);
                    Check(Convert.ToInt32(Scalar(c, tx, "SELECT COUNT(*) FROM dbo.bet_team WHERE team=@code AND is_active=1", team)) == 0, "Hide team in selection.");
                    Check(Equals(teamName, Scalar(c, tx, "SELECT team_name FROM dbo.bet_team WHERE team=@code", team)), "Keep historical team name.");
                    Scalar(c, tx, "UPDATE dbo.bet_team SET is_active=1 WHERE team=@code; SELECT 1", team);
                    Scalar(c, tx, "UPDATE dbo.bet_season SET is_active=0 WHERE season=@code; SELECT 1", season);
                    Rejected(c, tx, season, team);
                    Check(Convert.ToInt32(Scalar(c, tx, "SELECT COUNT(*) FROM dbo.bet_season WHERE season=@code AND is_active=1", season)) == 0, "Hide season in selection.");
                    Check(Equals(seasonName, Scalar(c, tx, "SELECT season_name FROM dbo.bet_season WHERE season=@code", season)), "Keep historical season name.");
                    Scalar(c, tx, "UPDATE dbo.bet_season SET is_active=1 WHERE season=@code; SELECT 1", season);
                    CatalogState.RequireActive(c, tx, season, new[] { team });
                    Rejected(c, tx, season, "_MISSING_001_");
                    Rejected(c, tx, "_MISSING_001_", team);
                    Check(Equals(historicalRows, Scalar(c, tx, "SELECT COUNT_BIG(*) FROM dbo.bet_match", null)), "Do not delete historical matches.");
                    Console.WriteLine("SQL catalog checks passed: active accepted; hidden/missing rejected; names/history preserved; reactivation accepted. Rolled back all test state changes.");
                }
                finally { tx.Rollback(); }
            }
        }
        return 0;
    }
}
