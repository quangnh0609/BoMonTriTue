<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Globalization" %>
<script runat="server">
    private bool webImportAdmin;
    string Connection { get { return ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString; } }
    void Reply(object value)
    {
        var serializer = new System.Web.Script.Serialization.JavaScriptSerializer { MaxJsonLength = 10000000 };
        var data = serializer.Deserialize<Dictionary<string, object>>(serializer.Serialize(value));
        data["quota"] = webImportAdmin ? WebMatchImport.CurrentQuota : null;
        var today = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7));
        data["quotaResetDate"] = new DateTime(today.Year, today.Month, 1).AddMonths(1).ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
        Response.Write(serializer.Serialize(data));
    }
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        Server.ScriptTimeout = 600;
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        try
        {
            if (Session["UserID"] == null) { Response.StatusCode = 401; throw new InvalidOperationException("Vui lòng đăng nhập lại."); }
            using (var conn = new SqlConnection(Connection))
            using (var cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.userinfo2 WHERE id = @id AND admin = 1", conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = Convert.ToInt32(Session["UserID"]);
                conn.Open();
                webImportAdmin = Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
            if (!webImportAdmin)
            {
                Response.StatusCode = 403;
                Response.TrySkipIisCustomErrors = true;
                throw new InvalidOperationException("Chỉ admin được sử dụng chức năng Lấy từ web.");
            }
            using (var conn = new SqlConnection(Connection))
            using (var cmd = new SqlCommand("SELECT dbo.bet_check_right(@id, 'bet_match_insert')", conn))
            {
                conn.Open(); cmd.Parameters.AddWithValue("@id", Session["UserID"]);
                string allowed = Convert.ToString(cmd.ExecuteScalar());
                if (allowed != "1" && !allowed.Equals("true", StringComparison.OrdinalIgnoreCase)) { Response.StatusCode = 403; throw new InvalidOperationException("Bạn không có quyền tạo trận đấu."); }
            }
            if (Request.HttpMethod != "POST") { Response.StatusCode = 405; throw new InvalidOperationException("Yêu cầu không hợp lệ."); }
            var input = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<Dictionary<string, object>>(new System.IO.StreamReader(Request.InputStream).ReadToEnd());
            if (WebMatchImport.Str(input, "token") != Convert.ToString(Session["WebMatchToken"]) || Session["WebMatchToken"] == null)
                throw new InvalidOperationException("Phiên làm việc đã thay đổi. Vui lòng tải lại trang.");
            string action = WebMatchImport.Str(input, "action");
            if (action == "leagues")
            {
                var leagues = WebMatchImport.GetLeagues();
                try { WebMatchImport.CachedGet("sports/", 120); } catch (InvalidOperationException) { }
                Reply(new { ok = true, leagues = leagues }); return;
            }
            if (action == "search") { Search(input); return; }
            if (action == "create") { Create(input); return; }
            throw new InvalidOperationException("Thao tác không hợp lệ.");
        }
        catch (InvalidOperationException ex) { Reply(new { ok = false, message = ex.Message }); }
        catch (Exception ex) { System.Diagnostics.Trace.TraceError("Web match import: {0}", ex); Reply(new { ok = false, message = "Không thể xử lý dữ liệu. Vui lòng thử lại hoặc liên hệ quản trị viên." }); }
    }
    void Search(Dictionary<string, object> input)
    {
        DateTime from;
        DateTime today = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7)).Date;
        if (!DateTime.TryParseExact(WebMatchImport.Str(input, "date"), "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out from) || from < today || from > today.AddDays(6))
            throw new InvalidOperationException("Chọn ngày trong 7 ngày tính từ hôm nay.");
        DateTime to = from.AddDays(1).AddSeconds(-1);
        string league = WebMatchImport.Str(input, "league");
        if (!WebMatchImport.IsAllowedLeague(league)) throw new InvalidOperationException("Vui lòng chọn một giải đấu trong danh sách được hỗ trợ.");
        Session.Remove("WebMatchResults");
        var result = new Dictionary<string, WebMatchImport.Fixture>();
        var start = new DateTimeOffset(from, TimeSpan.FromHours(7));
        var end = new DateTimeOffset(to, TimeSpan.FromHours(7));
        string range = "&commenceTimeFrom=" + Uri.EscapeDataString(start.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ")) + "&commenceTimeTo=" + Uri.EscapeDataString(end.UtcDateTime.ToString("yyyy-MM-ddTHH:mm:ssZ"));
        string root = "sports/" + league;
        var events = WebMatchImport.Rows(WebMatchImport.CachedGet(root + "/events?dateFormat=iso" + range, 120)).ToList();
        events = events.Where(r => {
            DateTimeOffset time = DateTimeOffset.Parse(WebMatchImport.Str(r, "commence_time"), CultureInfo.InvariantCulture);
            return time >= start && time <= end && time > DateTimeOffset.UtcNow;
        }).ToList();
        foreach (var item in events)
        {
            string id = WebMatchImport.Str(item, "id");
            var raw = WebMatchImport.Obj(WebMatchImport.CachedGet(root + "/events/" + Uri.EscapeDataString(id) + "/odds?regions=eu&markets=h2h,spreads,totals,h2h_h1,spreads_h1,totals_h1,alternate_spreads_corners,alternate_totals_corners,alternate_spreads_cards,alternate_totals_cards&oddsFormat=decimal&dateFormat=iso", 120));
            string home = WebMatchImport.Str(raw, "home_team"), away = WebMatchImport.Str(raw, "away_team");
            var markets = WebMatchImport.SelectMarkets(WebMatchImport.Rows(raw["bookmakers"]), home, away);
            WebMatchImport.ApplyFirstHalfRules(markets);
            if (markets.Count == 0) continue;
            result[id] = new WebMatchImport.Fixture { Id = id, League = WebMatchImport.Str(raw, "sport_title"), LeagueId = league, Season = "", Home = home, Away = away, HomeId = home, AwayId = away, Kickoff = DateTimeOffset.Parse(WebMatchImport.Str(raw, "commence_time"), CultureInfo.InvariantCulture), Markets = markets };
        }
        Session["WebMatchResults"] = result;
        Session["WebMatchExpires"] = DateTime.UtcNow.AddMinutes(15);
        string snapshot = Guid.NewGuid().ToString("N"); Session["WebMatchSnapshot"] = snapshot;
        Reply(new { ok = true, snapshot = snapshot, matches = result.Values.OrderBy(f => f.Kickoff).ToList() });
    }
    string Entity(SqlConnection conn, SqlTransaction tx, bool team, string code, string name)
    {
        string table = team ? "bet_team" : "bet_season", column = team ? "team" : "season";
        using (var cmd = new SqlCommand("SELECT TOP 1 " + column + " FROM " + table + " WITH (UPDLOCK,HOLDLOCK) WHERE " + column + "=@code OR " + column + "_name=@name ORDER BY CASE WHEN " + column + "=@code THEN 0 ELSE 1 END", conn, tx))
        {
            cmd.Parameters.AddWithValue("@code", code); cmd.Parameters.AddWithValue("@name", name);
            object found = cmd.ExecuteScalar(); if (found != null) return found.ToString().Trim();
        }
        using (var cmd = new SqlCommand("INSERT INTO " + table + " (" + column + "," + column + "_name) VALUES (@code,@name)", conn, tx))
        { cmd.Parameters.AddWithValue("@code", code); cmd.Parameters.AddWithValue("@name", name); cmd.ExecuteNonQuery(); }
        return code;
    }
    Dictionary<string, string> ResolveTeams(SqlConnection conn, SqlTransaction tx, IEnumerable<WebMatchImport.Fixture> fixtures, Dictionary<string, object> input)
    {
        object rawChoices;
        var choices = input.TryGetValue("teamChoices", out rawChoices) ? rawChoices as Dictionary<string, object> : null;
        object rawCodes;
        var newCodes = input.TryGetValue("newTeamCodes", out rawCodes) ? rawCodes as Dictionary<string, object> : null;
        var newTeams = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var names = new Dictionary<string, string>();
        foreach (var fixture in fixtures)
        {
            names[WebMatchImport.CompactId("OT", fixture.HomeId)] = fixture.Home;
            names[WebMatchImport.CompactId("OT", fixture.AwayId)] = fixture.Away;
        }
        var resolved = new Dictionary<string, string>();
        var missing = new List<object>();
        foreach (var entry in names)
        {
            string selected = choices == null ? "" : WebMatchImport.Str(choices, entry.Key);
            if (selected != "" && selected != "__new__")
            {
                using (var cmd = new SqlCommand("SELECT team FROM dbo.bet_team WITH (UPDLOCK,HOLDLOCK) WHERE team=@team", conn, tx))
                {
                    cmd.Parameters.AddWithValue("@team", selected);
                    object found = cmd.ExecuteScalar();
                    if (found == null) throw new InvalidOperationException("Đội được chọn không còn tồn tại. Vui lòng chọn lại.");
                    resolved[entry.Key] = found.ToString().Trim();
                }
                continue;
            }
            var matches = new List<string>();
            using (var cmd = new SqlCommand("SELECT TOP 2 team FROM dbo.bet_team WITH (UPDLOCK,HOLDLOCK) WHERE team=@code OR team_name=@name ORDER BY CASE WHEN team=@code THEN 0 ELSE 1 END, team", conn, tx))
            {
                cmd.Parameters.AddWithValue("@code", entry.Key); cmd.Parameters.AddWithValue("@name", entry.Value);
                using (var reader = cmd.ExecuteReader()) while (reader.Read()) matches.Add(reader[0].ToString().Trim());
            }
            if (matches.Contains(entry.Key)) resolved[entry.Key] = entry.Key;
            else if (matches.Count == 1) resolved[entry.Key] = matches[0];
            else if (selected == "__new__" && matches.Count == 0)
            {
                string code = newCodes == null ? "" : WebMatchImport.Str(newCodes, entry.Key).Trim();
                if (!System.Text.RegularExpressions.Regex.IsMatch(code, @"^[A-Za-z0-9_-]{1,16}$"))
                    throw new InvalidOperationException("Nhập mã đội cho " + entry.Value + ": 1–16 ký tự, gồm chữ không dấu, số, dấu - hoặc _.");
                if (newTeams.ContainsKey(code)) throw new InvalidOperationException("Mã đội " + code + " đang được dùng cho nhiều đội mới.");
                using (var cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.bet_team WITH (UPDLOCK,HOLDLOCK) WHERE team=@code", conn, tx))
                {
                    cmd.Parameters.AddWithValue("@code", code);
                    if (Convert.ToInt32(cmd.ExecuteScalar()) > 0) throw new InvalidOperationException("Mã đội " + code + " đã tồn tại. Chọn đội đang có hoặc nhập mã khác.");
                }
                newTeams[code] = entry.Value;
                resolved[entry.Key] = code;
            }
            else missing.Add(new { key = entry.Key, name = entry.Value, ambiguous = matches.Count > 1 });
        }
        if (missing.Count > 0)
        {
            var teams = new List<object>();
            using (var cmd = new SqlCommand("SELECT RTRIM(team) AS team, team_name FROM dbo.bet_team ORDER BY team_name, team", conn, tx))
            using (var reader = cmd.ExecuteReader())
                while (reader.Read()) teams.Add(new { id = reader["team"].ToString(), name = reader["team_name"].ToString() });
            Reply(new { ok = true, needsTeams = true, requiredTeams = missing, teams = teams });
            return null;
        }
        foreach (var team in newTeams)
        using (var cmd = new SqlCommand("INSERT INTO dbo.bet_team (team,team_name) VALUES (@code,@name)", conn, tx))
        {
            cmd.Parameters.AddWithValue("@code", team.Key); cmd.Parameters.AddWithValue("@name", team.Value); cmd.ExecuteNonQuery();
        }
        return resolved;
    }
    void Create(Dictionary<string, object> input)
    {
        var results = Session["WebMatchResults"] as Dictionary<string, WebMatchImport.Fixture>;
        if (results == null || Session["WebMatchExpires"] == null || DateTime.UtcNow > (DateTime)Session["WebMatchExpires"] || WebMatchImport.Str(input, "snapshot") != Convert.ToString(Session["WebMatchSnapshot"]))
            throw new InvalidOperationException("Danh sách đã hết hạn hoặc thay đổi. Vui lòng lọc lại.");
        var ids = WebMatchImport.SelectedIds(input);
        if (ids.Count == 0 || ids.Count > 100 || ids.Any(id => !results.ContainsKey(id))) throw new InvalidOperationException("Chọn từ 1 đến 100 trận trong danh sách.");
        using (var conn = new SqlConnection(Connection))
        {
            conn.Open(); using (var tx = conn.BeginTransaction(IsolationLevel.Serializable))
            {
                var resolvedTeams = ResolveTeams(conn, tx, ids.Select(id => results[id]), input);
                if (resolvedTeams == null) return;
                foreach (string id in ids)
                {
                    var f = results[id];
                    if (!WebMatchImport.IsAllowedLeague(f.LeagueId)) throw new InvalidOperationException("Danh sách có giải không được hỗ trợ. Vui lòng lọc lại.");
                    if (f.Kickoff <= DateTimeOffset.UtcNow) throw new InvalidOperationException("Có trận đã bắt đầu. Vui lòng lọc lại.");
                    string season = Entity(conn, tx, false, WebMatchImport.CompactId("OL", f.LeagueId), f.League);
                    string homeKey = WebMatchImport.CompactId("OT", f.HomeId), awayKey = WebMatchImport.CompactId("OT", f.AwayId);
                    string home = resolvedTeams[homeKey], away = resolvedTeams[awayKey];
                    if (home == away) throw new InvalidOperationException("Hai đội của trận " + f.Home + " – " + f.Away + " không được trùng nhau.");
                    using (var cmd = new SqlCommand("SELECT COUNT(*) FROM bet_match WITH (UPDLOCK,HOLDLOCK) WHERE match=@id OR (season=@season AND home=@home AND way=@away AND time=@time)", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", WebMatchImport.CompactId("OM", id)); cmd.Parameters.AddWithValue("@season", season); cmd.Parameters.AddWithValue("@home", home); cmd.Parameters.AddWithValue("@away", away); cmd.Parameters.AddWithValue("@time", f.Kickoff.ToOffset(TimeSpan.FromHours(7)).DateTime);
                        if (Convert.ToInt32(cmd.ExecuteScalar()) > 0) throw new InvalidOperationException("Trận " + f.Home + " – " + f.Away + " đã tồn tại. Bỏ chọn trận này và thử lại.");
                    }
                    foreach (var m in f.Markets)
                    using (var cmd = new SqlCommand(@"INSERT INTO bet_match (match,season,time,home,way,code,over_under,over_win,under_win,handicap,home_win,way_win,draw_win)
                        VALUES (@id,@season,@time,@home,@away,@code,@total,@over,@under,@handicap,@homeWin,@awayWin,@draw)", conn, tx))
                    {
                        bool total = m.Code[0] == '0' || m.Code[0] == '2' || m.Code[0] == '5', euro = m.Code[0] == '4';
                        cmd.Parameters.AddWithValue("@id", WebMatchImport.CompactId("OM", id)); cmd.Parameters.AddWithValue("@season", season); cmd.Parameters.AddWithValue("@time", f.Kickoff.ToOffset(TimeSpan.FromHours(7)).DateTime); cmd.Parameters.AddWithValue("@home", home); cmd.Parameters.AddWithValue("@away", away); cmd.Parameters.AddWithValue("@code", m.Code);
                        cmd.Parameters.AddWithValue("@total", total ? (object)m.Line.Value : DBNull.Value);
                        cmd.Parameters.AddWithValue("@over", total ? (object).9m : DBNull.Value); cmd.Parameters.AddWithValue("@under", total ? (object).9m : DBNull.Value);
                        cmd.Parameters.AddWithValue("@handicap", !total && !euro ? (object)m.Line.Value : DBNull.Value);
                        cmd.Parameters.AddWithValue("@homeWin", !total ? (object)m.Home : DBNull.Value); cmd.Parameters.AddWithValue("@awayWin", !total ? (object)m.Away : DBNull.Value); cmd.Parameters.AddWithValue("@draw", euro ? (object)m.Draw : DBNull.Value);
                        cmd.ExecuteNonQuery();
                    }
                    using (var cmd = new SqlCommand("UPDATE bet_match_total SET user_host=@user WHERE match=@id", conn, tx))
                    { cmd.Parameters.AddWithValue("@user", Session["UserID"]); cmd.Parameters.AddWithValue("@id", WebMatchImport.CompactId("OM", id)); cmd.ExecuteNonQuery(); }
                }
                tx.Commit();
            }
        }
        Session.Remove("WebMatchResults"); Reply(new { ok = true, count = ids.Count });
    }
</script>
