<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    public class TicketUserItem
    {
        public int id { get; set; }
        public string name { get; set; }
        public string comment { get; set; }
    }

    public class TicketMatchItem
    {
        public string match { get; set; }
        public string name { get; set; }
        public string time { get; set; }
        public string season { get; set; }
        public int user_host { get; set; }
    }

    public class TicketBootstrapData
    {
        public int currentUserId { get; set; }
        public bool currentUserIsAdmin { get; set; }
        public List<TicketUserItem> users { get; set; }
        public List<TicketMatchItem> matches { get; set; }
        public List<TicketMatchItem> esportMatches { get; set; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";

        try
        {
            int currentUserId = GetCurrentUserId();
            TicketBootstrapData data = new TicketBootstrapData
            {
                currentUserId = currentUserId,
                currentUserIsAdmin = false,
                users = new List<TicketUserItem>(),
                matches = new List<TicketMatchItem>(),
                esportMatches = new List<TicketMatchItem>()
            };

            if (currentUserId > 0)
            {
                string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    conn.Open();
                    data.currentUserIsAdmin = IsCurrentUserAdmin(conn, currentUserId);
                    LoadTicketUsers(conn, currentUserId, data.users);
                    LoadTicketMatches(conn, currentUserId, data.matches);
                    LoadEsportTicketMatches(conn, currentUserId, data.currentUserIsAdmin, data.esportMatches);
                }
            }

            JavaScriptSerializer serializer = new JavaScriptSerializer();
            Response.Write("{\"d\":" + serializer.Serialize(data) + "}");
        }
        catch
        {
            Response.Write("{\"d\":{\"currentUserId\":0,\"currentUserIsAdmin\":false,\"users\":[],\"matches\":[],\"esportMatches\":[]}}");
        }
    }

    private int GetCurrentUserId()
    {
        if (Session["UserID"] != null)
        {
            int userId;
            if (Int32.TryParse(Session["UserID"].ToString(), out userId)) return userId;
        }

        if (Session["UserName"] != null)
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("SELECT id FROM dbo.userinfo2 WHERE name = @name", conn))
            {
                cmd.Parameters.Add("@name", SqlDbType.NVarChar).Value = Session["UserName"].ToString();
                conn.Open();
                object result = cmd.ExecuteScalar();
                if (result != null && result != DBNull.Value)
                {
                    return Convert.ToInt32(result);
                }
            }
        }

        return 0;
    }

    private bool IsCurrentUserAdmin(SqlConnection conn, int currentUserId)
    {
        using (SqlCommand cmd = new SqlCommand("SELECT ISNULL(admin, 0) FROM dbo.userinfo2 WHERE id = @id", conn))
        {
            cmd.Parameters.Add("@id", SqlDbType.Int).Value = currentUserId;
            object result = cmd.ExecuteScalar();
            return result != null && result != DBNull.Value && Convert.ToBoolean(result);
        }
    }

    private void LoadTicketUsers(SqlConnection conn, int currentUserId, List<TicketUserItem> users)
    {
        using (SqlCommand cmd = new SqlCommand("bet_ticket_user", conn))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.Add("@userID", SqlDbType.Int).Value = currentUserId;

            using (SqlDataReader reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    users.Add(new TicketUserItem
                    {
                        id = reader["id"] != DBNull.Value ? Convert.ToInt32(reader["id"]) : 0,
                        name = reader["name"] != DBNull.Value ? reader["name"].ToString() : "",
                        comment = reader["comment"] != DBNull.Value ? reader["comment"].ToString() : ""
                    });
                }
            }
        }
    }

    private void LoadTicketMatches(SqlConnection conn, int currentUserId, List<TicketMatchItem> matches)
    {
        using (SqlCommand cmd = new SqlCommand("bet_ticket_match", conn))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.Add("@userID", SqlDbType.Int).Value = currentUserId;

            using (SqlDataReader reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    string time = "";
                    if (reader["time"] != DBNull.Value)
                    {
                        time = Convert.ToDateTime(reader["time"]).ToString("HH:mm dd/MM");
                    }

                    matches.Add(new TicketMatchItem
                    {
                        match = reader["match"] != DBNull.Value ? reader["match"].ToString() : "",
                        name = reader["name"] != DBNull.Value ? reader["name"].ToString() : "",
                        time = time,
                        season = reader["season"] != DBNull.Value ? reader["season"].ToString() : "",
                        user_host = reader["user_host"] != DBNull.Value ? Convert.ToInt32(reader["user_host"]) : 0
                    });
                }
            }
        }
    }

    private void LoadEsportTicketMatches(SqlConnection conn, int currentUserId, bool currentUserIsAdmin, List<TicketMatchItem> matches)
    {
        using (SqlCommand cmd = new SqlCommand(@"
            SELECT match_id, season_name, match_time, home_name, way_name, user_host
            FROM vbet_esport_match
            WHERE @admin = 1 OR status = 2 OR user_host = @userID
            ORDER BY match_time DESC, xKey", conn))
        {
            cmd.Parameters.Add("@admin", SqlDbType.Bit).Value = currentUserIsAdmin;
            cmd.Parameters.Add("@userID", SqlDbType.Int).Value = currentUserId;

            using (SqlDataReader reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    string time = "";
                    if (reader["match_time"] != DBNull.Value)
                    {
                        time = Convert.ToDateTime(reader["match_time"]).ToString("HH:mm dd/MM");
                    }

                    string home = reader["home_name"] != DBNull.Value ? reader["home_name"].ToString() : "";
                    string way = reader["way_name"] != DBNull.Value ? reader["way_name"].ToString() : "";

                    matches.Add(new TicketMatchItem
                    {
                        match = reader["match_id"] != DBNull.Value ? reader["match_id"].ToString() : "",
                        name = (home + " vs " + way).Trim(),
                        time = time,
                        season = reader["season_name"] != DBNull.Value ? reader["season_name"].ToString() : "",
                        user_host = reader["user_host"] != DBNull.Value ? Convert.ToInt32(reader["user_host"]) : 0
                    });
                }
            }
        }
    }
</script>
