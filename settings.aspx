<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucChangePass.ascx" TagPrefix="uc" TagName="ChangePass" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Globalization" %>

<script runat="server">
    private bool canManageCutoff;

    protected override void OnInit(EventArgs e)
    {
        ViewStateUserKey = Session.SessionID;
        base.OnInit(e);
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null) 
		{
			Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
			return;
		}
        canManageCutoff = IsCutoffAdministrator();
        cutoffPanel.Visible = canManageCutoff;
        if (!IsPostBack && Session["CutoffSaved"] != null)
        {
            cutoffMessage.Text = "Đã khai báo mốc mới. Lịch sử trước đó được giữ nguyên.";
            Session.Remove("CutoffSaved");
        }
        if (!IsPostBack) { BindSettingTable(); }
        
        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }

    private bool IsCutoffAdministrator()
    {
        int userId;
        if (!Int32.TryParse(Convert.ToString(Session["UserID"]), out userId)) return false;
        using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString))
        using (SqlCommand cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.userinfo2 WHERE id = @id AND admin = 1", conn))
        {
            cmd.Parameters.Add("@id", SqlDbType.Int).Value = userId;
            conn.Open();
            return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
        }
    }

    protected override void OnPreRender(EventArgs e)
    {
        if (canManageCutoff) BindCutoffHistory();
        base.OnPreRender(e);
    }

    private void BindCutoffHistory()
    {
        try
        {
            using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString))
            {
                conn.Open();
                using (SqlCommand cmd = new SqlCommand("SELECT TOP (1) cutoff_at FROM dbo.bet_ticket_tracking_cutoff ORDER BY id DESC", conn))
                {
                    object current = cmd.ExecuteScalar();
                    if (current == null || current == DBNull.Value) throw new InvalidOperationException("Missing tracking cutoff");
                    DateTime value = Convert.ToDateTime(current);
                    currentCutoff.Text = value.ToString("dd/MM/yyyy HH:mm:ss", CultureInfo.InvariantCulture);
                    if (!IsPostBack) cutoffInput.Text = value.ToString("yyyy-MM-ddTHH:mm:ss", CultureInfo.InvariantCulture);
                }
                using (SqlCommand cmd = new SqlCommand(@"SELECT id, cutoff_at,
                    DATEADD(HOUR, 7, declared_at_utc) AS declared_at_local, declared_by_name, note,
                    CASE WHEN id = (SELECT MAX(id) FROM dbo.bet_ticket_tracking_cutoff)
                         THEN N'Đang áp dụng' ELSE N'Lịch sử' END AS state
                    FROM dbo.bet_ticket_tracking_cutoff ORDER BY id DESC", conn))
                using (SqlDataAdapter adapter = new SqlDataAdapter(cmd))
                {
                    DataTable history = new DataTable();
                    adapter.Fill(history);
                    cutoffHistory.DataSource = history;
                    cutoffHistory.DataBind();
                }
            }
        }
        catch (Exception ex)
        {
            Trace.Warn("TrackingCutoff", "Cannot load cutoff history", ex);
            cutoffMessage.Text = "Không tải được cấu hình mốc theo dõi. Kiểm tra kết nối và script cập nhật database.";
            saveCutoff.Enabled = false;
        }
    }

    protected void SaveCutoff_Click(object sender, EventArgs e)
    {
        if (!canManageCutoff || !IsCutoffAdministrator())
        {
            Response.StatusCode = 403;
            return;
        }
        DateTime cutoff;
        if (!DateTime.TryParseExact(cutoffInput.Text, new string[] { "yyyy-MM-ddTHH:mm", "yyyy-MM-ddTHH:mm:ss" },
            CultureInfo.InvariantCulture, DateTimeStyles.None, out cutoff))
        {
            cutoffMessage.Text = "Vui lòng nhập ngày giờ mốc hợp lệ.";
            return;
        }
        if (cutoffNote.Text.Trim().Length > 500)
        {
            cutoffMessage.Text = "Ghi chú tối đa 500 ký tự.";
            return;
        }
        try
        {
            using (SqlConnection conn = new SqlConnection(ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString))
            using (SqlCommand cmd = new SqlCommand("dbo.bet_ticket_tracking_cutoff_append", conn))
            {
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.Add("@cutoff_at", SqlDbType.DateTime2).Value = cutoff;
                cmd.Parameters.Add("@user_id", SqlDbType.Int).Value = Convert.ToInt32(Session["UserID"]);
                cmd.Parameters.Add("@note", SqlDbType.NVarChar, 500).Value = cutoffNote.Text.Trim();
                conn.Open();
                cmd.ExecuteNonQuery();
            }
        }
        catch (Exception ex)
        {
            Trace.Warn("TrackingCutoff", "Cannot append cutoff", ex);
            cutoffMessage.Text = "Không lưu được mốc theo dõi. Vui lòng kiểm tra kết nối và cấu hình database.";
            return;
        }
        Session["CutoffSaved"] = true;
        Response.Redirect("settings.aspx", false);
        Context.ApplicationInstance.CompleteRequest();
    }

    protected void CutoffHistory_PageIndexChanging(object sender, System.Web.UI.WebControls.GridViewPageEventArgs e)
    {
        cutoffHistory.PageIndex = e.NewPageIndex;
    }

    private void BindSettingTable() {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("bet_setting", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@username", Session["UserName"].ToString());
                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable(); 
                da.Fill(dt);
                gvSettings.DataSource = dt; 
                gvSettings.DataBind();
            }
        } catch { }
    }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Cài đặt hệ thống</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body { font-family: sans-serif; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .menu-font { font-size: 16px; font-weight: bold; }
        .menu-link { display: flex; align-items: center; padding: 12px 16px; color: #4b5563; border-radius: 10px; margin: 4px 10px; text-decoration: none; transition: 0.2s; }
        .menu-link.active { background-color: #eff6ff; color: #1d4ed8; }
        .breadcrumb-link { color: #2563eb; text-decoration: none; }
        .breadcrumb-current { color: #4b5563; cursor: default; }
        .grid-header th { position: sticky; top: 0; z-index: 10; background-color: #1d4ed8 !important; color: white !important; text-align: center !important; padding: 12px 8px; font-size: 14px; font-weight: bold; }
        .row-style td { padding: 12px 8px; font-weight: bold; font-size: 14px; border-bottom: 1px solid #eef2f6; }
        .row-white { background-color: white; }
        .row-gray { background-color: #f9fafb; }
		
        /* Xử lý không scroll ngang */
        .table-fixed-layout { table-layout: fixed; width: 100%; }
        .truncate-text { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
		
		/* Sidebar không bị lệch và icon thẳng hàng */
		.nav-item { 
			border-right: 4px solid transparent; 
			display: flex;
			align-items: center;
			padding: 0.75rem 1rem; /* px-4 py-3 */
			font-weight: bold;
			transition: all 0.2s;
		}

		.nav-item-active { 
			border-right-color: #1d4ed8; 
			background-color: #eff6ff; 
			color: #1d4ed8 !important; 
		}

		/* Cố định kích thước icon */
		.nav-item i {
			width: 20px; 
			text-align: center;
			margin-right: 12px;
		}
    </style>
</head>
<body class="h-screen flex flex-col">
    <form runat="server" class="h-full flex flex-col">
        <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
            <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="settings" PageTitle="Cài đặt" />
        </nav>

        <div class="flex flex-1 overflow-hidden relative">
            <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>

            <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="settings" />

            <main class="flex-1 p-3 lg:p-6 overflow-hidden bg-[#f8fafc]">
                <div class="h-full bg-white rounded-xl shadow-md border flex flex-col overflow-hidden">
                    <div class="flex-1 overflow-auto main-scroll">
                        <asp:Panel ID="cutoffPanel" runat="server" Visible="false" CssClass="p-4 lg:p-6 border-b space-y-3">
                            <h2 class="font-bold text-blue-800">Mốc bắt đầu theo dõi dữ liệu vé cược</h2>
                            <p>Đang áp dụng: <strong><asp:Literal ID="currentCutoff" runat="server" Mode="Encode" /></strong> (UTC+7).</p>
                            <p class="text-sm text-gray-600">Mỗi lần lưu tạo một khai báo mới. Khai báo sau cùng được áp dụng, kể cả khi chọn ngày sớm hơn. Dữ liệu vé trước mốc được ẩn khỏi báo cáo, không bị xóa.</p>
                            <div class="flex flex-wrap items-end gap-3">
                                <div>
                                    <asp:Label runat="server" AssociatedControlID="cutoffInput" Text="Mốc mới (UTC+7)" CssClass="block text-sm mb-1" />
                                    <asp:TextBox ID="cutoffInput" runat="server" TextMode="DateTimeLocal" step="1" CssClass="border rounded p-2" />
                                </div>
                                <div class="flex-1 min-w-48">
                                    <asp:Label runat="server" AssociatedControlID="cutoffNote" Text="Ghi chú" CssClass="block text-sm mb-1" />
                                    <asp:TextBox ID="cutoffNote" runat="server" MaxLength="500" CssClass="border rounded p-2 w-full" />
                                </div>
                                <asp:Button ID="saveCutoff" runat="server" Text="Khai báo mốc mới" OnClick="SaveCutoff_Click" CssClass="bg-blue-700 text-white rounded px-4 py-2 cursor-pointer" />
                            </div>
                            <p role="status" class="text-sm text-blue-800"><asp:Literal ID="cutoffMessage" runat="server" Mode="Encode" /></p>
                            <h3 class="font-bold">Lịch sử khai báo (mới nhất trước)</h3>
                            <div class="overflow-x-auto">
                                <asp:GridView ID="cutoffHistory" runat="server" AutoGenerateColumns="false" AllowPaging="true" PageSize="20" OnPageIndexChanging="CutoffHistory_PageIndexChanging" GridLines="None" CssClass="w-full" EmptyDataText="Chưa có khai báo mốc.">
                                    <HeaderStyle CssClass="grid-header" />
                                    <RowStyle CssClass="row-style row-white" />
                                    <AlternatingRowStyle CssClass="row-style row-gray" />
                                    <PagerStyle CssClass="p-3 text-blue-700" />
                                    <Columns>
                                        <asp:BoundField DataField="id" HeaderText="ID" />
                                        <asp:BoundField DataField="cutoff_at" HeaderText="Mốc theo dõi" DataFormatString="{0:dd/MM/yyyy HH:mm:ss}" />
                                        <asp:BoundField DataField="declared_at_local" HeaderText="Khai báo lúc (UTC+7)" DataFormatString="{0:dd/MM/yyyy HH:mm:ss}" />
                                        <asp:BoundField DataField="declared_by_name" HeaderText="Người khai báo" HtmlEncode="true" />
                                        <asp:BoundField DataField="note" HeaderText="Ghi chú" HtmlEncode="true" />
                                        <asp:BoundField DataField="state" HeaderText="Trạng thái" />
                                    </Columns>
                                </asp:GridView>
                            </div>
                        </asp:Panel>
                        <asp:GridView ID="gvSettings" runat="server" AutoGenerateColumns="false" CssClass="table-fixed-layout" GridLines="None">
                            <HeaderStyle CssClass="grid-header" />
                            <RowStyle CssClass="row-style row-white" />
                            <AlternatingRowStyle CssClass="row-style row-gray" />
                            <Columns>
                                <asp:TemplateField HeaderText="STT">
                                    <ItemStyle CssClass="text-center w-12 lg:w-16 text-gray-400 font-normal" />
                                    <ItemTemplate><%# Container.DataItemIndex + 1 %></ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Tên đăng nhập">
                                    <ItemStyle CssClass="text-left px-2 lg:px-8 truncate-text text-blue-700" />
                                    <ItemTemplate><%# Eval("name") %></ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Tên hiển thị">
                                    <ItemStyle CssClass="text-left px-2 lg:px-8 text-gray-500 truncate-text" />
                                    <ItemTemplate><%# Eval("comment") %></ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Sửa">
                                    <ItemStyle CssClass="text-center w-16 lg:w-32" />
                                    <ItemTemplate>
                                        <button type="button" onclick='openChangePassModal("<%# Eval("name") %>")' 
                                                class="text-orange-500 hover:text-orange-600 transition p-2">
                                            <i class="fa-solid fa-key text-xl"></i>
                                        </button>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </main>
        </div>

        <uc:ChangePass runat="server" ID="ucChangePass" />
    </form>

    <script>
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
    </script>
</body>
</html>
