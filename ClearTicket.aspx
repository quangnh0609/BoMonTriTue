<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    public class ClearData
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
            var data = serializer.Deserialize<ClearData>(requestBody);
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                
                SqlCommand cmd = new SqlCommand("bet_ticket_clear", conn);
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
</script>
