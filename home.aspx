<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" MaintainScrollPositionOnPostBack="true" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Register Src="~/ucTicket.ascx" TagPrefix="uc" TagName="Ticket" %>
<%@ Register Src="~/ucChampionTicket.ascx" TagPrefix="uc" TagName="ChampionTicket" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Globalization" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    protected bool ShowFeeColumn = Lib.Config("ShowFeeColumn", true);
    private int? _currentUserId;
    private bool? _currentUserIsAdmin;

    protected void Page_Load(object sender, EventArgs e)
    {
		if (Session["UserName"] == null) 
		{
			Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
			return;
		}
		
        if (!IsPostBack) { 
            BindBetPrint(); 
            BindUserList(); 
        }
        
        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }

    private void BindBetPrint() {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                DataTable dt = GetBetPrintMatches(conn);
                ApplyMatchOddsHtml(conn, dt);
                try {
                    DataTable esportMatches = GetUpcomingEsportMatches(conn);
                    AppendEsportMatches(conn, dt, esportMatches);
                } catch { }
                try {
                    DataTable champions = GetUpcomingChampions(conn);
                    AppendChampionBets(dt, champions);
                } catch { }

                rptBetPrint.DataSource = GetSortedBetPrintRows(dt);
                rptBetPrint.DataBind();
            }
        } catch { }
    }

    private DataTable GetBetPrintMatches(SqlConnection conn) {
        SqlCommand cmd = new SqlCommand("bet_print", conn);
        cmd.CommandType = CommandType.StoredProcedure;

        SqlDataAdapter da = new SqlDataAdapter(cmd);
        DataTable dt = new DataTable();
        da.Fill(dt);

        AddBetPrintTypeColumn(dt);
        ApplyMatchSortValues(dt);
        FillNormalMatchHostValues(conn, dt);

        return dt;
    }

    private DataTable GetUpcomingEsportMatches(SqlConnection conn) {
        SqlCommand cmd = new SqlCommand("bet_esport_matches", conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.Add("@team", SqlDbType.Char, 16).Value = "";
        cmd.Parameters.Add("@season", SqlDbType.Char, 16).Value = "";
        cmd.Parameters.Add("@datefrom", SqlDbType.DateTime).Value = DBNull.Value;
        cmd.Parameters.Add("@dateto", SqlDbType.DateTime).Value = DBNull.Value;
        cmd.Parameters.Add("@status", SqlDbType.NVarChar).Value = "2";

        SqlDataAdapter da = new SqlDataAdapter(cmd);
        DataTable dt = new DataTable();
        da.Fill(dt);
        return dt;
    }

    private DataTable GetUpcomingChampions(SqlConnection conn) {
        SqlCommand cmd = new SqlCommand("bet_champions", conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddWithValue("@team", "");
        cmd.Parameters.AddWithValue("@season", "");
        cmd.Parameters.Add("@datefrom", SqlDbType.DateTime).Value = DBNull.Value;
        cmd.Parameters.Add("@dateto", SqlDbType.DateTime).Value = DBNull.Value;

        SqlDataAdapter da = new SqlDataAdapter(cmd);
        DataTable dt = new DataTable();
        da.Fill(dt);
        return dt;
    }

    private void AddBetPrintTypeColumn(DataTable dt) {
        if (!dt.Columns.Contains("bet_print_type")) {
            dt.Columns.Add("bet_print_type", typeof(string));
        }
        if (!dt.Columns.Contains("odds_html")) {
            dt.Columns.Add("odds_html", typeof(string));
        }
        if (!dt.Columns.Contains("sort_xKey")) {
            dt.Columns.Add("sort_xKey", typeof(int));
        }
        if (!dt.Columns.Contains("sort_time")) {
            dt.Columns.Add("sort_time", typeof(DateTime));
        }
        if (!dt.Columns.Contains("champion_season")) {
            dt.Columns.Add("champion_season", typeof(string));
        }
        if (!dt.Columns.Contains("champion_time")) {
            dt.Columns.Add("champion_time", typeof(string));
        }
        if (!dt.Columns.Contains("host_name")) {
            dt.Columns.Add("host_name", typeof(string));
        }
        if (!dt.Columns.Contains("statusname")) {
            dt.Columns.Add("statusname", typeof(string));
        }
        if (!dt.Columns.Contains("user_host")) {
            dt.Columns.Add("user_host", typeof(int));
        }
    }

    private void AppendEsportMatches(SqlConnection conn, DataTable betPrintMatches, DataTable esportMatches) {
        AddBetPrintTypeColumn(betPrintMatches);
        Dictionary<string, List<DataRow>> gamesByMatch = GetEsportGamesByMatch(conn, esportMatches);

        foreach (DataRow esport in esportMatches.Rows) {
            DataRow row = betPrintMatches.NewRow();
            row["match"] = esport["match_id"];
            row["season"] = esport["season_name"];
            row["time"] = FormatEsportMatchTime(esport["match_time"]);
            row["home"] = esport["home_name"];
            row["way"] = esport["way_name"];
            row["host_name"] = GetStringValue(esport, "host_name", "");
            row["user_host"] = GetIntValue(esport, "user_host", 0);
            row["statusname"] = GetStringValue(esport, "statusname", "Sắp tới");
            row["odds_html"] = BuildEsportOddsHtml(esport, GetRowsByKey(gamesByMatch, Convert.ToString(esport["match_id"])));
            row["bet_print_type"] = "esport";
            row["sort_xKey"] = GetIntValue(esport, "xKey", betPrintMatches.Rows.Count);
            row["sort_time"] = GetDateTimeValue(esport, "match_time", DateTime.MinValue);
            betPrintMatches.Rows.Add(row);
        }
    }

    private void AppendChampionBets(DataTable betPrintMatches, DataTable champions) {
        AddBetPrintTypeColumn(betPrintMatches);
        Dictionary<string, List<DataRow>> rowsByChampion = new Dictionary<string, List<DataRow>>(StringComparer.OrdinalIgnoreCase);
        List<string> order = new List<string>();

        foreach (DataRow champion in champions.Rows) {
            if (GetIntValue(champion, "status", 2) != 1) continue;

            string season = Convert.ToString(champion["season"]);
            DateTime time = GetDateTimeValue(champion, "time", DateTime.MinValue);
            string key = season + "|" + time.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            if (!rowsByChampion.ContainsKey(key)) {
                rowsByChampion[key] = new List<DataRow>();
                order.Add(key);
            }
            rowsByChampion[key].Add(champion);
        }

        foreach (string key in order) {
            List<DataRow> rows = rowsByChampion[key];
            if (rows.Count == 0) continue;

            DataRow first = rows[0];
            DateTime time = GetDateTimeValue(first, "time", DateTime.MinValue);

            DataRow row = betPrintMatches.NewRow();
            row["match"] = key;
            row["season"] = first["season_name"];
            row["time"] = FormatChampionTime(time);
            string championName = GetStringValue(first, "name", "");
            row["home"] = string.IsNullOrWhiteSpace(championName) ? "Kèo chung cuộc" : championName;
            row["way"] = "";
            row["host_name"] = GetStringValue(first, "host_name", "");
            row["user_host"] = GetIntValue(first, "user_host", 0);
            row["statusname"] = "Sắp tới";
            row["odds_html"] = BuildChampionOddsHtml(rows);
            row["bet_print_type"] = "champion";
            row["sort_xKey"] = betPrintMatches.Rows.Count;
            row["sort_time"] = time;
            row["champion_season"] = Convert.ToString(first["season"]);
            row["champion_time"] = time == DateTime.MinValue ? "" : time.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);
            betPrintMatches.Rows.Add(row);
        }
    }

    private void ApplyMatchSortValues(DataTable matches) {
        AddBetPrintTypeColumn(matches);
        for (int i = 0; i < matches.Rows.Count; i++) {
            DataRow row = matches.Rows[i];
            row["sort_xKey"] = GetIntValue(row, "xKey", i);
            row["sort_time"] = GetBetPrintDisplayTime(row["time"]);
        }
    }

    private DataView GetSortedBetPrintRows(DataTable matches) {
        DataView view = matches.DefaultView;
        view.Sort = "sort_time ASC, sort_xKey ASC";
        return view;
    }

    private void FillNormalMatchHostValues(SqlConnection conn, DataTable matches) {
        if (matches.Rows.Count == 0) return;

        SqlCommand cmd = new SqlCommand(@"
            SELECT match, user_host
            FROM bet_match_total
            WHERE match IN (" + BuildSqlParameterList(matches.Rows.Count, "@hostMatch") + @")", conn);

        AddSqlParameters(cmd, matches, "match", "@hostMatch");
        SqlDataAdapter da = new SqlDataAdapter(cmd);
        DataTable hosts = new DataTable();
        da.Fill(hosts);

        Dictionary<string, int> hostsByMatch = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        foreach (DataRow host in hosts.Rows) {
            hostsByMatch[Convert.ToString(host["match"])] = GetIntValue(host, "user_host", 0);
        }

        foreach (DataRow match in matches.Rows) {
            int hostUserId;
            if (hostsByMatch.TryGetValue(Convert.ToString(match["match"]), out hostUserId)) {
                match["user_host"] = hostUserId;
            }
        }
    }

    private int GetIntValue(DataRow row, string columnName, int defaultValue) {
        if (row == null || row.Table == null || !row.Table.Columns.Contains(columnName)) return defaultValue;
        if (row[columnName] == DBNull.Value || row[columnName] == null) return defaultValue;

        int value;
        if (Int32.TryParse(Convert.ToString(row[columnName]), out value)) return value;
        return defaultValue;
    }

    private string GetStringValue(DataRow row, string columnName, string defaultValue) {
        if (row == null || row.Table == null || !row.Table.Columns.Contains(columnName)) return defaultValue;
        if (row[columnName] == DBNull.Value || row[columnName] == null) return defaultValue;
        return Convert.ToString(row[columnName]);
    }

    private DateTime GetDateTimeValue(DataRow row, string columnName, DateTime defaultValue) {
        if (row == null || row.Table == null || !row.Table.Columns.Contains(columnName)) return defaultValue;
        if (row[columnName] == DBNull.Value || row[columnName] == null) return defaultValue;

        DateTime value;
        if (DateTime.TryParse(Convert.ToString(row[columnName]), out value)) return value;
        return defaultValue;
    }

    private DateTime GetBetPrintDisplayTime(object value) {
        string text = Convert.ToString(value);
        if (string.IsNullOrWhiteSpace(text)) return DateTime.MinValue;

        DateTime parsed;
        string[] formats = { "HH:mm  dd-MM-yyyy", "HH:mm dd-MM-yyyy", "H:mm  dd-MM-yyyy", "H:mm dd-MM-yyyy" };
        if (DateTime.TryParseExact(text.Trim(), formats, CultureInfo.InvariantCulture, DateTimeStyles.None, out parsed)) {
            return parsed;
        }
        if (DateTime.TryParse(text, out parsed)) return parsed;
        return DateTime.MinValue;
    }

    private string FormatEsportMatchTime(object matchTime) {
        if (matchTime == DBNull.Value || matchTime == null) return "";
        return Convert.ToDateTime(matchTime).ToString("HH:mm  dd-MM-yyyy");
    }

    protected bool CanOpenBetPrintTicket(object betPrintType) {
        return string.Equals(Convert.ToString(betPrintType), "match", StringComparison.OrdinalIgnoreCase);
    }

    protected bool CanOpenEsportBetPrintTicket(object betPrintType) {
        return string.Equals(Convert.ToString(betPrintType), "esport", StringComparison.OrdinalIgnoreCase);
    }

    protected bool CanOpenChampionBetPrintTicket(object betPrintType) {
        return string.Equals(Convert.ToString(betPrintType), "champion", StringComparison.OrdinalIgnoreCase);
    }

    protected string JsString(object value) {
        return System.Web.HttpUtility.JavaScriptStringEncode(Convert.ToString(value)).Replace("'", "\\'");
    }

    protected int GetCurrentUserId() {
        if (_currentUserId.HasValue) return _currentUserId.Value;

        int userId = 0;
        if (Session["UserID"] != null) {
            Int32.TryParse(Convert.ToString(Session["UserID"]), out userId);
        }

        _currentUserId = userId;
        return userId;
    }

    protected bool IsCurrentUserAdmin() {
        if (_currentUserIsAdmin.HasValue) return _currentUserIsAdmin.Value;

        bool isAdmin = false;
        int userId = GetCurrentUserId();
        if (userId > 0) {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("SELECT ISNULL(admin, 0) FROM dbo.userinfo2 WHERE id = @id", conn)) {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = userId;
                conn.Open();
                object result = cmd.ExecuteScalar();
                isAdmin = result != null && result != DBNull.Value && Convert.ToBoolean(result);
            }
        }

        _currentUserIsAdmin = isAdmin;
        return isAdmin;
    }

    protected string CanSelectTicketUserValue(object userHost) {
        int hostUserId = 0;
        Int32.TryParse(Convert.ToString(userHost), out hostUserId);
        return (IsCurrentUserAdmin() || (hostUserId > 0 && hostUserId == GetCurrentUserId())) ? "true" : "false";
    }

    protected string BuildBetPrintTitleHtml(object betPrintType, object home, object way) {
        if (CanOpenChampionBetPrintTicket(betPrintType)) {
            return "<div class=\"text-center px-4\">" + Server.HtmlEncode(Convert.ToString(home)) + "</div>";
        }

        return "<div class=\"flex-1 text-right pr-3\">" + Server.HtmlEncode(Convert.ToString(home)) + "</div>"
            + "<div class=\"text-1 font-bold lowercase opacity-70 px-1\">vs</div>"
            + "<div class=\"flex-1 text-left pl-3\">" + Server.HtmlEncode(Convert.ToString(way)) + "</div>";
    }

    private void ApplyMatchOddsHtml(SqlConnection conn, DataTable matches) {
        Dictionary<string, List<DataRow>> oddsByMatch = GetMatchOddsByMatch(conn, matches);
        foreach (DataRow row in matches.Rows) {
            row["bet_print_type"] = "match";
            row["statusname"] = "Sắp tới";
            row["odds_html"] = BuildMatchOddsHtml(row, GetRowsByKey(oddsByMatch, Convert.ToString(row["match"])));
        }
    }

    private Dictionary<string, List<DataRow>> GetMatchOddsByMatch(SqlConnection conn, DataTable matches) {
        Dictionary<string, List<DataRow>> oddsByMatch = new Dictionary<string, List<DataRow>>(StringComparer.OrdinalIgnoreCase);
        if (matches.Rows.Count == 0) return oddsByMatch;

        SqlCommand cmd = new SqlCommand(@"
            SELECT match, code, over_under, over_win, under_win, handicap, home_win, way_win, draw_win
            FROM bet_match
            WHERE match IN (" + BuildSqlParameterList(matches.Rows.Count, "@match") + @")
            ORDER BY match, code", conn);

        AddSqlParameters(cmd, matches, "match", "@match");
        SqlDataAdapter da = new SqlDataAdapter(cmd);
        DataTable odds = new DataTable();
        da.Fill(odds);
        return GroupRowsByColumn(odds, "match");
    }

    private string BuildMatchOddsHtml(DataRow match, List<DataRow> odds) {
        StringBuilder[] h1 = CreateOddsChipRows(4);
        StringBuilder[] h2 = CreateOddsChipRows(4);
        StringBuilder[] ft = CreateOddsChipRows(4);
        foreach (DataRow odd in odds) {
            string code = Convert.ToString(odd["code"]).Trim();
            StringBuilder[] rows = GetMatchOddsSectionRows(code, h1, h2, ft);
            AppendMatchOddsChips(rows[GetMatchOddsRowIndex(code)], odd, code, Convert.ToString(match["home"]), Convert.ToString(match["way"]));
        }

        StringBuilder sections = new StringBuilder();
        AppendOddsSection(sections, "Hiệp 1", h1);
        AppendOddsSection(sections, "Hiệp 2", h2);
        AppendOddsSection(sections, "Cả trận", ft);
        return WrapOddsSections(sections);
    }

    private Dictionary<string, List<DataRow>> GetEsportGamesByMatch(SqlConnection conn, DataTable esportMatches) {
        Dictionary<string, List<DataRow>> gamesByMatch = new Dictionary<string, List<DataRow>>(StringComparer.OrdinalIgnoreCase);
        if (esportMatches.Rows.Count == 0) return gamesByMatch;

        SqlCommand cmd = new SqlCommand(@"
            SELECT *
            FROM bet_esport_game
            WHERE match_id IN (" + BuildSqlParameterList(esportMatches.Rows.Count, "@esportMatch") + @")
            ORDER BY match_id, game_no", conn);

        AddSqlParameters(cmd, esportMatches, "match_id", "@esportMatch");
        SqlDataAdapter da = new SqlDataAdapter(cmd);
        DataTable games = new DataTable();
        da.Fill(games);
        return GroupRowsByColumn(games, "match_id");
    }

    private string BuildSqlParameterList(int count, string prefix) {
        StringBuilder parameters = new StringBuilder();
        for (int i = 0; i < count; i++) {
            if (i > 0) parameters.Append(",");
            parameters.Append(prefix);
            parameters.Append(i);
        }
        return parameters.ToString();
    }

    private void AddSqlParameters(SqlCommand cmd, DataTable source, string columnName, string prefix) {
        for (int i = 0; i < source.Rows.Count; i++) {
            cmd.Parameters.Add(prefix + i, SqlDbType.NVarChar).Value = Convert.ToString(source.Rows[i][columnName]);
        }
    }

    private Dictionary<string, List<DataRow>> GroupRowsByColumn(DataTable table, string columnName) {
        Dictionary<string, List<DataRow>> groupedRows = new Dictionary<string, List<DataRow>>(StringComparer.OrdinalIgnoreCase);
        foreach (DataRow row in table.Rows) {
            string key = Convert.ToString(row[columnName]);
            if (!groupedRows.ContainsKey(key)) {
                groupedRows[key] = new List<DataRow>();
            }
            groupedRows[key].Add(row);
        }
        return groupedRows;
    }

    private List<DataRow> GetRowsByKey(Dictionary<string, List<DataRow>> rowsByKey, string key) {
        List<DataRow> rows;
        if (rowsByKey.TryGetValue(key, out rows)) return rows;
        return new List<DataRow>();
    }

    private StringBuilder[] CreateOddsChipRows(int count) {
        StringBuilder[] rows = new StringBuilder[count];
        for (int i = 0; i < count; i++) {
            rows[i] = new StringBuilder();
        }
        return rows;
    }

    private StringBuilder[] GetMatchOddsSectionRows(string code, StringBuilder[] h1, StringBuilder[] h2, StringBuilder[] ft) {
        if (string.IsNullOrEmpty(code)) return ft;

        switch (code[code.Length - 1]) {
            case '1': return h1;
            case '2': return h2;
            default: return ft;
        }
    }

    private int GetMatchOddsRowIndex(string code) {
        if (string.IsNullOrEmpty(code)) return 3;

        switch (code[0]) {
            case '0':
            case '1':
                return 0;
            case '2':
            case '3':
                return 1;
            case '5':
            case '6':
                return 2;
            default:
                return 3;
        }
    }

    private void AppendMatchOddsChips(StringBuilder chips, DataRow odd, string code, string home, string way) {
        if (HasOddsValue(odd["over_under"])) {
            string line = FormatOddsValue(odd["over_under"]);
            AppendOddsChip(chips, GetMatchOverLabel(code) + " " + line);
            return;
        }

        if (HasOddsValue(odd["handicap"])) {
            AppendHandicapChip(chips, odd["handicap"], home, GetMatchHandicapUnit(code));
            return;
        }

        AppendRateChip(chips, EncodeOddsText(home), odd["home_win"]);
        AppendRateChip(chips, "Hòa", odd["draw_win"]);
        AppendRateChip(chips, EncodeOddsText(way), odd["way_win"]);
    }

    private string GetMatchOverLabel(string code) {
        if (string.IsNullOrEmpty(code)) return "Kèo";

        switch (code[0]) {
            case '0': return "Tài góc";
            case '2': return "Tài bàn";
            case '5': return "Tài thẻ";
            default: return "Tài";
        }
    }

    private string GetMatchHandicapUnit(string code) {
        if (string.IsNullOrEmpty(code)) return "";

        switch (code[0]) {
            case '1': return "góc";
            case '3': return "";
            case '6': return "thẻ";
            default: return "";
        }
    }

    private string BuildEsportOddsHtml(DataRow esport, List<DataRow> games) {
        string home = Convert.ToString(esport["home_name"]);
        string way = Convert.ToString(esport["way_name"]);
        StringBuilder sections = new StringBuilder();
        int normalGameCount = 0;

        foreach (DataRow game in games) {
            int gameNo = Convert.ToInt32(game["game_no"]);
            string stage = gameNo == 6 ? "BO x" : "Game " + gameNo;
            StringBuilder[] rows = CreateOddsChipRows(gameNo == 6 ? 1 : 8);

            if (gameNo == 6) {
                AppendEsportLineOdds(rows[0], "Tài", "game", game, "ou_line", "ou_over_win", "ou_under_win");
                AppendEsportHandicapOdds(rows[0], "game", game, "hc_line", "hc_home_win", "hc_way_win", home, way);
                AppendOddsSection(sections, stage, rows);
                continue;
            }

            normalGameCount++;
            AppendEsportLineOdds(rows[0], "Tài", "kill", game, "ou_line", "ou_over_win", "ou_under_win");
            AppendEsportHandicapOdds(rows[0], "kill", game, "hc_line", "hc_home_win", "hc_way_win", home, way);
            AppendEsportLineOdds(rows[0], "Tài", "phút", game, "minute_line", "minute_over_win", "minute_under_win");
            AppendEsportLineOdds(rows[1], "Tài", "rồng", game, "dragon_ou_line", "dragon_ou_over_win", "dragon_ou_under_win");
            AppendEsportHandicapOdds(rows[1], "rồng", game, "dragon_hc_line", "dragon_hc_home_win", "dragon_hc_way_win", home, way);
            AppendEsportPairOdds(rows[2], "Rồng đầu", game, "first_dragon_home_win", "first_dragon_way_win", home, way);
            AppendEsportPairOdds(rows[3], "Mạng đầu", game, "first_home_win", "first_way_win", home, way);
            AppendEsportPairOdds(rows[4], "3 mạng đầu", game, "third_home_win", "third_way_win", home, way);
            AppendEsportPairOdds(rows[5], "5 mạng đầu", game, "five_home_win", "five_way_win", home, way);
            AppendEsportPairOdds(rows[6], "10 mạng đầu", game, "ten_home_win", "ten_way_win", home, way);
            AppendEsportPairOdds(rows[7], "", game, "win_home_win", "win_way_win", home + " win", way + " win");
            AppendOddsSection(sections, stage, rows);
        }

        return WrapEsportOddsSections(sections, normalGameCount);
    }

    private string BuildChampionOddsHtml(List<DataRow> champions) {
        List<StringBuilder> rows = new List<StringBuilder>();
        StringBuilder chips = new StringBuilder();
        int chipCount = 0;
        foreach (DataRow champion in champions) {
            if (!HasOddsValue(champion["rate_win"])) continue;
            if (chipCount == 3) {
                rows.Add(chips);
                chips = new StringBuilder();
                chipCount = 0;
            }
            AppendRateChip(chips, EncodeOddsText(Convert.ToString(champion["team_name"])), champion["rate_win"]);
            chipCount++;
        }
        if (chips.Length > 0) rows.Add(chips);

        StringBuilder sections = new StringBuilder();
        AppendOddsSection(sections, "Vô địch", rows.ToArray());
        return WrapChampionOddsSections(sections, champions.Count);
    }

    private string WrapChampionOddsSections(StringBuilder sections, int teamCount) {
        string summary = "<div class=\"text-center text-amber-700 text-[12px] font-bold pt-1\">"
            + "<i class=\"fa-solid fa-trophy mr-1\"></i>" + teamCount + " đội</div>";
        return summary + WrapOddsSections(sections);
    }

    private string FormatChampionTime(DateTime time) {
        if (time == DateTime.MinValue) return "";
        return time.ToString("dd-MM-yyyy");
    }

    private void AppendEsportLineOdds(StringBuilder chips, string label, string unit, DataRow game, string line, string overWin, string underWin) {
        if (!HasAnyOddsValue(game[line], game[overWin], game[underWin])) return;

        string formattedLine = FormatOddsValue(game[line]);
        AppendOddsChip(chips, EncodeOddsText(label) + " " + formattedLine + " " + EncodeOddsText(unit));
    }

    private void AppendEsportHandicapOdds(StringBuilder chips, string unit, DataRow game, string line, string homeWin, string wayWin, string home, string way) {
        if (!HasAnyOddsValue(game[line], game[homeWin], game[wayWin])) return;

        AppendHandicapChip(chips, game[line], home, unit);
    }

    private void AppendEsportPairOdds(StringBuilder chips, string label, DataRow game, string homeWin, string wayWin, string home, string way) {
        if (!HasAnyOddsValue(game[homeWin], game[wayWin])) return;

        string prefix = string.IsNullOrEmpty(label) ? "" : EncodeOddsText(label) + " ";
        AppendRateChip(chips, prefix + EncodeOddsText(home), game[homeWin]);
        AppendRateChip(chips, prefix + EncodeOddsText(way), game[wayWin]);
    }

    private void AppendOddsSection(StringBuilder sections, string title, StringBuilder chips) {
        if (chips.Length == 0) return;

        sections.Append("<div class=\"bet-odds-section\">");
        sections.Append("<div class=\"bet-odds-title\">");
        sections.Append(EncodeOddsText(title));
        sections.Append("</div><div class=\"bet-odds-grid\">");
        sections.Append(chips.ToString());
        sections.Append("</div></div>");
    }

    private void AppendOddsSection(StringBuilder sections, string title, StringBuilder[] rows) {
        if (!HasOddsChipRows(rows)) return;

        sections.Append("<div class=\"bet-odds-section\">");
        sections.Append("<div class=\"bet-odds-title\">");
        sections.Append(EncodeOddsText(title));
        sections.Append("</div><div class=\"bet-odds-rows\">");
        foreach (StringBuilder row in rows) {
            if (row.Length == 0) continue;
            sections.Append("<div class=\"bet-odds-grid\">");
            sections.Append(row.ToString());
            sections.Append("</div>");
        }
        sections.Append("</div></div>");
    }

    private bool HasOddsChipRows(StringBuilder[] rows) {
        foreach (StringBuilder row in rows) {
            if (row.Length > 0) return true;
        }
        return false;
    }

    private void AppendOddsChip(StringBuilder chips, string text) {
        chips.Append("<span class=\"bet-odds-chip\">");
        chips.Append(text);
        chips.Append("</span>");
    }

    private void AppendRateChip(StringBuilder chips, string label, object value) {
        if (!HasOddsValue(value)) return;

        AppendOddsChip(chips, label + ": <span class=\"ml-1\">" + FormatOddsValue(value) + "</span>");
    }

    private void AppendHandicapChip(StringBuilder chips, object line, string home, string unit) {
        AppendOddsChip(chips, EncodeOddsText(home) + " " + FormatHandicapOddsValue(line, false) + " " + EncodeOddsText(unit));
    }

    private string WrapOddsSections(StringBuilder sections) {
        if (sections.Length == 0) {
            return "<div class=\"text-center text-slate-400 text-[12px] font-bold py-2\">Chưa có kèo</div>";
        }

        return "<div class=\"bet-print-odds-scroll\">" + sections.ToString() + "</div>";
    }

    private string WrapEsportOddsSections(StringBuilder sections, int gameCount) {
        string summary = "<div class=\"text-center text-green-700 text-[12px] font-bold pt-1\">"
            + "BO" + gameCount + "</div>";
        return summary + WrapOddsSections(sections);
    }

    private bool HasAnyOddsValue(params object[] values) {
        foreach (object value in values) {
            if (HasOddsValue(value)) return true;
        }
        return false;
    }

    private bool HasOddsValue(object value) {
        return value != null && value != DBNull.Value && !string.IsNullOrWhiteSpace(Convert.ToString(value));
    }

    private string FormatOddsValue(object value) {
        if (!HasOddsValue(value)) return "-";
        decimal number;
        if (TryParseOddsNumber(value, out number)) {
            return FormatOddsMetric(number.ToString("0.##", CultureInfo.InvariantCulture));
        }
        return EncodeOddsText(Convert.ToString(value).Trim());
    }

    private string FormatHandicapOddsValue(object value, bool reverse) {
        decimal number;
        if (!TryParseOddsNumber(value, out number)) {
            return FormatOddsValue(value);
        }

        if (reverse) number = -number;
        string sign = number >= 0 ? "+" : "-";
        string format = number == 0 ? "0.00" : "0.##";
        return FormatOddsMetric(sign + Math.Abs(number).ToString(format, CultureInfo.InvariantCulture));
    }

    private bool TryParseOddsNumber(object value, out decimal number) {
        if (value is decimal) {
            number = (decimal)value;
            return true;
        }

        return decimal.TryParse(Convert.ToString(value), NumberStyles.Number, CultureInfo.InvariantCulture, out number)
            || decimal.TryParse(Convert.ToString(value), out number);
    }

    private string FormatOddsMetric(string value) {
        return "<span class=\"odds-metric mx-1 text-red-600\">" + EncodeOddsText(value) + "</span>";
    }

    private string EncodeOddsText(string value) {
        return Server.HtmlEncode(value ?? "");
    }
    
    private void BindUserList() {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("SELECT id, name, comment FROM dbo.userinfo2 WHERE user_yn = 1 ORDER BY comment", conn);
                conn.Open();
                DataTable dt = new DataTable();
                dt.Load(cmd.ExecuteReader());

                ddlUser.DataSource = dt;
                ddlUser.DataTextField = "comment";
                ddlUser.DataValueField = "id";
                ddlUser.DataBind();
                ddlUser.Items.Insert(0, new ListItem("Tất cả", "-2"));
                
                if (Session["UserName"] != null) {
                    string currentUserName = Session["UserName"].ToString().Trim().ToLower();
                    foreach (DataRow row in dt.Rows) {
                        if (row["name"].ToString().Trim().ToLower() == currentUserName) {
                            ddlUser.ClearSelection();
                            ddlUser.SelectedValue = row["id"].ToString();
                            break;
                        }
                    }
                }
            }
        } catch { }
    }

</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Bộ môn trí tuệ</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; height: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .grid-header th { position: sticky; top: 0; z-index: 10; background-color: #1d4ed8 !important; color: white !important; text-align: center !important; padding: 10px 12px; font-size: 16px; }
        .row-style td { padding: 8px 12px; font-weight: bold; font-size: 16px; border-bottom: 1px solid #eef2f6; }
        .bet-item { border-bottom: 2px solid #f1f5f9; padding: 12px 16px; background-color: white; display: flex; flex-direction: column; gap: 4px; }
        .bet-print-item { position: relative; padding: 12px 18px 14px; }
        .bet-print-action { display: flex; justify-content: center; }
        .bet-print-odds-scroll {
            margin-top: 6px;
            padding-top: 6px;
            border-top: 1px solid #e2e8f0;
            max-height: 220px;
            overflow-y: auto;
            overscroll-behavior: contain;
            padding-right: 4px;
        }
        .bet-print-odds-scroll::-webkit-scrollbar { width: 4px; }
        .bet-print-odds-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .bet-odds-section { margin-top: 6px; }
        .bet-odds-section:first-child { margin-top: 0; }
        .bet-odds-title {
            color: #15803d;
            font-size: 12px;
            line-height: 16px;
            font-weight: 800;
            margin-bottom: 3px;
        }
        .bet-odds-rows { display: flex; flex-direction: column; gap: 3px; }
        .bet-odds-grid {
            display: grid;
            grid-auto-flow: column;
            grid-auto-columns: minmax(0, 1fr);
            gap: 3px;
        }
        .bet-odds-chip {
            display: inline-flex;
            min-width: 0;
            align-items: center;
            justify-content: center;
            text-align: center;
            padding: 4px 7px;
            border-radius: 4px;
            border: 1px solid #22c55e;
            background: #fff;
            color: #000;
            font-size: 15px;
            font-weight: 700;
            line-height: 18px;
        }
        @media (max-width: 640px) {
            .bet-print-odds-scroll { max-height: 180px; }
            .bet-odds-chip { padding: 3px 6px; font-size: 14px; line-height: 17px; }
        }
		
		/* Sidebar không bị lệch và icon thẳng hàng */
		.nav-item { 
			border-right: 4px solid transparent; 
			display: flex;
			align-items: center;
			padding: 0.75rem 1rem; /* px-4 py-3 */
			font-weight: bold;
			transition: all 0.2s;
		}

		.nav-item-active { 
			border-right-color: #1d4ed8; 
			background-color: #eff6ff; 
			color: #1d4ed8 !important; 
		}

		/* Cố định kích thước icon */
		.nav-item i {
			width: 20px; 
			text-align: center;
			margin-right: 12px;
		}
	</style>
</head>
<body class="h-[100dvh] flex flex-col">
    <form runat="server" class="h-full flex flex-col">
        <asp:HiddenField ID="hfScrollPosition" runat="server" Value="0" />

        <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
            <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="home" />
        </nav>

        <div class="flex flex-1 overflow-hidden relative">
            <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>

            <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="home" />

            <main id="mainContent" class="flex-1 p-3 lg:p-4 flex flex-col lg:flex-row gap-4 overflow-y-auto lg:overflow-hidden bg-[#f8fafc]">
                
                <!-- Mobile: Thứ tự từ trên xuống - rptBetPrint, gvBetTable, gvTickets -->
                <!-- Web: rptBetPrint bên trái (lg:w-1/2), bên phải chia 2 hàng (gvBetTable trên, gvTickets dưới) -->
                
                <!-- rptBetPrint - Bên trái trên web, đầu tiên trên mobile -->
                <div class="bg-white rounded-xl shadow-md border flex flex-col overflow-hidden min-h-[450px] lg:h-full lg:w-1/2" id="rptBetPrintContainer">
                    <div class="py-4 text-center font-bold text-red-600 text-[18px] lg:text-[20px] uppercase border-b bg-white">Trận đấu sắp tới</div>
                    <div class="flex-1 overflow-auto main-scroll bg-white flex flex-col">
                        <asp:Repeater ID="rptBetPrint" runat="server">
                            <ItemTemplate>
                                <div class='<%# "bet-item bet-print-item hover:bg-slate-50 transition border-b-2 border-[#f1f5f9] flex flex-col gap-1 " + (Container.ItemIndex % 2 == 0 ? "bg-white" : "bg-[#FFFFE0]") %>'>
                                    <div class="flex justify-between items-center gap-2 text-[16px] font-bold leading-tight w-full">
										<div class="flex-shrink-0">
											<%# string.IsNullOrWhiteSpace(Convert.ToString(Eval("host_name"))) ? "" : "<span class=\"bg-gray-100 px-2 py-0.5 rounded text-[12px] border border-gray-200 font-bold text-gray-800\">Cái: " + Server.HtmlEncode(Convert.ToString(Eval("host_name"))) + "</span>" %>
										</div>
										
										<div class="bet-print-action flex-shrink-0">
											<asp:PlaceHolder runat="server" Visible='<%# CanOpenBetPrintTicket(Eval("bet_print_type")) %>'>
												<button type="button" onclick="openTicketModal('<%# JsString(Eval("match")) %>', '<%# JsString(Convert.ToString(Eval("home")) + " vs " + Convert.ToString(Eval("way")) + " " + Convert.ToString(Eval("time")) + " " + Convert.ToString(Eval("season"))) %>', <%# CanSelectTicketUserValue(Eval("user_host")) %>)" 
													class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded-lg text-[11px] font-bold transition-all active:scale-95 flex items-center gap-1">
													<i class="fa-solid fa-ticket text-[10px]"></i>Cược
												</button>
											</asp:PlaceHolder>
											<asp:PlaceHolder runat="server" Visible='<%# CanOpenEsportBetPrintTicket(Eval("bet_print_type")) %>'>
												<button type="button" onclick="openEsportTicketModal('<%# JsString(Eval("match")) %>', '<%# JsString(Convert.ToString(Eval("home")) + " vs " + Convert.ToString(Eval("way")) + " " + Convert.ToString(Eval("time")) + " " + Convert.ToString(Eval("season"))) %>', <%# CanSelectTicketUserValue(Eval("user_host")) %>)" 
													class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded-lg text-[11px] font-bold transition-all active:scale-95 flex items-center gap-1">
													<i class="fa-solid fa-ticket text-[10px]"></i>Cược
												</button>
											</asp:PlaceHolder>
											<asp:PlaceHolder runat="server" Visible='<%# CanOpenChampionBetPrintTicket(Eval("bet_print_type")) %>'>
												<button type="button" onclick="openChampionTicketModal('<%# Eval("champion_season") %>', '<%# Eval("champion_time") %>')" 
													class="bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded-lg text-[11px] font-bold transition-all active:scale-95 flex items-center gap-1">
													<i class="fa-solid fa-ticket text-[10px]"></i>Cược
												</button>
											</asp:PlaceHolder>
										</div>
									</div>
                                    <div class="flex justify-between items-center gap-3 text-[16px] font-bold leading-tight">
                                        <div class="min-w-0 text-green-700 text-left"><%# Eval("season") %></div>
                                        <div class="text-blue-700 text-right whitespace-nowrap"><%# Eval("time") %></div>
                                    </div>
                                    <div class="flex justify-center items-center text-[16px] font-black uppercase text-red-600 py-0.5 leading-tight">
                                        <%# BuildBetPrintTitleHtml(Eval("bet_print_type"), Eval("home"), Eval("way")) %>
                                    </div>
                                    <div class="w-full pt-0.5"><%# Eval("odds_html") %></div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                        <% if (rptBetPrint.Items.Count == 0) { %>
                            <div class="flex-1 flex flex-col items-center justify-center text-gray-400 py-10 lg:py-20" id="emptyMatchState">
                                <i class="fa-solid fa-calendar-xmark text-4xl lg:text-6xl opacity-20"></i>
                                <div class="mt-3 lg:mt-4 text-center">
                                    <p class="font-bold text-sm lg:text-base">Chưa có trận đấu nào</p>
                                </div>
                            </div>
                        <% } %>
                    </div>
                </div>

                <!-- Cột bên phải trên web, chứa gvBetTable và gvTickets xếp dọc -->
                <div class="flex flex-col gap-4 lg:w-1/2 lg:h-full">
                    
                    <!-- gvBetTable - Bên phải trên cùng trên web, thứ 2 trên mobile -->
                    <div class="bg-white rounded-xl shadow-md border flex flex-col overflow-hidden h-[400px] lg:h-1/2">
                        <div class="py-4 text-center font-bold text-blue-700 text-[18px] lg:text-[20px] uppercase border-b bg-white">Bảng xếp hạng</div>
                        <div class="flex-1 overflow-auto main-scroll" id="betTableContainer">
                            <div class="text-center text-gray-400 py-10">Đang tải...</div>
                        </div>
                    </div>

                    <!-- gvTickets - Bên phải dưới cùng trên web, thứ 3 trên mobile -->
                    <div class="bg-white rounded-xl shadow-md border flex flex-col overflow-hidden h-[600px] lg:h-1/2">
                        <div class="py-4 text-center font-bold text-green-700 text-[18px] lg:text-[20px] uppercase border-b bg-white flex-none">Danh sách vé cược</div>
                        <div class="p-2 bg-slate-50 border-b grid grid-cols-3 gap-2 flex-none">
                            <asp:DropDownList ID="ddlUser" runat="server" 
                                CssClass="w-full border rounded p-1.5 text-[13px] font-bold focus:ring-2 focus:ring-blue-500 outline-none bg-white"
                                onchange="loadTicketList(true)">
                            </asp:DropDownList>
                            <asp:DropDownList ID="ddlClear" runat="server"
                                CssClass="w-full border rounded p-1.5 text-[13px] font-bold outline-none bg-white"
                                onchange="loadTicketList(true)">
                                <asp:ListItem Text="Chưa TT" Value="0"></asp:ListItem>
                                <asp:ListItem Text="Đã TT" Value="1"></asp:ListItem>
                                <asp:ListItem Text="Cả hai" Value="2"></asp:ListItem>
                            </asp:DropDownList>
                            <asp:DropDownList ID="ddlResult" runat="server"
                                CssClass="w-full border rounded p-1.5 text-[13px] font-bold outline-none bg-white"
                                onchange="loadTicketList(true)">
                                <asp:ListItem Text="Chưa có" Value="0"></asp:ListItem>
                                <asp:ListItem Text="Đã có" Value="1"></asp:ListItem>
                                <asp:ListItem Text="Cả hai" Value="2"></asp:ListItem>
                            </asp:DropDownList>
                        </div>
                        <div class="flex-1 overflow-auto main-scroll" id="ticketListContainer">
                            <div class="text-center text-gray-400 py-10">Đang tải...</div>
                        </div>
                    </div>

                </div>
            </main>
        </div>
        
        <uc:Ticket runat="server" ID="ucTicket" />
        <uc:ChampionTicket runat="server" ID="ucChampionTicket" />
    </form>
    <script>
        const showFeeColumn = <%= ShowFeeColumn ? "true" : "false" %>;

        function toggleSidebar() {
            const s = document.getElementById('sidebar'), o = document.getElementById('overlay');
            s.classList.toggle('-translate-x-full'); o.classList.toggle('hidden');
        }

        // --- CODE CHỐNG NHẢY TRANG MOBILE ---
        const mainContent = document.getElementById('mainContent');
        const hfScroll = document.getElementById('<%= hfScrollPosition.ClientID %>');

        // Khi load lại trang, cuộn về vị trí cũ
        window.onload = function() {
            if (mainContent && hfScroll) {
                mainContent.scrollTop = hfScroll.value;
            }
            
            // Thu gọn vùng rptBetPrint trên mobile nếu không có data
            adjustEmptyMatchContainer();
            
            initBetTableLazyLoad();
            initTicketListLazyLoad();
        };

        // Trước khi PostBack (thay đổi dropdown), lưu lại vị trí cuộn hiện tại
        mainContent.onscroll = function() {
            if (hfScroll) hfScroll.value = mainContent.scrollTop;
        };

        // Thu gọn container khi không có trận đấu (chỉ trên mobile)
        function adjustEmptyMatchContainer() {
            const container = document.getElementById('rptBetPrintContainer');
            const emptyState = document.getElementById('emptyMatchState');
            
            if (container && emptyState && window.innerWidth < 1024) {
                // Mobile: thu gọn chiều cao
                container.style.minHeight = '200px';
            }
        }

        // Lắng nghe resize để điều chỉnh lại khi thay đổi kích thước màn hình
        window.addEventListener('resize', adjustEmptyMatchContainer);

        let betTableLoaded = false;

        function initBetTableLazyLoad() {
            const container = document.getElementById('betTableContainer');
            if (!container) return;

            if (!('IntersectionObserver' in window)) {
                loadBetTable();
                return;
            }

            const observer = new IntersectionObserver((entries, currentObserver) => {
                if (entries.some(entry => entry.isIntersecting)) {
                    currentObserver.disconnect();
                    loadBetTable();
                }
            }, { root: mainContent, rootMargin: '120px' });

            observer.observe(container);
        }

        function loadBetTable(forceReload) {
            if (betTableLoaded && !forceReload) return;
            betTableLoaded = true;

            fetch('GetBetTable.aspx', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: '{}'
            })
            .then(response => response.json())
            .then(data => {
                renderBetTable(data.d);
            })
            .catch(error => {
                console.error('Error loading bet table:', error);
                betTableLoaded = false;
                const container = document.getElementById('betTableContainer');
                if (container) container.innerHTML = '<div class="text-center text-gray-400 py-10">Không tải được dữ liệu</div>';
            });
        }

        function renderBetTable(rows) {
            const container = document.getElementById('betTableContainer');
            if (!container) return;

            if (!rows || rows.length === 0) {
                container.innerHTML = '<div class="text-center text-gray-400 py-10">Không có dữ liệu</div>';
                return;
            }

            let html = '<table class="w-full">';
            html += '<thead class="grid-header">';
            html += '<tr>';
            html += '<th style="text-align: left; padding: 10px 24px;">Tên</th>';
            html += '<th style="text-align: right; padding: 10px 24px;">Lãi/Lỗ</th>';
            html += '<th style="text-align: right; padding: 10px 24px;">Số dư</th>';
            if (showFeeColumn) html += '<th style="text-align: right; padding: 10px 24px;">Phế</th>';
            html += '</tr>';
            html += '</thead><tbody>';

            rows.forEach((item, index) => {
                const bg = index % 2 === 0 ? '#ffffff' : '#FFFFE0';
                const moneyClass = Number(item.money_win || 0) >= 0 ? 'text-green-600' : 'text-red-600';
                const balanceClass = Number(item.balance || 0) >= 0 ? 'text-green-600' : 'text-red-600';
                const feeClass = Number(item.fee || 0) >= 0 ? 'text-green-600' : 'text-red-600';

                html += '<tr class="row-style" style="background-color:' + bg + ';">';
                html += '<td class="px-4 lg:px-6 text-left"><span class="' + moneyClass + '">' + escapeHtml(item.name || '') + '</span></td>';
                html += '<td class="px-4 lg:px-6 text-right"><span class="' + moneyClass + '">' + formatNumber(item.money_win || 0) + '</span></td>';
                html += '<td class="px-4 lg:px-6 text-right"><span class="' + balanceClass + '">' + formatNumber(item.balance || 0) + '</span></td>';
                if (showFeeColumn) html += '<td class="px-4 lg:px-6 text-right"><span class="' + feeClass + '">' + formatNumber(item.fee || 0) + '</span></td>';
                html += '</tr>';
            });

            html += '</tbody></table>';
            container.innerHTML = html;
        }
        
        let ticketListLoaded = false;

        function initTicketListLazyLoad() {
            const container = document.getElementById('ticketListContainer');
            if (!container) return;

            if (!('IntersectionObserver' in window)) {
                loadTicketList();
                return;
            }

            const observer = new IntersectionObserver((entries, currentObserver) => {
                if (entries.some(entry => entry.isIntersecting)) {
                    currentObserver.disconnect();
                    loadTicketList();
                }
            }, { root: mainContent, rootMargin: '120px' });

            observer.observe(container);
        }

        // Load danh sách vé cược qua AJAX
        function loadTicketList(forceReload) {
            if (ticketListLoaded && !forceReload) return;
            ticketListLoaded = true;

            const userId = document.getElementById('<%= ddlUser.ClientID %>').value;
            const clear = document.getElementById('<%= ddlClear.ClientID %>').value;
            const result = document.getElementById('<%= ddlResult.ClientID %>').value;
            
            fetch('GetTicketList.aspx', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    userId: userId,
                    match: '',
                    type: '0',
                    clear: clear,
                    result: result,
                    dateFrom: '',
                    dateTo: ''
                })
            })
            .then(response => response.json())
            .then(data => {
                renderTicketList(data.d);
            })
            .catch(error => {
                console.error('Error loading ticket list:', error);
                ticketListLoaded = false;
            });
        }
        
        function renderTicketList(tickets) {
            const container = document.getElementById('ticketListContainer');
            if (!container) return;
            
            if (!tickets || tickets.length === 0) {
                container.innerHTML = '<div class="text-center text-gray-400 py-10">Không có dữ liệu</div>';
                return;
            }
            
            let html = '<table class="w-full">';
            html += '<thead class="grid-header">';
            html += '<tr>';
            html += '<th style="width: ' + (showFeeColumn ? '45%' : '50%') + '; text-align: left; padding: 10px 12px;">Cược</th>';
            html += '<th style="width: ' + (showFeeColumn ? '20%' : '25%') + '; text-align: right; padding: 10px 12px;">Tiền</th>';
            html += '<th style="width: ' + (showFeeColumn ? '20%' : '25%') + '; text-align: right; padding: 10px 12px;">Lãi/Lỗ</th>';
            if (showFeeColumn) html += '<th style="width: 15%; text-align: center; padding: 10px 12px;">Phế</th>';
            html += '</tr>';
            html += '</thead>';
            html += '<tbody>';
            
            tickets.forEach((item, index) => {
                const rowStyle = item.rowColor ? 'background-color: ' + item.rowColor + ';' : '';
                const textStyle = item.textColor ? 'color: ' + item.textColor + ';' : '';
                const fontWeight = item.rowBold === '1' || item.rowBold === 'true' ? 'font-weight: bold;' : '';
                const combinedStyle = rowStyle + textStyle + fontWeight;
                
                html += '<tr class="row-style" style="' + combinedStyle + '">';
                html += '<td style="width: ' + (showFeeColumn ? '45%' : '50%') + ';">' + (item.ticket_name || '') + '</td>';
                html += '<td class="text-right" style="width: ' + (showFeeColumn ? '20%' : '25%') + ';">' + formatNumber(item.money) + '</td>';
                html += '<td class="text-right" style="width: ' + (showFeeColumn ? '20%' : '25%') + ';">' + formatNumber(item.money_win) + '</td>';
                if (showFeeColumn) html += '<td class="text-right" style="width: 15%;">' + formatNumber(item.fee) + '</td>';
                html += '</tr>';
            });
            
            html += '</tbody>';
            html += '</table>';
            
            container.innerHTML = html;
        }
        
        function formatNumber(num) {
            return Math.round(num).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
        }

        function escapeHtml(value) {
            return String(value)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }
    </script>
</body>
</html>
