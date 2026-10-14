<%@ Page Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Xml.Linq" %>

<script runat="server">
    public class ChampionDetail
    {
        public string id { get; set; }
        public string team { get; set; }
        public string rate { get; set; }
    }

    public class ChampionData
    {
        public string name          { get; set; }
        public string season        { get; set; }
        public string time          { get; set; }
        public string time_lock     { get; set; }
        public string editYn        { get; set; }
        public string saveResultYn  { get; set; }
        public List<ChampionDetail> details       { get; set; }
        public List<ResultDetail>   resultDetails { get; set; }
    }

    public class ResultDetail
    {
        public string id       { get; set; }
        public string team       { get; set; }
        public int    result_win { get; set; }
		public int    result_lost { get; set; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        Response.ContentType = "application/json";
        try
        {
            string requestBody = new System.IO.StreamReader(Request.InputStream).ReadToEnd();
            var serializer = new JavaScriptSerializer();
            var data = serializer.Deserialize<ChampionData>(requestBody);

            if (string.IsNullOrEmpty(data.season))
            {
                Response.Write("{\"isSuccess\":0,\"msg\":\"Thiếu thông tin bắt buộc\"}");
                return;
            }

            // ── Lưu kết quả ──────────────────────────────────────────────────
            if ((data.saveResultYn ?? "") == "true")
            {
                DateTime? parsedTimeR = null;
                if (!string.IsNullOrEmpty(data.time))
                {
                    DateTime dt;
                    if (DateTime.TryParse(data.time, out dt)) parsedTimeR = dt;
                }

                XElement resultXml = new XElement("details");
                if (data.resultDetails != null)
                {
                    foreach (var rd in data.resultDetails)
                    {
                        if (!string.IsNullOrEmpty(rd.id))
                        {
                            resultXml.Add(new XElement("item",
                                new XElement("id",       rd.id),
                                new XElement("result_win", rd.result_win),
								new XElement("result_lost", rd.result_lost)
                            ));
                        }
                    }
                }

                string connStrR = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
                using (SqlConnection connR = new SqlConnection(connStrR))
                {
                    connR.Open();
                    SqlCommand cmdR = new SqlCommand("exec bet_champion_result @season, @time, @details, @userID", connR);
                    cmdR.Parameters.AddWithValue("@season",  data.season);
                    cmdR.Parameters.AddWithValue("@time",    parsedTimeR.HasValue ? (object)parsedTimeR.Value : DBNull.Value);
                    cmdR.Parameters.AddWithValue("@details", resultXml.ToString());
                    cmdR.Parameters.AddWithValue("@userID",  Session["UserID"]);

                    SqlDataReader readerR = cmdR.ExecuteReader();
                    int isSuccessR = 0; string msgR = "";
                    if (readerR.Read())
                    {
                        isSuccessR = readerR["isSuccess"] != DBNull.Value ? Convert.ToInt32(readerR["isSuccess"]) : 0;
                        msgR       = readerR["msg"]       != DBNull.Value ? readerR["msg"].ToString() : "Có lỗi xảy ra";
                    }
                    else { msgR = "Stored procedure không trả về kết quả"; }
                    readerR.Close();

                    Response.Write("{\"isSuccess\":" + isSuccessR + ",\"msg\":\"" + msgR.Replace("\"", "\\\"") + "\"}");
                }
                return;
            }

            // ── Lưu thêm/sửa kèo ─────────────────────────────────────────────
            XElement detailsXml = new XElement("details");
            if (data.details != null)
            {
                foreach (var detail in data.details)
                {
                    if (!string.IsNullOrEmpty(detail.team))
                    {
                        detailsXml.Add(new XElement("item",
                            new XElement("id", detail.id),
                            new XElement("team", detail.team),
                            new XElement("rate", (detail.rate ?? "").Trim().Replace(',', '.'))
                        ));
                    }
                }
            }

            DateTime? parsedTime = null;
            if (!string.IsNullOrEmpty(data.time))
            {
                DateTime dt;
                if (DateTime.TryParse(data.time, out dt))
                    parsedTime = dt;
            }

            DateTime? parsedTimeLock = null;
            if (!string.IsNullOrEmpty(data.time_lock))
            {
                DateTime dt;
                if (DateTime.TryParse(data.time_lock, out dt))
                    parsedTimeLock = dt;
            }

            bool isEdit = (data.editYn ?? "false") == "true";

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                conn.Open();
                string sql = "exec bet_champion_insert @season=@season, @time=@time, @time_lock=@time_lock, @details=@details, @userID=@userID, @edit=@edit, @name=@name";
                SqlCommand cmd = new SqlCommand(sql, conn);
                cmd.Parameters.AddWithValue("@season",    data.season);
                cmd.Parameters.AddWithValue("@time",      parsedTime.HasValue ? (object)parsedTime.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@time_lock", parsedTimeLock.HasValue ? (object)parsedTimeLock.Value : DBNull.Value);
                cmd.Parameters.AddWithValue("@name",      string.IsNullOrWhiteSpace(data.name) ? (object)DBNull.Value : data.name.Trim());
                cmd.Parameters.AddWithValue("@details",   detailsXml.ToString());
                cmd.Parameters.AddWithValue("@userID",    Session["UserID"]);
                cmd.Parameters.AddWithValue("@edit",      isEdit);
                
                SqlDataReader reader = cmd.ExecuteReader();
                int isSuccess = 0; string msg = "";
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
