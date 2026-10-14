<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Xml.Linq" %>

<script runat="server">
    public class TicketDetail
    {
        public string code { get; set; }
        public decimal money { get; set; }
    }
    
    public class TicketData
    {
        public int userId { get; set; }
        public string matchId { get; set; }
        public List<TicketDetail> details { get; set; }
    }
    
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        
        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<TicketData>(requestBody);
            
            if (data.userId == 0 || string.IsNullOrEmpty(data.matchId) || data.details == null || data.details.Count == 0)
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Thiếu thông tin bắt buộc\"}");
                return;
            }
            
            XElement detailsXml = new XElement("details");
            foreach (var detail in data.details)
            {
                if (detail.money > 0)
                {
                    detailsXml.Add(new XElement("item",
                        new XElement("code", detail.code),
                        new XElement("money", detail.money)
                    ));
                }
            }
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();

                int currentUserId = GetCurrentUserId();
                if (currentUserId == 0)
                {
                    Response.Write("{\"isSuccess\":0,\"msg\":\"Phiên đăng nhập không hợp lệ\"}");
                    return;
                }

                if (data.userId != currentUserId && !CanSelectTicketUser(conn, currentUserId, data.matchId))
                {
                    Response.Write("{\"isSuccess\":0,\"msg\":\"Bạn không có quyền chọn người cược khác cho trận này\"}");
                    return;
                }
                
                SqlCommand cmd = new SqlCommand("bet_ticket_insert", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@user_id", data.userId);
                cmd.Parameters.AddWithValue("@match", data.matchId);
                cmd.Parameters.AddWithValue("@details", detailsXml.ToString());
                cmd.Parameters.AddWithValue("@userID", currentUserId);
                
                // Đọc kết quả trả về từ stored procedure
                SqlDataReader reader = cmd.ExecuteReader();
                int isSuccess = 0;
                string msg = "";
                
                if (reader.Read())
                {
                    isSuccess = reader["isSuccess"] != DBNull.Value ? Convert.ToInt32(reader["isSuccess"]) : 0;
                    msg = reader["msg"] != DBNull.Value ? reader["msg"].ToString() : "Có lỗi xảy ra";
                }
                else
                {
                    isSuccess = 0;
                    msg = "Stored procedure không trả về kết quả";
                }
                
                reader.Close();
                
                Response.Write("{\"isSuccess\":" + isSuccess + ",\"msg\":\"" + msg.Replace("\"", "\\\"") + "\"}");
            }
        }
        catch (Exception ex)
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"" + ex.Message.Replace("\"", "\\\"") + "\"}");
        }
    }

    private int GetCurrentUserId()
    {
        int currentUserId = 0;
        if (Session["UserID"] != null)
        {
            Int32.TryParse(Convert.ToString(Session["UserID"]), out currentUserId);
        }
        return currentUserId;
    }

    private bool CanSelectTicketUser(SqlConnection conn, int currentUserId, string match)
    {
        using (SqlCommand cmd = new SqlCommand(@"
            SELECT CASE WHEN EXISTS (SELECT 1 FROM dbo.userinfo2 WHERE id = @userID AND admin = 1)
                OR EXISTS (SELECT 1 FROM bet_match_total WHERE match = @match AND user_host = @userID)
                THEN 1 ELSE 0 END", conn))
        {
            cmd.Parameters.Add("@userID", SqlDbType.Int).Value = currentUserId;
            cmd.Parameters.Add("@match", SqlDbType.NVarChar).Value = match;
            return Convert.ToInt32(cmd.ExecuteScalar()) == 1;
        }
    }
</script>
