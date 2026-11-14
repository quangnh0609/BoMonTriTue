<%@ Page Language="C#" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.Globalization" %>
<script runat="server">
    private bool webImportAdmin;
    private string source = "the-odds-api";
    bool AllowedLeague(string league) { return source == "api-football" ? ApiFootballImport.GetLeagues().Any(l => l.id == league) : WebMatchImport.IsAllowedLeague(league); }
    string MatchId(WebMatchImport.Fixture fixture) { return WebMatchImport.CompactId("OM", fixture.Source == "api-football" ? "api-football:" + fixture.Id : fixture.Id); }
    string Connection { get { return ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString; } }
    void Reply(object value)
    {
        var serializer = new System.Web.Script.Serialization.JavaScriptSerializer { MaxJsonLength = 10000000 };
        var data = serializer.Deserialize<Dictionary<string, object>>(serializer.Serialize(value));
        data["quota"] = webImportAdmin ? (source == "api-football" ? ApiFootballImport.CurrentQuota : WebMatchImport.CurrentQuota) : null;
        data["source"] = source;
        data["quotaUnit"] = source == "api-football" ? "Lượt gọi hôm nay" : "Credits còn lại";
        var today = DateTimeOffset.UtcNow.ToOffset(TimeSpan.FromHours(7));
        data["quotaResetDate"] = source == "api-football" ? "Theo hạn mức ngày của tài khoản" : new DateTime(today.Year, today.Month, 1).AddMonths(1).ToString("dd/MM/yyyy", CultureInfo.InvariantCulture);
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
            // A restored FormsAuth login can have a new session while the page still holds its old token.
            // Same-origin JSON GET exposes no data to other origins and performs no import operation.
            if (Request.HttpMethod == "GET" && Request.QueryString["action"] == "token")
            {
                Response.Cache.SetNoStore();
                if (Session["WebMatchToken"] == null) Session["WebMatchToken"] = Guid.NewGuid().ToString("N");
                Reply(new { ok = true, token = Convert.ToString(Session["WebMatchToken"]) }); return;
            }
            if (Request.HttpMethod != "POST") { Response.StatusCode = 405; throw new InvalidOperationException("Yêu cầu không hợp lệ."); }
            var input = new System.Web.Script.Serialization.JavaScriptSerializer().Deserialize<Dictionary<string, object>>(new System.IO.StreamReader(Request.InputStream).ReadToEnd());
            if (WebMatchImport.Str(input, "token") != Convert.ToString(Session["WebMatchToken"]) || Session["WebMatchToken"] == null)
            {
                Reply(new { ok = false, code = "WEB_MATCH_TOKEN_CHANGED", message = "Phiên làm việc đã thay đổi. Vui lòng tải lại trang." }); return;
            }
            string requestedSource = WebMatchImport.Str(input, "source");
            if (requestedSource != "" && requestedSource != "the-odds-api" && requestedSource != "api-football") throw new InvalidOperationException("Nguồn dữ liệu không hợp lệ.");
            if (requestedSource != "") source = requestedSource;
            if (source == "api-football") Server.ScriptTimeout = 1800;
            string action = WebMatchImport.Str(input, "action");
            if (action == "leagues")
            {
                var leagues = source == "api-football" ? ApiFootballImport.GetLeagues() : WebMatchImport.GetLeagues();
                if (source == "the-odds-api") { try { WebMatchImport.CachedGet("sports/", 120); } catch (InvalidOperationException) { } }
                Reply(new { ok = true, leagues = leagues }); return;
            }
            if (action == "search") { Search(input); return; }
            if (action == "preview") { Preview(input); return; }
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
        if (!AllowedLeague(league)) throw new InvalidOperationException("Vui lòng chọn một giải đấu trong danh sách được hỗ trợ.");
        Session.Remove("WebMatchResults");
        Session.Remove("WebMatchPreviewToken"); Session.Remove("WebMatchPreviewIds");
        var result = new Dictionary<string, WebMatchImport.Fixture>();
        if (source == "api-football") result = ApiFootballImport.Search(dates, league);
        else
        {
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
        }
        Session["WebMatchSource"] = source;
        Session["WebMatchResults"] = result;
        Session["WebMatchExpires"] = DateTime.UtcNow.AddMinutes(15);
        string snapshot = Guid.NewGuid().ToString("N"); Session["WebMatchSnapshot"] = snapshot;
        Reply(new { ok = true, snapshot = snapshot, matches = result.Values.OrderBy(f => f.Kickoff).ToList() });
    }
    List<Dictionary<string, object>> EntityOptions(SqlConnection conn, SqlTransaction tx, string table, string column, string where, string value, bool includeInactive = false)
    {
        var rows = new List<Dictionary<string, object>>();
        using (var cmd = new SqlCommand("SELECT RTRIM(" + column + ") AS id, " + column + "_name AS name, the_odds_api_name, api_football_name FROM dbo." + table + " WITH (UPDLOCK,HOLDLOCK) " + (where == "" ? "WHERE " : where + " AND ") + (includeInactive ? "1=1" : "is_active=1") + " ORDER BY " + column, conn, tx))
        {
            if (value != null) cmd.Parameters.AddWithValue("@value", value);
            using (var reader = cmd.ExecuteReader()) while (reader.Read())
                rows.Add(new Dictionary<string, object> { { "id", reader["id"].ToString() }, { "name", reader["name"].ToString() }, { "theOddsApiName", reader["the_odds_api_name"].ToString() }, { "apiFootballName", reader["api_football_name"].ToString() } });
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
            string aliasColumn = source == "api-football" ? "api_football_name" : "the_odds_api_name";
            if (selected == "")
            {
                string exactWhere = "WHERE (" + column + "=@value OR " + column + "_name=@value OR the_odds_api_name=@value OR api_football_name=@value)";
                var exact = EntityOptions(conn, tx, table, column, exactWhere, entry.Value);
                if (exact.Count == 1) selected = WebMatchImport.Str(exact[0], "id");
                else
                {
                    string pattern = "%" + WebMatchImport.LikeLiteral(entry.Value) + "%";
                    string likeWhere = "WHERE (" + column + " LIKE @value ESCAPE '~' OR " + column + "_name LIKE @value ESCAPE '~' OR the_odds_api_name LIKE @value ESCAPE '~' OR api_football_name LIKE @value ESCAPE '~')";
                    var candidates = exact.Count > 1 ? exact : EntityOptions(conn, tx, table, column, likeWhere, pattern);
                    var all = EntityOptions(conn, tx, table, column, "", null);
                    missing.Add(new { key = entry.Key, name = entry.Value, kind = kind, candidates = candidates, allOptions = all });
                    continue;
                }
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
                    using (var cmd = new SqlCommand("INSERT INTO dbo." + table + " (" + column + "," + column + "_name," + aliasColumn + ") VALUES (@code,@name,@name)", conn, tx))
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
                    using (var cmd = new SqlCommand("UPDATE dbo." + table + " SET " + aliasColumn + "=@name WHERE " + column + "=@code", conn, tx))
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
    Dictionary<string, WebMatchImport.Fixture> SelectedFixtures(Dictionary<string, object> input, out List<string> ids)
    {
        var results = Session["WebMatchResults"] as Dictionary<string, WebMatchImport.Fixture>;
        if (results == null || Session["WebMatchExpires"] == null || DateTime.UtcNow > (DateTime)Session["WebMatchExpires"] || WebMatchImport.Str(input, "snapshot") != Convert.ToString(Session["WebMatchSnapshot"]))
            throw new InvalidOperationException("Danh sách đã hết hạn hoặc thay đổi. Vui lòng lọc lại.");
        if (Convert.ToString(Session["WebMatchSource"]) != source || results.Values.Any(f => f.Source != source))
            throw new InvalidOperationException("Nguồn dữ liệu đã thay đổi. Vui lòng lọc lại.");
        ids = WebMatchImport.SelectedIds(input);
        if (ids.Count == 0 || ids.Count > 100 || ids.Any(id => !results.ContainsKey(id))) throw new InvalidOperationException("Chọn từ 1 đến 100 trận trong danh sách.");
        foreach (string id in ids)
            if (!AllowedLeague(results[id].LeagueId) || results[id].Kickoff <= DateTimeOffset.UtcNow)
                throw new InvalidOperationException("Có trận đã bắt đầu hoặc giải không được hỗ trợ. Vui lòng lọc lại.");
        return results;
    }
    void LoadSelectedMarkets(Dictionary<string, WebMatchImport.Fixture> results, List<string> ids)
    {
        foreach (string id in ids)
        {
            var f = results[id];
            f.Markets.RemoveAll(m => m.Code.EndsWith("2", StringComparison.Ordinal));
            if (f.Markets.Count > 0) continue;
            if (source == "api-football") f.Markets = ApiFootballImport.LoadMarkets(f);
            else
            {
                var raw = WebMatchImport.Obj(WebMatchImport.CachedGet("sports/" + f.LeagueId + "/events/" + Uri.EscapeDataString(id) + "/odds?regions=eu&markets=h2h,spreads,totals,h2h_h1,spreads_h1,totals_h1,alternate_spreads_corners,alternate_totals_corners,alternate_spreads_cards,alternate_totals_cards&oddsFormat=decimal&dateFormat=iso", 120));
                if (WebMatchImport.Str(raw, "home_team") != f.Home || WebMatchImport.Str(raw, "away_team") != f.Away)
                    throw new InvalidOperationException("Thông tin trận đã thay đổi. Vui lòng lọc lại.");
                f.Kickoff = DateTimeOffset.Parse(WebMatchImport.Str(raw, "commence_time"), CultureInfo.InvariantCulture);
                f.Markets = WebMatchImport.SelectMarkets(WebMatchImport.Rows(raw["bookmakers"]), f.Home, f.Away);
            }
            f.Markets.RemoveAll(m => m.Code.EndsWith("2", StringComparison.Ordinal));
            WebMatchImport.ApplyFirstHalfRules(f.Markets);
            if (f.Markets.Count == 0)
                throw new InvalidOperationException("Trận " + f.Home + " – " + f.Away + " chưa có kèo phù hợp. Bỏ chọn trận này và thử lại.");
        }
    }
    void Preview(Dictionary<string, object> input)
    {
        if (source != "api-football") throw new InvalidOperationException("Xem trước này dành cho API-Football.");
        List<string> ids;
        var results = SelectedFixtures(input, out ids);
        Session.Remove("WebMatchPreviewToken");
        LoadSelectedMarkets(results, ids);
        string token = Guid.NewGuid().ToString("N");
        Session["WebMatchPreviewToken"] = token;
        Session["WebMatchPreviewIds"] = ids.OrderBy(id => id, StringComparer.Ordinal).ToArray();
        Reply(new { ok = true, previewToken = token, matches = ids.Select(id => {
            var f = results[id];
            return new { f.Id, f.Home, f.Away, f.Time, Markets = f.Markets.Where(m => m.Code != "71").Concat(new[] {
                new WebMatchImport.Market { Code = "71", Name = "Giao bóng hiệp 1", Line = 0m, Home = 1m, Away = 1m, Bookmaker = "Mặc định hệ thống" }
            }).OrderBy(m => m.Code).ToList() };
        }).ToList() });
    }
    void Create(Dictionary<string, object> input)
    {
        List<string> ids;
        var results = SelectedFixtures(input, out ids);
        if (source == "api-football")
        {
            var previewIds = Session["WebMatchPreviewIds"] as string[];
            if (Session["WebMatchPreviewToken"] == null || WebMatchImport.Str(input, "previewToken") != Convert.ToString(Session["WebMatchPreviewToken"]) ||
                previewIds == null || !previewIds.SequenceEqual(ids.OrderBy(id => id, StringComparer.Ordinal)) || ids.Any(id => results[id].Markets.Count == 0))
                throw new InvalidOperationException("Vui lòng xem trước kèo cho đúng các trận đã chọn trước khi tạo.");
        }
        else LoadSelectedMarkets(results, ids);
        if (source == "api-football")
        {
            object rawEdits;
            if (!input.TryGetValue("edits", out rawEdits)) throw new InvalidOperationException("Thiếu dữ liệu kèo đã chỉnh sửa.");
            var edited = WebMatchEdits.ParseBatch(rawEdits, results, ids);
            foreach (string id in ids) results[id].Markets = edited[id];
        }
        using (var conn = new SqlConnection(Connection))
        {
            conn.Open();
            using (var schema = new SqlCommand("SELECT CASE WHEN COL_LENGTH('dbo.bet_team','the_odds_api_name') IS NOT NULL AND COL_LENGTH('dbo.bet_team','api_football_name') IS NOT NULL AND COL_LENGTH('dbo.bet_season','the_odds_api_name') IS NOT NULL AND COL_LENGTH('dbo.bet_season','api_football_name') IS NOT NULL THEN 1 ELSE 0 END", conn))
                if (Convert.ToInt32(schema.ExecuteScalar()) != 1) throw new InvalidOperationException("Chưa cập nhật DB. Chạy migration 20261114_WebImportAliases/01_web_import_aliases.sql trước khi nhập trận.");
            using (var tx = conn.BeginTransaction(IsolationLevel.Serializable))
            {
                var resolvedTeams = ResolveEntities(conn, tx, ids.Select(id => results[id]), input);
                if (resolvedTeams == null) return;
                foreach (string id in ids)
                {
                    var f = results[id];
                    if (f.Kickoff <= DateTimeOffset.UtcNow) throw new InvalidOperationException("Có trận đã bắt đầu. Vui lòng lọc lại.");
                    string season = resolvedTeams["league:" + f.League];
                    string homeKey = "team:" + f.Home, awayKey = "team:" + f.Away;
                    string home = resolvedTeams[homeKey], away = resolvedTeams[awayKey];
                    CatalogState.RequireActive(conn, tx, season, new[] { home, away });
                    if (home == away) throw new InvalidOperationException("Hai đội của trận " + f.Home + " – " + f.Away + " không được trùng nhau.");
                    using (var cmd = new SqlCommand("SELECT COUNT(*) FROM bet_match WITH (UPDLOCK,HOLDLOCK) WHERE match=@id OR (season=@season AND home=@home AND way=@away AND time=@time)", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", MatchId(f)); cmd.Parameters.AddWithValue("@season", season); cmd.Parameters.AddWithValue("@home", home); cmd.Parameters.AddWithValue("@away", away); cmd.Parameters.AddWithValue("@time", f.Kickoff.ToOffset(TimeSpan.FromHours(7)).DateTime);
                        if (Convert.ToInt32(cmd.ExecuteScalar()) > 0) throw new InvalidOperationException("Trận " + f.Home + " – " + f.Away + " đã tồn tại. Bỏ chọn trận này và thử lại.");
                    }
                    foreach (var m in f.Markets)
                    using (var cmd = new SqlCommand(@"INSERT INTO bet_match (match,season,time,home,way,code,over_under,over_win,under_win,handicap,home_win,way_win,draw_win)
                        VALUES (@id,@season,@time,@home,@away,@code,@total,@over,@under,@handicap,@homeWin,@awayWin,@draw)", conn, tx))
                    {
                        bool total = m.Code[0] == '0' || m.Code[0] == '2' || m.Code[0] == '5', euro = m.Code[0] == '4';
                        cmd.Parameters.AddWithValue("@id", MatchId(f)); cmd.Parameters.AddWithValue("@season", season); cmd.Parameters.AddWithValue("@time", f.Kickoff.ToOffset(TimeSpan.FromHours(7)).DateTime); cmd.Parameters.AddWithValue("@home", home); cmd.Parameters.AddWithValue("@away", away); cmd.Parameters.AddWithValue("@code", m.Code);
                        cmd.Parameters.AddWithValue("@total", total ? (object)m.Line.Value : DBNull.Value);
                        cmd.Parameters.AddWithValue("@over", total ? (object)m.Home : DBNull.Value); cmd.Parameters.AddWithValue("@under", total ? (object)m.Away : DBNull.Value);
                        cmd.Parameters.AddWithValue("@handicap", !total && !euro ? (object)m.Line.Value : DBNull.Value);
                        cmd.Parameters.AddWithValue("@homeWin", !total ? (object)m.Home : DBNull.Value); cmd.Parameters.AddWithValue("@awayWin", !total ? (object)m.Away : DBNull.Value); cmd.Parameters.AddWithValue("@draw", euro ? (object)m.Draw : DBNull.Value);
                        cmd.ExecuteNonQuery();
                    }
                    // Same default as the manual bet_match_insert procedure: kickoff, handicap 0, both sides 1.
                    if (source != "api-football")
                    using (var cmd = new SqlCommand(@"INSERT INTO dbo.bet_match (match,season,time,home,way,code,handicap,home_win,way_win)
                        VALUES (@id,@season,@time,@home,@away,'71',0,1,1)", conn, tx))
                    {
                        cmd.Parameters.AddWithValue("@id", MatchId(f)); cmd.Parameters.AddWithValue("@season", season);
                        cmd.Parameters.AddWithValue("@time", f.Kickoff.ToOffset(TimeSpan.FromHours(7)).DateTime);
                        cmd.Parameters.AddWithValue("@home", home); cmd.Parameters.AddWithValue("@away", away); cmd.ExecuteNonQuery();
                    }
                    using (var cmd = new SqlCommand("UPDATE bet_match_total SET user_host=@user WHERE match=@id", conn, tx))
                    { cmd.Parameters.AddWithValue("@user", Session["UserID"]); cmd.Parameters.AddWithValue("@id", MatchId(f)); cmd.ExecuteNonQuery(); }
                }
                tx.Commit();
            }
        }
        Session.Remove("WebMatchResults"); Session.Remove("WebMatchPreviewToken"); Session.Remove("WebMatchPreviewIds"); Reply(new { ok = true, count = ids.Count });
    }
</script>
