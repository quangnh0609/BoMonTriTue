using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Globalization;
using System.Linq;

public static class ApiFootballResults
{
    public sealed class LocalMatch
    {
        public string Id, Name, Status, Home, Away, League;
        public DateTime Kickoff;
        public string Time { get { return Kickoff.ToString("HH:mm dd/MM/yyyy", CultureInfo.InvariantCulture); } }
    }

    public sealed class Outcome
    {
        public string Id, Name, Message;
        public bool Updated;
    }

    private sealed class MarketResult
    {
        public string Code, Home, Away;
        public bool HasTicket;
    }

    private static readonly TimeSpan LocalOffset = TimeSpan.FromHours(7);
    private static readonly Dictionary<string, string> MarketLabels = new Dictionary<string, string> {
        { "h1_goal", "bàn hiệp 1" }, { "ft_goal", "bàn cả trận" },
        { "h1_conner", "góc hiệp 1" }, { "ft_conner", "góc cả trận" },
        { "h1_card", "thẻ hiệp 1" }, { "ft_card", "thẻ cả trận" }
    };

    public static List<LocalMatch> List(SqlConnection conn, SqlTransaction tx, IList<string> ids)
    {
        using (var cmd = new SqlCommand(@"SELECT m.match, m.time, m.statusname, m.name,
    COALESCE(NULLIF(LTRIM(RTRIM(h.api_football_name)), ''), NULLIF(h.team_name, ''), m.home) AS home_name,
    COALESCE(NULLIF(LTRIM(RTRIM(w.api_football_name)), ''), NULLIF(w.team_name, ''), m.way) AS away_name,
    COALESCE(NULLIF(LTRIM(RTRIM(s.api_football_name)), ''), NULLIF(s.season_name, ''), m.season) AS league_name,
    COALESCE(NULLIF(h.team_name, ''), m.home) + N' - ' + COALESCE(NULLIF(w.team_name, ''), m.way) AS display_name
FROM dbo.vbet_match_total m
LEFT JOIN dbo.bet_team h ON h.team = m.home
LEFT JOIN dbo.bet_team w ON w.team = m.way
LEFT JOIN dbo.bet_season s ON s.season = m.season
WHERE m.status IN (1, 3)", conn, tx))
        {
            if (ids != null)
            {
                var names = new List<string>();
                foreach (string id in ids)
                {
                    string name = "@id" + names.Count;
                    cmd.Parameters.Add(name, SqlDbType.VarChar, 16).Value = id;
                    names.Add(name);
                }
                cmd.CommandText += " AND m.match IN (" + String.Join(",", names) + ")";
            }
            cmd.CommandText += " ORDER BY m.time DESC, m.match";
            var matches = new List<LocalMatch>();
            using (var reader = cmd.ExecuteReader())
                while (reader.Read())
                    matches.Add(new LocalMatch {
                        Id = reader["match"].ToString(), Kickoff = (DateTime)reader["time"],
                        Name = Convert.ToString(reader["display_name"] == DBNull.Value ? reader["name"] : reader["display_name"]),
                        Status = reader["statusname"].ToString(), Home = reader["home_name"].ToString(),
                        Away = reader["away_name"].ToString(), League = reader["league_name"].ToString()
                    });
            return matches;
        }
    }

    public static List<Outcome> Import(string connection, int user, List<string> ids)
    {
        if (ids.Any(id => id.Length > 16)) throw new InvalidOperationException("Mã trận không hợp lệ.");
        using (var conn = new SqlConnection(connection))
        {
            conn.Open();
            var matches = List(conn, null, ids);
            bool supportsServe = MatchResultSave.SupportsServe(conn, null);
            var outcomes = ids.Except(matches.Select(m => m.Id)).Select(id => new Outcome {
                Id = id, Name = id, Message = "Trận không còn ở trạng thái Trực tiếp hoặc Chờ kết quả."
            }).ToList();
            foreach (var day in matches.GroupBy(m => m.Kickoff.Date))
            {
                List<Dictionary<string, object>> rows;
                try { rows = ApiFootballImport.FixturesOn(day.Key).ToList(); }
                catch (InvalidOperationException ex)
                {
                    outcomes.AddRange(day.Select(m => new Outcome { Id = m.Id, Name = m.Name, Message = ex.Message }));
                    continue;
                }
                var fixtures = rows.Select(row => new { Row = row, Match = ApiFootballImport.ReadFixture(row) })
                    .Where(f => f.Match != null && f.Match.Id != "").ToList();
                foreach (var match in day)
                {
                    var outcome = new Outcome { Id = match.Id, Name = match.Name };
                    outcomes.Add(outcome);
                    try
                    {
                        var candidates = fixtures.Where(f => ApiFootballImport.LocalMatchId(f.Match.Id) == match.Id).ToList();
                        if (candidates.Count == 0) candidates = fixtures.Where(f => IsSameMatch(match, f.Match)).ToList();
                        if (candidates.Count != 1)
                            throw new InvalidOperationException(candidates.Count == 0 ? "Không tìm thấy trận khớp trên API-Football. Kiểm tra giải, đội và giờ thi đấu." : "Có nhiều trận API-Football trùng thông tin.");

                        var candidate = candidates[0];
                        string status = ApiFootballImport.FixtureStatus(candidate.Row);
                        if (status != "FT" && status != "AET" && status != "PEN")
                            throw new InvalidOperationException("API-Football chưa có kết quả chung cuộc (" + status + ").");

                        var values = ReadScore(candidate.Row);
                        var markets = ReadMarkets(conn, null, match.Id);
                        bool needsStats = MatchResultSave.Markets.Any(group =>
                            !group.Key.EndsWith("_goal", StringComparison.Ordinal) &&
                            markets.Any(m => group.Value.Contains(m.Code) && m.Home == "" && m.Away == ""));
                        string statsError = "";
                        if (needsStats)
                        {
                            try
                            {
                                var data = ApiFootballImport.Get("fixtures/statistics?fixture=" + Uri.EscapeDataString(candidate.Match.Id) + "&half=true", 90);
                                AddStatistics(values, WebMatchImport.Rows(data["response"]), candidate.Match, status);
                            }
                            catch (InvalidOperationException ex) { statsError = " " + ex.Message; }
                        }
                        Save(conn, user, match, values, supportsServe, outcome);
                        outcome.Message += statsError;
                    }
                    catch (InvalidOperationException ex) { outcome.Message = ex.Message; }
                    catch (Exception ex)
                    {
                        System.Diagnostics.Trace.TraceError("API-Football result for {0}: {1}", match.Id, ex);
                        outcome.Message = "Không thể cập nhật trận này. Vui lòng thử lại hoặc nhập kết quả thủ công.";
                    }
                }
            }
            return outcomes;
        }
    }

    public static bool IsSameMatch(LocalMatch local, WebMatchImport.Fixture fixture)
    {
        return Math.Abs((fixture.Kickoff.ToOffset(LocalOffset).DateTime - local.Kickoff).TotalSeconds) < 60 &&
            SameName(local.Home, fixture.Home) && SameName(local.Away, fixture.Away) && SameName(local.League, fixture.League);
    }

    private static bool SameName(string left, string right)
    {
        return !String.IsNullOrWhiteSpace(left) && !String.IsNullOrWhiteSpace(right) &&
            String.Equals(left.Trim(), right.Trim(), StringComparison.OrdinalIgnoreCase);
    }

    public static Dictionary<string, object> ReadScore(Dictionary<string, object> row)
    {
        var values = new Dictionary<string, object>();
        var score = Child(row, "score");
        var half = Child(score, "halftime");
        var full = Child(score, "fulltime");
        AddPair(values, "h1_goal", ReadCount(half, "home"), ReadCount(half, "away"));
        AddPair(values, "ft_goal", ReadCount(full, "home"), ReadCount(full, "away"));
        return values;
    }

    public static void AddStatistics(Dictionary<string, object> values, IEnumerable<Dictionary<string, object>> statistics,
        WebMatchImport.Fixture match, string status)
    {
        var teams = statistics.ToList();
        var home = teams.Where(t => WebMatchImport.Str(Child(t, "team"), "id") == match.HomeId).ToList();
        var away = teams.Where(t => WebMatchImport.Str(Child(t, "team"), "id") == match.AwayId).ToList();
        if (home.Count != 1 || away.Count != 1 || match.HomeId == "" || match.HomeId == match.AwayId) return;
        var h = home[0];
        var a = away[0];
        AddPair(values, "h1_conner", Stat(h, "statistics_1h", "Corner Kicks"), Stat(a, "statistics_1h", "Corner Kicks"));
        AddPair(values, "h1_card", Cards(h, "statistics_1h"), Cards(a, "statistics_1h"));
        if (status == "FT")
        {
            AddPair(values, "ft_conner", Stat(h, "statistics", "Corner Kicks"), Stat(a, "statistics", "Corner Kicks"));
            AddPair(values, "ft_card", Cards(h, "statistics"), Cards(a, "statistics"));
        }
        else
        {
            AddPair(values, "ft_conner", Stat(h, "statistics_1h", "Corner Kicks") + Stat(h, "statistics_2h", "Corner Kicks"),
                Stat(a, "statistics_1h", "Corner Kicks") + Stat(a, "statistics_2h", "Corner Kicks"));
            AddPair(values, "ft_card", Cards(h, "statistics_1h") + Cards(h, "statistics_2h"),
                Cards(a, "statistics_1h") + Cards(a, "statistics_2h"));
        }
    }

    private static Dictionary<string, object> Child(Dictionary<string, object> row, string key)
    {
        object raw;
        var value = row.TryGetValue(key, out raw) ? raw as Dictionary<string, object> : null;
        return value ?? new Dictionary<string, object>();
    }

    private static int? ReadCount(Dictionary<string, object> row, string key)
    {
        int value;
        return Int32.TryParse(WebMatchImport.Str(row, key), NumberStyles.None, CultureInfo.InvariantCulture, out value)
            ? (int?)value : null;
    }

    private static int? Stat(Dictionary<string, object> team, string period, string name)
    {
        object raw;
        if (!team.TryGetValue(period, out raw) || !(raw is System.Collections.IList)) return null;
        var rows = WebMatchImport.Rows(raw).Where(r => WebMatchImport.Str(r, "type") == name).ToList();
        return rows.Count == 1 ? ReadCount(rows[0], "value") : null;
    }

    private static int? Cards(Dictionary<string, object> team, string period)
    {
        // Red/second-yellow settlement depends on the market rules. Only use unambiguous yellow-only counts.
        return Stat(team, period, "Red Cards") == 0 ? Stat(team, period, "Yellow Cards") : null;
    }

    private static void AddPair(Dictionary<string, object> values, string market, int? home, int? away)
    {
        if (!home.HasValue || !away.HasValue) return;
        values[market + "_home"] = home.Value;
        values[market + "_way"] = away.Value;
    }

    private static List<MarketResult> ReadMarkets(SqlConnection conn, SqlTransaction tx, string match)
    {
        string table = tx == null ? "dbo.bet_match m" : "dbo.bet_match m WITH (UPDLOCK, HOLDLOCK)";
        using (var cmd = new SqlCommand(@"SELECT m.code, m.result_home, m.result_way,
CAST(CASE WHEN EXISTS (SELECT 1 FROM dbo.bet_ticket t WHERE t.match=m.match AND t.code=m.code) THEN 1 ELSE 0 END AS bit)
FROM " + table + " WHERE m.match = @match", conn, tx))
        {
            cmd.Parameters.Add("@match", SqlDbType.VarChar, 16).Value = match;
            var rows = new List<MarketResult>();
            using (var reader = cmd.ExecuteReader())
                while (reader.Read())
                    rows.Add(new MarketResult {
                        Code = reader.GetString(0).Trim(), Home = Convert.ToString(reader.GetValue(1), CultureInfo.InvariantCulture),
                        Away = Convert.ToString(reader.GetValue(2), CultureInfo.InvariantCulture), HasTicket = reader.GetBoolean(3)
                    });
            return rows;
        }
    }

    private static void Save(SqlConnection conn, int user, LocalMatch original, Dictionary<string, object> fetched,
        bool supportsServe, Outcome outcome)
    {
        using (var tx = conn.BeginTransaction())
        {
            var rows = ReadMarkets(conn, tx, original.Id);
            var current = List(conn, tx, new[] { original.Id }).SingleOrDefault();
            if (current == null || current.Kickoff != original.Kickoff || current.Home != original.Home ||
                current.Away != original.Away || current.League != original.League)
                throw new InvalidOperationException("Thông tin hoặc trạng thái trận đã thay đổi. Vui lòng mở lại danh sách.");

            var values = new Dictionary<string, object>();
            var updated = new List<string>();
            var missing = new List<string>();
            foreach (var group in MatchResultSave.Markets)
            {
                var markets = rows.Where(r => group.Value.Contains(r.Code)).ToList();
                if (markets.Count == 0) continue;
                string homeKey = group.Key + "_home", awayKey = group.Key + "_way";
                var first = markets[0];
                if (markets.Any(m => m.Home != first.Home || m.Away != first.Away))
                    throw new InvalidOperationException("Các kèo cùng loại có kết quả khác nhau. Kiểm tra trận trong nút Kết quả.");
                if (first.Home == "" && first.Away == "" && fetched.ContainsKey(homeKey))
                {
                    values[homeKey] = fetched[homeKey];
                    values[awayKey] = fetched[awayKey];
                    updated.Add(MarketLabels[group.Key] + " " + values[homeKey] + "–" + values[awayKey]);
                }
                else
                {
                    values[homeKey] = first.Home;
                    values[awayKey] = first.Away;
                    if ((first.Home == "" || first.Away == "") && markets.Any(m => m.HasTicket))
                        missing.Add(MarketLabels[group.Key]);
                }
            }
            if (rows.Any(r => r.Code == "71" && r.HasTicket && (r.Home == "" || r.Away == "")))
                missing.Add("giao bóng");
            if (rows.Any(r => r.HasTicket && r.Code != "71" && !MatchResultSave.Markets.Values.Any(codes => codes.Contains(r.Code))))
                missing.Add("kèo nhập thủ công");

            if (updated.Count > 0)
            {
                if (supportsServe && rows.Any(r => r.Code == "71" && (r.Home != "" || r.Away != "")))
                    values["serve_result"] = ReadServe(conn, tx, original.Id);
                var result = MatchResultSave.Run(conn, tx, original.Id, user, values, supportsServe);
                if (Convert.ToInt32(result["isSuccess"]) != 1) throw new InvalidOperationException(Convert.ToString(result["msg"]));
                tx.Commit();
                outcome.Updated = true;
            }
            string remaining = missing.Count == 0 ? "" : " Cần kiểm tra trong nút Kết quả: " + String.Join(", ", missing) + ".";
            outcome.Message = (outcome.Updated ? "Đã lưu " + String.Join(", ", updated) + "." : "Không có kết quả mới để lưu.") + remaining;
        }
    }

    private static string ReadServe(SqlConnection conn, SqlTransaction tx, string id)
    {
        using (var cmd = new SqlCommand("dbo.bet_match_result", conn, tx))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@match", id);
            using (var reader = cmd.ExecuteReader())
            {
                if (reader.Read())
                    for (int i = 0; i < reader.FieldCount; i++)
                        if (String.Equals(reader.GetName(i), "serve_result", StringComparison.OrdinalIgnoreCase))
                        {
                            string value = reader.GetValue(i).ToString();
                            if (value == "H" || value == "W") return value;
                        }
            }
        }
        throw new InvalidOperationException("Không đọc được kết quả giao bóng đã lưu.");
    }
}
