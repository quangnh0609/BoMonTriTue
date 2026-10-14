<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        Response.ContentEncoding = System.Text.Encoding.UTF8;

        if (Session["UserID"] == null)
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.\"}");
            return;
        }

        if (Request.HttpMethod != "POST")
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"Invalid request method.\"}");
            return;
        }

        try
        {
            string body = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var ser = new System.Web.Script.Serialization.JavaScriptSerializer();
            ser.MaxJsonLength = int.MaxValue;
            var data = ser.Deserialize<Dictionary<string, object>>(body);

            string matchId   = data.ContainsKey("match_id")   ? (data["match_id"]   ?? "").ToString().Trim() : "";
            string editYn    = data.ContainsKey("edit_yn")     ? (data["edit_yn"]    ?? "false").ToString() : "false";
            string season    = data.ContainsKey("season")      ? (data["season"]     ?? "").ToString().Trim() : "";
            string home      = data.ContainsKey("home")        ? (data["home"]       ?? "").ToString().Trim() : "";
            string way       = data.ContainsKey("way")         ? (data["way"]        ?? "").ToString().Trim() : "";
            string matchTime = data.ContainsKey("match_time")  ? (data["match_time"] ?? "").ToString().Trim() : "";
            int userId       = Convert.ToInt32(Session["UserID"]);

            if (string.IsNullOrEmpty(season) || string.IsNullOrEmpty(home) || string.IsNullOrEmpty(way) || string.IsNullOrEmpty(matchTime))
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Vui lòng điền đầy đủ thông tin trận đấu.\"}");
                return;
            }

            DateTime matchTimeValue;
            if (!DateTime.TryParse(
                matchTime,
                System.Globalization.CultureInfo.InvariantCulture,
                System.Globalization.DateTimeStyles.AssumeLocal,
                out matchTimeValue))
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Định dạng thời gian không hợp lệ.\"}");
                return;
            }

            // Parse games array
            var gamesRaw = data.ContainsKey("games") ? data["games"] as System.Collections.ArrayList : null;
            if (gamesRaw == null || gamesRaw.Count == 0)
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Vui lòng nhập kèo cho ít nhất 1 game.\"}");
                return;
            }

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                if (editYn != "true")
                {
                    SqlCommand cmdDup = new SqlCommand(@"
                        SELECT 1
                        FROM bet_esport_match
                        WHERE season = @season
                          AND home = @home
                          AND way = @way
                          AND CONVERT(VARCHAR(64), match_time, 120) = CONVERT(VARCHAR(64), @match_time, 120)", conn);
                    cmdDup.Parameters.AddWithValue("@season", season);
                    cmdDup.Parameters.AddWithValue("@home", home);
                    cmdDup.Parameters.AddWithValue("@way", way);
                    cmdDup.Parameters.Add("@match_time", SqlDbType.DateTime).Value = matchTimeValue;
                    if (cmdDup.ExecuteScalar() != null)
                    {
                        Response.Write("{\"isSuccess\":0,\"msg\":\"Đã có trận đấu Esports này rồi!\"}");
                        return;
                    }
                }

                SqlTransaction tran = conn.BeginTransaction();
                try
                {
                    // 1. Lưu thông tin trận đấu chính
                    string sqlMatch = editYn == "true"
                        ? @"exec bet_esport_match_save @match_id, 1, @season, @home, @way, @match_time, @userID"
                        : @"exec bet_esport_match_save NULL, 0, @season, @home, @way, @match_time, @userID";

                    SqlCommand cmdMatch = new SqlCommand(sqlMatch, conn, tran);
                    if (editYn == "true")
                        cmdMatch.Parameters.AddWithValue("@match_id", string.IsNullOrEmpty(matchId) ? (object)DBNull.Value : matchId);
                    cmdMatch.Parameters.AddWithValue("@season", season);
                    cmdMatch.Parameters.AddWithValue("@home", home);
                    cmdMatch.Parameters.AddWithValue("@way", way);
                    cmdMatch.Parameters.Add("@match_time", SqlDbType.DateTime).Value = matchTimeValue;
                    cmdMatch.Parameters.AddWithValue("@userID", userId);

                    SqlDataReader rdrMatch = cmdMatch.ExecuteReader();
                    int isSuccess = 0;
                    string msg = "";
                    string newMatchId = matchId;

                    if (rdrMatch.Read())
                    {
                        isSuccess = rdrMatch["isSuccess"] != DBNull.Value ? Convert.ToInt32(rdrMatch["isSuccess"]) : 0;
                        msg = rdrMatch["msg"] != DBNull.Value ? rdrMatch["msg"].ToString() : "Có lỗi xảy ra";
                        if (rdrMatch.FieldCount > 2 && rdrMatch["match_id"] != DBNull.Value)
                            newMatchId = rdrMatch["match_id"].ToString();
                    }
                    rdrMatch.Close();

                    if (isSuccess != 1)
                    {
                        tran.Rollback();
                        Response.Write("{\"isSuccess\":0,\"msg\":\"" + msg.Replace("\"","\\\"") + "\"}");
                        return;
                    }

                    // 2. Xóa game cũ nếu edit
                    if (editYn == "true" && !string.IsNullOrEmpty(newMatchId))
                    {
                        SqlCommand cmdDel = new SqlCommand("DELETE FROM bet_esport_game WHERE match_id = @match_id", conn, tran);
                        cmdDel.Parameters.AddWithValue("@match_id", newMatchId);
                        cmdDel.ExecuteNonQuery();
                    }

                    // 3. Lưu từng game
                    foreach (var gameObj in gamesRaw)
                    {
                        var g = gameObj as Dictionary<string, object>;
                        if (g == null) continue;
                        string gNo = g.ContainsKey("game_no") ? g["game_no"].ToString() : "1";

                        SqlCommand cmdGame = new SqlCommand(@"
                            INSERT INTO bet_esport_game 
                            (match_id, game_no, ou_line, ou_over_win, ou_under_win,
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
                             win_home_win, win_way_win)
                            VALUES
                            (@match_id, @game_no, @ou_line, @ou_over_win, @ou_under_win,
                             @hc_line, @hc_home_win, @hc_way_win,
                             @minute_line, @minute_over_win, @minute_under_win,
                             @dragon_ou_line, @dragon_ou_over_win, @dragon_ou_under_win,
                             @dragon_hc_line, @dragon_hc_home_win, @dragon_hc_way_win,
                             @first_dragon_home_win, @first_dragon_way_win,
                             @first_dragon_tech_win, @first_dragon_chemtech_win, @first_dragon_wind_win, @first_dragon_water_win,
                             @first_dragon_fire_win, @first_dragon_earth_win,
                             @first_home_win, @first_way_win,
                             @third_home_win, @third_way_win,
                             @five_home_win, @five_way_win,
                             @ten_home_win, @ten_way_win,
                             @win_home_win, @win_way_win)", conn, tran);

                        cmdGame.Parameters.AddWithValue("@match_id", newMatchId);
                        cmdGame.Parameters.AddWithValue("@game_no", int.Parse(gNo));
                        cmdGame.Parameters.AddWithValue("@ou_line",       ParseDecimal(g, "ou_line"));
                        cmdGame.Parameters.AddWithValue("@ou_over_win",   ParseDecimal(g, "ou_over_win"));
                        cmdGame.Parameters.AddWithValue("@ou_under_win",  ParseDecimal(g, "ou_under_win"));
                        cmdGame.Parameters.AddWithValue("@hc_line",       ParseDecimal(g, "hc_line"));
                        cmdGame.Parameters.AddWithValue("@hc_home_win",   ParseDecimal(g, "hc_home_win"));
                        cmdGame.Parameters.AddWithValue("@hc_way_win",    ParseDecimal(g, "hc_way_win"));
                        cmdGame.Parameters.AddWithValue("@minute_line",   ParseDecimal(g, "minute_line"));
                        cmdGame.Parameters.AddWithValue("@minute_over_win", ParseDecimal(g, "minute_over_win"));
                        cmdGame.Parameters.AddWithValue("@minute_under_win", ParseDecimal(g, "minute_under_win"));
                        cmdGame.Parameters.AddWithValue("@dragon_ou_line", ParseDecimal(g, "dragon_ou_line"));
                        cmdGame.Parameters.AddWithValue("@dragon_ou_over_win", ParseDecimal(g, "dragon_ou_over_win"));
                        cmdGame.Parameters.AddWithValue("@dragon_ou_under_win", ParseDecimal(g, "dragon_ou_under_win"));
                        cmdGame.Parameters.AddWithValue("@dragon_hc_line", ParseDecimal(g, "dragon_hc_line"));
                        cmdGame.Parameters.AddWithValue("@dragon_hc_home_win", ParseDecimal(g, "dragon_hc_home_win"));
                        cmdGame.Parameters.AddWithValue("@dragon_hc_way_win", ParseDecimal(g, "dragon_hc_way_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_home_win", ParseDecimal(g, "first_dragon_home_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_way_win", ParseDecimal(g, "first_dragon_way_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_tech_win", ParseDecimal(g, "first_dragon_tech_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_chemtech_win", ParseDecimal(g, "first_dragon_chemtech_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_wind_win", ParseDecimal(g, "first_dragon_wind_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_water_win", ParseDecimal(g, "first_dragon_water_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_fire_win", ParseDecimal(g, "first_dragon_fire_win"));
                        cmdGame.Parameters.AddWithValue("@first_dragon_earth_win", ParseDecimal(g, "first_dragon_earth_win"));
                        cmdGame.Parameters.AddWithValue("@first_home_win",ParseDecimal(g, "first_home_win"));
                        cmdGame.Parameters.AddWithValue("@first_way_win", ParseDecimal(g, "first_way_win"));
                        cmdGame.Parameters.AddWithValue("@third_home_win",ParseDecimal(g, "third_home_win"));
                        cmdGame.Parameters.AddWithValue("@third_way_win", ParseDecimal(g, "third_way_win"));
                        cmdGame.Parameters.AddWithValue("@five_home_win", ParseDecimal(g, "five_home_win"));
                        cmdGame.Parameters.AddWithValue("@five_way_win",  ParseDecimal(g, "five_way_win"));
                        cmdGame.Parameters.AddWithValue("@ten_home_win",  ParseDecimal(g, "ten_home_win"));
                        cmdGame.Parameters.AddWithValue("@ten_way_win",   ParseDecimal(g, "ten_way_win"));
                        cmdGame.Parameters.AddWithValue("@win_home_win",  ParseDecimal(g, "win_home_win"));
                        cmdGame.Parameters.AddWithValue("@win_way_win",   ParseDecimal(g, "win_way_win"));
                        cmdGame.ExecuteNonQuery();
                    }

                    tran.Commit();
                    Response.Write("{\"isSuccess\":1,\"msg\":\"Lưu trận đấu Esports thành công.\"}");
                }
                catch (Exception exInner)
                {
                    tran.Rollback();
                    Response.Write("{\"isSuccess\":0,\"msg\":\"Lỗi khi lưu: " + exInner.Message.Replace("\"","\\\"") + "\"}");
                }
            }
        }
        catch (Exception ex)
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"Lỗi: " + ex.Message.Replace("\"","\\\"") + "\"}");
        }
    }

    private object ParseDecimal(Dictionary<string, object> d, string key)
    {
        if (!d.ContainsKey(key)) return DBNull.Value;
        string v = (d[key] ?? "").ToString().Trim();
        if (string.IsNullOrEmpty(v)) return DBNull.Value;
        decimal result;
        if (decimal.TryParse(v, System.Globalization.NumberStyles.Any, System.Globalization.CultureInfo.InvariantCulture, out result))
            return result;
        return DBNull.Value;
    }
</script>
