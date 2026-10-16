<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucAddEsport.ascx" TagPrefix="uc" TagName="AddEsport" %>
<%@ Register Src="~/ucTicketMatch.ascx" TagPrefix="uc" TagName="TicketMatch" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null) 
        {
            Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
            return;
        }
        if (!IsPostBack) { 
            LoadSmartData();
        }
        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }
    
    protected bool CheckRight(string action)
    {
        if (Session["UserID"] == null) return false;
        try {
            int userId = Convert.ToInt32(Session["UserID"]);
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("SELECT dbo.bet_check_right(@userID, @action)", conn);
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = userId;
                cmd.Parameters.Add("@action", SqlDbType.NVarChar).Value = action;
                conn.Open();
                object result = cmd.ExecuteScalar();
                if (result == null) return false;
                string resultStr = result.ToString().Trim();
                return resultStr == "1" || resultStr == "True" || resultStr == "true";
            }
        } catch { return false; }
    }

    protected int GetCurrentUserId()
    {
        if (Session["UserID"] == null) return 0;
        int userId;
        return Int32.TryParse(Session["UserID"].ToString(), out userId) ? userId : 0;
    }

    protected bool IsAdminUser()
    {
        if (Session["UserID"] == null) return false;
        try {
            int userId = Convert.ToInt32(Session["UserID"]);
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.userinfo2 WHERE id = @userID AND admin = 1", conn);
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = userId;
                conn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        } catch { return false; }
    }

    protected bool CanManageMatch(object userHostValue)
    {
        if (IsAdminUser()) return true;
        if (userHostValue == null || userHostValue == DBNull.Value) return false;
        int userHost;
        return Int32.TryParse(userHostValue.ToString(), out userHost) && userHost == GetCurrentUserId();
    }

    protected bool CanManageMatchRow(object dataItem)
    {
        if (IsAdminUser()) return true;
        DataRowView row = dataItem as DataRowView;
        if (row == null || row.DataView == null || row.DataView.Table == null) return false;
        if (row.DataView.Table.Columns.Contains("user_host")) return CanManageMatch(row["user_host"]);
        if (row.DataView.Table.Columns.Contains("created_by")) return CanManageMatch(row["created_by"]);
        return false;
    }

    protected string GetRowString(object dataItem, string columnName)
    {
        DataRowView row = dataItem as DataRowView;
        if (row == null || row.DataView == null || row.DataView.Table == null) return "";
        if (!row.DataView.Table.Columns.Contains(columnName)) return "";
        if (row[columnName] == null || row[columnName] == DBNull.Value) return "";
        return row[columnName].ToString();
    }

    protected string GetEsportStatusTextClass(object statusValue)
    {
        int status;
        if (!int.TryParse(Convert.ToString(statusValue), out status)) return "text-gray-500";
        if (status == 2) return "text-green-600";
        if (status == 1) return "text-red-600";
        if (status == 3) return "text-fuchsia-600";
        if (status == 4) return "text-gray-600";
        return "text-gray-500";
    }

    private void BindMatchTable() {
        try {
            string team = Request.Form["filterTeam"] ?? "";
            string season = Request.Form["filterSeason"] ?? "";
            string dateFrom = Request.Form["filterDateFrom"] ?? "";
            string dateTo = Request.Form["filterDateTo"] ?? "";
            string status = "";
            if (IsPostBack && Request.Form.GetValues("filterStatus") != null)
                status = string.Join(",", Request.Form.GetValues("filterStatus"));
            else if (!IsPostBack)
                status = "1, 2, 3, 4";
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("bet_esport_matches", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@team", string.IsNullOrEmpty(team) ? "" : team);
                cmd.Parameters.AddWithValue("@season", string.IsNullOrEmpty(season) ? "" : season);
                cmd.Parameters.AddWithValue("@datefrom", string.IsNullOrEmpty(dateFrom) ? (object)DBNull.Value : dateFrom);
                cmd.Parameters.AddWithValue("@dateto", string.IsNullOrEmpty(dateTo) ? (object)DBNull.Value : dateTo);
                cmd.Parameters.AddWithValue("@status", status);
                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable(); 
                da.Fill(dt);                
                rptMatches.DataSource = dt;
                rptMatches.DataBind();
            }
        } catch (Exception ex) { }
    }

    private void LoadSmartData() {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                string sqlSeason = "SELECT rtrim(ltrim(season)) as season, season_name FROM bet_season";
                SqlDataAdapter daSeason = new SqlDataAdapter(sqlSeason, conn);
                DataTable dtSeason = new DataTable();
                daSeason.Fill(dtSeason);
                string sqlTeam = "SELECT rtrim(ltrim(team)) as team, team_name FROM bet_team";
                SqlDataAdapter daTeam = new SqlDataAdapter(sqlTeam, conn);
                DataTable dtTeam = new DataTable();
                daTeam.Fill(dtTeam);
                var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
                var listS = new List<Dictionary<string, object>>();
                foreach (DataRow r in dtSeason.Rows)
                    listS.Add(new Dictionary<string, object> { { "season", r["season"] }, { "season_name", r["season_name"] } });
                var listT = new List<Dictionary<string, object>>();
                foreach (DataRow r in dtTeam.Rows)
                    listT.Add(new Dictionary<string, object> { { "team", r["team"] }, { "team_name", r["team_name"] } });
                string script = "var dataSeason = " + serializer.Serialize(listS) + "; var dataTeam = " + serializer.Serialize(listT) + ";";
                ClientScript.RegisterStartupScript(this.GetType(), "InitData", script, true);
            }
        } catch (Exception ex) { }
    }

    [System.Web.Services.WebMethod]
    public static string FilterMatchHeaders(string team, string season, string dateFrom, string dateTo, string status)
    {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("bet_esport_matches", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@team", string.IsNullOrEmpty(team) ? "" : team);
                cmd.Parameters.AddWithValue("@season", string.IsNullOrEmpty(season) ? "" : season);
                cmd.Parameters.AddWithValue("@datefrom", string.IsNullOrEmpty(dateFrom) ? (object)DBNull.Value : dateFrom);
                cmd.Parameters.AddWithValue("@dateto", string.IsNullOrEmpty(dateTo) ? (object)DBNull.Value : dateTo);
                cmd.Parameters.AddWithValue("@status", string.IsNullOrEmpty(status) ? "1, 2, 3, 4" : status);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                var matches = new List<Dictionary<string, object>>();
                while (reader.Read()) {
                    var match = new Dictionary<string, object>();
                    for (int i = 0; i < reader.FieldCount; i++) {
                        match[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    }
                    matches.Add(match);
                }
                reader.Close();
                return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(matches);
            }
        } catch (Exception ex) {
            var r = new Dictionary<string, object>(); r["error"] = ex.Message;
            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(r);
        }
    }

    [System.Web.Services.WebMethod]
    public static string GetMatchGames(string matchId)
    {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand(@"
                    SELECT *
                    FROM bet_esport_game
                    WHERE match_id = @match
                    ORDER BY game_no", conn);
                cmd.Parameters.AddWithValue("@match", matchId);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                var games = new List<Dictionary<string, object>>();
                while (reader.Read()) {
                    var game = new Dictionary<string, object>();
                    for (int i = 0; i < reader.FieldCount; i++)
                        game[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    games.Add(game);
                }
                reader.Close();
                return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(games);
            }
        } catch (Exception ex) {
            var r = new Dictionary<string, object>(); r["error"] = ex.Message;
            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(r);
        }
    }

    [System.Web.Services.WebMethod]
    public static string FilterMatches(string team, string season, string dateFrom, string dateTo, string status)
    {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("bet_esport_matches", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@team", string.IsNullOrEmpty(team) ? "" : team);
                cmd.Parameters.AddWithValue("@season", string.IsNullOrEmpty(season) ? "" : season);
                cmd.Parameters.AddWithValue("@datefrom", string.IsNullOrEmpty(dateFrom) ? (object)DBNull.Value : dateFrom);
                cmd.Parameters.AddWithValue("@dateto", string.IsNullOrEmpty(dateTo) ? (object)DBNull.Value : dateTo);
                cmd.Parameters.AddWithValue("@status", string.IsNullOrEmpty(status) ? "" : status);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                var matches = new List<Dictionary<string, object>>();
                while (reader.Read()) {
                    var match = new Dictionary<string, object>();
                    for (int i = 0; i < reader.FieldCount; i++) {
                        match[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    }
                    matches.Add(match);
                }
                reader.Close();

                // Load game odds for all visible matches in one query. Avoids one SELECT per match.
                var gamesByMatch = new Dictionary<string, List<Dictionary<string, object>>>();
                if (matches.Count > 0)
                {
                    var paramNames = new List<string>();
                    SqlCommand cmdGame = new SqlCommand();
                    cmdGame.Connection = conn;
                    for (int i = 0; i < matches.Count; i++)
                    {
                        var id = matches[i].ContainsKey("match_id") && matches[i]["match_id"] != null ? matches[i]["match_id"].ToString() : "";
                        if (string.IsNullOrEmpty(id)) continue;
                        string param = "@m" + paramNames.Count;
                        paramNames.Add(param);
                        cmdGame.Parameters.AddWithValue(param, id);
                    }

                    if (paramNames.Count > 0)
                    {
                        cmdGame.CommandText = "SELECT * FROM bet_esport_game WHERE match_id IN (" + string.Join(",", paramNames.ToArray()) + ") ORDER BY match_id, game_no";
                        SqlDataReader rg = cmdGame.ExecuteReader();
                        while (rg.Read())
                        {
                            string gameMatchId = rg["match_id"] == DBNull.Value ? "" : rg["match_id"].ToString();
                            if (!gamesByMatch.ContainsKey(gameMatchId))
                                gamesByMatch[gameMatchId] = new List<Dictionary<string, object>>();

                            var g = new Dictionary<string, object>();
                            for (int i = 0; i < rg.FieldCount; i++)
                                g[rg.GetName(i)] = rg.IsDBNull(i) ? null : rg.GetValue(i);
                            gamesByMatch[gameMatchId].Add(g);
                        }
                        rg.Close();
                    }
                }

                foreach (var m in matches)
                {
                    var id = m.ContainsKey("match_id") && m["match_id"] != null ? m["match_id"].ToString() : "";
                    m["games"] = !string.IsNullOrEmpty(id) && gamesByMatch.ContainsKey(id)
                        ? gamesByMatch[id]
                        : new List<Dictionary<string, object>>();
                }

                return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(matches);
            }
        } catch (Exception ex) {
            var r = new Dictionary<string, object>(); r["error"] = ex.Message;
            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(r);
        }
    }

    [System.Web.Services.WebMethod]
    public static string GetMatchData(string matchId)
    {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("SELECT * FROM vbet_esport_match WHERE match_id = @match", conn);
                cmd.Parameters.AddWithValue("@match", matchId);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                if (reader.Read()) {
                    var d = new Dictionary<string, object>();
                    for (int i = 0; i < reader.FieldCount; i++)
                        d[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    reader.Close();

                    // Load game odds/details for edit form
                    var games = new List<Dictionary<string, object>>();
                    SqlCommand cmdGame = new SqlCommand(@"
                        SELECT *
                        FROM bet_esport_game
                        WHERE match_id = @match
                        ORDER BY game_no", conn);
                    cmdGame.Parameters.AddWithValue("@match", matchId);
                    SqlDataReader rdrGame = cmdGame.ExecuteReader();
                    while (rdrGame.Read())
                    {
                        var g = new Dictionary<string, object>();
                        for (int i = 0; i < rdrGame.FieldCount; i++)
                            g[rdrGame.GetName(i)] = rdrGame.IsDBNull(i) ? null : rdrGame.GetValue(i);
                        games.Add(g);
                    }
                    rdrGame.Close();
                    d["games"] = games;

                    return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(d);
                }
                reader.Close();
            }
            return null;
        } catch { return null; }
    }

    [System.Web.Services.WebMethod]
    public static string GetResultData(string matchId)
    {
        var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                var resultData = new Dictionary<string, object>();

                SqlCommand cmdMatch = new SqlCommand(@"
                    SELECT m.match_id,
                           m.home,
                           m.way,
                           ISNULL(h.team_name, m.home) AS home_name,
                           ISNULL(w.team_name, m.way) AS way_name
                    FROM bet_esport_match m
                    LEFT JOIN bet_team h ON h.team = m.home
                    LEFT JOIN bet_team w ON w.team = m.way
                    WHERE m.match_id = @match", conn);
                cmdMatch.Parameters.AddWithValue("@match", matchId);
                SqlDataReader rm = cmdMatch.ExecuteReader();
                if (!rm.Read())
                {
                    rm.Close();
                    resultData["error"] = "Không tìm thấy trận đấu";
                    return serializer.Serialize(resultData);
                }
                resultData["match_id"] = rm["match_id"] == DBNull.Value ? "" : rm["match_id"].ToString();
                resultData["home"] = rm["home"] == DBNull.Value ? "" : rm["home"].ToString();
                resultData["way"] = rm["way"] == DBNull.Value ? "" : rm["way"].ToString();
                resultData["home_name"] = rm["home_name"] == DBNull.Value ? "" : rm["home_name"].ToString();
                resultData["way_name"] = rm["way_name"] == DBNull.Value ? "" : rm["way_name"].ToString();
                rm.Close();

                var ticketResultFields = GetEsportTicketResultFields(conn, matchId);

                var games = new List<Dictionary<string, object>>();
                SqlCommand cmdGame = new SqlCommand(@"
                    SELECT game_no,
                           ou_line, ou_over_win, ou_under_win,
                           hc_line, hc_home_win, hc_way_win,
                           minute_line, minute_over_win, minute_under_win,
                           dragon_ou_line, dragon_ou_over_win, dragon_ou_under_win,
                           dragon_hc_line, dragon_hc_home_win, dragon_hc_way_win,
                           first_dragon_home_win, first_dragon_way_win,
                           first_dragon_tech_win, first_dragon_chemtech_win, first_dragon_wind_win, first_dragon_water_win,
                           first_dragon_fire_win, first_dragon_earth_win,
                           first_home_win, first_way_win,
                           third_home_win, third_way_win,
                           five_home_win, five_way_win,
                           ten_home_win, ten_way_win,
                           win_home_win, win_way_win,
                           result_kill_home, result_kill_way, result_minute,
                           result_dragon_home, result_dragon_way, result_first_dragon,
                           result_first_dragon_type,
                           result_first, result_third, result_five, result_ten, result_win
                    FROM bet_esport_game
                    WHERE match_id = @match
                    ORDER BY game_no", conn);
                cmdGame.Parameters.AddWithValue("@match", matchId);
                SqlDataReader rg = cmdGame.ExecuteReader();
                while (rg.Read())
                {
                    var g = new Dictionary<string, object>();
                    for (int i = 0; i < rg.FieldCount; i++)
                        g[rg.GetName(i)] = rg.IsDBNull(i) ? null : rg.GetValue(i);
                    int gameNo = Convert.ToInt32(g["game_no"]);
                    g["result_fields"] = ticketResultFields.ContainsKey(gameNo)
                        ? ticketResultFields[gameNo]
                        : new Dictionary<string, bool>();
                    games.Add(g);
                }
                rg.Close();
                resultData["games"] = games;
                return serializer.Serialize(resultData);
            }
        }
        catch (Exception ex)
        {
            var err = new Dictionary<string, object>();
            err["error"] = ex.Message;
            return serializer.Serialize(err);
        }
    }

    private static Dictionary<int, Dictionary<string, bool>> GetEsportTicketResultFields(SqlConnection conn, string matchId)
    {
        var games = new Dictionary<int, Dictionary<string, bool>>();
        SqlCommand cmd = new SqlCommand(@"
            SELECT DISTINCT code
            FROM bet_ticket_esport
            WHERE match_id = @match", conn);
        cmd.Parameters.AddWithValue("@match", matchId);
        SqlDataReader reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            string code = reader["code"] == DBNull.Value ? "" : reader["code"].ToString().Trim().ToUpper();
            if (!code.StartsWith("G")) continue;

            string[] parts = code.Split('.');
            if (parts.Length < 3) continue;

            int gameNo;
            if (!int.TryParse(parts[0].Substring(1), out gameNo)) continue;
            if (!games.ContainsKey(gameNo)) games[gameNo] = new Dictionary<string, bool>();

            string market = parts[1];
            if (market == "OU" || market == "HC")
            {
                games[gameNo]["kill"] = true;
            }
            else if (market == "MIN")
            {
                games[gameNo]["minute"] = true;
            }
            else if (market == "DOU" || market == "DHC")
            {
                games[gameNo]["dragon"] = true;
            }
            else if (market == "FD")
            {
                games[gameNo]["first_dragon"] = true;
            }
            else if (market == "FDT" || market == "FDCHEM" || market == "FDWIND" || market == "FDWATER" || market == "FDFIRE" || market == "FDEARTH")
            {
                games[gameNo]["first_dragon_type"] = true;
            }
            else if (market == "FIRST")
            {
                games[gameNo]["first"] = true;
            }
            else if (market == "THIRD")
            {
                games[gameNo]["third"] = true;
            }
            else if (market == "FIVE")
            {
                games[gameNo]["five"] = true;
            }
            else if (market == "TEN")
            {
                games[gameNo]["ten"] = true;
            }
            else if (market == "WIN")
            {
                games[gameNo]["win"] = true;
            }
        }
        reader.Close();
        return games;
    }

    [System.Web.Services.WebMethod]
    public static string SaveResultData(string resultData)
    {
        var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
        try
        {
            if (HttpContext.Current.Session["UserID"] == null)
                return serializer.Serialize(new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", "Phiên làm việc đã hết hạn." } });

            string body = resultData ?? "";
            var ser = new System.Web.Script.Serialization.JavaScriptSerializer();
            var data = ser.Deserialize<Dictionary<string, object>>(body);
            string matchId = data.ContainsKey("match_id") ? (data["match_id"] ?? "").ToString() : "";
            var games = data.ContainsKey("games") ? data["games"] as System.Collections.ArrayList : null;
            bool endGame = data.ContainsKey("end_game") && Convert.ToBoolean(data["end_game"]);
            if (string.IsNullOrEmpty(matchId) || games == null)
                return serializer.Serialize(new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", "Dữ liệu không hợp lệ." } });

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                using (SqlTransaction tran = conn.BeginTransaction())
                {
                    try
                    {
                        if (endGame)
                        {
                            string endGameError;
                            ApplyEsportEndGameResults(conn, tran, matchId, games, out endGameError);
                            if (!string.IsNullOrEmpty(endGameError))
                            {
                                tran.Rollback();
                                return serializer.Serialize(new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", endGameError } });
                            }
                        }

                        foreach (var item in games)
                        {
                            var g = item as Dictionary<string, object>;
                            if (g == null) continue;
                            int gameNo = g.ContainsKey("game_no") ? Convert.ToInt32(g["game_no"]) : 0;
                            if (gameNo <= 0) continue;

                            SqlCommand cmd = new SqlCommand(@"
                                UPDATE bet_esport_game
                                SET result_kill_home = CASE WHEN @has_result_kill_home = 1 THEN @result_kill_home ELSE result_kill_home END,
                                    result_kill_way  = CASE WHEN @has_result_kill_way = 1 THEN @result_kill_way ELSE result_kill_way END,
                                    result_minute    = CASE WHEN @has_result_minute = 1 THEN @result_minute ELSE result_minute END,
                                    result_dragon_home = CASE WHEN @has_result_dragon_home = 1 THEN @result_dragon_home ELSE result_dragon_home END,
                                    result_dragon_way  = CASE WHEN @has_result_dragon_way = 1 THEN @result_dragon_way ELSE result_dragon_way END,
                                    result_first_dragon = CASE WHEN @has_result_first_dragon = 1 THEN @result_first_dragon ELSE result_first_dragon END,
                                    result_first_dragon_type = CASE WHEN @has_result_first_dragon_type = 1 THEN @result_first_dragon_type ELSE result_first_dragon_type END,
                                    result_first     = CASE WHEN @has_result_first = 1 THEN @result_first ELSE result_first END,
                                    result_third     = CASE WHEN @has_result_third = 1 THEN @result_third ELSE result_third END,
                                    result_five      = CASE WHEN @has_result_five = 1 THEN @result_five ELSE result_five END,
                                    result_ten       = CASE WHEN @has_result_ten = 1 THEN @result_ten ELSE result_ten END,
                                    result_win       = CASE WHEN @has_result_win = 1 THEN @result_win ELSE result_win END
                                WHERE match_id = @match_id AND game_no = @game_no", conn, tran);
                            cmd.Parameters.AddWithValue("@match_id", matchId);
                            cmd.Parameters.AddWithValue("@game_no", gameNo);
                            cmd.Parameters.AddWithValue("@has_result_kill_home", HasKey(g, "result_kill_home"));
                            cmd.Parameters.AddWithValue("@has_result_kill_way", HasKey(g, "result_kill_way"));
                            cmd.Parameters.AddWithValue("@has_result_minute", HasKey(g, "result_minute"));
                            cmd.Parameters.AddWithValue("@has_result_dragon_home", HasKey(g, "result_dragon_home"));
                            cmd.Parameters.AddWithValue("@has_result_dragon_way", HasKey(g, "result_dragon_way"));
                            cmd.Parameters.AddWithValue("@has_result_first_dragon", HasKey(g, "result_first_dragon"));
                            cmd.Parameters.AddWithValue("@has_result_first_dragon_type", HasKey(g, "result_first_dragon_type"));
                            cmd.Parameters.AddWithValue("@has_result_first", HasKey(g, "result_first"));
                            cmd.Parameters.AddWithValue("@has_result_third", HasKey(g, "result_third"));
                            cmd.Parameters.AddWithValue("@has_result_five", HasKey(g, "result_five"));
                            cmd.Parameters.AddWithValue("@has_result_ten", HasKey(g, "result_ten"));
                            cmd.Parameters.AddWithValue("@has_result_win", HasKey(g, "result_win"));
                            cmd.Parameters.AddWithValue("@result_kill_home", ParseDecimalOrDbNull(g, "result_kill_home"));
                            cmd.Parameters.AddWithValue("@result_kill_way", ParseDecimalOrDbNull(g, "result_kill_way"));
                            cmd.Parameters.AddWithValue("@result_minute", ParseDecimalOrDbNull(g, "result_minute"));
                            cmd.Parameters.AddWithValue("@result_dragon_home", ParseDecimalOrDbNull(g, "result_dragon_home"));
                            cmd.Parameters.AddWithValue("@result_dragon_way", ParseDecimalOrDbNull(g, "result_dragon_way"));
                            cmd.Parameters.AddWithValue("@result_first_dragon", ParseStrOrDbNull(g, "result_first_dragon"));
                            cmd.Parameters.AddWithValue("@result_first_dragon_type", ParseStrOrDbNull(g, "result_first_dragon_type"));
                            cmd.Parameters.AddWithValue("@result_first", ParseStrOrDbNull(g, "result_first"));
                            cmd.Parameters.AddWithValue("@result_third", ParseStrOrDbNull(g, "result_third"));
                            cmd.Parameters.AddWithValue("@result_five", ParseStrOrDbNull(g, "result_five"));
                            cmd.Parameters.AddWithValue("@result_ten", ParseStrOrDbNull(g, "result_ten"));
                            cmd.Parameters.AddWithValue("@result_win", ParseStrOrDbNull(g, "result_win"));
                            cmd.ExecuteNonQuery();
                        }

                        tran.Commit();
                        return serializer.Serialize(new Dictionary<string, object> { { "isSuccess", 1 }, { "msg", "Lưu kết quả thành công." } });
                    }
                    catch (Exception ex2)
                    {
                        tran.Rollback();
                        return serializer.Serialize(new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", "Lỗi khi lưu: " + ex2.Message } });
                    }
                }
            }
        }
        catch (Exception ex)
        {
            return serializer.Serialize(new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", "Lỗi: " + ex.Message } });
        }
    }

    private static void ApplyEsportEndGameResults(SqlConnection conn, SqlTransaction tran, string matchId, System.Collections.ArrayList games, out string error)
    {
        error = "";
        var ticketFields = GetEsportTicketResultFields(conn, matchId, tran);
        var existingGames = GetEsportGamesForEndGame(conn, tran, matchId);
        var gameMap = new Dictionary<int, Dictionary<string, object>>();

        foreach (var item in games)
        {
            var g = item as Dictionary<string, object>;
            if (g == null || !g.ContainsKey("game_no")) continue;
            int gameNo;
            if (!int.TryParse((g["game_no"] ?? "").ToString(), out gameNo) || gameNo <= 0) continue;
            gameMap[gameNo] = g;
        }

        int boHome;
        int boWay;
        BuildBoXScore(existingGames, gameMap, out boHome, out boWay);

        foreach (var kv in ticketFields)
        {
            int gameNo = kv.Key;
            if (!existingGames.ContainsKey(gameNo)) continue;
            if (!gameMap.ContainsKey(gameNo)) gameMap[gameNo] = new Dictionary<string, object> { { "game_no", gameNo } };

            var fields = kv.Value;
            var source = existingGames[gameNo];
            var target = gameMap[gameNo];
            var effectiveSource = MergePendingEndGameValues(source, target);
            bool unenteredGame = IsUnenteredResultWin(effectiveSource);
            bool forceRecalculate = unenteredGame && !HasAnyPendingResultValue(target);

            if (HasVisibleField(fields, "kill") && (gameNo == 6 || IsMissingOrAutoEndGameResult(effectiveSource, "result_kill_home", "result_kill_way", unenteredGame)))
            {
                if (gameNo == 6)
                {
                    PutValue(target, "result_kill_home", boHome.ToString(System.Globalization.CultureInfo.InvariantCulture));
                    PutValue(target, "result_kill_way", boWay.ToString(System.Globalization.CultureInfo.InvariantCulture));
                }
                else
                {
                    decimal home;
                    decimal way;
                    if (!TryBuildDrawPair(effectiveSource, "ou_line", "hc_line", HasVisibleField(fields, "kill_ou"), HasVisibleField(fields, "kill_hc"), out home, out way))
                    {
                        error = "Không thể tự tính hòa kill/game cho Game " + gameNo + " vì line không hợp lệ.";
                        return;
                    }
                    PutEndGameValue(target, "result_kill_home", DecimalToText(home), forceRecalculate);
                    PutEndGameValue(target, "result_kill_way", DecimalToText(way), forceRecalculate);
                }
            }

            if (HasVisibleField(fields, "minute") && (IsDbNull(effectiveSource, "result_minute") || unenteredGame))
                PutEndGameValue(target, "result_minute", DecimalToText(GetDecimalOrZero(effectiveSource, "minute_line")), forceRecalculate);

            if (HasVisibleField(fields, "dragon") && IsMissingOrAutoEndGameResult(effectiveSource, "result_dragon_home", "result_dragon_way", unenteredGame))
            {
                decimal home;
                decimal way;
                if (!TryBuildDrawPair(effectiveSource, "dragon_ou_line", "dragon_hc_line", HasVisibleField(fields, "dragon_ou"), HasVisibleField(fields, "dragon_hc"), out home, out way))
                {
                    error = "Không thể tự tính hòa rồng cho Game " + gameNo + " vì line không hợp lệ.";
                    return;
                }
                PutEndGameValue(target, "result_dragon_home", DecimalToText(home), forceRecalculate);
                PutEndGameValue(target, "result_dragon_way", DecimalToText(way), forceRecalculate);
            }

            if (HasVisibleField(fields, "first_dragon") && (IsDbNull(effectiveSource, "result_first_dragon") || unenteredGame))
                PutEndGameValue(target, "result_first_dragon", "draw", forceRecalculate);
            if (HasVisibleField(fields, "first_dragon_type") && (IsDbNull(effectiveSource, "result_first_dragon_type") || unenteredGame))
                PutEndGameValue(target, "result_first_dragon_type", "draw", forceRecalculate);
            if (HasVisibleField(fields, "first") && (IsDbNull(effectiveSource, "result_first") || unenteredGame))
                PutEndGameValue(target, "result_first", "draw", forceRecalculate);
            if (HasVisibleField(fields, "third") && (IsDbNull(effectiveSource, "result_third") || unenteredGame))
                PutEndGameValue(target, "result_third", "draw", forceRecalculate);
            if (HasVisibleField(fields, "five") && (IsDbNull(effectiveSource, "result_five") || unenteredGame))
                PutEndGameValue(target, "result_five", "draw", forceRecalculate);
            if (HasVisibleField(fields, "ten") && (IsDbNull(effectiveSource, "result_ten") || unenteredGame))
                PutEndGameValue(target, "result_ten", "draw", forceRecalculate);
            if (gameNo != 6 && (IsDbNull(effectiveSource, "result_win") || unenteredGame))
                PutIfMissing(target, "result_win", "draw");
        }

        games.Clear();
        foreach (var kv in gameMap)
            games.Add(kv.Value);
    }

    private static Dictionary<int, Dictionary<string, object>> GetEsportGamesForEndGame(SqlConnection conn, SqlTransaction tran, string matchId)
    {
        var games = new Dictionary<int, Dictionary<string, object>>();
        SqlCommand cmd = new SqlCommand(@"
            SELECT game_no, ou_line, hc_line, minute_line, dragon_ou_line, dragon_hc_line,
                   result_kill_home, result_kill_way, result_minute,
                   result_dragon_home, result_dragon_way, result_first_dragon,
                   result_first_dragon_type,
                   result_first, result_third, result_five, result_ten, result_win
            FROM bet_esport_game
            WHERE match_id = @match", conn, tran);
        cmd.Parameters.AddWithValue("@match", matchId);
        SqlDataReader reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            var g = new Dictionary<string, object>();
            for (int i = 0; i < reader.FieldCount; i++)
                g[reader.GetName(i)] = reader.IsDBNull(i) ? DBNull.Value : reader.GetValue(i);
            games[Convert.ToInt32(g["game_no"])] = g;
        }
        reader.Close();
        return games;
    }

    private static void BuildBoXScore(Dictionary<int, Dictionary<string, object>> existingGames, Dictionary<int, Dictionary<string, object>> gameMap, out int home, out int way)
    {
        home = 0;
        way = 0;
        for (int gameNo = 1; gameNo <= 5; gameNo++)
        {
            string resultWin = GetPendingOrExistingResult(gameMap, existingGames, gameNo, "result_win");
            if (resultWin == "home") home++;
            else if (resultWin == "way") way++;
        }
    }

    private static string GetPendingOrExistingResult(Dictionary<int, Dictionary<string, object>> gameMap, Dictionary<int, Dictionary<string, object>> existingGames, int gameNo, string key)
    {
        if (gameMap.ContainsKey(gameNo) && gameMap[gameNo].ContainsKey(key))
        {
            if (gameMap[gameNo][key] == null) return "";
            return gameMap[gameNo][key].ToString().Trim().ToLower();
        }

        if (existingGames.ContainsKey(gameNo) && existingGames[gameNo].ContainsKey(key) && existingGames[gameNo][key] != null && existingGames[gameNo][key] != DBNull.Value)
            return existingGames[gameNo][key].ToString().Trim().ToLower();

        return "";
    }

    private static Dictionary<int, Dictionary<string, bool>> GetEsportTicketResultFields(SqlConnection conn, string matchId, SqlTransaction tran)
    {
        var games = new Dictionary<int, Dictionary<string, bool>>();
        SqlCommand cmd = new SqlCommand(@"
            SELECT DISTINCT code
            FROM bet_ticket_esport
            WHERE match_id = @match", conn, tran);
        cmd.Parameters.AddWithValue("@match", matchId);
        SqlDataReader reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            string code = reader["code"] == DBNull.Value ? "" : reader["code"].ToString().Trim().ToUpper();
            if (!code.StartsWith("G")) continue;

            string[] parts = code.Split('.');
            if (parts.Length < 3) continue;

            int gameNo;
            if (!int.TryParse(parts[0].Substring(1), out gameNo)) continue;
            if (!games.ContainsKey(gameNo)) games[gameNo] = new Dictionary<string, bool>();

            string market = parts[1];
            if (market == "OU")
            {
                games[gameNo]["kill"] = true;
                games[gameNo]["kill_ou"] = true;
            }
            else if (market == "HC")
            {
                games[gameNo]["kill"] = true;
                games[gameNo]["kill_hc"] = true;
            }
            else if (market == "MIN") games[gameNo]["minute"] = true;
            else if (market == "DOU")
            {
                games[gameNo]["dragon"] = true;
                games[gameNo]["dragon_ou"] = true;
            }
            else if (market == "DHC")
            {
                games[gameNo]["dragon"] = true;
                games[gameNo]["dragon_hc"] = true;
            }
            else if (market == "FD") games[gameNo]["first_dragon"] = true;
            else if (market == "FDT" || market == "FDCHEM" || market == "FDWIND" || market == "FDWATER" || market == "FDFIRE" || market == "FDEARTH") games[gameNo]["first_dragon_type"] = true;
            else if (market == "FIRST") games[gameNo]["first"] = true;
            else if (market == "THIRD") games[gameNo]["third"] = true;
            else if (market == "FIVE") games[gameNo]["five"] = true;
            else if (market == "TEN") games[gameNo]["ten"] = true;
            else if (market == "WIN") games[gameNo]["win"] = true;
        }
        reader.Close();
        return games;
    }

    private static bool TryBuildDrawPair(Dictionary<string, object> g, string totalField, string handicapField, bool hasOverUnder, bool hasHandicap, out decimal home, out decimal way)
    {
        decimal total = GetDecimalOrZero(g, totalField);
        decimal handicap = GetDecimalOrZero(g, handicapField);
        if (hasOverUnder && hasHandicap)
        {
            home = (total - handicap) / 2m;
            way = (total + handicap) / 2m;
        }
        else if (hasOverUnder)
        {
            home = total;
            way = 0m;
        }
        else if (hasHandicap)
        {
            home = handicap < 0 ? -handicap : 0m;
            way = handicap > 0 ? handicap : 0m;
        }
        else
        {
            home = 0m;
            way = 0m;
        }
        return home >= 0 && way >= 0;
    }

    private static bool HasVisibleField(Dictionary<string, bool> fields, string key)
    {
        return fields.ContainsKey(key) && fields[key];
    }

    private static bool IsDbNull(Dictionary<string, object> g, string key)
    {
        return !g.ContainsKey(key) || g[key] == null || g[key] == DBNull.Value || string.IsNullOrWhiteSpace(g[key].ToString());
    }

    private static bool IsUnenteredResultWin(Dictionary<string, object> g)
    {
        if (IsDbNull(g, "result_win")) return true;
        return g["result_win"].ToString().Trim().ToLower() == "draw";
    }

    private static bool IsMissingOrAutoEndGameResult(Dictionary<string, object> g, string homeKey, string wayKey, bool unenteredGame)
    {
        return (IsDbNull(g, homeKey) && IsDbNull(g, wayKey)) || unenteredGame;
    }

    private static bool HasPendingValue(Dictionary<string, object> g, string key)
    {
        return g.ContainsKey(key) && g[key] != null && !string.IsNullOrWhiteSpace(g[key].ToString());
    }

    private static bool HasAnyPendingResultValue(Dictionary<string, object> g)
    {
        string[] keys = {
            "result_kill_home", "result_kill_way", "result_minute",
            "result_dragon_home", "result_dragon_way", "result_first_dragon",
            "result_first_dragon_type", "result_first", "result_third",
            "result_five", "result_ten", "result_win"
        };
        foreach (string key in keys)
        {
            if (HasPendingValue(g, key)) return true;
        }
        return false;
    }

    private static Dictionary<string, object> MergePendingEndGameValues(Dictionary<string, object> source, Dictionary<string, object> pending)
    {
        var merged = new Dictionary<string, object>(source);
        string[] keys = {
            "result_kill_home", "result_kill_way", "result_minute",
            "result_dragon_home", "result_dragon_way", "result_first_dragon",
            "result_first_dragon_type", "result_first", "result_third",
            "result_five", "result_ten", "result_win"
        };
        foreach (string key in keys)
        {
            if (HasPendingValue(pending, key)) merged[key] = pending[key];
        }
        return merged;
    }

    private static decimal GetDecimalOrZero(Dictionary<string, object> g, string key)
    {
        if (IsDbNull(g, key)) return 0m;
        decimal v;
        return decimal.TryParse(g[key].ToString(), out v) ? v : 0m;
    }

    private static void PutIfMissing(Dictionary<string, object> g, string key, string value)
    {
        if (!g.ContainsKey(key) || g[key] == null || string.IsNullOrWhiteSpace(g[key].ToString()))
            g[key] = value;
    }

    private static void PutEndGameValue(Dictionary<string, object> g, string key, string value, bool force)
    {
        if (force) PutValue(g, key, value);
        else PutIfMissing(g, key, value);
    }

    private static void PutValue(Dictionary<string, object> g, string key, string value)
    {
        g[key] = value;
    }

    private static string DecimalToText(decimal value)
    {
        return value.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture);
    }

    private static int HasKey(Dictionary<string, object> d, string key)
    {
        return d.ContainsKey(key) ? 1 : 0;
    }

    private static object ParseStrOrDbNull(Dictionary<string, object> d, string key)
    {
        if (!d.ContainsKey(key) || d[key] == null) return DBNull.Value;
        string v = d[key].ToString().Trim().ToLower();
        if (v != "home" && v != "way" && v != "draw" &&
            v != "tech" && v != "chemtech" && v != "fire" && v != "earth" && v != "water" && v != "wind") return DBNull.Value;
        return v;
    }

    private static object ParseDecimalOrDbNull(Dictionary<string, object> d, string key)
    {
        if (!d.ContainsKey(key) || d[key] == null) return DBNull.Value;
        string raw = d[key].ToString().Trim();
        if (raw.Contains(":"))
        {
            string[] parts = raw.Split(':');
            int minutes;
            int seconds;
            if (parts.Length != 2 ||
                !int.TryParse(parts[0], out minutes) ||
                !int.TryParse(parts[1], out seconds) ||
                minutes < 0 ||
                seconds < 0 ||
                seconds > 59)
                return DBNull.Value;

            return Math.Round(minutes + (seconds / 60m), 3);
        }

        if (System.Text.RegularExpressions.Regex.IsMatch(raw, @"^\d{3,}$"))
        {
            int minutes;
            int seconds;
            if (int.TryParse(raw.Substring(0, raw.Length - 2), out minutes) &&
                int.TryParse(raw.Substring(raw.Length - 2), out seconds) &&
                seconds <= 59)
                return Math.Round(minutes + (seconds / 60m), 3);
        }

        decimal v;
        if (decimal.TryParse(raw, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out v))
            return Math.Round(v, 3);
        return decimal.TryParse(raw, out v) ? (object)Math.Round(v, 3) : DBNull.Value;
    }

    [System.Web.Services.WebMethod]
    public static string DeleteMatch(string matchId)
    {
        try {
            if (HttpContext.Current.Session["UserID"] == null) {
                var r = new Dictionary<string, object>(); r["isSuccess"] = 0; r["msg"] = "Phiên làm việc đã hết hạn.";
                return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(r);
            }
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("exec bet_esport_match_delete @match, @userID", conn);
                cmd.Parameters.AddWithValue("@match", matchId);
                cmd.Parameters.AddWithValue("@userID", HttpContext.Current.Session["UserID"]);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                int isSuccess = 0; string msg = "";
                if (reader.Read()) {
                    isSuccess = reader["isSuccess"] != DBNull.Value ? Convert.ToInt32(reader["isSuccess"]) : 0;
                    msg = reader["msg"] != DBNull.Value ? reader["msg"].ToString() : "Có lỗi xảy ra";
                }
                reader.Close();
                var res = new Dictionary<string, object>(); res["isSuccess"] = isSuccess; res["msg"] = msg;
                return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(res);
            }
        } catch (Exception ex) {
            var r = new Dictionary<string, object>(); r["isSuccess"] = 0; r["msg"] = "Lỗi: " + ex.Message;
            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(r);
        }
    }

    protected void ucAddEsport_MatchAdded(object sender, EventArgs e) { BindMatchTable(); }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Trận đấu Esports</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .nav-item { border-right: 4px solid transparent; display: flex; align-items: center; padding: 0.75rem 1rem; font-weight: bold; transition: all 0.2s; }
        .nav-item-active { border-right-color: #1d4ed8; background-color: #eff6ff; color: #1d4ed8 !important; }
        .nav-item i { width: 20px; text-align: center; margin-right: 12px; }
        input:focus { font-size: 16px !important; }
        .esport-match-detail-scroll {
            max-height: 220px;
            overflow-y: auto;
            overscroll-behavior: contain;
            padding-right: 4px;
        }
        .esport-match-detail-scroll::-webkit-scrollbar { width: 4px; }
        .esport-match-detail-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .menu-font { font-size: 16px; font-weight: bold; }
        .breadcrumb-link { color: #2563eb; text-decoration: none; }
        .breadcrumb-current { color: #4b5563; cursor: default; }
    </style>
</head>
<body class="h-[100dvh] flex flex-col">
    <form runat="server" class="h-full flex flex-col">
        <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
            <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="esports" PageTitle="Esports" />
        </nav>
        <div class="flex flex-1 overflow-hidden relative">
            <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>
            <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="esports" />
            <main class="flex-1 flex flex-col overflow-hidden bg-[#f8fafc]">
                <!-- Bộ lọc -->
                <div class="flex-none bg-white border-b">
                    <div class="p-3 lg:p-6 pb-3 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition-colors" onclick="toggleFilter()">
                        <h3 class="text-base font-bold text-gray-700 flex items-center gap-2">
                            <i class="fa-solid fa-filter text-purple-600"></i>Bộ lọc
                        </h3>
                        <i id="filterIcon" class="fa-solid fa-chevron-down text-gray-600 transition-transform"></i>
                    </div>
                    <div id="filterContent" class="hidden px-3 lg:px-6 pb-3">
                        <div class="grid grid-cols-1 lg:grid-cols-5 gap-3">
                            <div class="col-span-1 lg:col-span-2 grid grid-cols-2 gap-3">
                                <div class="relative">
                                    <label class="block text-base font-bold text-gray-700 mb-1">Đội</label>
                                    <input type="text" id="filterTeamSearch" class="w-full border rounded-lg p-2 text-base font-bold focus:ring-2 focus:ring-purple-500 outline-none" placeholder="Tìm kiếm đội..." onfocus="showTeamDropdown()" oninput="filterTeamOptions()" />
                                    <input type="hidden" id="filterTeam" name="filterTeam" />
                                    <div id="teamDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto"></div>
                                </div>
                                <div class="relative">
                                    <label class="block text-base font-bold text-gray-700 mb-1">Giải đấu</label>
                                    <input type="text" id="filterSeasonSearch" class="w-full border rounded-lg p-2 text-base font-bold focus:ring-2 focus:ring-purple-500 outline-none" placeholder="Tìm kiếm giải đấu..." onfocus="showSeasonDropdown()" oninput="filterSeasonOptions()" />
                                    <input type="hidden" id="filterSeason" name="filterSeason" />
                                    <div id="seasonDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto"></div>
                                </div>
                            </div>
                            <div class="col-span-1 lg:col-span-2 grid grid-cols-2 gap-3">
                                <div>
                                    <label class="block text-base font-bold text-gray-700 mb-1">Từ ngày</label>
                                    <input type="date" id="filterDateFrom" name="filterDateFrom" class="w-full border rounded-lg p-2 text-base font-bold focus:ring-2 focus:ring-purple-500 outline-none" />
                                </div>
                                <div>
                                    <label class="block text-base font-bold text-gray-700 mb-1">Đến ngày</label>
                                    <input type="date" id="filterDateTo" name="filterDateTo" class="w-full border rounded-lg p-2 text-base font-bold focus:ring-2 focus:ring-purple-500 outline-none" />
                                </div>
                            </div>
                            <div>
                                <label class="block text-base font-bold text-gray-700 mb-1">Trạng thái</label>
                                <div class="border rounded-lg p-2 bg-white">
                                    <label class="flex items-center gap-2 mb-1"><input type="checkbox" name="filterStatus" value="1" class="w-4 h-4" checked /><span class="text-base font-bold">Trực tiếp</span></label>
                                    <label class="flex items-center gap-2 mb-1"><input type="checkbox" name="filterStatus" value="2" class="w-4 h-4" checked /><span class="text-base font-bold">Sắp tới</span></label>
                                    <label class="flex items-center gap-2 mb-1"><input type="checkbox" name="filterStatus" value="3" class="w-4 h-4" checked /><span class="text-base font-bold">Chờ kết quả</span></label>
                                    <label class="flex items-center gap-2 mb-1"><input type="checkbox" name="filterStatus" value="4" class="w-4 h-4" checked /><span class="text-base font-bold">Chưa tất toán</span></label>
                                    <label class="flex items-center gap-2"><input type="checkbox" name="filterStatus" value="5" class="w-4 h-4" /><span class="text-base font-bold">Kết thúc</span></label>
                                </div>
                            </div>
                        </div>
                        <div class="mt-3 flex justify-end">
                            <button type="button" onclick="applyFilter()" class="bg-purple-600 hover:bg-purple-700 text-white px-6 py-2 rounded-lg font-bold text-base transition-all active:scale-95 flex items-center gap-2">
                                <i class="fa-solid fa-search"></i>Tìm kiếm
                            </button>
                        </div>
                    </div>
                </div>

                <div class="flex-none p-3 lg:p-6 pb-0">
                    <% if (CheckRight("bet_match_insert")) { %>
                    <button type="button" onclick="openAddEsportModal()" class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2.5 rounded-xl shadow-lg flex items-center transition-all active:scale-95 group border-2 border-white">
                        <i class="fa-solid fa-plus mr-2 group-hover:rotate-90 transition-transform"></i>
                        <span class="font-bold text-[11px] lg:text-xs tracking-wide">Thêm trận</span>
                    </button>
                    <% } %>
                </div>

                <div class="flex-1 overflow-auto main-scroll p-3 lg:p-6 pt-4">
                    <div id="matchesContainer" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <asp:Repeater ID="rptMatches" runat="server">
                            <ItemTemplate>
                                <div class="bg-white rounded-xl shadow-md border border-gray-200 p-4 flex flex-col transition-all hover:shadow-lg <%# GetEsportStatusTextClass(Eval("status")) %>">
                                    <div class="flex justify-end items-center gap-2 mb-3">
                                        <button type="button" onclick="openTicketMatchModal('<%# Eval("match_id") %>', '<%# Eval("home") %> vs <%# Eval("way") %>', 'esport')"
                                            class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-ticket mr-1"></i>Vé cược
                                        </button>
                                        <% if (CheckRight("bet_match_result")) { %>
                                        <button type="button" onclick="openEsportResult('<%# Eval("match_id") %>')"
                                            class="bg-purple-500 hover:bg-purple-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-flag-checkered mr-1"></i>Kết quả
                                        </button>
                                        <% } %>
                                        <% if (CheckRight("bet_match_insert")) { %>
                                        <button type="button" onclick="copyMatch('<%# Eval("match_id") %>')"
                                            class="bg-green-500 hover:bg-green-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-copy mr-1"></i>Sao chép
                                        </button>
                                        <% } %>
                                        <button type="button" style='<%# CanManageMatchRow(Container.DataItem) ? "" : "display:none" %>' onclick="editMatch('<%# Eval("match_id") %>')" class="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-pen-to-square mr-1"></i>Sửa
                                        </button>
                                        <button type="button" style='<%# CanManageMatchRow(Container.DataItem) ? "" : "display:none" %>' onclick="deleteMatch('<%# Eval("match_id") %>')" class="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-trash mr-1"></i>Xóa
                                        </button>
                                    </div>
                                    <div class="flex justify-between items-center gap-3 mb-1 font-bold text-base">
                                        <div class="min-w-0 text-left">
                                            <%# string.IsNullOrWhiteSpace(GetRowString(Container.DataItem, "host_name")) ? "" : "<span class=\"bg-gray-50 px-2 py-0.5 rounded text-base border border-current font-bold\">Cái: " + Server.HtmlEncode(GetRowString(Container.DataItem, "host_name")) + "</span>" %>
                                        </div>
                                        <span class="font-bold text-right whitespace-nowrap"><%# Eval("statusname") %></span>
                                    </div>
                                    <div class="flex justify-between items-center gap-3 mb-2 font-bold text-base">
                                        <span class="bg-gray-50 px-2 py-0.5 rounded text-base border border-current"><%# Eval("season") %></span>
                                        <span class="text-base text-right whitespace-nowrap"><%# Eval("match_time", "{0:HH:mm dd/MM/yyyy}") %></span>
                                    </div>
                                    <div class="flex justify-between items-center mb-3 font-black text-base">
                                        <div class="w-[45%] text-right"><%# Eval("home") %></div>
                                        <div class="w-[10%] text-center font-bold">vs</div>
                                        <div class="w-[45%] text-left"><%# Eval("way") %></div>
                                    </div>
                                    <!-- Tóm tắt số game -->
                                    <div class="text-center text-base font-bold mb-2">
                                        BO<%# Eval("total_games") %>
                                    </div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>
            </main>
        </div>
        <uc:AddEsport runat="server" ID="ucAddEsport" OnMatchAdded="ucAddEsport_MatchAdded" />
        <uc:TicketMatch runat="server" ID="ucTicketMatch" />
        <div id="modalEsportResult" class="fixed inset-0 bg-gray-900/80 z-[70] hidden items-center justify-center p-3">
            <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-4xl max-h-[92vh] flex flex-col overflow-hidden">
                <div class="bg-gradient-to-r from-purple-600 to-purple-700 px-4 py-3 text-white flex items-center justify-between">
                    <h3 class="font-bold text-base"><i class="fa-solid fa-flag-checkered mr-2"></i>Kết quả Esports - <span id="erMatchLabel"></span></h3>
                    <button type="button" onclick="closeEsportResultModal()" class="text-white text-xl"><i class="fa-solid fa-xmark"></i></button>
                </div>
                <div class="px-4 py-3 bg-purple-50 border-b border-purple-100">
                    <label class="inline-flex items-center gap-2 font-bold text-base text-purple-800 cursor-pointer">
                        <input type="checkbox" id="erEndGame" class="w-4 h-4 accent-purple-600" />
                        <span>End game</span>
                    </label>
                </div>
                <div id="erBody" class="p-4 overflow-auto"></div>
                <div class="px-4 py-3 bg-gray-50 border-t flex justify-end gap-2">
                    <button type="button" onclick="closeEsportResultModal()" class="px-4 py-2 rounded border border-gray-300 font-bold text-base">Đóng</button>
                    <button type="button" onclick="clearEsportResultData()" class="px-4 py-2 rounded bg-red-500 hover:bg-red-600 text-white font-bold text-base">Xóa kết quả</button>
                    <button type="button" onclick="saveEsportResultData()" class="px-4 py-2 rounded bg-purple-600 hover:bg-purple-700 text-white font-bold text-base">Lưu kết quả</button>
                </div>
            </div>
        </div>
    </form>

    <script type="text/javascript">
        function toggleSidebar() {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('overlay');
            if (sidebar.classList.contains('-translate-x-full')) {
                sidebar.classList.remove('-translate-x-full');
                overlay.classList.remove('hidden');
            } else {
                sidebar.classList.add('-translate-x-full');
                overlay.classList.add('hidden');
            }
        }
        function toggleFilter() {
            const fc = document.getElementById('filterContent');
            const fi = document.getElementById('filterIcon');
            fc.classList.toggle('hidden');
            fi.classList.toggle('rotate-180');
        }
        let teamData = [], seasonData = [];
        window.addEventListener('load', function() {
            if (typeof dataTeam !== 'undefined') { teamData = dataTeam; renderTeamDropdown(teamData); }
            if (typeof dataSeason !== 'undefined') { seasonData = dataSeason; renderSeasonDropdown(seasonData); }
            // Always render list from API so detail odds are shown on first load too
            reloadMatchesData();
        });
        function renderTeamDropdown(data) {
            const dd = document.getElementById('teamDropdown');
            let html = '<div class="p-2 hover:bg-purple-50 cursor-pointer font-bold text-base" onclick="selectTeam(\'\',\'-- Chọn đội --\')">-- Chọn đội --</div>';
            data.forEach(i => { html += `<div class="p-2 hover:bg-purple-50 cursor-pointer font-bold text-base" onclick="selectTeam('${i.team}','${i.team_name}')">${i.team_name}</div>`; });
            dd.innerHTML = html;
        }
        function renderSeasonDropdown(data) {
            const dd = document.getElementById('seasonDropdown');
            let html = '<div class="p-2 hover:bg-purple-50 cursor-pointer font-bold text-base" onclick="selectSeason(\'\',\'-- Chọn giải đấu --\')">-- Chọn giải đấu --</div>';
            data.forEach(i => { html += `<div class="p-2 hover:bg-purple-50 cursor-pointer font-bold text-base" onclick="selectSeason('${i.season}','${i.season_name}')">${i.season_name}</div>`; });
            dd.innerHTML = html;
        }
        function showTeamDropdown() { document.getElementById('teamDropdown').classList.remove('hidden'); document.getElementById('seasonDropdown').classList.add('hidden'); }
        function showSeasonDropdown() { document.getElementById('seasonDropdown').classList.remove('hidden'); document.getElementById('teamDropdown').classList.add('hidden'); }
        function selectTeam(v, t) { document.getElementById('filterTeam').value = v; document.getElementById('filterTeamSearch').value = t; document.getElementById('teamDropdown').classList.add('hidden'); }
        function selectSeason(v, t) { document.getElementById('filterSeason').value = v; document.getElementById('filterSeasonSearch').value = t; document.getElementById('seasonDropdown').classList.add('hidden'); }
        function filterTeamOptions() { const s = document.getElementById('filterTeamSearch').value.toLowerCase(); renderTeamDropdown(teamData.filter(i => i.team_name.toLowerCase().includes(s) || i.team.toLowerCase().includes(s))); showTeamDropdown(); }
        function filterSeasonOptions() { const s = document.getElementById('filterSeasonSearch').value.toLowerCase(); renderSeasonDropdown(seasonData.filter(i => i.season_name.toLowerCase().includes(s) || i.season.toLowerCase().includes(s))); showSeasonDropdown(); }
        document.addEventListener('click', function(e) { if (!e.target.closest('.relative')) { document.getElementById('teamDropdown').classList.add('hidden'); document.getElementById('seasonDropdown').classList.add('hidden'); } });

        function applyFilter() {
            const team = document.getElementById('filterTeam').value;
            const season = document.getElementById('filterSeason').value;
            const dateFrom = document.getElementById('filterDateFrom').value;
            const dateTo = document.getElementById('filterDateTo').value;
            const statusCbs = document.querySelectorAll('input[name="filterStatus"]:checked');
            const status = Array.from(statusCbs).map(cb => cb.value).join(',');
            toggleFilter();
            loadMatchesData(team, season, dateFrom, dateTo, status);
        }
        function reloadMatchesData() {
            const team = document.getElementById('filterTeam').value;
            const season = document.getElementById('filterSeason').value;
            const dateFrom = document.getElementById('filterDateFrom').value;
            const dateTo = document.getElementById('filterDateTo').value;
            const statusCbs = document.querySelectorAll('input[name="filterStatus"]:checked');
            const status = Array.from(statusCbs).map(cb => cb.value).join(',');
            loadMatchesData(team, season, dateFrom, dateTo, status);
        }
        let esportLoadToken = 0;
        const esportGameDetailsCache = {};
        const esportGameDetailsLoading = {};
        function clearEsportGameDetailsCache(matchId) {
            if (matchId) {
                delete esportGameDetailsCache[String(matchId)];
                delete esportGameDetailsLoading[String(matchId)];
                return;
            }
            Object.keys(esportGameDetailsCache).forEach(k => delete esportGameDetailsCache[k]);
            Object.keys(esportGameDetailsLoading).forEach(k => delete esportGameDetailsLoading[k]);
        }
        function loadMatchesData(team, season, dateFrom, dateTo, status) {
            const token = ++esportLoadToken;
            const container = document.getElementById('matchesContainer');
            container.innerHTML = '<div class="col-span-2 text-center py-10"><i class="fa-solid fa-spinner fa-spin text-4xl text-purple-600"></i><p class="mt-4 text-gray-600 font-bold">Đang tải dữ liệu...</p></div>';
            fetch('esports.aspx/FilterMatchHeaders', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ team, season, dateFrom, dateTo, status })
            })
            .then(r => r.json())
            .then(data => { if (data.d && token === esportLoadToken) { renderMatches(JSON.parse(data.d), token); } })
            .catch(() => { container.innerHTML = '<div class="col-span-2 text-center py-10 text-red-600"><i class="fa-solid fa-exclamation-triangle text-4xl"></i><p class="mt-4 font-bold">Lỗi khi tải dữ liệu</p></div>'; });
        }
        function renderMatches(matches, token) {
            const container = document.getElementById('matchesContainer');
            if (!matches || matches.length === 0) {
                container.innerHTML = '<div class="col-span-2 text-center py-10 text-gray-400"><i class="fa-solid fa-inbox text-4xl"></i><p class="mt-4 font-bold">Không có trận đấu nào</p></div>';
                return;
            }
            const canInsert = <%= CheckRight("bet_match_insert") ? "true" : "false" %>;
            const canResult = <%= CheckRight("bet_match_result") ? "true" : "false" %>;
            const isAdmin = <%= IsAdminUser() ? "true" : "false" %>;
            const currentUserId = <%= GetCurrentUserId() %>;
            const statusTextClass = (status) => {
                const value = Number(status);
                if (value === 2) return 'text-green-600';
                if (value === 1) return 'text-red-600';
                if (value === 3) return 'text-fuchsia-600';
                if (value === 4) return 'text-gray-600';
                return 'text-gray-500';
            };
            const fmtNum = (v, withSign) => {
                if (v === null || v === undefined || v === '') return '';
                const n = Number(v);
                if (Number.isNaN(n)) return '';
                if (withSign) {
                    const sign = n > 0 ? '+' : (n < 0 ? '-' : '');
                    const abs = Math.abs(n).toFixed(2).replace(/\.00$/, '');
                    return sign + abs;
                }
                return n.toFixed(2).replace(/\.00$/, '');
            };
            const lineItem = (label, value, withSign) => {
                const v = fmtNum(value, !!withSign);
                if (!v) return '';
                return `<span class="inline-flex items-center px-2 py-0.5 rounded bg-gray-50 border border-current">${label}: <b class="ml-1">${v}</b></span>`;
            };
            const lineText = (text) => {
                if (!text) return '';
                return `<span class="inline-flex items-center px-2 py-0.5 rounded bg-gray-50 border border-current">${text}</span>`;
            };
            const lineGroup = (items) => {
                const html = items.filter(Boolean).join('');
                if (!html) return '';
                return `<div class="flex flex-wrap gap-1 text-base">${html}</div>`;
            };
            const gameDetailHtml = (g, homeName, awayName) => {
                const no = Number(g.game_no || 0);
                const title = no === 6 ? 'BO x' : `Game ${no}`;
                const h = homeName || 'Đội 1';
                const a = awayName || 'Đội 2';
                const signed = (v, unit) => {
                    const t = fmtNum(v, true);
                    if (!t) return '';
                    return `${h} ${t.replace('-', '- ').replace('+', '+ ')} ${unit}`;
                };
                const plain = (v) => fmtNum(v, false);
                const rows = [];
                if (no === 6) {
                    rows.push(lineGroup([
                        plain(g.ou_line) ? lineText(`Tài ${plain(g.ou_line)} game`) : '',
                        signed(g.hc_line, 'game') ? lineText(signed(g.hc_line, 'game')) : ''
                    ]));
                } else {
                    rows.push(lineGroup([
                        plain(g.ou_line) ? lineText(`Tài ${plain(g.ou_line)} kill`) : '',
                        signed(g.hc_line, 'kill') ? lineText(signed(g.hc_line, 'kill')) : '',
                        plain(g.minute_line) ? lineText(`Tài ${plain(g.minute_line)} phút`) : ''
                    ]));
                    rows.push(lineGroup([
                        plain(g.dragon_ou_line) ? lineText(`Tài ${plain(g.dragon_ou_line)} rồng`) : '',
                        signed(g.dragon_hc_line, 'rồng') ? lineText(signed(g.dragon_hc_line, 'rồng')) : ''
                    ]));
                    rows.push(lineGroup([
                        lineItem(`Rồng đầu ${h}`, g.first_dragon_home_win),
                        lineItem(`Rồng đầu ${a}`, g.first_dragon_way_win)
                    ]));
                    rows.push(lineGroup([
                        lineItem('Rồng đầu công nghệ', g.first_dragon_tech_win),
                        lineItem('Rồng đầu hóa kỹ', g.first_dragon_chemtech_win),
                        lineItem('Rồng đầu gió', g.first_dragon_wind_win),
                        lineItem('Rồng đầu nước', g.first_dragon_water_win),
                        lineItem('Rồng đầu lửa', g.first_dragon_fire_win),
                        lineItem('Rồng đầu đất', g.first_dragon_earth_win)
                    ]));
                    rows.push(lineGroup([
                        lineItem(`Mạng đầu ${h}`, g.first_home_win),
                        lineItem(`Mạng đầu ${a}`, g.first_way_win)
                    ]));
                    rows.push(lineGroup([
                        lineItem(`3 mạng đầu ${h}`, g.third_home_win),
                        lineItem(`3 mạng đầu ${a}`, g.third_way_win)
                    ]));
                    rows.push(lineGroup([
                        lineItem(`5 mạng đầu ${h}`, g.five_home_win),
                        lineItem(`5 mạng đầu ${a}`, g.five_way_win)
                    ]));
                    rows.push(lineGroup([
                        lineItem(`10 mạng đầu ${h}`, g.ten_home_win),
                        lineItem(`10 mạng đầu ${a}`, g.ten_way_win)
                    ]));
                    rows.push(lineGroup([
                        lineItem(`${h} win`, g.win_home_win),
                        lineItem(`${a} win`, g.win_way_win)
                    ]));
                }
                const filtered = rows.filter(Boolean);
                if (filtered.length === 0) return '';
                return `<div class="mt-2">
                    <div class="text-base font-extrabold mb-1">${title}</div>
                    <div class="space-y-1">${filtered.join('')}</div>
                </div>`;
            };
            const matchDomId = (id) => `esport_${String(id || '').replace(/[^a-zA-Z0-9_-]/g, '_')}`;
            const renderGameDetails = (m, games) => {
                const detailEl = document.getElementById(`gameDetail_${matchDomId(m.match_id)}`);
                const countEl = document.getElementById(`gameCount_${matchDomId(m.match_id)}`);
                if (!detailEl || !countEl) return;
                const list = Array.isArray(games) ? games : [];
                const normalGameCount = list.filter(g => {
                    const no = Number(g.game_no || 0);
                    return no >= 1 && no <= 5;
                }).length;
                countEl.textContent = `BO${normalGameCount || Number(m.total_games || 0)}`;
                const detail = list.map(g => gameDetailHtml(g, m.home || 'Đội 1', m.way || 'Đội 2')).filter(Boolean).join('');
                detailEl.innerHTML = detail || '<div class="text-center text-sm text-gray-400 font-bold">Không có kèo chi tiết</div>';
            };
            const loadGameDetails = (m) => {
                const matchId = String(m.match_id || '');
                if (!matchId) return Promise.resolve();
                if (esportGameDetailsCache[matchId]) {
                    renderGameDetails(m, esportGameDetailsCache[matchId]);
                    return Promise.resolve();
                }
                if (esportGameDetailsLoading[matchId]) return esportGameDetailsLoading[matchId];
                esportGameDetailsLoading[matchId] = fetch('esports.aspx/GetMatchGames', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ matchId: matchId })
                })
                .then(r => r.json())
                .then(data => {
                    if (!data.d) return;
                    const games = JSON.parse(data.d);
                    esportGameDetailsCache[matchId] = games;
                    if (token === esportLoadToken) renderGameDetails(m, games);
                })
                .catch(() => {
                    const detailEl = document.getElementById(`gameDetail_${matchDomId(m.match_id)}`);
                    if (detailEl) detailEl.innerHTML = '<div class="text-center text-sm text-red-500 font-bold">Lỗi tải kèo chi tiết</div>';
                })
                .finally(() => {
                    delete esportGameDetailsLoading[matchId];
                });
                return esportGameDetailsLoading[matchId];
            };
            let html = '';
            matches.forEach(m => {
                const canManage = isAdmin || Number(m.user_host || m.created_by || 0) === currentUserId;
                const time = m.match_time ? new Date(parseInt(m.match_time.replace('/Date(','').replace(')/',''))) : null;
                const timeStr = time ? `${String(time.getHours()).padStart(2,'0')}:${String(time.getMinutes()).padStart(2,'0')} ${String(time.getDate()).padStart(2,'0')}/${String(time.getMonth()+1).padStart(2,'0')}/${time.getFullYear()}` : '';
                const domId = matchDomId(m.match_id);
                const matchLabel = `${m.home || ''} vs ${m.way || ''}`.replace(/'/g, "\\'");
                html += `<div class="bg-white rounded-xl shadow-md border border-gray-200 p-4 flex flex-col transition-all hover:shadow-lg ${statusTextClass(m.status)}">
                    <div class="flex justify-end items-center gap-2 mb-3">
                        <button type="button" onclick="openTicketMatchModal('${m.match_id}', '${matchLabel}', 'esport')" class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-ticket mr-1"></i>Vé cược</button>
                        ${canResult ? `<button type="button" onclick="openEsportResult('${m.match_id}')" class="bg-purple-500 hover:bg-purple-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-flag-checkered mr-1"></i>Kết quả</button>` : ''}
                        ${canInsert ? `<button type="button" onclick="copyMatch('${m.match_id}')" class="bg-green-500 hover:bg-green-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-copy mr-1"></i>Sao chép</button>` : ''}
                        ${canManage ? `<button type="button" onclick="editMatch('${m.match_id}')" class="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-pen-to-square mr-1"></i>Sửa</button>` : ''}
                        ${canManage ? `<button type="button" onclick="deleteMatch('${m.match_id}')" class="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-trash mr-1"></i>Xóa</button>` : ''}
                    </div>
                    <div class="flex justify-between items-center gap-3 mb-1 font-bold text-base">
                        <div class="min-w-0 text-left">${m.host_name ? `<span class="inline-block bg-gray-50 px-2 py-0.5 rounded text-base border border-current font-bold">Cái: ${m.host_name}</span>` : ''}</div>
                        <div class="text-right whitespace-nowrap">${m.statusname || ''}</div>
                    </div>
                    <div class="flex justify-between items-center gap-3 mb-2 font-bold text-base">
                        <span class="inline-block bg-gray-50 px-2 py-0.5 rounded text-base border border-current">${m.season || ''}</span>
                        <div class="text-right whitespace-nowrap">${timeStr}</div>
                    </div>
                    <div class="flex justify-between items-center mb-3 font-black text-base">
                        <div class="w-[45%] text-right">${m.home || ''}</div>
                        <div class="w-[10%] text-center font-bold">vs</div>
                        <div class="w-[45%] text-left">${m.way || ''}</div>
                    </div>
                    <div id="gameCount_${domId}" class="text-center text-base font-bold">BO${Number(m.total_games || 0)}</div>
                    <div id="gameDetail_${domId}" class="mt-3 pt-3 border-t border-gray-100 esport-match-detail-scroll">
                        <div class="text-center text-sm text-gray-400 font-bold"><i class="fa-solid fa-spinner fa-spin mr-1"></i>Đang tải kèo chi tiết...</div>
                    </div>
                </div>`;
            });
            container.innerHTML = html;
            const attachLazyDetailLoaders = () => {
                if ('IntersectionObserver' in window) {
                    const observer = new IntersectionObserver((entries, obs) => {
                        entries.forEach(entry => {
                            if (!entry.isIntersecting) return;
                            obs.unobserve(entry.target);
                            const idx = Number(entry.target.getAttribute('data-match-index'));
                            if (token === esportLoadToken && matches[idx]) loadGameDetails(matches[idx]);
                        });
                    }, { root: document.querySelector('.main-scroll'), rootMargin: '350px 0px', threshold: 0.01 });

                    matches.forEach((m, idx) => {
                        const el = document.getElementById(`gameDetail_${matchDomId(m.match_id)}`);
                        if (!el) return;
                        el.setAttribute('data-match-index', String(idx));
                        observer.observe(el);
                    });
                    return;
                }

                matches.slice(0, 4).forEach(m => loadGameDetails(m));
            };
            attachLazyDetailLoaders();
        }
        function openAddEsportModal() {
            const editYn = document.querySelector('[id$="editYn"]');
            if (editYn) editYn.value = 'false';
            if (typeof prepareNewEsportForm === 'function') prepareNewEsportForm();
            openAddEsportModalUI();
        }
        function editMatch(matchId) {
            fetch('esports.aspx/GetMatchData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(r => r.json())
            .then(data => {
                if (data.d) {
                    const matchData = JSON.parse(data.d);
                    fillEsportEditForm(matchData);
                    openAddEsportModalUI();
                }
            })
            .catch(err => alert('Lỗi khi tải dữ liệu: ' + err));
        }
        function copyMatch(matchId) {
            fetch('esports.aspx/GetMatchData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(r => r.json())
            .then(data => {
                if (data.d) {
                    const matchData = JSON.parse(data.d);
                    fillEsportEditForm(matchData);
                    document.getElementById('esport_match_id').value = '';
                    document.getElementById('esport_edit_yn').value = 'false';
                    const title = document.getElementById('esportModalTitle');
                    if (title) title.innerHTML = '<i class="fa-solid fa-gamepad mr-3 text-lg"></i> Sao chép trận Esports';
                    openAddEsportModalUI();
                }
            })
            .catch(err => alert('Lỗi khi tải dữ liệu: ' + err));
        }
        function openEsportResult(matchId) {
            fetch('esports.aspx/GetResultData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(r => r.json())
            .then(data => {
                if (!data.d) return alert('Không nhận được dữ liệu kết quả');
                const rs = JSON.parse(data.d);
                if (rs.error) return alert(rs.error);
                const homeName = rs.home_name || rs.home || 'Home';
                const wayName = rs.way_name || rs.way || 'Way';
                const esc = (v) => String(v ?? '').replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[ch]));
                document.getElementById('erMatchLabel').textContent = `${homeName} vs ${wayName}`;
                const games = Array.isArray(rs.games) ? rs.games : [];
                let html = '';
                games.forEach(g => {
                    const no = Number(g.game_no || 0);
                    const title = no === 6 ? 'BO x' : `Game ${no}`;
                    const sel = (val, cur) => (String(cur || '').toLowerCase() === val ? 'selected' : '');
                    const inputField = (label, field, value, inputmode, step) => `<div>
                        <label class="font-bold block mb-1">${esc(label)}</label>
                        <input type="text" inputmode="${inputmode}" data-number-input="1" data-step="${step}" data-game="${no}" data-field="${field}" data-original-value="${esc(value ?? '')}" value="${esc(value ?? '')}" class="w-full border rounded px-2 py-1"/>
                    </div>`;
                    const minuteText = (value) => {
                        if (value === null || value === undefined || String(value).trim() === '') return '';
                        const totalSeconds = Math.round(Number(value) * 60);
                        if (!Number.isFinite(totalSeconds)) return '';
                        const minutes = Math.floor(totalSeconds / 60);
                        const seconds = totalSeconds % 60;
                        return `${minutes}:${String(seconds).padStart(2, '0')}`;
                    };
                    const minuteField = (label, field, value) => `<div>
                        <label class="font-bold block mb-1">${esc(label)}</label>
                        <input type="text" inputmode="numeric" placeholder="mm:ss" pattern="\\d+:\\d{2}" data-minute-mask="1" data-game="${no}" data-field="${field}" data-original-value="${esc(minuteText(value))}" value="${esc(minuteText(value))}" class="w-full border rounded px-2 py-1"/>
                    </div>`;
                    const selectField = (label, field, value) => `<div>
                        <label class="font-bold block mb-1">${esc(label)}</label>
                        <select data-game="${no}" data-field="${field}" data-original-value="${esc(String(value ?? '').trim().toLowerCase())}" class="w-full border rounded px-2 py-1">
                            <option value=""></option>
                            <option value="home" ${sel('home', value)}>${esc(homeName)}</option>
                            <option value="way" ${sel('way', value)}>${esc(wayName)}</option>
                            <option value="draw" ${sel('draw', value)}>Hòa</option>
                        </select>
                    </div>`;
                    const dragonTypeSelectField = (label, field, value) => `<div>
                        <label class="font-bold block mb-1">${esc(label)}</label>
                        <select data-game="${no}" data-field="${field}" data-original-value="${esc(String(value ?? '').trim().toLowerCase())}" class="w-full border rounded px-2 py-1">
                            <option value=""></option>
                            <option value="draw" ${sel('draw', value)}>Hòa</option>
                            <option value="tech" ${sel('tech', value)}>Công nghệ</option>
                            <option value="chemtech" ${sel('chemtech', value)}>Hóa kỹ</option>
                            <option value="fire" ${sel('fire', value)}>Lửa</option>
                            <option value="earth" ${sel('earth', value)}>Đất</option>
                            <option value="water" ${sel('water', value)}>Nước</option>
                            <option value="wind" ${sel('wind', value)}>Gió</option>
                        </select>
                    </div>`;
                    const fieldRow = (items) => items.length ? `<div class="grid grid-cols-${items.length > 1 ? '2' : '1'} gap-2">${items.join('')}</div>` : '';
                    const resultFields = g.result_fields || {};
                    const showKill = !!resultFields.kill;
                    const showMinute = !!resultFields.minute;
                    const showDragon = !!resultFields.dragon;
                    const showFirstDragon = !!resultFields.first_dragon;
                    const showFirstDragonType = !!resultFields.first_dragon_type;
                    const showFirst = !!resultFields.first;
                    const showThird = !!resultFields.third;
                    const showFive = !!resultFields.five;
                    const showTen = !!resultFields.ten;
                    const showWin = no !== 6;
                    if (!showKill && !showMinute && !showDragon && !showFirstDragon && !showFirstDragonType && !showFirst && !showThird && !showFive && !showTen && !showWin) return;
                    const rows = [];
                    if (showKill) {
                        const scoreLabel = no === 6 ? 'Game Win' : 'Kill';
                        rows.push(fieldRow([
                            inputField(`${scoreLabel} ${homeName}`, 'result_kill_home', g.result_kill_home, 'decimal', '0.01'),
                            inputField(`${scoreLabel} ${wayName}`, 'result_kill_way', g.result_kill_way, 'decimal', '0.01')
                        ]));
                    }
                    if (showMinute) {
                        rows.push(fieldRow([
                            minuteField('Số phút', 'result_minute', g.result_minute)
                        ]));
                    }
                    if (showDragon) {
                        rows.push(fieldRow([
                            inputField(`Rồng ${homeName}`, 'result_dragon_home', g.result_dragon_home, 'decimal', '0.01'),
                            inputField(`Rồng ${wayName}`, 'result_dragon_way', g.result_dragon_way, 'decimal', '0.01')
                        ]));
                    }
                    if (showFirstDragon) {
                        rows.push(fieldRow([
                            selectField('Rồng đầu', 'result_first_dragon', g.result_first_dragon)
                        ]));
                    }
                    if (showFirstDragonType) {
                        rows.push(fieldRow([
                            dragonTypeSelectField('Rồng đầu loại', 'result_first_dragon_type', g.result_first_dragon_type)
                        ]));
                    }
                    const milestoneFields = [];
                    if (showFirst) milestoneFields.push(selectField('Mạng đầu', 'result_first', g.result_first));
                    if (showThird) milestoneFields.push(selectField('3 mạng đầu', 'result_third', g.result_third));
                    if (showFive) milestoneFields.push(selectField('5 mạng đầu', 'result_five', g.result_five));
                    if (showTen) milestoneFields.push(selectField('10 mạng đầu', 'result_ten', g.result_ten));
                    for (let i = 0; i < milestoneFields.length; i += 2) {
                        rows.push(fieldRow(milestoneFields.slice(i, i + 2)));
                    }
                    if (showWin) {
                        rows.push(fieldRow([
                            selectField('Kết quả win', 'result_win', g.result_win)
                        ]));
                    }
                    html += `<div class="border rounded-lg mb-3 overflow-hidden" data-result-game-card>
                        <div class="px-3 py-2 bg-purple-50 flex items-center justify-between gap-2">
                            <div class="font-extrabold text-purple-700">${title}</div>
                            <button type="button" onclick="toggleEsportResultGame(this)" title="Mở rộng/thu gọn" aria-label="Mở rộng/thu gọn ${esc(title)}" aria-expanded="false" class="w-8 h-8 rounded border border-purple-200 bg-white text-purple-700 hover:bg-purple-100 transition-all">
                                <i class="fa-solid fa-chevron-down"></i>
                            </button>
                        </div>
                        <div class="hidden space-y-2 text-base p-3 border-t border-purple-100" data-result-game-body>${rows.join('')}</div>
                    </div>`;
                });
                document.getElementById('erBody').innerHTML = html || '<div class="text-gray-500 font-bold">Chưa có dữ liệu game.</div>';
                document.querySelectorAll('#erBody [data-minute-mask]').forEach(el => {
                    el.addEventListener('input', function() {
                        const digits = this.value.replace(/\D/g, '').slice(0, 6);
                        if (!digits) {
                            this.value = '';
                            return;
                        }
                        if (digits.length <= 2) {
                            this.value = digits;
                            return;
                        }
                        this.value = `${digits.slice(0, -2)}:${digits.slice(-2)}`;
                    });
                    el.addEventListener('blur', function() {
                        const digits = this.value.replace(/\D/g, '');
                        if (!digits) return;
                        if (digits.length <= 2) {
                            this.value = `0:${digits.padStart(2, '0')}`;
                            return;
                        }
                        this.value = `${digits.slice(0, -2)}:${digits.slice(-2)}`;
                    });
                });
                if (window.NumericKeyboard) {
                    window.NumericKeyboard.attachToFields([
                        '#erBody input[data-number-input]',
                        '#erBody input[data-minute-mask]'
                    ]);
                }
                document.getElementById('modalEsportResult').classList.remove('hidden');
                document.getElementById('modalEsportResult').classList.add('flex');
                document.getElementById('modalEsportResult').dataset.matchId = matchId;
                document.getElementById('erEndGame').checked = false;
            })
            .catch(err => alert('Lỗi khi tải kết quả: ' + err));
        }
        function toggleEsportResultGame(btn) {
            const card = btn.closest('[data-result-game-card]');
            if (!card) return;
            const body = card.querySelector('[data-result-game-body]');
            const icon = btn.querySelector('i');
            if (!body) return;
            const isHidden = body.classList.toggle('hidden');
            btn.setAttribute('aria-expanded', (!isHidden).toString());
            if (icon) {
                icon.classList.toggle('fa-chevron-down', isHidden);
                icon.classList.toggle('fa-chevron-up', !isHidden);
            }
        }
        function closeEsportResultModal() {
            const m = document.getElementById('modalEsportResult');
            m.classList.add('hidden');
            m.classList.remove('flex');
            m.dataset.matchId = '';
            document.getElementById('erBody').innerHTML = '';
            document.getElementById('erEndGame').checked = false;
        }
        function saveEsportResultData() {
            const modal = document.getElementById('modalEsportResult');
            const matchId = modal.dataset.matchId || '';
            if (!matchId) return alert('Thiếu match_id');
            const endGame = !!document.getElementById('erEndGame').checked;
            const map = {};
            let invalidMinute = false;
            document.querySelectorAll('#erBody [data-game][data-field]').forEach(el => {
                const g = Number(el.getAttribute('data-game'));
                const f = el.getAttribute('data-field');
                const value = (el.value || '').trim();
                const originalValue = (el.getAttribute('data-original-value') || '').trim();
                if (f === 'result_minute' && value) {
                    const parts = value.split(':');
                    const seconds = parts.length === 2 ? Number(parts[1]) : NaN;
                    if (parts.length !== 2 || !/^\d+$/.test(parts[0]) || !/^\d{1,2}$/.test(parts[1]) || seconds > 59) {
                        invalidMinute = true;
                    }
                }
                if (value !== originalValue) {
                    if (!map[g]) map[g] = { game_no: g };
                    map[g][f] = value;
                }
            });
            if (invalidMinute) return alert('Số phút phải nhập theo dạng mm:ss, ví dụ 30:40.');
            const games = Object.keys(map).map(k => map[k]);
            if (games.length === 0 && !endGame) return alert('Chưa có kết quả nào thay đổi.');
            const payload = { match_id: matchId, games: games, end_game: endGame };
            fetch('esports.aspx/SaveResultData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ resultData: JSON.stringify(payload) })
            })
            .then(r => r.json())
            .then(data => {
                if (!data.d) return alert('Không nhận được phản hồi');
                const res = JSON.parse(data.d);
                alert(res.msg || 'Đã lưu');
                if (res.isSuccess == 1) {
                    closeEsportResultModal();
                    clearEsportGameDetailsCache(matchId);
                }
            })
            .catch(err => alert('Lỗi khi lưu kết quả: ' + err));
        }
        function clearEsportResultData() {
            if (!confirm('Bạn có chắc muốn xóa toàn bộ kết quả của trận này?')) return;
            const modal = document.getElementById('modalEsportResult');
            const matchId = modal.dataset.matchId || '';
            if (!matchId) return alert('Thiếu match_id');

            const map = {};
            document.querySelectorAll('#erBody [data-game]').forEach(el => {
                const n = Number(el.getAttribute('data-game'));
                const f = el.getAttribute('data-field');
                if (n <= 0 || !f) return;
                if (!map[n]) map[n] = { game_no: n };
                map[n][f] = '';
            });

            const games = Object.keys(map).map(k => map[k]);

            const payload = { match_id: matchId, games: games };
            fetch('esports.aspx/SaveResultData', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ resultData: JSON.stringify(payload) })
            })
            .then(r => r.json())
            .then(data => {
                if (!data.d) return alert('Không nhận được phản hồi');
                const res = JSON.parse(data.d);
                alert(res.msg || 'Đã xóa kết quả');
                if (res.isSuccess == 1) {
                    closeEsportResultModal();
                    clearEsportGameDetailsCache(matchId);
                    reloadMatchesData();
                }
            })
            .catch(err => alert('Lỗi khi xóa kết quả: ' + err));
        }
        function deleteMatch(matchId) {
            if (!confirm('Bạn có chắc muốn xóa trận đấu này?')) return;
            fetch('esports.aspx/DeleteMatch', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(r => r.json())
            .then(data => {
                if (data.d) {
                    const res = JSON.parse(data.d);
                    alert(res.msg);
                    if (res.isSuccess == 1) {
                        clearEsportGameDetailsCache(matchId);
                        reloadMatchesData();
                    }
                }
            })
            .catch(err => alert('Lỗi: ' + err));
        }
    </script>
</body>
</html>
