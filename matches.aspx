<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucAddMatch.ascx" TagPrefix="uc" TagName="AddMatch" %>
<%@ Register Src="~/ucResultMatch.ascx" TagPrefix="uc" TagName="ResultMatch" %>
<%@ Register Src="~/ucTicketMatch.ascx" TagPrefix="uc" TagName="TicketMatch" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null) 
        {
            Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
            return;
        }

        if (!IsPostBack) { 
            BindMatchTable();
			LoadSmartData();
        }
        
        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }
    
    protected bool CheckRight(string action)
    {
        if (Session["UserID"] == null) return false;
        
        try {
            int userId = Convert.ToInt32(Session["UserID"]);
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("SELECT dbo.bet_check_right(@userID, @action)", conn);
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = userId;
                cmd.Parameters.Add("@action", SqlDbType.NVarChar).Value = action;
                
                conn.Open();
                object result = cmd.ExecuteScalar();
                
                if (result == null) return false;
                
                string resultStr = result.ToString().Trim();
                return resultStr == "1" || resultStr == "True" || resultStr == "true";
            }
        } catch {
            return false;
        }
    }

    protected int GetCurrentUserId()
    {
        if (Session["UserID"] == null) return 0;
        int userId;
        return Int32.TryParse(Session["UserID"].ToString(), out userId) ? userId : 0;
    }

    protected bool IsAdminUser()
    {
        if (Session["UserID"] == null) return false;
        try {
            int userId = Convert.ToInt32(Session["UserID"]);
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.userinfo2 WHERE id = @userID AND admin = 1", conn);
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = userId;
                conn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        } catch {
            return false;
        }
    }

    protected bool CanManageMatch(object userHostValue)
    {
        if (IsAdminUser()) return true;
        if (userHostValue == null || userHostValue == DBNull.Value) return false;
        int userHost;
        return Int32.TryParse(userHostValue.ToString(), out userHost) && userHost == GetCurrentUserId();
    }

    protected bool CanManageMatchRow(object dataItem)
    {
        if (IsAdminUser()) return true;
        DataRowView row = dataItem as DataRowView;
        if (row == null || row.DataView == null || row.DataView.Table == null) return false;
        if (!row.DataView.Table.Columns.Contains("user_host")) return false;
        return CanManageMatch(row["user_host"]);
    }

    protected string GetRowString(object dataItem, string columnName)
    {
        DataRowView row = dataItem as DataRowView;
        if (row == null || row.DataView == null || row.DataView.Table == null) return "";
        if (!row.DataView.Table.Columns.Contains(columnName)) return "";
        if (row[columnName] == null || row[columnName] == DBNull.Value) return "";
        return row[columnName].ToString();
    }

    private void BindMatchTable() {
        try {
            string team = Request.Form["filterTeam"] ?? "";
            string season = Request.Form["filterSeason"] ?? "";
            string dateFrom = Request.Form["filterDateFrom"] ?? "";
            string dateTo = Request.Form["filterDateTo"] ?? "";
            
            // Lấy status từ form, nếu không có thì mặc định là "1,2"
            string status = "";
            if (IsPostBack && Request.Form.GetValues("filterStatus") != null)
            {
                status = string.Join(",", Request.Form.GetValues("filterStatus"));
            }
            else if (!IsPostBack)
            {
                status = "1, 2, 3, 4"; // Mặc định load trang: Trực tiếp và Sắp tới
            }
            
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("bet_matches", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                
                cmd.Parameters.AddWithValue("@team", string.IsNullOrEmpty(team) ? "" : team);
                cmd.Parameters.AddWithValue("@season", string.IsNullOrEmpty(season) ? "" : season);
                cmd.Parameters.AddWithValue("@datefrom", string.IsNullOrEmpty(dateFrom) ? (object)DBNull.Value : dateFrom);
                cmd.Parameters.AddWithValue("@dateto", string.IsNullOrEmpty(dateTo) ? (object)DBNull.Value : dateTo);
                cmd.Parameters.AddWithValue("@status", status);
                
                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable(); 
                da.Fill(dt);                
                rptMatches.DataSource = dt;
                rptMatches.DataBind();
            }
        } catch (Exception ex) { }
    }


	
	[System.Web.Services.WebMethod]
	public static string GetMatchData(string matchId)
	{
		try
		{
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = "SELECT * FROM vbet_match_total_for_web WHERE match = @match";
				SqlCommand cmd = new SqlCommand(sql, conn);
				cmd.Parameters.AddWithValue("@match", matchId);
				
				conn.Open();
				SqlDataReader reader = cmd.ExecuteReader();
				
				if (reader.Read())
				{
					var matchData = new Dictionary<string, object>();
					
					for (int i = 0; i < reader.FieldCount; i++)
					{
						string fieldName = reader.GetName(i);
						object value = reader.IsDBNull(i) ? null : reader.GetValue(i);
						matchData[fieldName] = value;
					}
					
					reader.Close();
					
					var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
					return serializer.Serialize(matchData);
				}
				
				reader.Close();
			}
			
			return null;
		}
		catch (Exception ex)
		{
			return null;
		}
	}
	
	[System.Web.Services.WebMethod]
	public static string GetTicketData(string matchId)
	{
		try
		{
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = "exec bet_ticket_result '-2', @match, '', 0, 2, 2, '', '', ''";
				SqlCommand cmd = new SqlCommand(sql, conn);
				cmd.Parameters.AddWithValue("@match", matchId);
				
				conn.Open();
				SqlDataReader reader = cmd.ExecuteReader();
				
				if (reader.Read())
				{
					var ticketData = new Dictionary<string, object>();
					
					// Thêm match vào ticket
					ticketData["match"] = matchId;
					
					for (int i = 0; i < reader.FieldCount; i++)
					{
						string fieldName = reader.GetName(i);
						object value = reader.IsDBNull(i) ? "" : reader.GetValue(i);
						ticketData[fieldName] = value;
					}
					
					reader.Close();
					conn.Close();
					
					var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
					return serializer.Serialize(ticketData);
				}
				else
				{
					// Không có dữ liệu, trả về object rỗng với match
					reader.Close();
					conn.Close();
					
					var ticketData = new Dictionary<string, object>();
					ticketData["match"] = matchId;
					
					var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
					return serializer.Serialize(ticketData);
				}
			}
		}
		catch (Exception ex)
		{
			// Trả về lỗi để debug
			var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
			var errorData = new Dictionary<string, object>();
			errorData["error"] = ex.Message;
			errorData["match"] = matchId;
			return serializer.Serialize(errorData);
		}
	}
	
	[System.Web.Services.WebMethod]
	public static string GetResultData(string matchId)
	{
		try
		{
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = "exec bet_match_result @match";
				SqlCommand cmd = new SqlCommand(sql, conn);
				cmd.Parameters.AddWithValue("@match", matchId);
				
				conn.Open();
				SqlDataReader reader = cmd.ExecuteReader();
				
				if (reader.Read())
				{
					var resultData = new Dictionary<string, object>();
					
					// Thêm match vào result
					resultData["match"] = matchId;
					
					for (int i = 0; i < reader.FieldCount; i++)
					{
						string fieldName = reader.GetName(i);
						object value = reader.IsDBNull(i) ? "" : reader.GetValue(i);
						resultData[fieldName] = value;
					}
					
					reader.Close();
					resultData["result_fields"] = GetMatchResultFields(conn, matchId);
					conn.Close();
					
					var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
					return serializer.Serialize(resultData);
				}
				else
				{
					// Không có dữ liệu, trả về object rỗng với match
					reader.Close();
					
					var resultData = new Dictionary<string, object>();
					resultData["match"] = matchId;
					resultData["result_fields"] = GetMatchResultFields(conn, matchId);
					conn.Close();
					
					var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
					return serializer.Serialize(resultData);
				}
			}
		}
		catch (Exception ex)
		{
			// Trả về lỗi để debug
			var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
			var errorData = new Dictionary<string, object>();
			errorData["error"] = ex.Message;
			errorData["match"] = matchId;
			return serializer.Serialize(errorData);
		}
	}

	private static Dictionary<string, bool> GetMatchResultFields(SqlConnection conn, string matchId)
	{
		var fields = new Dictionary<string, bool>();
		string sql = @"
			SELECT DISTINCT code
			FROM bet_ticket
			WHERE match = @match";
		SqlCommand cmd = new SqlCommand(sql, conn);
		cmd.Parameters.AddWithValue("@match", matchId);
		SqlDataReader reader = cmd.ExecuteReader();
		while (reader.Read())
		{
			string code = reader["code"] == DBNull.Value ? "" : reader["code"].ToString().Trim();
			if (code == "01" || code == "11") fields["h1_conner"] = true;
			if (code == "02" || code == "12" || code == "03" || code == "13") fields["ft_conner"] = true;
			if (code == "21" || code == "31" || code == "41") fields["h1_goal"] = true;
			if (code == "22" || code == "32" || code == "23" || code == "33" || code == "42" || code == "43") fields["ft_goal"] = true;
			if (code == "51" || code == "61") fields["h1_card"] = true;
			if (code == "52" || code == "62" || code == "53" || code == "63") fields["ft_card"] = true;
			if (code == "71") fields["serve"] = true;
		}
		reader.Close();
		return fields;
	}
	
	[System.Web.Services.WebMethod]
	public static string SaveResultData(string resultData)
	{
		try
		{
			// Kiểm tra session
			if (HttpContext.Current.Session["UserID"] == null)
			{
				var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
				var result = new Dictionary<string, object>();
				result["isSuccess"] = 0;
				result["msg"] = "Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.";
				return serializer.Serialize(result);
			}
			
			var ser = new System.Web.Script.Serialization.JavaScriptSerializer();
			var data = ser.Deserialize<Dictionary<string, object>>(resultData);
			
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = @"exec bet_match_result_update @match, 1, 
					@h1_conner_home, @h1_conner_way, 
					@h1_goal_home, @h1_goal_way, 
					@h1_card_home, @h1_card_way, 
					@ft_conner_home, @ft_conner_way, 
					@ft_goal_home, @ft_goal_way, 
					@ft_card_home, @ft_card_way, 
					@serve_result,
					@userID";

				SqlCommand cmd = new SqlCommand(sql, conn);
				
				cmd.Parameters.AddWithValue("@match", data.ContainsKey("match") ? data["match"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_conner_home", data.ContainsKey("h1_conner_home") && !string.IsNullOrEmpty(data["h1_conner_home"].ToString()) ? data["h1_conner_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_conner_way", data.ContainsKey("h1_conner_way") && !string.IsNullOrEmpty(data["h1_conner_way"].ToString()) ? data["h1_conner_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_goal_home", data.ContainsKey("h1_goal_home") && !string.IsNullOrEmpty(data["h1_goal_home"].ToString()) ? data["h1_goal_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_goal_way", data.ContainsKey("h1_goal_way") && !string.IsNullOrEmpty(data["h1_goal_way"].ToString()) ? data["h1_goal_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_card_home", data.ContainsKey("h1_card_home") && !string.IsNullOrEmpty(data["h1_card_home"].ToString()) ? data["h1_card_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_card_way", data.ContainsKey("h1_card_way") && !string.IsNullOrEmpty(data["h1_card_way"].ToString()) ? data["h1_card_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_conner_home", data.ContainsKey("ft_conner_home") && !string.IsNullOrEmpty(data["ft_conner_home"].ToString()) ? data["ft_conner_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_conner_way", data.ContainsKey("ft_conner_way") && !string.IsNullOrEmpty(data["ft_conner_way"].ToString()) ? data["ft_conner_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_goal_home", data.ContainsKey("ft_goal_home") && !string.IsNullOrEmpty(data["ft_goal_home"].ToString()) ? data["ft_goal_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_goal_way", data.ContainsKey("ft_goal_way") && !string.IsNullOrEmpty(data["ft_goal_way"].ToString()) ? data["ft_goal_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_card_home", data.ContainsKey("ft_card_home") && !string.IsNullOrEmpty(data["ft_card_home"].ToString()) ? data["ft_card_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_card_way", data.ContainsKey("ft_card_way") && !string.IsNullOrEmpty(data["ft_card_way"].ToString()) ? data["ft_card_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@serve_result", data.ContainsKey("serve_result") && data["serve_result"] != null ? data["serve_result"].ToString() : "");
				cmd.Parameters.AddWithValue("@userID", HttpContext.Current.Session["UserID"]);
				
				conn.Open();
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
				conn.Close();
				
				var res = new Dictionary<string, object>();
				res["isSuccess"] = isSuccess;
				res["msg"] = msg;
				
				return ser.Serialize(res);
			}
		}
		catch (Exception ex)
		{
			var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
			var result = new Dictionary<string, object>();
			result["isSuccess"] = 0;
			result["msg"] = "Lỗi: " + ex.Message;
			return serializer.Serialize(result);
		}
	}
	
	[System.Web.Services.WebMethod]
	public static string DeleteResultData(string resultData)
	{
		try
		{
			// Kiểm tra session
			if (HttpContext.Current.Session["UserID"] == null)
			{
				var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
				var result = new Dictionary<string, object>();
				result["isSuccess"] = 0;
				result["msg"] = "Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.";
				return serializer.Serialize(result);
			}
			
			var ser = new System.Web.Script.Serialization.JavaScriptSerializer();
			var data = ser.Deserialize<Dictionary<string, object>>(resultData);
			
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = @"exec bet_match_result_update @match, 0, 
					@h1_conner_home, @h1_conner_way, 
					@h1_goal_home, @h1_goal_way, 
					@h1_card_home, @h1_card_way, 
					@ft_conner_home, @ft_conner_way, 
					@ft_goal_home, @ft_goal_way, 
					@ft_card_home, @ft_card_way, 
					@serve_result,
					@userID";

				SqlCommand cmd = new SqlCommand(sql, conn);
				
				cmd.Parameters.AddWithValue("@match", data.ContainsKey("match") ? data["match"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_conner_home", data.ContainsKey("h1_conner_home") && !string.IsNullOrEmpty(data["h1_conner_home"].ToString()) ? data["h1_conner_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_conner_way", data.ContainsKey("h1_conner_way") && !string.IsNullOrEmpty(data["h1_conner_way"].ToString()) ? data["h1_conner_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_goal_home", data.ContainsKey("h1_goal_home") && !string.IsNullOrEmpty(data["h1_goal_home"].ToString()) ? data["h1_goal_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_goal_way", data.ContainsKey("h1_goal_way") && !string.IsNullOrEmpty(data["h1_goal_way"].ToString()) ? data["h1_goal_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_card_home", data.ContainsKey("h1_card_home") && !string.IsNullOrEmpty(data["h1_card_home"].ToString()) ? data["h1_card_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@h1_card_way", data.ContainsKey("h1_card_way") && !string.IsNullOrEmpty(data["h1_card_way"].ToString()) ? data["h1_card_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_conner_home", data.ContainsKey("ft_conner_home") && !string.IsNullOrEmpty(data["ft_conner_home"].ToString()) ? data["ft_conner_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_conner_way", data.ContainsKey("ft_conner_way") && !string.IsNullOrEmpty(data["ft_conner_way"].ToString()) ? data["ft_conner_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_goal_home", data.ContainsKey("ft_goal_home") && !string.IsNullOrEmpty(data["ft_goal_home"].ToString()) ? data["ft_goal_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_goal_way", data.ContainsKey("ft_goal_way") && !string.IsNullOrEmpty(data["ft_goal_way"].ToString()) ? data["ft_goal_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_card_home", data.ContainsKey("ft_card_home") && !string.IsNullOrEmpty(data["ft_card_home"].ToString()) ? data["ft_card_home"].ToString() : "");
				cmd.Parameters.AddWithValue("@ft_card_way", data.ContainsKey("ft_card_way") && !string.IsNullOrEmpty(data["ft_card_way"].ToString()) ? data["ft_card_way"].ToString() : "");
				cmd.Parameters.AddWithValue("@serve_result", data.ContainsKey("serve_result") && data["serve_result"] != null ? data["serve_result"].ToString() : "");
				cmd.Parameters.AddWithValue("@userID", HttpContext.Current.Session["UserID"]);

				conn.Open();
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
				conn.Close();
				
				var res = new Dictionary<string, object>();
				res["isSuccess"] = isSuccess;
				res["msg"] = msg;
				
				return ser.Serialize(res);
			}
		}
		catch (Exception ex)
		{
			var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
			var result = new Dictionary<string, object>();
			result["isSuccess"] = 0;
			result["msg"] = "Lỗi: " + ex.Message;
			return serializer.Serialize(result);
		}
	}
	
	private void LoadSmartData() {
		try {
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr)) {
				// 1. Lấy dữ liệu Season
				string sqlSeason = "SELECT rtrim(ltrim(season)) as season, season_name FROM bet_season";
				SqlDataAdapter daSeason = new SqlDataAdapter(sqlSeason, conn);
				DataTable dtSeason = new DataTable();
				daSeason.Fill(dtSeason);

				// 2. Lấy dữ liệu Team
				string sqlTeam = "SELECT rtrim(ltrim(team)) as team, team_name FROM bet_team";
				SqlDataAdapter daTeam = new SqlDataAdapter(sqlTeam, conn);
				DataTable dtTeam = new DataTable();
				daTeam.Fill(dtTeam);

				// 3. Chuyển DataTable thành JSON (Dùng vòng lặp Dictionary để tránh lỗi thư viện)
				var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
				
				var listS = new List<Dictionary<string, object>>();
				foreach (DataRow r in dtSeason.Rows) {
					listS.Add(new Dictionary<string, object> { 
						{ "season", r["season"] }, { "season_name", r["season_name"] } 
					});
				}

				var listT = new List<Dictionary<string, object>>();
				foreach (DataRow r in dtTeam.Rows) {
					listT.Add(new Dictionary<string, object> { 
						{ "team", r["team"] }, { "team_name", r["team_name"] } 
					});
				}

				// 4. Đẩy chuỗi script ra Client
				string jsonS = serializer.Serialize(listS);
				string jsonT = serializer.Serialize(listT);
				string script = "var dataSeason = " + jsonS + "; var dataTeam = " + jsonT + ";";
				
				ClientScript.RegisterStartupScript(this.GetType(), "InitData", script, true);
			}
		} catch (Exception ex) {
			// Ghi log lỗi ở đây để check nếu SQL có vấn đề
		}
	}
	
	protected void ucAddMatch_MatchAdded(object sender, EventArgs e)
	{
		BindMatchTable();
	}
	
	[System.Web.Services.WebMethod]
	public static string DeleteMatch(string matchId)
	{
		try
		{
			// Kiểm tra session
			if (HttpContext.Current.Session["UserID"] == null)
			{
				var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
				var result = new Dictionary<string, object>();
				result["isSuccess"] = 0;
				result["msg"] = "Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.";
				return serializer.Serialize(result);
			}
			
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = "exec bet_match_delete @match, @userID";
				SqlCommand cmd = new SqlCommand(sql, conn);
				
				cmd.Parameters.AddWithValue("@match", matchId);
				cmd.Parameters.AddWithValue("@userID", HttpContext.Current.Session["UserID"]);
				
				conn.Open();
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
				conn.Close();
				
				var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
				var res = new Dictionary<string, object>();
				res["isSuccess"] = isSuccess;
				res["msg"] = msg;
				
				return serializer.Serialize(res);
			}
		}
		catch (Exception ex)
		{
			var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
			var result = new Dictionary<string, object>();
			result["isSuccess"] = 0;
			result["msg"] = "Lỗi: " + ex.Message;
			return serializer.Serialize(result);
		}
	}
	
	[System.Web.Services.WebMethod]
	public static string FilterMatches(string team, string season, string dateFrom, string dateTo, string status)
	{
		try
		{
			string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
			using (SqlConnection conn = new SqlConnection(connStr))
			{
				SqlCommand cmd = new SqlCommand("bet_matches", conn);
				cmd.CommandType = CommandType.StoredProcedure;
				
				cmd.Parameters.AddWithValue("@team", string.IsNullOrEmpty(team) ? "" : team);
				cmd.Parameters.AddWithValue("@season", string.IsNullOrEmpty(season) ? "" : season);
				cmd.Parameters.AddWithValue("@datefrom", string.IsNullOrEmpty(dateFrom) ? (object)DBNull.Value : dateFrom);
				cmd.Parameters.AddWithValue("@dateto", string.IsNullOrEmpty(dateTo) ? (object)DBNull.Value : dateTo);
				cmd.Parameters.AddWithValue("@status", string.IsNullOrEmpty(status) ? "" : status);
				
				conn.Open();
				SqlDataReader reader = cmd.ExecuteReader();
				
				var matches = new List<Dictionary<string, object>>();
				while (reader.Read())
				{
					var match = new Dictionary<string, object>();
					for (int i = 0; i < reader.FieldCount; i++)
					{
						string fieldName = reader.GetName(i);
						object value = reader.IsDBNull(i) ? null : reader.GetValue(i);
						match[fieldName] = value;
					}
					matches.Add(match);
				}
				
				reader.Close();
				conn.Close();
				
				var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
				return serializer.Serialize(matches);
			}
		}
		catch (Exception ex)
		{
			var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
			var result = new Dictionary<string, object>();
			result["error"] = ex.Message;
			return serializer.Serialize(result);
		}
	}

</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Danh sách trận đấu</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .menu-font { font-size: 16px; font-weight: bold; }
        .breadcrumb-link { color: #2563eb; text-decoration: none; }
        .breadcrumb-current { color: #4b5563; cursor: default; }
        
        .nav-item { 
            border-right: 4px solid transparent; 
            display: flex;
            align-items: center;
            padding: 0.75rem 1rem;
            font-weight: bold;
            transition: all 0.2s;
        }
        .nav-item-active { 
            border-right-color: #1d4ed8; 
            background-color: #eff6ff; 
            color: #1d4ed8 !important; 
        }
        .nav-item i { width: 20px; text-align: center; margin-right: 12px; }

        /* Style cho Dropdown gọn gàng trong card */
        .ddl-season {
            background: transparent; border: none; outline: none;
            font-weight: bold; text-align: center; width: 100%;
            color: inherit; cursor: pointer;
        }
		
		/* Fix cho Safari để không bị lệch text bên trong ô */
		input[type="datetime-local"] {
			appearance: none;
			-webkit-appearance: none;
			min-height: 2.25rem; /* Tương đương h-9 */
		}
		
		/* Safari datetime picker fix */
		.safari-datetime-fix {
			position: relative;
		}
		
		/* Đảm bảo picker hoạt động trên Safari */
		.safari-datetime-fix::-webkit-datetime-edit {
			padding: 0;
		}
		
		.safari-datetime-fix::-webkit-calendar-picker-indicator {
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			bottom: 0;
			width: 100%;
			height: 100%;
			opacity: 0;
			cursor: pointer;
			z-index: 1;
		}
		
		/* Chỉ áp dụng cho mobile để tránh ảnh hưởng desktop */
		@media screen and (max-width: 768px) {
			.safari-datetime-fix {
				font-size: 16px !important; /* Đánh lừa trình duyệt để không zoom */
			}

			/* Nếu muốn chữ nhìn vẫn nhỏ như 12px thì dùng scale */
			.safari-datetime-fix {
				display: block;
			}
			
			/* Hoặc đơn giản nhất là ép font-size lên 16px khi focus */
			input:focus {
				font-size: 16px !important;
			}
		}
		
		/* Fix lỗi không hiện picker trên Safari/iPhone */
		input[id$='time'] {
			position: relative;
			-webkit-appearance: none;
		}

		/* Kéo dãn vùng kích hoạt lịch ra toàn bộ ô input */
		input[id$='time']::-webkit-calendar-picker-indicator {
			position: absolute;
			top: 0;
			left: 0;
			right: 0;
			bottom: 0;
			width: 100%;
			height: 100%;
			opacity: 0;
			cursor: pointer;
		}
    </style>
</head>
<body class="h-[100dvh] flex flex-col">
    <form runat="server" class="h-full flex flex-col">
        <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
            <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="matches" PageTitle="Trận đấu" />
        </nav>
		
		<div class="flex flex-1 overflow-hidden relative">
            <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>

            <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="matches" />

            <main class="flex-1 flex flex-col overflow-hidden bg-[#f8fafc]">
				<!-- Bộ lọc -->
				<div class="flex-none bg-white border-b">
					<!-- Header bộ lọc -->
					<div class="p-3 lg:p-6 pb-3 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition-colors" onclick="toggleFilter()">
						<h3 class="text-sm font-bold text-gray-700 flex items-center gap-2">
							<i class="fa-solid fa-filter text-blue-600"></i>
							Bộ lọc
						</h3>
						<i id="filterIcon" class="fa-solid fa-chevron-down text-gray-600 transition-transform"></i>
					</div>
					
					<!-- Nội dung bộ lọc -->
					<div id="filterContent" class="hidden px-3 lg:px-6 pb-3">
						<div class="grid grid-cols-1 lg:grid-cols-5 gap-3">
							<div class="col-span-1 lg:col-span-2 grid grid-cols-2 gap-3">
								<div class="relative">
									<label class="block text-xs font-bold text-gray-700 mb-1">Đội</label>
									<input type="text" id="filterTeamSearch" 
										class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
										placeholder="Tìm kiếm đội..." 
										onfocus="showTeamDropdown()" 
										oninput="filterTeamOptions()" />
									<input type="hidden" id="filterTeam" name="filterTeam" />
									<div id="teamDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto">
										<!-- Options will be populated here -->
									</div>
								</div>
								
								<div class="relative">
									<label class="block text-xs font-bold text-gray-700 mb-1">Giải đấu</label>
									<input type="text" id="filterSeasonSearch" 
										class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
										placeholder="Tìm kiếm giải đấu..." 
										onfocus="showSeasonDropdown()" 
										oninput="filterSeasonOptions()" />
									<input type="hidden" id="filterSeason" name="filterSeason" />
									<div id="seasonDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto">
										<!-- Options will be populated here -->
									</div>
								</div>
							</div>
							
							<div class="col-span-1 lg:col-span-2 grid grid-cols-2 gap-3">
								<div>
									<label class="block text-xs font-bold text-gray-700 mb-1">Từ ngày</label>
									<input type="date" id="filterDateFrom" name="filterDateFrom"
										class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none" />
								</div>
								
								<div>
									<label class="block text-xs font-bold text-gray-700 mb-1">Đến ngày</label>
									<input type="date" id="filterDateTo" name="filterDateTo"
										class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none" />
								</div>
							</div>
							
							<div>
								<label class="block text-xs font-bold text-gray-700 mb-1">Trạng thái</label>
								<div class="border rounded-lg p-2 bg-white">
									<label class="flex items-center gap-2 mb-1">
										<input type="checkbox" name="filterStatus" value="1" class="w-4 h-4" checked />
										<span class="text-sm font-bold">Trực tiếp</span>
									</label>
									<label class="flex items-center gap-2 mb-1">
										<input type="checkbox" name="filterStatus" value="2" class="w-4 h-4" checked />
										<span class="text-sm font-bold">Sắp tới</span>
									</label>
									<label class="flex items-center gap-2">
										<input type="checkbox" name="filterStatus" value="3" class="w-4 h-4" checked />
										<span class="text-sm font-bold">Chờ kết quả</span>
									</label>
									<label class="flex items-center gap-2">
										<input type="checkbox" name="filterStatus" value="4" class="w-4 h-4" checked />
										<span class="text-sm font-bold">Chưa tất toán</span>
									</label>
									<label class="flex items-center gap-2">
										<input type="checkbox" name="filterStatus" value="5" class="w-4 h-4" />
										<span class="text-sm font-bold">Kết thúc</span>
									</label>
								</div>
							</div>
						</div>
						
						<div class="mt-3 flex justify-end">
							<button type="button" onclick="applyFilter()" 
								class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-bold text-sm transition-all active:scale-95 flex items-center gap-2">
								<i class="fa-solid fa-search"></i>
								Tìm kiếm
							</button>
						</div>
					</div>
				</div>
				
				<div class="flex-none p-3 lg:p-6 pb-0">
					<% if (CheckRight("bet_match_insert")) { %>
					<button type="button" onclick="openAddMatchModalNew()" 
						class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 rounded-xl shadow-lg flex items-center transition-all active:scale-95 group border-2 border-white">
						<i class="fa-solid fa-plus mr-2 group-hover:rotate-90 transition-transform"></i>
						<span class="font-bold text-[11px] lg:text-xs tracking-wide">Thêm trận</span>
					</button>
					<% } %>
				</div>
				
				<div class="flex-1 overflow-auto main-scroll p-3 lg:p-6 pt-4">
                    <div id="matchesContainer" class="grid grid-cols-1 lg:grid-cols-2 gap-6">
                        <asp:Repeater ID="rptMatches" runat="server">
                            <ItemTemplate>
                                <div class="bg-white rounded-xl shadow-md border border-gray-200 p-4 flex flex-col transition-all hover:shadow-lg" data-status='<%# Eval("status") %>'>
                                    
                                    <div class="flex justify-end items-center gap-2 mb-3">
                                        <button type="button" onclick="openTicketMatchModal('<%# Eval("match") %>', '<%# Eval("name") %>')" 
                                            class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-ticket mr-1"></i>Vé cược
                                        </button>
                                        <button type="button" onclick="openResultMatchModal('<%# Eval("match") %>')" 
                                            class="bg-purple-500 hover:bg-purple-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-flag-checkered mr-1"></i>Kết quả
                                        </button>
                                        <% if (CheckRight("bet_match_insert")) { %>
                                        <button type="button" onclick="copyMatch('<%# Eval("match") %>')" 
                                            class="bg-green-500 hover:bg-green-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-copy mr-1"></i>Sao chép
                                        </button>
                                        <% } %>
                                        <button type="button" style='<%# CanManageMatchRow(Container.DataItem) ? "" : "display:none" %>' onclick="editMatch('<%# Eval("match") %>')" 
                                            class="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-pen-to-square mr-1"></i>Sửa
                                        </button>
                                        <button type="button" style='<%# CanManageMatchRow(Container.DataItem) ? "" : "display:none" %>' onclick="deleteMatch('<%# Eval("match") %>')" 
                                            class="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded text-[11px] transition-all">
                                            <i class="fa-solid fa-trash mr-1"></i>Xóa
                                        </button>
                                    </div>
                                    
                                    <div class="flex justify-between items-center gap-3 mb-1 font-bold text-[14px] lg:text-[16px] match-colored-row">
                                        <div class="min-w-0 text-left opacity-80">
                                            <%# string.IsNullOrWhiteSpace(GetRowString(Container.DataItem, "host_name")) ? "" : "<span class=\"bg-gray-100 px-2 py-0.5 rounded text-[12px] border border-gray-200 font-bold\">Cái: " + Server.HtmlEncode(GetRowString(Container.DataItem, "host_name")) + "</span>" %>
                                        </div>
                                        <div class="text-right whitespace-nowrap"><%# Eval("statusname") %></div>
                                    </div>
                                    <div class="flex justify-between items-center gap-3 mb-2 font-bold text-[14px] lg:text-[16px] match-colored-row">
                                        <div class="min-w-0 text-left opacity-80">
                                            <span class="bg-gray-100 px-2 py-0.5 rounded text-[12px] border border-gray-200">
                                                <%# Eval("season") %>
                                            </span>
                                        </div>
                                        <div class="text-right whitespace-nowrap"><%# Eval("time", "{0:HH:mm dd/MM/yyyy}") %></div>
                                    </div>

                                    <div class="flex justify-between items-center mb-4 font-bold text-[14px] lg:text-[16px] match-colored-row">
                                        <div class="w-[45%] text-right"><%# Eval("home") %></div>
                                        <div class="w-[10%] text-center">vs</div>
                                        <div class="w-[45%] text-left"><%# Eval("way") %></div>
                                    </div>

                                    <div class="w-full">
										<table class="w-full border-collapse font-bold text-[14px] lg:text-[16px] match-colored-row table-fixed">
											<thead>
												<tr>
													<!-- Khóa độ rộng cố định tại đây -->
													<th class="w-[42%]"></th> 
													<th class="w-[19%] text-right pb-2">Hiệp 1</th>
													<th class="w-[20%] text-right pb-2">Cả trận</th>
													<th class="w-[19%] text-right pb-2">Hiệp 2</th>
												</tr>
											</thead>
											<tbody>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title="Tài góc">Tài góc</td>
													<td class="text-right"><%# Eval("h1_conner_over_under") %></td>
													<td class="text-right"><%# Eval("ft_conner_over_under") %></td>
													<td class="text-right"><%# Eval("h2_conner_over_under") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title="Góc (chủ nhà)">Góc (chủ nhà)</td>
													<td class="text-right"><%# Eval("h1_conner_handicap") %></td>
													<td class="text-right"><%# Eval("ft_conner_handicap") %></td>
													<td class="text-right"><%# Eval("h2_conner_handicap") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title="Tài bàn">Tài bàn</td>
													<td class="text-right"><%# Eval("h1_goal_over_under") %></td>
													<td class="text-right"><%# Eval("ft_goal_over_under") %></td>
													<td class="text-right"><%# Eval("h2_goal_over_under") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title="Bàn (chủ nhà)">Bàn (chủ nhà)</td>
													<td class="text-right"><%# Eval("h1_goal_handicap") %></td>
													<td class="text-right"><%# Eval("ft_goal_handicap") %></td>
													<td class="text-right"><%# Eval("h2_goal_handicap") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title="Tài thẻ">Tài thẻ</td>
													<td class="text-right"><%# Eval("h1_card_over_under") %></td>
													<td class="text-right"><%# Eval("ft_card_over_under") %></td>
													<td class="text-right"><%# Eval("h2_card_over_under") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title="Thẻ (chủ nhà)">Thẻ (chủ nhà)</td>
													<td class="text-right"><%# Eval("h1_card_handicap") %></td>
													<td class="text-right"><%# Eval("ft_card_handicap") %></td>
													<td class="text-right"><%# Eval("h2_card_handicap") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title='<%# Eval("home") %>'><%# Eval("home") %></td>
													<td class="text-right"><%# Eval("h1_euro_home") %></td>
													<td class="text-right"><%# Eval("ft_euro_home") %></td>
													<td class="text-right"><%# Eval("h2_euro_home") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title="Hòa">Hòa</td>
													<td class="text-right"><%# Eval("h1_euro_draw") %></td>
													<td class="text-right"><%# Eval("ft_euro_draw") %></td>
													<td class="text-right"><%# Eval("h2_euro_draw") %></td>
												</tr>
												<tr>
													<td class="text-right pr-2 py-1 truncate" title='<%# Eval("way") %>'><%# Eval("way") %></td>
													<td class="text-right"><%# Eval("h1_euro_way") %></td>
													<td class="text-right"><%# Eval("ft_euro_way") %></td>
													<td class="text-right"><%# Eval("h2_euro_way") %></td>
												</tr>
											</tbody>
										</table>
									</div>
                                </div>
                            </ItemTemplate>
                        </asp:Repeater>
                    </div>
                </div>
            </main>
        </div>
		
		<uc:AddMatch runat="server" ID="ucAddMatch" OnMatchAdded="ucAddMatch_MatchAdded" />
		<uc:ResultMatch runat="server" ID="ucResultMatch" />
		<uc:TicketMatch runat="server" ID="ucTicketMatch" />
    </form>

    <script type="text/javascript">
        function toggleSidebar() {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('overlay');
            if (sidebar.classList.contains('-translate-x-full')) {
                sidebar.classList.remove('-translate-x-full');
                overlay.classList.remove('hidden');
            } else {
                sidebar.classList.add('-translate-x-full');
                overlay.classList.add('hidden');
            }
        }
        
        function toggleFilter() {
            const filterContent = document.getElementById('filterContent');
            const filterIcon = document.getElementById('filterIcon');
            
            if (filterContent.classList.contains('hidden')) {
                filterContent.classList.remove('hidden');
                filterIcon.classList.add('rotate-180');
            } else {
                filterContent.classList.add('hidden');
                filterIcon.classList.remove('rotate-180');
            }
        }
        
        // Load dữ liệu cho datalist
        let teamData = [];
        let seasonData = [];
        
        window.addEventListener('load', function() {
            if (typeof dataTeam !== 'undefined') {
                teamData = dataTeam;
                renderTeamDropdown(teamData);
            }
            
            if (typeof dataSeason !== 'undefined') {
                seasonData = dataSeason;
                renderSeasonDropdown(seasonData);
            }
        });
        
        function renderTeamDropdown(data) {
            const dropdown = document.getElementById('teamDropdown');
            let html = '<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm" onclick="selectTeam(\'\', \'-- Chọn đội --\')">-- Chọn đội --</div>';
            data.forEach(item => {
                html += `<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm" onclick="selectTeam('${item.team}', '${item.team_name}')">${item.team_name}</div>`;
            });
            dropdown.innerHTML = html;
        }
        
        function renderSeasonDropdown(data) {
            const dropdown = document.getElementById('seasonDropdown');
            let html = '<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm" onclick="selectSeason(\'\', \'-- Chọn giải đấu --\')">-- Chọn giải đấu --</div>';
            data.forEach(item => {
                html += `<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm" onclick="selectSeason('${item.season}', '${item.season_name}')">${item.season_name}</div>`;
            });
            dropdown.innerHTML = html;
        }
        
        function showTeamDropdown() {
            document.getElementById('teamDropdown').classList.remove('hidden');
            document.getElementById('seasonDropdown').classList.add('hidden');
        }
        
        function showSeasonDropdown() {
            document.getElementById('seasonDropdown').classList.remove('hidden');
            document.getElementById('teamDropdown').classList.add('hidden');
        }
        
        function selectTeam(value, text) {
            document.getElementById('filterTeam').value = value;
            document.getElementById('filterTeamSearch').value = text;
            document.getElementById('teamDropdown').classList.add('hidden');
        }
        
        function selectSeason(value, text) {
            document.getElementById('filterSeason').value = value;
            document.getElementById('filterSeasonSearch').value = text;
            document.getElementById('seasonDropdown').classList.add('hidden');
        }
        
        function filterTeamOptions() {
            const searchText = document.getElementById('filterTeamSearch').value.toLowerCase();
            const filtered = teamData.filter(item => 
                item.team_name.toLowerCase().includes(searchText) || 
                item.team.toLowerCase().includes(searchText)
            );
            renderTeamDropdown(filtered);
            showTeamDropdown();
        }
        
        function filterSeasonOptions() {
            const searchText = document.getElementById('filterSeasonSearch').value.toLowerCase();
            const filtered = seasonData.filter(item => 
                item.season_name.toLowerCase().includes(searchText) || 
                item.season.toLowerCase().includes(searchText)
            );
            renderSeasonDropdown(filtered);
            showSeasonDropdown();
        }
        
        // Đóng dropdown khi click bên ngoài
        document.addEventListener('click', function(e) {
            if (!e.target.closest('.relative')) {
                document.getElementById('teamDropdown').classList.add('hidden');
                document.getElementById('seasonDropdown').classList.add('hidden');
            }
        });

        function openAddMatchModalNew() {
            // Set editYn = false cho chế độ thêm mới
            const editYnField = document.querySelector('[id$="editYn"]');
            if (editYnField) editYnField.value = 'false';
            
            openAddMatchModal();
        }
        
        function applyFilter() {
            const team = document.getElementById('filterTeam').value;
            const season = document.getElementById('filterSeason').value;
            const dateFrom = document.getElementById('filterDateFrom').value;
            const dateTo = document.getElementById('filterDateTo').value;
            
            const statusCheckboxes = document.querySelectorAll('input[name="filterStatus"]:checked');
            const status = Array.from(statusCheckboxes).map(cb => cb.value).join(',');
            
            <%--
			// Kiểm tra nếu chọn status "Kết thúc" (value = 5)
            if (status.includes('5')) {
                if (!dateFrom || !dateTo) {
                    alert('Khi chọn trạng thái "Kết thúc", bạn phải chọn cả Từ ngày và Đến ngày!');
                    return;
                }
                
                // Kiểm tra khoảng thời gian không quá 1 tháng (31 ngày)
                const fromDate = new Date(dateFrom);
                const toDate = new Date(dateTo);
                const diffTime = Math.abs(toDate - fromDate);
                const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                
                if (diffDays > 31) {
                    alert('Khi chọn trạng thái "Kết thúc", khoảng thời gian từ ngày đến ngày không được vượt quá 1 tháng (31 ngày)!');
                    return;
                }
            }
            --%>
            // Ẩn bộ lọc sau khi bấm tìm kiếm
            toggleFilter();
            
            loadMatchesData(team, season, dateFrom, dateTo, status);
        }
        
        function reloadMatchesData() {
            // Reload với filter hiện tại
            const team = document.getElementById('filterTeam').value;
            const season = document.getElementById('filterSeason').value;
            const dateFrom = document.getElementById('filterDateFrom').value;
            const dateTo = document.getElementById('filterDateTo').value;
            
            const statusCheckboxes = document.querySelectorAll('input[name="filterStatus"]:checked');
            const status = Array.from(statusCheckboxes).map(cb => cb.value).join(',');
            
            loadMatchesData(team, season, dateFrom, dateTo, status);
        }
        
        function loadMatchesData(team, season, dateFrom, dateTo, status) {
            // Hiển thị loading
            const container = document.getElementById('matchesContainer');
            container.innerHTML = '<div class="col-span-2 text-center py-10"><i class="fa-solid fa-spinner fa-spin text-4xl text-blue-600"></i><p class="mt-4 text-gray-600 font-bold">Đang tải dữ liệu...</p></div>';
            
            fetch('matches.aspx/FilterMatches', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ 
                    team: team, 
                    season: season, 
                    dateFrom: dateFrom, 
                    dateTo: dateTo, 
                    status: status 
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.d) {
                    const matches = JSON.parse(data.d);
                    renderMatches(matches);
                }
            })
            .catch(error => {
                console.error('Error:', error);
                container.innerHTML = '<div class="col-span-2 text-center py-10 text-red-600"><i class="fa-solid fa-exclamation-triangle text-4xl"></i><p class="mt-4 font-bold">Lỗi khi tải dữ liệu</p></div>';
            });
        }
        
        function getStatusColor(status) {
            if (status == 1) return '#FF0000';
            else if (status == 2) return '#00FF00';
            else if (status == 3) return '#FF00FF';
            else if (status == 4) return '#808080';
            else return '#808080';
        }
        
        function applyStatusColors(container) {
            (container || document).querySelectorAll('[data-status]').forEach(card => {
                const color = getStatusColor(card.dataset.status);
                card.querySelectorAll('.match-colored-row').forEach(el => el.style.color = color);
            });
        }
        
        function formatDateTime(dateStr) {
            if (!dateStr) return '';
            
            let date;
            
            if (dateStr.indexOf('/Date(') === 0) {
                // ASP.NET JSON Date format
                const timestamp = parseInt(dateStr.replace(/\/Date\((\d+)\)\//, '$1'));
                date = new Date(timestamp);
            } else {
                // ISO format hoặc SQL datetime
                date = new Date(dateStr);
            }
            
            if (isNaN(date.getTime())) return '';
            
            const hours = String(date.getHours()).padStart(2, '0');
            const minutes = String(date.getMinutes()).padStart(2, '0');
            const day = String(date.getDate()).padStart(2, '0');
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const year = date.getFullYear();
            return `${hours}:${minutes} ${day}/${month}/${year}`;
        }
        
        function renderMatches(matches) {
            const container = document.getElementById('matchesContainer');
            
            if (!matches || matches.length === 0) {
                container.innerHTML = '<div class="col-span-2 text-center py-10 text-gray-400"><i class="fa-solid fa-inbox text-6xl opacity-20"></i><p class="mt-4 font-bold">Không tìm thấy trận đấu nào</p></div>';
                return;
            }
            
            // Lấy quyền từ server-side
            const canInsert = <%= CheckRight("bet_match_insert") ? "true" : "false" %>;
            const canResult = <%= CheckRight("bet_match_result") ? "true" : "false" %>;
            const isAdmin = <%= IsAdminUser() ? "true" : "false" %>;
            const currentUserId = <%= GetCurrentUserId() %>;
            
            let html = '';
            matches.forEach(match => {
                const canManage = isAdmin || Number(match.user_host || 0) === currentUserId;
                html += `
                    <div class="bg-white rounded-xl shadow-md border border-gray-200 p-4 flex flex-col transition-all hover:shadow-lg" data-status="${match.status}">
                        <div class="flex justify-end items-center gap-2 mb-3">
                            ${canResult ? `<button type="button" onclick="openTicketMatchModal('${match.match}', '${(match.name||'').replace(/'/g, "\\'")}')" class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-ticket mr-1"></i>Vé cược</button>` : ''}
							${canResult ? `<button type="button" onclick="openResultMatchModal('${match.match}')" class="bg-purple-500 hover:bg-purple-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-flag-checkered mr-1"></i>Kết quả</button>` : ''}
                            ${canInsert ? `<button type="button" onclick="copyMatch('${match.match}')" class="bg-green-500 hover:bg-green-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-copy mr-1"></i>Sao chép</button>` : ''}
                            ${canManage ? `<button type="button" onclick="editMatch('${match.match}')" class="bg-blue-500 hover:bg-blue-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-pen-to-square mr-1"></i>Sửa</button>` : ''}
                            ${canManage ? `<button type="button" onclick="deleteMatch('${match.match}')" class="bg-red-500 hover:bg-red-600 text-white px-3 py-1 rounded text-[11px] transition-all"><i class="fa-solid fa-trash mr-1"></i>Xóa</button>` : ''}
                        </div>
                        
                        <div class="flex justify-between items-center gap-3 mb-1 font-bold text-[14px] lg:text-[16px] match-colored-row">
                            <div class="min-w-0 text-left opacity-80">${match.host_name ? `<span class="bg-gray-100 px-2 py-0.5 rounded text-[12px] border border-gray-200 font-bold">Cái: ${match.host_name}</span>` : ''}</div>
                            <div class="text-right whitespace-nowrap">${match.statusname || ''}</div>
                        </div>
                        <div class="flex justify-between items-center gap-3 mb-2 font-bold text-[14px] lg:text-[16px] match-colored-row">
                            <div class="min-w-0 text-left opacity-80">
                                <span class="bg-gray-100 px-2 py-0.5 rounded text-[12px] border border-gray-200">${match.season || ''}</span>
                            </div>
                            <div class="text-right whitespace-nowrap">${formatDateTime(match.time)}</div>
                        </div>

                        <div class="flex justify-between items-center mb-4 font-bold text-[14px] lg:text-[16px] match-colored-row">
                            <div class="w-[45%] text-right">${match.home || ''}</div>
                            <div class="w-[10%] text-center">vs</div>
                            <div class="w-[45%] text-left">${match.way || ''}</div>
                        </div>

                        <div class="w-full">
                            <table class="w-full border-collapse font-bold text-[14px] lg:text-[16px] match-colored-row">
                                <thead>
                                    <tr>
                                        <th class="w-[42%]"></th> 
                                        <th class="w-[19%] text-right pb-2">Hiệp 1</th>
                                        <th class="w-[20%] text-right pb-2">Cả trận</th>
                                        <th class="w-[19%] text-right pb-2">Hiệp 2</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">Tài góc</td>
                                        <td class="text-right">${match.h1_conner_over_under || ''}</td>
                                        <td class="text-right">${match.ft_conner_over_under || ''}</td>
                                        <td class="text-right">${match.h2_conner_over_under || ''}</td>
                                    </tr>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">Góc (chủ nhà)</td>
                                        <td class="text-right">${match.h1_conner_handicap || ''}</td>
                                        <td class="text-right">${match.ft_conner_handicap || ''}</td>
                                        <td class="text-right">${match.h2_conner_handicap || ''}</td>
                                    </tr>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">Tài bàn</td>
                                        <td class="text-right">${match.h1_goal_over_under || ''}</td>
                                        <td class="text-right">${match.ft_goal_over_under || ''}</td>
                                        <td class="text-right">${match.h2_goal_over_under || ''}</td>
                                    </tr>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">Bàn (chủ nhà)</td>
                                        <td class="text-right">${match.h1_goal_handicap || ''}</td>
                                        <td class="text-right">${match.ft_goal_handicap || ''}</td>
                                        <td class="text-right">${match.h2_goal_handicap || ''}</td>
                                    </tr>
									<tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">Tài thẻ</td>
                                        <td class="text-right">${match.h1_card_over_under || ''}</td>
                                        <td class="text-right">${match.ft_card_over_under || ''}</td>
                                        <td class="text-right">${match.h2_card_over_under || ''}</td>
                                    </tr>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">Thẻ (chủ nhà)</td>
                                        <td class="text-right">${match.h1_card_handicap || ''}</td>
                                        <td class="text-right">${match.ft_card_handicap || ''}</td>
                                        <td class="text-right">${match.h2_card_handicap || ''}</td>
                                    </tr>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">${match.home || ''}</td>
                                        <td class="text-right">${match.h1_euro_home || ''}</td>
                                        <td class="text-right">${match.ft_euro_home || ''}</td>
                                        <td class="text-right">${match.h2_euro_home || ''}</td>
                                    </tr>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">Hòa</td>
                                        <td class="text-right">${match.h1_euro_draw || ''}</td>
                                        <td class="text-right">${match.ft_euro_draw || ''}</td>
                                        <td class="text-right">${match.h2_euro_draw || ''}</td>
                                    </tr>
                                    <tr>
                                        <td class="text-right pr-2 py-1 whitespace-nowrap">${match.way || ''}</td>
                                        <td class="text-right">${match.h1_euro_way || ''}</td>
                                        <td class="text-right">${match.ft_euro_way || ''}</td>
                                        <td class="text-right">${match.h2_euro_way || ''}</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                `;
            });
            
            container.innerHTML = html;
            applyStatusColors(container);
        }

        function openTicketMatchModal(matchId, matchLabel) {
            tmCurrentMatch = matchId;
            const modal = document.getElementById('modalTicketMatch');
            if (!modal) return;
            const label = document.getElementById('tmMatchLabel');
            if (label) label.textContent = matchLabel || matchId;

            tmScrollPosition = window.pageYOffset || document.documentElement.scrollTop;
            document.body.style.position = 'fixed';
            document.body.style.top = `-${tmScrollPosition}px`;
            document.body.style.width = '100%';
            document.body.style.overflow = 'hidden';

            modal.classList.remove('hidden');
            modal.classList.add('flex');

            if (typeof loadTicketMatchTable === 'function') {
                loadTicketMatchTable(matchId);
            }
        }

        function openResultMatchModal(matchId) {
            fetch('matches.aspx/GetResultData', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.d) {
                    const resultData = JSON.parse(data.d);
                    
                    // Kiểm tra nếu có lỗi
                    if (resultData.error) {
                        console.error('Error from server:', resultData.error);
                        return;
                    }
                    
                    fillResultForm(resultData);
                    openResultModal();
                } else {
                    alert('Không nhận được dữ liệu từ server');
                }
            })
            .catch(error => {
                console.error('Error:', error);
            });
        }

        function editMatch(matchId) {
            fetch('matches.aspx/GetMatchData', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.d) {
                    const matchData = JSON.parse(data.d);
                    fillEditForm(matchData, true);
                    
                    const editYnField = document.querySelector('[id$="editYn"]');
                    if (editYnField) editYnField.value = 'true';
                    
                    openAddMatchModal();
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Lỗi khi tải dữ liệu trận đấu');
            });
        }

        function copyMatch(matchId) {
            fetch('matches.aspx/GetMatchData', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.d) {
                    const matchData = JSON.parse(data.d);
                    fillEditForm(matchData, false);
                    
                    const editYnField = document.querySelector('[id$="editYn"]');
                    if (editYnField) editYnField.value = 'false';
                    
                    openAddMatchModal();
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Lỗi khi tải dữ liệu trận đấu');
            });
        }
        
        function deleteMatch(matchId) {
            if (!confirm('Bạn có chắc chắn muốn xóa trận đấu này?')) {
                return;
            }
            
            fetch('matches.aspx/DeleteMatch', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ matchId: matchId })
            })
            .then(response => response.json())
            .then(data => {
                if (data.d) {
                    const result = JSON.parse(data.d);
                    alert(result.msg);
                    
                    if (result.isSuccess == 1) {
                        // Reload data thay vì reload trang
                        reloadMatchesData();
                    }
                }
            })
            .catch(error => {
                console.error('Error:', error);
                alert('Lỗi khi xóa trận đấu');
            });
        }

        document.addEventListener('DOMContentLoaded', function() {
            applyStatusColors();
        });
	</script>
</body>
</html>
