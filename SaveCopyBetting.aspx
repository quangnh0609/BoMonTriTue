<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Xml.Linq" %>
<%@ Import Namespace="System.Linq" %>

<script runat="server">
    public class TicketDetail
    {
        public string code { get; set; }
        public string match { get; set; }
        public decimal money { get; set; }
        public bool selected { get; set; }
    }
    
    public class SaveData
    {
        public int userId { get; set; }
        public List<TicketDetail> details { get; set; }
    }
    
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        
        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<SaveData>(requestBody);
            
            if (data.userId == 0 || data.details == null || data.details.Count == 0)
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Thiếu thông tin bắt buộc\"}");
                return;
            }
            
            // Lọc các item được chọn
            var selectedItems = data.details.Where(d => d.selected).ToList();
            
            if (selectedItems.Count == 0)
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Vui lòng chọn ít nhất một vé cược\"}");
                return;
            }
            
            // Nhóm theo match
            var groupedByMatch = selectedItems.GroupBy(d => d.match);
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                
                int totalSuccess = 0;
                List<string> messages = new List<string>();
                
                foreach (var group in groupedByMatch)
                {
                    string match = group.Key;
                    bool isEsportMatch = MatchExists(conn, "SELECT COUNT(1) FROM bet_esport_match WHERE match_id = @match", match);
                    
                    // Tạo XML cho details
                    XElement detailsXml = new XElement("details");
                    foreach (var detail in group)
                    {
                        if (detail.money > 0)
                        {
                            detailsXml.Add(new XElement("item",
                                new XElement("code", detail.code),
                                new XElement("money", detail.money)
                            ));
                        }
                    }
                    
                    // Gọi stored procedure
                    SqlCommand cmd = new SqlCommand(isEsportMatch ? "bet_ticket_esport_insert" : "bet_ticket_insert", conn);
                    cmd.CommandType = CommandType.StoredProcedure;
                    cmd.Parameters.AddWithValue("@user_id", data.userId);
                    cmd.Parameters.AddWithValue("@match", match);
                    cmd.Parameters.AddWithValue("@details", detailsXml.ToString());
					cmd.Parameters.AddWithValue("@userID", Session["UserID"]);
                    
                    SqlDataReader reader = cmd.ExecuteReader();
                    
                    if (reader.Read())
                    {
                        int isSuccess = reader["isSuccess"] != DBNull.Value ? Convert.ToInt32(reader["isSuccess"]) : 0;
                        string msg = reader["msg"] != DBNull.Value ? reader["msg"].ToString() : "";
                        
                        if (isSuccess == 1)
                        {
                            totalSuccess++;
                        }
                        else
                        {
                            messages.Add(msg);
                        }
                    }
                    
                    reader.Close();
                }
                
                if (totalSuccess > 0)
                {
                    string msg = "Đã lưu thành công " + totalSuccess + " trận đấu";
                    if (messages.Count > 0)
                    {
                        msg += ". Lỗi: " + string.Join(", ", messages);
                    }
                    Response.Write("{\"isSuccess\":1,\"msg\":\"" + msg.Replace("\"", "\\\"") + "\"}");
                }
                else
                {
                    Response.Write("{\"isSuccess\":0,\"msg\":\"" + string.Join(", ", messages).Replace("\"", "\\\"") + "\"}");
                }
            }
        }
        catch (Exception ex)
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"" + ex.Message.Replace("\"", "\\\"") + "\"}");
        }
    }

    private bool MatchExists(SqlConnection conn, string sql, string match)
    {
        using (SqlCommand cmd = new SqlCommand(sql, conn))
        {
            cmd.Parameters.AddWithValue("@match", match);
            object result = cmd.ExecuteScalar();
            return result != null && result != DBNull.Value && Convert.ToInt32(result) > 0;
        }
    }
</script>
