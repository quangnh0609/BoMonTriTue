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
        DateTime today = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7)).Date;
        var dates = WebMatchImport.SelectedDates(input, today);
        DateTime from = dates.Min(), to = dates.Max().AddDays(1).AddSeconds(-1);
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
            return dates.Contains(time.ToOffset(TimeSpan.FromHours(7)).Date) && time > DateTimeOffset.UtcNow;
        }).ToList();
        foreach (var item in events)
        {
            string id = WebMatchImport.Str(item, "id");
            var raw = item;
            string home = WebMatchImport.Str(raw, "home_team"), away = WebMatchImport.Str(raw, "away_team");
            result[id] = new WebMatchImport.Fixture { Id = id, League = WebMatchImport.Str(raw, "sport_title"), LeagueId = league, Season = "", Home = home, Away = away, HomeId = home, AwayId = away, Kickoff = DateTimeOffset.Parse(WebMatchImport.Str(raw, "commence_time"), CultureInfo.InvariantCulture) };
        }
        Session["WebMatchResults"] = result;
        Session["WebMatchExpires"] = DateTime.UtcNow.AddMinutes(15);
        string snapshot = Guid.NewGuid().ToString("N"); Session["WebMatchSnapshot"] = snapshot;
        Reply(new { ok = true, snapshot = snapshot, matches = result.Values.OrderBy(f => f.Kickoff).ToList() });
    }
    List<Dictionary<string, object>> EntityOptions(SqlConnection conn, SqlTransaction tx, string table, string column, string where, string value, bool includeInactive = false)
    {
        var rows = new List<Dictionary<string, object>>();
        using (var cmd = new SqlCommand("SELECT RTRIM(" + column + ") AS id, " + column + "_name AS name FROM dbo." + table + " WITH (UPDLOCK,HOLDLOCK) " + (where == "" ? "WHERE " : where + " AND ") + (includeInactive ? "1=1" : "is_active=1") + " ORDER BY " + column, conn, tx))
        {
            if (value != null) cmd.Parameters.AddWithValue("@value", value);
            using (var reader = cmd.ExecuteReader()) while (reader.Read())
                rows.Add(new Dictionary<string, object> { { "id", reader["id"].ToString() }, { "name", reader["name"].ToString() } });
        }
        return rows;
    }
    Dictionary<string, string> ResolveEntities(SqlConnection conn, SqlTransaction tx, IEnumerable<WebMatchImport.Fixture> fixtures, Dictionary<string, object> input)
    {
        object raw;
        var choices = input.TryGetValue("teamChoices", out raw) ? raw as Dictionary<string, object> : null;
        var codes = input.TryGetValue("newTeamCodes", out raw) ? raw as Dictionary<string, object> : null;
        var sources = new Dictionary<string, string>();
        foreach (var f in fixtures)
        {
            sources["team:" + f.Home] = f.Home; sources["team:" + f.Away] = f.Away;
            sources["league:" + f.League] = f.League;
        }
        var resolved = new Dictionary<string, string>();
        var missing = new List<object>();
        var pending = new List<Action>();
        var newCodes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var targets = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var entry in sources)
        {
            bool team = entry.Key.StartsWith("team:");
            string kind = team ? "đội" : "giải", table = team ? "bet_team" : "bet_season", column = team ? "team" : "season";
            string selected = choices == null ? "" : WebMatchImport.Str(choices, entry.Key);
            if (entry.Value.Length > 128) throw new InvalidOperationException("Tên " + kind + " vượt quá 128 ký tự.");
            if (selected == "")
            {
                var exact = EntityOptions(conn, tx, table, column, "WHERE " + column + "_name=@value", entry.Value);
                if (exact.Count > 0) { resolved[entry.Key] = WebMatchImport.Str(exact[0], "id"); continue; }
                string pattern = "%" + WebMatchImport.LikeLiteral(entry.Value) + "%";
                var candidates = EntityOptions(conn, tx, table, column, "WHERE " + column + "_name LIKE @value ESCAPE '~'", pattern);
                var all = EntityOptions(conn, tx, table, column, "", null);
                missing.Add(new { key = entry.Key, name = entry.Value, kind = kind, candidates = candidates, allOptions = all });
                continue;
            }
            if (selected == "__new__")
            {
                string code = codes == null ? "" : WebMatchImport.Str(codes, entry.Key).Trim();
                if (!System.Text.RegularExpressions.Regex.IsMatch(code, @"^[A-Za-z0-9_-]{1,16}$"))
                    throw new InvalidOperationException("Nhập mã " + kind + " cho " + entry.Value + ": 1–16 ký tự, gồm chữ không dấu, số, dấu - hoặc _.");
                if (!newCodes.Add(column + ":" + code)) throw new InvalidOperationException("Mã " + kind + " " + code + " bị trùng trong lần tạo này.");
                if (EntityOptions(conn, tx, table, column, "WHERE " + column + "=@value", code, true).Count > 0)
                    throw new InvalidOperationException("Mã " + kind + " " + code + " đã tồn tại. Chọn bản ghi đang có hoặc nhập mã khác.");
                resolved[entry.Key] = code;
                string sourceName = entry.Value;
                pending.Add(() => {
                    using (var cmd = new SqlCommand("INSERT INTO dbo." + table + " (" + column + "," + column + "_name) VALUES (@code,@name)", conn, tx))
                    { cmd.Parameters.AddWithValue("@code", code); cmd.Parameters.AddWithValue("@name", sourceName); cmd.ExecuteNonQuery(); }
                });
            }
            else
            {
                var found = EntityOptions(conn, tx, table, column, "WHERE " + column + "=@value", selected);
                if (found.Count == 0) throw new InvalidOperationException("Bản ghi " + kind + " được chọn không còn tồn tại. Vui lòng chọn lại.");
                string code = WebMatchImport.Str(found[0], "id"), sourceName = entry.Value;
                string target = column + ":" + code;
                if (targets.ContainsKey(target) && targets[target] != sourceName)
                    throw new InvalidOperationException("Không thể gán nhiều tên nguồn khác nhau cho cùng mã " + kind + " " + code + " trong một lần tạo.");
                targets[target] = sourceName; resolved[entry.Key] = code;
                pending.Add(() => {
                    using (var cmd = new SqlCommand("UPDATE dbo." + table + " SET " + column + "_name=@name WHERE " + column + "=@code", conn, tx))
                    { cmd.Parameters.AddWithValue("@code", code); cmd.Parameters.AddWithValue("@name", sourceName); cmd.ExecuteNonQuery(); }
                });
            }
        }
        if (missing.Count > 0)
        {
            Reply(new { ok = true, needsTeams = true, requiredTeams = missing });
            return null;
        }
        foreach (var write in pending) write();
        return resolved;
    }
    void Create(Dictionary<string, object> input)
    {
        var results = Session["WebMatchResults"] as Dictionary<string, WebMatchImport.Fixture>;
        if (results == null || Session["WebMatchExpires"] == null || DateTime.UtcNow > (DateTime)Session["WebMatchExpires"] || WebMatchImport.Str(input, "snapshot") != Convert.ToString(Session["WebMatchSnapshot"]))
            throw new InvalidOperationException("Danh sách đã hết hạn hoặc thay đổi. Vui lòng lọc lại.");
        var ids = WebMatchImport.SelectedIds(input);
        if (ids.Count == 0 || ids.Count > 100 || ids.Any(id => !results.ContainsKey(id))) throw new InvalidOperationException("Chọn từ 1 đến 100 trận trong danh sách.");
        // Fetch odds only for the explicit selection, before opening a database transaction.
        foreach (string id in ids)
        {
            var f = results[id];
            if (!WebMatchImport.IsAllowedLeague(f.LeagueId) || f.Kickoff <= DateTimeOffset.UtcNow)
                throw new InvalidOperationException("Có trận đã bắt đầu hoặc giải không được hỗ trợ. Vui lòng lọc lại.");
        }
        foreach (string id in ids)
        {
            var f = results[id];
            if (f.Markets.Count > 0) continue;
            var raw = WebMatchImport.Obj(WebMatchImport.CachedGet("sports/" + f.LeagueId + "/events/" + Uri.EscapeDataString(id) + "/odds?regions=eu&markets=h2h,spreads,totals,h2h_h1,spreads_h1,totals_h1,alternate_spreads_corners,alternate_totals_corners,alternate_spreads_cards,alternate_totals_cards&oddsFormat=decimal&dateFormat=iso", 120));
            if (WebMatchImport.Str(raw, "home_team") != f.Home || WebMatchImport.Str(raw, "away_team") != f.Away)
                throw new InvalidOperationException("Thông tin trận đã thay đổi. Vui lòng lọc lại.");
            f.Kickoff = DateTimeOffset.Parse(WebMatchImport.Str(raw, "commence_time"), CultureInfo.InvariantCulture);
            f.Markets = WebMatchImport.SelectMarkets(WebMatchImport.Rows(raw["bookmakers"]), f.Home, f.Away);
            WebMatchImport.ApplyFirstHalfRules(f.Markets);
            if (f.Markets.Count == 0)
                throw new InvalidOperationException("Trận " + f.Home + " – " + f.Away + " chưa có kèo phù hợp. Bỏ chọn trận này và thử lại.");
        }
        using (var conn = new SqlConnection(Connection))
        {
            conn.Open(); using (var tx = conn.BeginTransaction(IsolationLevel.Serializable))
            {
                var resolvedTeams = ResolveEntities(conn, tx, ids.Select(id => results[id]), input);
                if (resolvedTeams == null) return;
                foreach (string id in ids)
                {
                    var f = results[id];
                    if (!WebMatchImport.IsAllowedLeague(f.LeagueId)) throw new InvalidOperationException("Danh sách có giải không được hỗ trợ. Vui lòng lọc lại.");
                    if (f.Kickoff <= DateTimeOffset.UtcNow) throw new InvalidOperationException("Có trận đã bắt đầu. Vui lòng lọc lại.");
                    string season = resolvedTeams["league:" + f.League];
                    string homeKey = "team:" + f.Home, awayKey = "team:" + f.Away;
                    string home = resolvedTeams[homeKey], away = resolvedTeams[awayKey];
                    CatalogState.RequireActive(conn, tx, season, new[] { home, away });
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
                    // Same default as the manual bet_match_insert procedure: kickoff, handicap 0, both sides 1.
                    using (var cmd = new SqlCommand(@"INSERT INTO dbo.bet_match (match,season,time,home,way,code,handicap,home_win,way_win)
                        VALUES (@id,@season,@time,@home,@away,'71',0,1,1)", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", WebMatchImport.CompactId("OM", id)); cmd.Parameters.AddWithValue("@season", season);
                        cmd.Parameters.AddWithValue("@time", f.Kickoff.ToOffset(TimeSpan.FromHours(7)).DateTime);
                        cmd.Parameters.AddWithValue("@home", home); cmd.Parameters.AddWithValue("@away", away); cmd.ExecuteNonQuery();
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
