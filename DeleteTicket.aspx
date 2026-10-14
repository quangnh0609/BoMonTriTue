<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    public class DeleteData
    {
        public string match { get; set; }
        public int user_id { get; set; }
        public string code { get; set; }
        public string ticket { get; set; }
    }
    
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        
        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<DeleteData>(requestBody);
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                if ((data.code ?? "").Trim() == "46")
                {
                    DeleteChampionTicket(conn, data);
                    return;
                }
                
                SqlCommand cmd = new SqlCommand("bet_ticket_delete", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@match", data.match);
                cmd.Parameters.AddWithValue("@user_id", data.user_id);
                cmd.Parameters.AddWithValue("@code", data.code);
                cmd.Parameters.AddWithValue("@ticket", data.ticket);
                cmd.Parameters.AddWithValue("@userID", Session["UserID"]);
                
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

    private void DeleteChampionTicket(SqlConnection conn, DeleteData data)
    {
        int currentUserId = 0;
        if (Session["UserID"] != null) int.TryParse(Session["UserID"].ToString(), out currentUserId);
        if (currentUserId == 0)
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.\"}");
            return;
        }

        SqlCommand cmdRight = new SqlCommand(@"
            SELECT ISNULL(admin, 0) AS admin,
                   dbo.bet_check_right(@userID, 'bet_ticket_delete') AS can_delete
            FROM dbo.userinfo2
            WHERE id = @userID", conn);
        cmdRight.Parameters.AddWithValue("@userID", currentUserId);
        SqlDataReader rightReader = cmdRight.ExecuteReader();
        bool isAdmin = false;
        bool canDelete = false;
        if (rightReader.Read())
        {
            isAdmin = rightReader["admin"] != DBNull.Value && Convert.ToBoolean(rightReader["admin"]);
            string right = rightReader["can_delete"] != DBNull.Value ? rightReader["can_delete"].ToString().Trim() : "0";
            canDelete = right == "1" || right == "True" || right == "true";
        }
        rightReader.Close();

        if (!isAdmin && !canDelete)
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"Không được phân quyền thực hiện chức năng này!\"}");
            return;
        }

        int championId;
        string key = (data.match ?? "").Trim();
        if (key.Length < 6 || !int.TryParse(key.Substring(key.Length - 6), out championId) || championId <= 0)
        {
            Response.Write("{\"isSuccess\":0,\"msg\":\"Không xóa dòng này\"}");
            return;
        }

        if (!isAdmin)
        {
            SqlCommand cmdCheck = new SqlCommand(@"
                SELECT TOP 1 result_win, time_lock, user_host
                FROM bet_champion
                WHERE id = @id", conn);
            cmdCheck.Parameters.AddWithValue("@id", championId);
            SqlDataReader checkReader = cmdCheck.ExecuteReader();
            bool isOwner = false;
            bool isOwnTicket = currentUserId == data.user_id;
            if (checkReader.Read())
            {
                isOwner = checkReader["user_host"] != DBNull.Value && Convert.ToInt32(checkReader["user_host"]) == currentUserId;
                if (!isOwner && !isOwnTicket)
                {
                    checkReader.Close();
                    Response.Write("{\"isSuccess\":0,\"msg\":\"Không được phân quyền thực hiện chức năng này!\"}");
                    return;
                }
                if (!isOwner && checkReader["result_win"] != DBNull.Value)
                {
                    checkReader.Close();
                    Response.Write("{\"isSuccess\":0,\"msg\":\"Đã vào kết quả, không xóa vé cược!\"}");
                    return;
                }
                if (!isOwner && checkReader["time_lock"] != DBNull.Value && Convert.ToDateTime(checkReader["time_lock"]) <= DateTime.Now)
                {
                    checkReader.Close();
                    Response.Write("{\"isSuccess\":0,\"msg\":\"Kèo đã khóa, không thể xóa vé cược. Liên hệ nhà cái để xóa vé cược hộ!\"}");
                    return;
                }
            }
            checkReader.Close();
        }

        SqlCommand cmdDelete = new SqlCommand(@"
            DELETE FROM bet_ticket_champion
            WHERE id = @id AND user_id = @user_id", conn);
        cmdDelete.Parameters.AddWithValue("@id", championId);
        cmdDelete.Parameters.AddWithValue("@user_id", data.user_id);
        int affected = cmdDelete.ExecuteNonQuery();
        Response.Write("{\"isSuccess\":" + (affected > 0 ? "1" : "0") + ",\"msg\":\"" + (affected > 0 ? "Xóa thành công!" : "Không tìm thấy vé cược") + "\"}");
    }
</script>
