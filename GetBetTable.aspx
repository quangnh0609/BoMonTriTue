<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<script runat="server">
    public class BetTableItem
    {
        public int stt { get; set; }
        public int user_id { get; set; }
        public decimal money_win { get; set; }
        public decimal rate_of_win { get; set; }
        public decimal balance { get; set; }
        public decimal fee { get; set; }
        public string name { get; set; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";

        try
        {
            List<BetTableItem> list = HttpRuntime.Cache["home_bet_table"] as List<BetTableItem>;
            if (list == null)
            {
                list = LoadBetTable();
                HttpRuntime.Cache.Insert(
                    "home_bet_table",
                    list,
                    null,
                    DateTime.Now.AddSeconds(30),
                    System.Web.Caching.Cache.NoSlidingExpiration
                );
            }

            JavaScriptSerializer serializer = new JavaScriptSerializer();
            Response.Write("{\"d\":" + serializer.Serialize(list) + "}");
        }
        catch
        {
            Response.Write("{\"d\":[]}");
        }
    }

    private List<BetTableItem> LoadBetTable()
    {
        List<BetTableItem> list = new List<BetTableItem>();
        string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;

        using (SqlConnection conn = new SqlConnection(connStr))
        using (SqlCommand cmd = new SqlCommand("bet_table", conn))
        {
            cmd.CommandType = CommandType.StoredProcedure;
            conn.Open();

            using (SqlDataReader reader = cmd.ExecuteReader())
            {
                while (reader.Read())
                {
                    list.Add(new BetTableItem
                    {
                        stt = reader["stt"] != DBNull.Value ? Convert.ToInt32(reader["stt"]) : 0,
                        user_id = reader["user_id"] != DBNull.Value ? Convert.ToInt32(reader["user_id"]) : 0,
                        money_win = reader["money_win"] != DBNull.Value ? Convert.ToDecimal(reader["money_win"]) : 0,
                        rate_of_win = reader["rate_of_win"] != DBNull.Value ? Convert.ToDecimal(reader["rate_of_win"]) : 0,
                        balance = reader["balance"] != DBNull.Value ? Convert.ToDecimal(reader["balance"]) : 0,
                        fee = reader["fee"] != DBNull.Value ? Convert.ToDecimal(reader["fee"]) : 0,
                        name = reader["name"] != DBNull.Value ? reader["name"].ToString() : ""
                    });
                }
            }
        }

        return list;
    }
</script>
