<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Xml.Linq" %>

<script runat="server">
    public class MatchData
    {
        public string match  { get; set; }
        public string season { get; set; }
        public string time   { get; set; }
        public string home   { get; set; }
        public string way    { get; set; }
        public string editYn { get; set; }

        public string h1_conner_over_under  { get; set; }
        public string ft_conner_over_under  { get; set; }
        public string h2_conner_over_under  { get; set; }
        public string h1_conner_handicap    { get; set; }
        public string ft_conner_handicap    { get; set; }
        public string h2_conner_handicap    { get; set; }
		
        public string h1_goal_over_under    { get; set; }
        public string ft_goal_over_under    { get; set; }
        public string h2_goal_over_under    { get; set; }
        public string h1_goal_handicap      { get; set; }
        public string ft_goal_handicap      { get; set; }
        public string h2_goal_handicap      { get; set; }
        
		public string h1_card_over_under  { get; set; }
        public string ft_card_over_under  { get; set; }
        public string h2_card_over_under  { get; set; }
        public string h1_card_handicap    { get; set; }
        public string ft_card_handicap    { get; set; }
        public string h2_card_handicap    { get; set; }
		
		public string h1_euro_home          { get; set; }
        public string ft_euro_home          { get; set; }
        public string h2_euro_home          { get; set; }
        public string h1_euro_draw          { get; set; }
        public string ft_euro_draw          { get; set; }
        public string h2_euro_draw          { get; set; }
        public string h1_euro_way           { get; set; }
        public string ft_euro_way           { get; set; }
        public string h2_euro_way           { get; set; }
		
        public string h1_conner_over_win    { get; set; }
        public string ft_conner_over_win    { get; set; }
        public string h2_conner_over_win    { get; set; }
        public string h1_conner_under_win   { get; set; }
        public string ft_conner_under_win   { get; set; }
        public string h2_conner_under_win   { get; set; }
        public string h1_conner_home_win    { get; set; }
        public string ft_conner_home_win    { get; set; }
        public string h2_conner_home_win    { get; set; }
        public string h1_conner_way_win     { get; set; }
        public string ft_conner_way_win     { get; set; }
        public string h2_conner_way_win     { get; set; }
		
        public string h1_goal_over_win      { get; set; }
        public string ft_goal_over_win      { get; set; }
        public string h2_goal_over_win      { get; set; }
        public string h1_goal_under_win     { get; set; }
        public string ft_goal_under_win     { get; set; }
        public string h2_goal_under_win     { get; set; }
        public string h1_goal_home_win      { get; set; }
        public string ft_goal_home_win      { get; set; }
        public string h2_goal_home_win      { get; set; }
        public string h1_goal_way_win       { get; set; }
        public string ft_goal_way_win       { get; set; }
        public string h2_goal_way_win       { get; set; }
		
		public string h1_card_over_win    { get; set; }
        public string ft_card_over_win    { get; set; }
        public string h2_card_over_win    { get; set; }
        public string h1_card_under_win   { get; set; }
        public string ft_card_under_win   { get; set; }
        public string h2_card_under_win   { get; set; }
        public string h1_card_home_win    { get; set; }
        public string ft_card_home_win    { get; set; }
        public string h2_card_home_win    { get; set; }
        public string h1_card_way_win     { get; set; }
        public string ft_card_way_win     { get; set; }
        public string h2_card_way_win     { get; set; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<MatchData>(requestBody);

            if (string.IsNullOrEmpty(data.season) || string.IsNullOrEmpty(data.home) || string.IsNullOrEmpty(data.way))
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Thiếu thông tin bắt buộc\"}");
                return;
            }

            // Build XML details — mỗi dòng kèo là 1 <item> với <col>, <h1>, <ft>, <h2>
            XElement details = new XElement("details",
                new XElement("item", new XElement("col", "conner_over_under"),  new XElement("h1", data.h1_conner_over_under  ?? ""), new XElement("ft", data.ft_conner_over_under  ?? ""), new XElement("h2", data.h2_conner_over_under  ?? "")),
                new XElement("item", new XElement("col", "conner_handicap"),    new XElement("h1", data.h1_conner_handicap    ?? ""), new XElement("ft", data.ft_conner_handicap    ?? ""), new XElement("h2", data.h2_conner_handicap    ?? "")),
                
				new XElement("item", new XElement("col", "goal_over_under"),    new XElement("h1", data.h1_goal_over_under    ?? ""), new XElement("ft", data.ft_goal_over_under    ?? ""), new XElement("h2", data.h2_goal_over_under    ?? "")),
                new XElement("item", new XElement("col", "goal_handicap"),      new XElement("h1", data.h1_goal_handicap      ?? ""), new XElement("ft", data.ft_goal_handicap      ?? ""), new XElement("h2", data.h2_goal_handicap      ?? "")),
                
				new XElement("item", new XElement("col", "card_over_under"),  new XElement("h1", data.h1_card_over_under  ?? ""), new XElement("ft", data.ft_card_over_under  ?? ""), new XElement("h2", data.h2_card_over_under  ?? "")),
                new XElement("item", new XElement("col", "card_handicap"),    new XElement("h1", data.h1_card_handicap    ?? ""), new XElement("ft", data.ft_card_handicap    ?? ""), new XElement("h2", data.h2_card_handicap    ?? "")),
                
				new XElement("item", new XElement("col", "euro_home"),          new XElement("h1", data.h1_euro_home          ?? ""), new XElement("ft", data.ft_euro_home          ?? ""), new XElement("h2", data.h2_euro_home          ?? "")),
                new XElement("item", new XElement("col", "euro_draw"),          new XElement("h1", data.h1_euro_draw          ?? ""), new XElement("ft", data.ft_euro_draw          ?? ""), new XElement("h2", data.h2_euro_draw          ?? "")),
                new XElement("item", new XElement("col", "euro_way"),           new XElement("h1", data.h1_euro_way           ?? ""), new XElement("ft", data.ft_euro_way           ?? ""), new XElement("h2", data.h2_euro_way           ?? "")),
                
				new XElement("item", new XElement("col", "conner_over_win"),    new XElement("h1", data.h1_conner_over_win    ?? ""), new XElement("ft", data.ft_conner_over_win    ?? ""), new XElement("h2", data.h2_conner_over_win    ?? "")),
                new XElement("item", new XElement("col", "conner_under_win"),   new XElement("h1", data.h1_conner_under_win   ?? ""), new XElement("ft", data.ft_conner_under_win   ?? ""), new XElement("h2", data.h2_conner_under_win   ?? "")),
                new XElement("item", new XElement("col", "conner_home_win"),    new XElement("h1", data.h1_conner_home_win    ?? ""), new XElement("ft", data.ft_conner_home_win    ?? ""), new XElement("h2", data.h2_conner_home_win    ?? "")),
                new XElement("item", new XElement("col", "conner_way_win"),     new XElement("h1", data.h1_conner_way_win     ?? ""), new XElement("ft", data.ft_conner_way_win     ?? ""), new XElement("h2", data.h2_conner_way_win     ?? "")),
                
				new XElement("item", new XElement("col", "goal_over_win"),      new XElement("h1", data.h1_goal_over_win      ?? ""), new XElement("ft", data.ft_goal_over_win      ?? ""), new XElement("h2", data.h2_goal_over_win      ?? "")),
                new XElement("item", new XElement("col", "goal_under_win"),     new XElement("h1", data.h1_goal_under_win     ?? ""), new XElement("ft", data.ft_goal_under_win     ?? ""), new XElement("h2", data.h2_goal_under_win     ?? "")),
                new XElement("item", new XElement("col", "goal_home_win"),      new XElement("h1", data.h1_goal_home_win      ?? ""), new XElement("ft", data.ft_goal_home_win      ?? ""), new XElement("h2", data.h2_goal_home_win      ?? "")),
                new XElement("item", new XElement("col", "goal_way_win"),       new XElement("h1", data.h1_goal_way_win       ?? ""), new XElement("ft", data.ft_goal_way_win       ?? ""), new XElement("h2", data.h2_goal_way_win       ?? "")),
				
				new XElement("item", new XElement("col", "card_over_win"),    new XElement("h1", data.h1_card_over_win    ?? ""), new XElement("ft", data.ft_card_over_win    ?? ""), new XElement("h2", data.h2_card_over_win    ?? "")),
                new XElement("item", new XElement("col", "card_under_win"),   new XElement("h1", data.h1_card_under_win   ?? ""), new XElement("ft", data.ft_card_under_win   ?? ""), new XElement("h2", data.h2_card_under_win   ?? "")),
                new XElement("item", new XElement("col", "card_home_win"),    new XElement("h1", data.h1_card_home_win    ?? ""), new XElement("ft", data.ft_card_home_win    ?? ""), new XElement("h2", data.h2_card_home_win    ?? "")),
                new XElement("item", new XElement("col", "card_way_win"),     new XElement("h1", data.h1_card_way_win     ?? ""), new XElement("ft", data.ft_card_way_win     ?? ""), new XElement("h2", data.h2_card_way_win     ?? ""))
            );

            DateTime? parsedTime = null;
            if (!string.IsNullOrEmpty(data.time))
            {
                DateTime dt;
                if (DateTime.TryParse(data.time, out dt))
                    parsedTime = dt;
            }

            bool isEdit = (data.editYn ?? "false") == "true";

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                SqlCommand cmd = new SqlCommand("bet_match_insert", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@match",   string.IsNullOrEmpty(data.match) ? (object)DBNull.Value : data.match);
                cmd.Parameters.AddWithValue("@season",  data.season);
                cmd.Parameters.AddWithValue("@time",    parsedTime.HasValue ? (object)parsedTime.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@home",    data.home);
                cmd.Parameters.AddWithValue("@way",     data.way);
                cmd.Parameters.AddWithValue("@details", details.ToString());
                cmd.Parameters.AddWithValue("@userID",  Session["UserID"]);
                cmd.Parameters.AddWithValue("@edit",    isEdit);

                SqlDataReader reader = cmd.ExecuteReader();
                int isSuccess = 0;
                string msg = "";
                if (reader.Read())
                {
                    isSuccess = reader["isSuccess"] != DBNull.Value ? Convert.ToInt32(reader["isSuccess"]) : 0;
                    msg       = reader["msg"]       != DBNull.Value ? reader["msg"].ToString() : "Có lỗi xảy ra";
                }
                else { msg = "Stored procedure không trả về kết quả"; }
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
