<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    public class TicketItem
    {
        public string match { get; set; }
        public int user_id { get; set; }
        public string code { get; set; }
        public string ticket { get; set; }
        public string ticket_name { get; set; }
        public decimal money { get; set; }
        public decimal money_win { get; set; }
        public decimal fee { get; set; }
		public string result_name { get; set; }
        public string textColor { get; set; }
        public string rowColor { get; set; }
        public string rowBold { get; set; }
        public string ticket_type { get; set; }
    }
    
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        
        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<Dictionary<string, string>>(requestBody);
            
            // Lấy giá trị từ request (đã có mặc định trong HTML)
            int userId = int.Parse(data["userId"]);
            string match = data["match"];
            bool exactFootballMatch = data.ContainsKey("ticketType") && data["ticketType"] == "football";
            bool exactEsportMatch = data.ContainsKey("ticketType") && data["ticketType"] == "esport";
            string season = data.ContainsKey("season") ? data["season"] : "";
            string type = data["type"];
            string clear = data["clear"];
            string result = data["result"];
            string dateFrom = !string.IsNullOrEmpty(data["dateFrom"]) ? data["dateFrom"] : null;
            string dateTo = !string.IsNullOrEmpty(data["dateTo"]) ? data["dateTo"] : null;
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                var list = new List<TicketItem>();
                SqlCommand cmd = CreateTicketListCommand(conn, "bet_ticket_result", userId, match, season, type, clear, result, dateFrom, dateTo);
                cmd.Parameters.Add("@zcInssert", SqlDbType.NVarChar).Value = "";
                if (exactEsportMatch)
                {
                    cmd.Parameters.Add("@exactEsportMatch", SqlDbType.Bit).Value = true;
                }
                if (exactFootballMatch)
                {
                    cmd.Parameters.Add("@exactFootballMatch", SqlDbType.Bit).Value = true;
                }
                SqlDataReader reader = cmd.ExecuteReader();
                ReadTicketItems(reader, list, exactEsportMatch ? "esport" : "match");
                reader.Close();

                string jsonResult = serializer.Serialize(list);
                Response.Write("{\"d\":" + jsonResult + "}");
            }
        }
        catch (Exception ex)
        {
            Response.Write("{\"d\":[]}");
        }
    }

    private SqlCommand CreateTicketListCommand(SqlConnection conn, string procName, int userId, string match, string season, string type, string clear, string result, string dateFrom, string dateTo)
    {
        SqlCommand cmd = new SqlCommand(procName, conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.Add("@user_id", SqlDbType.Int).Value = userId;
        cmd.Parameters.Add("@match", SqlDbType.NVarChar).Value = match;
        cmd.Parameters.Add("@season", SqlDbType.NVarChar).Value = season ?? "";
        cmd.Parameters.Add("@type", SqlDbType.Char, 1).Value = type[0];
        cmd.Parameters.Add("@clear", SqlDbType.Char, 1).Value = clear[0];
        cmd.Parameters.Add("@result", SqlDbType.Char, 1).Value = result[0];
        cmd.Parameters.Add("@df", SqlDbType.NVarChar).Value = dateFrom != null ? (object)dateFrom : DBNull.Value;
        cmd.Parameters.Add("@dt", SqlDbType.NVarChar).Value = dateTo != null ? (object)dateTo : DBNull.Value;
        return cmd;
    }

    private void ReadTicketItems(SqlDataReader reader, List<TicketItem> list, string defaultTicketType)
    {
        int ticketTypeOrdinal = -1;
        for (int i = 0; i < reader.FieldCount; i++) {
            if (reader.GetName(i) == "ticket_type") {
                ticketTypeOrdinal = i;
                break;
            }
        }

        while (reader.Read())
        {
            list.Add(new TicketItem
            {
                match = reader["match"] != DBNull.Value ? reader["match"].ToString() : "",
                user_id = reader["user_id"] != DBNull.Value ? Convert.ToInt32(reader["user_id"]) : 0,
                code = reader["code"] != DBNull.Value ? reader["code"].ToString() : "",
                ticket = reader["ticket"] != DBNull.Value ? reader["ticket"].ToString() : "",
                ticket_name = reader["ticket_name"] != DBNull.Value ? reader["ticket_name"].ToString() : "",
                money = reader["money"] != DBNull.Value ? Convert.ToDecimal(reader["money"]) : 0,
                money_win = reader["money_win"] != DBNull.Value ? Convert.ToDecimal(reader["money_win"]) : 0,
                fee = reader["fee"] != DBNull.Value ? Convert.ToDecimal(reader["fee"]) : 0,
                result_name = reader["result_name"] != DBNull.Value ? reader["result_name"].ToString() : "",
                textColor = reader["textColor"] != DBNull.Value ? reader["textColor"].ToString() : "",
                rowColor = reader["rowColor"] != DBNull.Value ? reader["rowColor"].ToString() : "",
                rowBold = reader["rowBold"] != DBNull.Value ? reader["rowBold"].ToString() : "",
                ticket_type = ticketTypeOrdinal >= 0 && reader[ticketTypeOrdinal] != DBNull.Value ? reader[ticketTypeOrdinal].ToString() : defaultTicketType
            });
        }
    }
</script>
