<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System" %>
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
        var serializer = new JavaScriptSerializer();

        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var data = serializer.Deserialize<Dictionary<string, string>>(requestBody);
            string season = data.ContainsKey("season") ? (data["season"] ?? "").Trim() : "";
            string time = data.ContainsKey("time") ? (data["time"] ?? "").Trim() : "";

            DateTime ticketDate;
            bool hasDate = DateTime.TryParse(time, out ticketDate);
            if (string.IsNullOrEmpty(season) || !hasDate)
            {
                Response.Write("{\"d\":[]}");
                return;
            }

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("bet_ticket_result", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add("@user_id", SqlDbType.Int).Value = -2;
                cmd.Parameters.Add("@match", SqlDbType.NVarChar).Value = "";
                cmd.Parameters.Add("@season", SqlDbType.NVarChar).Value = season;
                cmd.Parameters.Add("@type", SqlDbType.Char, 1).Value = "0";
                cmd.Parameters.Add("@clear", SqlDbType.Char, 1).Value = "2";
                cmd.Parameters.Add("@result", SqlDbType.Char, 1).Value = "2";
                cmd.Parameters.Add("@df", SqlDbType.NVarChar).Value = ticketDate.ToString("yyyy-MM-dd HH:mm:ss");
                cmd.Parameters.Add("@dt", SqlDbType.NVarChar).Value = ticketDate.ToString("yyyy-MM-dd HH:mm:ss");
                cmd.Parameters.Add("@zcInssert", SqlDbType.NVarChar).Value = "";
                cmd.Parameters.Add("@isChampion", SqlDbType.Bit).Value = true;

                var list = new List<TicketItem>();
                SqlDataReader reader = cmd.ExecuteReader();
                while (reader.Read())
                {
                    int sysTotal = reader["systotal"] != DBNull.Value ? Convert.ToInt32(reader["systotal"]) : 0;
                    string code = reader["code"] != DBNull.Value ? reader["code"].ToString().Trim() : "";
                    if (sysTotal == 0 && code != "46") continue;

                    list.Add(new TicketItem
                    {
                        match = reader["match"] != DBNull.Value ? reader["match"].ToString() : "",
                        user_id = reader["user_id"] != DBNull.Value ? Convert.ToInt32(reader["user_id"]) : 0,
                        code = code,
                        ticket = reader["ticket"] != DBNull.Value ? reader["ticket"].ToString() : "",
                        ticket_name = reader["ticket_name"] != DBNull.Value ? reader["ticket_name"].ToString() : "",
                        money = reader["money"] != DBNull.Value ? Convert.ToDecimal(reader["money"]) : 0,
                        money_win = reader["money_win"] != DBNull.Value ? Convert.ToDecimal(reader["money_win"]) : 0,
                        fee = reader["fee"] != DBNull.Value ? Convert.ToDecimal(reader["fee"]) : 0,
                        result_name = reader["result_name"] != DBNull.Value ? reader["result_name"].ToString() : "",
                        textColor = reader["textColor"] != DBNull.Value ? reader["textColor"].ToString() : "",
                        rowColor = reader["rowColor"] != DBNull.Value ? reader["rowColor"].ToString() : "",
                        rowBold = reader["rowBold"] != DBNull.Value ? reader["rowBold"].ToString() : "",
                        ticket_type = "champion"
                    });
                }
                reader.Close();

                Response.Write("{\"d\":" + serializer.Serialize(list) + "}");
            }
        }
        catch
        {
            Response.Write("{\"d\":[]}");
        }
    }
</script>
