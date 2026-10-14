<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        try {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<Dictionary<string, object>>(requestBody);

            string season = data.ContainsKey("season") ? data["season"].ToString() : "";
            string time   = data.ContainsKey("time")   ? data["time"].ToString()   : "";
            int userId = 0;
            if (data.ContainsKey("userId")) int.TryParse(data["userId"].ToString(), out userId);
            if (userId == 0 && Session["UserID"] != null) int.TryParse(Session["UserID"].ToString(), out userId);

            if (string.IsNullOrEmpty(season)) { Response.Write("{\"d\":[]}"); return; }

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                int currentUserId = GetCurrentUserId();
                if (currentUserId > 0 && userId != currentUserId && !CanSelectChampionTicketUser(conn, currentUserId, season, time))
                {
                    userId = currentUserId;
                }

                SqlCommand cmd = new SqlCommand("bet_ticket_champion_code", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@season", season);
                cmd.Parameters.AddWithValue("@time",   string.IsNullOrEmpty(time) ? (object)DBNull.Value : time);
                cmd.Parameters.AddWithValue("@userID", userId);

                SqlDataReader reader = cmd.ExecuteReader();
                var list = new System.Collections.Generic.List<object>();
                while (reader.Read())
                {
                    list.Add(new {
                        code      = reader["code"].ToString(),
                        code_name = reader["code_name"].ToString(),
                        money     = reader["money"] != DBNull.Value ? Convert.ToDecimal(reader["money"]) : 0,
                        textColor = reader["textColor"] != DBNull.Value ? reader["textColor"].ToString() : "",
                        rowColor  = reader["rowColor"]  != DBNull.Value ? reader["rowColor"].ToString()  : ""
                    });
                }
                reader.Close();
                Response.Write("{\"d\":" + serializer.Serialize(list) + "}");
            }
        } catch { Response.Write("{\"d\":[]}"); }
    }

    private int GetCurrentUserId()
    {
        int currentUserId = 0;
        if (Session["UserID"] != null) Int32.TryParse(Convert.ToString(Session["UserID"]), out currentUserId);
        return currentUserId;
    }

    private bool CanSelectChampionTicketUser(SqlConnection conn, int currentUserId, string season, string time)
    {
        using (SqlCommand cmd = new SqlCommand(@"
            SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE id = @userID AND admin = 1)
                OR EXISTS (
                    SELECT 1 FROM bet_champion
                    WHERE season = @season
                        AND (@time IS NULL OR CONVERT(date, time) = CONVERT(date, @time))
                        AND user_host = @userID
                )
                THEN 1 ELSE 0 END", conn))
        {
            cmd.Parameters.Add("@userID", SqlDbType.Int).Value = currentUserId;
            cmd.Parameters.Add("@season", SqlDbType.NVarChar).Value = season;
            cmd.Parameters.Add("@time", SqlDbType.DateTime).Value = string.IsNullOrEmpty(time) ? (object)DBNull.Value : time;
            return Convert.ToInt32(cmd.ExecuteScalar()) == 1;
        }
    }
</script>
