<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    public class RequestData
    {
        public int userId { get; set; }
    }
    
    public class TicketItem
    {
        public string code { get; set; }
        public string match { get; set; }
        public string code_name { get; set; }
        public decimal money { get; set; }
        public string textColor { get; set; }
        public string rowColor { get; set; }
    }
    
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        
        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<RequestData>(requestBody);
            
            if (data.userId == 0)
            {
                Response.Write("{\"d\":[]}");
                return;
            }
            
            List<TicketItem> tickets = new List<TicketItem>();
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand("bet_ticket_copy", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@user_id", data.userId);
                
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                
                while (reader.Read())
                {
                    TicketItem item = new TicketItem();
                    item.code = reader["code"] != DBNull.Value ? reader["code"].ToString() : "";
                    item.match = reader["match"] != DBNull.Value ? reader["match"].ToString() : "";
                    item.code_name = reader["code_name"] != DBNull.Value ? reader["code_name"].ToString() : "";
                    item.money = reader["money"] != DBNull.Value ? Convert.ToDecimal(reader["money"]) : 0;
                    item.textColor = reader["textColor"] != DBNull.Value ? reader["textColor"].ToString() : "";
                    item.rowColor = reader["rowColor"] != DBNull.Value ? reader["rowColor"].ToString() : "";
                    
                    tickets.Add(item);
                }
                
                reader.Close();
            }
            
            string json = serializer.Serialize(new { d = tickets });
            Response.Write(json);
        }
        catch (Exception ex)
        {
            Response.Write("{\"d\":[],\"error\":\"" + ex.Message.Replace("\"", "\\\"") + "\"}");
        }
    }
</script>
