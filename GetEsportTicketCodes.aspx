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

            string match = data.ContainsKey("match") ? Convert.ToString(data["match"]) : "";
            int userId = 0;
            if (data.ContainsKey("userId")) int.TryParse(Convert.ToString(data["userId"]), out userId);
            if (userId == 0 && Session["UserID"] != null) int.TryParse(Convert.ToString(Session["UserID"]), out userId);

            if (string.IsNullOrEmpty(match)) {
                Response.Write("{\"d\":[]}");
                return;
            }

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                conn.Open();

                int currentUserId = GetCurrentUserId();
                if (currentUserId > 0 && userId != currentUserId && !CanSelectTicketUser(conn, currentUserId, match)) {
                    userId = currentUserId;
                }

                SqlCommand cmd = new SqlCommand("bet_ticket_esport_code", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@match", match);
                cmd.Parameters.AddWithValue("@userID", userId);

                SqlDataReader reader = cmd.ExecuteReader();
                var list = new System.Collections.Generic.List<object>();
                while (reader.Read()) {
                    list.Add(new {
                        code = Convert.ToString(reader["code"]),
                        code_name = Convert.ToString(reader["code_name"]),
                        money = reader["money"] != DBNull.Value ? Convert.ToDecimal(reader["money"]) : 0,
                        textColor = reader["textColor"] != DBNull.Value ? Convert.ToString(reader["textColor"]) : "",
                        rowColor = reader["rowColor"] != DBNull.Value ? Convert.ToString(reader["rowColor"]) : ""
                    });
                }
                reader.Close();

                Response.Write("{\"d\":" + serializer.Serialize(list) + "}");
            }
        } catch {
            Response.Write("{\"d\":[]}");
        }
    }

    private int GetCurrentUserId()
    {
        int currentUserId = 0;
        if (Session["UserID"] != null) Int32.TryParse(Convert.ToString(Session["UserID"]), out currentUserId);
        return currentUserId;
    }

    private bool CanSelectTicketUser(SqlConnection conn, int currentUserId, string match)
    {
        using (SqlCommand cmd = new SqlCommand(@"
            SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE id = @userID AND admin = 1)
                OR EXISTS (SELECT 1 FROM bet_esport_match WHERE match_id = @match AND created_by = @userID)
                THEN 1 ELSE 0 END", conn))
        {
            cmd.Parameters.Add("@userID", SqlDbType.Int).Value = currentUserId;
            cmd.Parameters.Add("@match", SqlDbType.NVarChar).Value = match;
            return Convert.ToInt32(cmd.ExecuteScalar()) == 1;
        }
    }
</script>
