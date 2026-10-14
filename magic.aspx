<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Globalization" %>

<script runat="server">
    private bool? _isAdmin;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null)
        {
            Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
            return;
        }

        if (!IsPostBack || IsGridCommandPostBack(gvPayments.UniqueID))
        {
            BindUsers();
            BindPayments();
        }

        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }

    private bool IsAdminUser()
    {
        if (_isAdmin.HasValue) return _isAdmin.Value;
        int userId = GetCurrentUserId();
        if (userId <= 0) return false;

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.userinfo2 WHERE id = @userID AND admin = 1", conn))
            {
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = userId;
                conn.Open();
                _isAdmin = Convert.ToInt32(cmd.ExecuteScalar()) > 0;
                return _isAdmin.Value;
            }
        }
        catch
        {
            _isAdmin = false;
            return false;
        }
    }

    private int GetCurrentUserId()
    {
        int userId;
        if (Session["UserID"] != null && Int32.TryParse(Convert.ToString(Session["UserID"]), out userId)) return userId;
        return 0;
    }

    private bool IsGridCommandPostBack(string gridUniqueID)
    {
        string eventTarget = Request.Form["__EVENTTARGET"] ?? "";
        return eventTarget.StartsWith(gridUniqueID + "$", StringComparison.Ordinal);
    }

    private void BindUsers()
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(@"
                SELECT id, ISNULL(NULLIF(LTRIM(RTRIM(comment)), ''), name) AS display_name
                FROM dbo.userinfo2
                WHERE user_yn = 1
                ORDER BY ISNULL(NULLIF(LTRIM(RTRIM(comment)), ''), name), id", conn))
            {
                conn.Open();
                DataTable users = new DataTable();
                users.Load(cmd.ExecuteReader());
                ddlHost.DataSource = users;
                ddlHost.DataTextField = "display_name";
                ddlHost.DataValueField = "id";
                ddlHost.DataBind();
                ddlWizard.DataSource = users.Copy();
                ddlWizard.DataTextField = "display_name";
                ddlWizard.DataValueField = "id";
                ddlWizard.DataBind();
            }
        }
        catch
        {
            ddlHost.Items.Clear();
            ddlWizard.Items.Clear();
        }
    }

    private void BindPayments()
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(@"
                SELECT id, host_id, user_id, host_name, user_name, money, datetime, clear
                FROM vbet_payment
                ORDER BY datetime DESC, id DESC", conn))
            {
                conn.Open();
                DataTable payments = new DataTable();
                payments.Load(cmd.ExecuteReader());
                gvPayments.DataSource = payments;
                gvPayments.DataBind();
            }
        }
        catch
        {
            gvPayments.DataSource = null;
            gvPayments.DataBind();
            ShowMessage("Không thể tải danh sách phép thuật.", false);
        }
    }

    protected void btnSavePayment_Click(object sender, EventArgs e)
    {
        int wizardId;
        int hostId;
        decimal money;

        if (!Int32.TryParse(ddlWizard.SelectedValue, out wizardId) || wizardId <= 0)
        {
            ShowMessage("Vui lòng chọn pháp sư.", false);
            ReopenCurrentModal();
            return;
        }

        if (!Int32.TryParse(ddlHost.SelectedValue, out hostId) || hostId <= 0)
        {
            ShowMessage("Vui lòng chọn cái.", false);
            ReopenCurrentModal();
            return;
        }

        if (!IsAdminUser())
        {
            hostId = GetCurrentUserId();
        }

        if (!TryParseMoney(txtMoney.Text, out money) || money == 0)
        {
            ShowMessage("Tiền phải là số nguyên khác 0.", false);
            ReopenCurrentModal();
            return;
        }

        int id;
        if (hfPaymentMode.Value == "edit" && Int32.TryParse(hfPaymentId.Value, out id) && id > 0)
        {
            if (!CanModifyPayment(id))
            {
                ShowMessage("Không được phân quyền sửa dòng này.", false);
                return;
            }

            UpdatePayment(id, wizardId, hostId, money);
        }
        else
        {
            InsertPayment(wizardId, hostId, money);
        }
    }

    private void InsertPayment(int wizardId, int hostId, decimal money)
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("INSERT INTO bet_payment (user_id, money, datetime, clear, user_host) VALUES (@wizardId, @money, GETDATE(), NULL, @hostId)", conn))
            {
                cmd.Parameters.Add("@wizardId", SqlDbType.Int).Value = wizardId;
                cmd.Parameters.Add("@money", SqlDbType.Decimal).Value = money;
                cmd.Parameters["@money"].Precision = 19;
                cmd.Parameters["@money"].Scale = 4;
                cmd.Parameters.Add("@hostId", SqlDbType.Int).Value = hostId;
                conn.Open();
                cmd.ExecuteNonQuery();
            }

            BindPayments();
            ShowMessage("Đã làm phép.", true);
        }
        catch
        {
            ShowMessage("Không thể lưu phép thuật.", false);
            ReopenCurrentModal();
        }
    }

    private void UpdatePayment(int id, int wizardId, int hostId, decimal money)
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("UPDATE bet_payment SET user_id = @wizardId, money = @money, user_host = @hostId WHERE id = @id", conn))
            {
                cmd.Parameters.Add("@wizardId", SqlDbType.Int).Value = wizardId;
                cmd.Parameters.Add("@money", SqlDbType.Decimal).Value = money;
                cmd.Parameters["@money"].Precision = 19;
                cmd.Parameters["@money"].Scale = 4;
                cmd.Parameters.Add("@hostId", SqlDbType.Int).Value = hostId;
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = id;
                conn.Open();
                cmd.ExecuteNonQuery();
            }

            BindPayments();
            ShowMessage("Đã cập nhật phép thuật.", true);
        }
        catch
        {
            ShowMessage("Không thể cập nhật phép thuật.", false);
            ReopenCurrentModal();
        }
    }

    protected void gvPayments_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName != "DeletePayment") return;

        int id;
        if (!Int32.TryParse(Convert.ToString(e.CommandArgument), out id) || id <= 0)
        {
            ShowMessage("Không tìm thấy dòng cần xóa.", false);
            return;
        }

        if (!CanModifyPayment(id))
        {
            ShowMessage("Không được phân quyền xóa dòng này.", false);
            return;
        }

        DeletePayment(id);
    }

    protected void gvPayments_RowDataBound(object sender, GridViewRowEventArgs e)
	{
		if (e.Row.RowType != DataControlRowType.DataRow) return;

		DataRowView row = e.Row.DataItem as DataRowView;
		if (row == null) return;

		// 1. Lấy giá trị money từ row, ép kiểu về double và nhân với 1000
		double moneyValue = 0;
		if (row["money"] != DBNull.Value)
		{
			moneyValue = Convert.ToDouble(row["money"]) * 1000;
		}

		bool canModify = CanModifyPaymentRow(row["host_id"]);
		
		// 2. Truyền biến moneyValue đã nhân vào hàm FormatMoney
		string script = "openPaymentModal('view','" + Js(row["id"]) + "','" + Js(row["host_id"]) + "','" + Js(row["user_id"]) + "','" + Js(FormatMoney(moneyValue)) + "','" + Js(FormatDate(row["datetime"])) + "'," + (canModify ? "true" : "false") + ")";
		
		e.Row.Attributes["onclick"] = script;
		e.Row.Attributes["class"] = (e.Row.Attributes["class"] + " cursor-pointer hover:bg-indigo-50").Trim();

		if (IsClearedPayment(row["clear"]))
		{
			e.Row.Style["background-color"] = "#FFFFE0";
		}
}

    protected void btnDeletePaymentModal_Click(object sender, EventArgs e)
    {
        int id;
        if (!Int32.TryParse(hfPaymentId.Value, out id) || id <= 0)
        {
            ShowMessage("Không tìm thấy dòng cần xóa.", false);
            return;
        }

        if (!CanModifyPayment(id))
        {
            ShowMessage("Không được phân quyền xóa dòng này.", false);
            return;
        }

        DeletePayment(id);
    }

    private void DeletePayment(int id)
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("DELETE FROM bet_payment WHERE id = @id", conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = id;
                conn.Open();
                cmd.ExecuteNonQuery();
            }

            BindPayments();
            ShowMessage("Đã xóa phép thuật.", true);
        }
        catch
        {
            ShowMessage("Không thể xóa phép thuật.", false);
        }
    }

    private bool TryParseMoney(string text, out decimal money)
    {
        string normalized = (text ?? "").Replace(" ", "").Replace(",", "").Trim();
        return Decimal.TryParse(normalized, NumberStyles.AllowLeadingSign, CultureInfo.InvariantCulture, out money)
            && Decimal.Truncate(money) == money;
    }

    private void ReopenCurrentModal()
    {
        string script = "setTimeout(function(){ openPaymentModal('" + Js(hfPaymentMode.Value) + "','" + Js(hfPaymentId.Value) + "','" + Js(ddlHost.SelectedValue) + "','" + Js(ddlWizard.SelectedValue) + "','" + Js(txtMoney.Text) + "','" + Js(txtDate.Text) + "'); }, 0);";
        ClientScript.RegisterStartupScript(this.GetType(), "ReopenPaymentModal", script, true);
    }

    private void ShowMessage(string text, bool isSuccess)
    {
        string script = "setTimeout(function(){ showToast('" + Js(text) + "', " + (isSuccess ? "true" : "false") + "); }, 0);";
        ClientScript.RegisterStartupScript(this.GetType(), "ToastMessage", script, true);
    }

    protected string FormatMoney(object value)
    {
        if (value == null || value == DBNull.Value) return "";
        decimal money;
        if (!Decimal.TryParse(Convert.ToString(value), out money)) return "";
        return Decimal.Truncate(money).ToString("#,##0", CultureInfo.InvariantCulture).Replace(",", " ");
    }

    protected string FormatDate(object value)
    {
        if (value == null || value == DBNull.Value) return "";
        return Convert.ToDateTime(value).ToString("dd/MM/yyyy HH:mm:ss");
    }

    protected bool IsPositiveMoney(object value)
    {
        if (value == null || value == DBNull.Value) return true;
        decimal money;
        if (!Decimal.TryParse(Convert.ToString(value), out money)) return true;
        return money >= 0;
    }

    protected bool CanModifyPaymentRow(object hostId)
    {
        if (IsAdminUser()) return true;

        int rowHostId;
        if (!Int32.TryParse(Convert.ToString(hostId), out rowHostId)) return false;
        return rowHostId > 0 && rowHostId == GetCurrentUserId();
    }

    protected bool IsClearedPayment(object value)
    {
        string text = Convert.ToString(value ?? "").Trim();
        return text == "1" || text.Equals("true", StringComparison.OrdinalIgnoreCase);
    }

    private bool CanModifyPayment(int id)
    {
        if (IsAdminUser()) return true;

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("SELECT COUNT(1) FROM bet_payment WHERE id = @id AND user_host = @hostId", conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = id;
                cmd.Parameters.Add("@hostId", SqlDbType.Int).Value = GetCurrentUserId();
                conn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }
        catch
        {
            return false;
        }
    }

    protected string Js(object value)
    {
        return System.Web.HttpUtility.JavaScriptStringEncode(Convert.ToString(value ?? ""));
    }

    protected string Attr(object value)
    {
        return System.Web.HttpUtility.HtmlAttributeEncode(Convert.ToString(value ?? ""));
    }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" />
    <title>Phép thuật</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" />
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .nav-item { border-right: 4px solid transparent; display: flex; align-items: center; padding: 0.75rem 1rem; font-weight: bold; transition: all 0.2s; }
        .nav-item-active { border-right-color: #1d4ed8; background-color: #eff6ff; color: #1d4ed8 !important; }
        .nav-item i { width: 20px; text-align: center; margin-right: 12px; }
        .payment-grid { table-layout: fixed; width: 100%; font-size: 16px; }
        .payment-grid th { position: sticky; top: 0; z-index: 1; background: #f8fafc; }
        .payment-grid th, .payment-grid td { border-bottom: 1px solid #e5e7eb; padding: 0.75rem; vertical-align: top; overflow-wrap: anywhere; }
        .payment-grid th:nth-child(1), .payment-grid td:nth-child(1) { width: 5.5rem; }
        .payment-grid th:nth-child(2), .payment-grid td:nth-child(2) { width: 30%; }
        .payment-grid th:nth-child(3), .payment-grid td:nth-child(3) { width: 34%; }
        .payment-grid th:nth-child(4), .payment-grid td:nth-child(4) { width: calc(36% - 5.5rem); text-align: right; }
        #paymentModal input,
        #paymentModal select,
        #paymentModal button {
            font-size: 16px !important;
        }
        #paymentModal label {
            font-size: 16px;
        }
    </style>
</head>
<body class="h-[100dvh] flex flex-col">
<form runat="server" class="h-full flex flex-col">
    <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
        <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="magic" PageTitle="Phép thuật" />
    </nav>

    <div class="flex flex-1 overflow-hidden relative">
        <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>
        <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="magic" />

        <main class="flex-1 p-4 lg:p-6 overflow-auto main-scroll bg-[#f8fafc]">
            <section class="max-w-6xl mx-auto bg-white rounded-lg shadow-md border overflow-hidden">
                <div class="px-5 py-4 border-b flex flex-wrap items-center justify-between gap-3">
                    <h1 class="text-lg font-bold text-gray-800">Lịch sử phép thuật</h1>
                    <button type="button" onclick="openPaymentModal('add','','<%= GetCurrentUserId() %>','<%= GetCurrentUserId() %>','','')"
                        class="px-4 py-2 rounded-lg bg-indigo-600 text-white font-bold hover:bg-indigo-700 transition">
                        <i class="fa-solid fa-wand-magic-sparkles mr-2"></i>Làm phép
                    </button>
                </div>
				<div class="max-h-[calc(100dvh-13rem)] overflow-auto main-scroll">
					<asp:GridView ID="gvPayments" runat="server" AutoGenerateColumns="false" GridLines="None"
						CssClass="payment-grid text-sm w-full" OnRowCommand="gvPayments_RowCommand" OnRowDataBound="gvPayments_RowDataBound">
						<Columns>
							<asp:TemplateField HeaderText="" ItemStyle-CssClass="align-top" ItemStyle-Width="90px" HeaderStyle-Width="90px">
								<ItemTemplate>
									<div class="flex items-center gap-1" onclick="event.stopPropagation()">
										<asp:PlaceHolder runat="server" Visible='<%# CanModifyPaymentRow(Eval("host_id")) %>'>
											<button type="button" title="Sửa"
												onclick='event.stopPropagation(); openPaymentModal("edit","<%# Js(Eval("id")) %>","<%# Js(Eval("host_id")) %>","<%# Js(Eval("user_id")) %>","<%# Js(FormatMoney(Convert.ToDouble(Eval("money")) * 1000)) %>","<%# Js(FormatDate(Eval("datetime"))) %>")'
												class="h-9 w-9 shrink-0 rounded border border-blue-100 text-blue-600 hover:bg-blue-50 hover:text-blue-800">
												<i class="fa-solid fa-pen-to-square"></i>
											</button>
										</asp:PlaceHolder>
										<asp:LinkButton ID="btnDeletePayment" runat="server" CommandName="DeletePayment"
											CommandArgument='<%# Eval("id") %>' OnClientClick="event.stopPropagation(); return confirm('Xóa phép thuật này?');"
											ToolTip="Xóa"
											Visible='<%# CanModifyPaymentRow(Eval("host_id")) %>'
											CssClass="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded border border-red-100 text-red-600 hover:bg-red-50 hover:text-red-800">
											<i class="fa-solid fa-trash"></i>
										</asp:LinkButton>
									</div>
								</ItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField HeaderText="Cái" ItemStyle-Width="30%" HeaderStyle-Width="30%">
								<ItemTemplate>
									<span class="font-bold text-gray-800 whitespace-nowrap"><%# Eval("host_name") %></span>
								</ItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField HeaderText="Pháp sư" ItemStyle-Width="30%" HeaderStyle-Width="30%">
								<ItemTemplate>
									<span class="font-bold text-indigo-700 whitespace-nowrap"><%# Eval("user_name") %></span>
								</ItemTemplate>
							</asp:TemplateField>
							<asp:TemplateField HeaderText="Tiền" ItemStyle-Width="30%" HeaderStyle-Width="30%" ItemStyle-CssClass="text-right" HeaderStyle-CssClass="text-right">
								<ItemTemplate>
									<span class='<%# IsPositiveMoney(Eval("money")) ? "font-bold text-green-700" : "font-bold text-red-700" %>'>
										<%# FormatMoney(Eval("money")) %>
									</span>
								</ItemTemplate>
							</asp:TemplateField>
						</Columns>
						<asp:EmptyDataTemplate>
							<div class="px-5 py-10 text-center text-gray-500">Chưa có phép thuật.</div>
						</asp:EmptyDataTemplate>
					</asp:GridView>
				</div>
            </section>
        </main>
    </div>

    <div id="paymentModal" class="fixed inset-0 z-[70] hidden items-center justify-center bg-gray-900/70 p-4">
        <div class="w-full max-w-lg rounded-lg border bg-white shadow-xl">
            <div class="flex items-center justify-between border-b px-5 py-4">
                <h2 id="paymentModalTitle" class="text-lg font-bold text-gray-800">Làm phép</h2>
                <button type="button" onclick="closePaymentModal()" title="Đóng" class="p-2 text-gray-500 hover:text-gray-800">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <div class="grid gap-4 p-5">
                <asp:HiddenField ID="hfPaymentMode" runat="server" />
                <asp:HiddenField ID="hfPaymentId" runat="server" />
                <div>
                    <label class="mb-2 block text-sm font-bold text-gray-700">Ngày</label>
                    <asp:TextBox ID="txtDate" runat="server" Enabled="false"
                        CssClass="w-full rounded-lg border bg-gray-100 p-2.5 text-sm font-bold text-gray-600 outline-none">
                    </asp:TextBox>
                </div>
                <div>
                    <label class="mb-2 block text-sm font-bold text-gray-700">Cái</label>
                    <asp:DropDownList ID="ddlHost" runat="server"
                        CssClass="w-full rounded-lg border p-2.5 text-sm font-bold outline-none focus:ring-2 focus:ring-indigo-500">
                    </asp:DropDownList>
                </div>
                <div>
                    <label class="mb-2 block text-sm font-bold text-gray-700">Pháp sư</label>
                    <asp:DropDownList ID="ddlWizard" runat="server"
                        CssClass="w-full rounded-lg border p-2.5 text-sm font-bold outline-none focus:ring-2 focus:ring-indigo-500">
                    </asp:DropDownList>
                </div>
                <div>
                    <label class="mb-2 block text-sm font-bold text-gray-700">Tiền</label>
                    <asp:TextBox ID="txtMoney" runat="server" inputmode="numeric"
                        CssClass="w-full rounded-lg border p-2.5 text-right text-sm font-bold outline-none focus:ring-2 focus:ring-indigo-500"
                        oninput="formatPaymentMoneyInput(this)">
                    </asp:TextBox>
                </div>
            </div>
            <div class="flex justify-end gap-2 border-t px-5 py-4">
                <div id="paymentViewActions" class="hidden justify-end gap-2">
                    <button type="button" id="btnPaymentEditView" onclick="switchPaymentViewToEdit()"
                        class="rounded-lg bg-blue-600 px-5 py-2 font-bold text-white hover:bg-blue-700 transition">
                        <i class="fa-solid fa-pen-to-square mr-2"></i>Sửa
                    </button>
                    <asp:Button ID="btnDeletePaymentModal" runat="server" Text="Xóa" OnClick="btnDeletePaymentModal_Click"
                        OnClientClick="return confirm('Xóa phép thuật này?');"
                        CssClass="rounded-lg bg-red-600 px-5 py-2 font-bold text-white hover:bg-red-700 transition" />
                    <button type="button" onclick="closePaymentModal()" class="rounded-lg border px-4 py-2 font-bold text-gray-700 hover:bg-gray-50">Đóng</button>
                </div>
                <div id="paymentEditActions" class="flex justify-end gap-2">
                <button type="button" onclick="closePaymentModal()" class="rounded-lg border px-4 py-2 font-bold text-gray-700 hover:bg-gray-50">Hủy</button>
                <asp:Button ID="btnSavePayment" runat="server" Text="Lưu" OnClick="btnSavePayment_Click" OnClientClick="return validatePaymentModal();"
                    CssClass="rounded-lg bg-indigo-600 px-5 py-2 font-bold text-white hover:bg-indigo-700 transition" />
                </div>
            </div>
        </div>
    </div>

    <div id="toastContainer" class="pointer-events-none fixed right-3 top-20 z-[90] flex w-[calc(100%-1.5rem)] max-w-sm flex-col gap-2 sm:right-5"></div>
</form>

<script>
    const currentPaymentUserIsAdmin = <%= IsAdminUser() ? "true" : "false" %>;
    let currentPaymentCanModify = false;

    function toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('overlay');
        sidebar.classList.toggle('-translate-x-full');
        overlay.classList.toggle('hidden');
    }

    function openPaymentModal(mode, id, hostId, wizardId, money, dateText, canModify) {
        const normalizedMode = mode || 'add';
        currentPaymentCanModify = canModify === true || canModify === 'true' || normalizedMode === 'add' || normalizedMode === 'edit';
        document.getElementById('<%= hfPaymentMode.ClientID %>').value = normalizedMode;
        document.getElementById('<%= hfPaymentId.ClientID %>').value = id || '';
        document.getElementById('<%= txtDate.ClientID %>').value = normalizedMode === 'add' ? '' : (dateText || '');
        document.getElementById('<%= txtMoney.ClientID %>').value = money || '';
        const hostSelect = document.getElementById('<%= ddlHost.ClientID %>');
        selectOptionValue('<%= ddlHost.ClientID %>', currentPaymentUserIsAdmin ? (hostId || '<%= GetCurrentUserId() %>') : '<%= GetCurrentUserId() %>');
        selectOptionValue('<%= ddlWizard.ClientID %>', wizardId || '');
        applyPaymentModalMode(normalizedMode);
        const modal = document.getElementById('paymentModal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        if (normalizedMode !== 'view') {
            setTimeout(() => document.getElementById('<%= ddlWizard.ClientID %>').focus(), 0);
        }
    }

    function applyPaymentModalMode(mode) {
        const isView = mode === 'view';
        const isEdit = mode === 'edit';
        const hostSelect = document.getElementById('<%= ddlHost.ClientID %>');
        const wizardSelect = document.getElementById('<%= ddlWizard.ClientID %>');
        const moneyInput = document.getElementById('<%= txtMoney.ClientID %>');
        const dateInput = document.getElementById('<%= txtDate.ClientID %>');
        const viewActions = document.getElementById('paymentViewActions');
        const editActions = document.getElementById('paymentEditActions');
        const editViewButton = document.getElementById('btnPaymentEditView');
        const deleteButton = document.getElementById('<%= btnDeletePaymentModal.ClientID %>');

        document.getElementById('paymentModalTitle').textContent = isView ? 'Xem phép thuật' : (isEdit ? 'Sửa phép thuật' : 'Làm phép');
        if (dateInput) {
            dateInput.disabled = true;
            dateInput.classList.add('bg-gray-100');
        }
        if (hostSelect) {
            hostSelect.disabled = isView || !currentPaymentUserIsAdmin;
            hostSelect.classList.toggle('bg-gray-100', hostSelect.disabled);
        }
        if (wizardSelect) {
            wizardSelect.disabled = isView;
            wizardSelect.classList.toggle('bg-gray-100', isView);
        }
        if (moneyInput) {
            moneyInput.disabled = isView;
            moneyInput.classList.toggle('bg-gray-100', isView);
        }

        if (viewActions) {
            viewActions.classList.toggle('hidden', !isView);
            viewActions.classList.toggle('flex', isView);
        }
        if (editActions) {
            editActions.classList.toggle('hidden', isView);
            editActions.classList.toggle('flex', !isView);
        }
        if (editViewButton) editViewButton.classList.toggle('hidden', !currentPaymentCanModify);
        if (deleteButton) deleteButton.classList.toggle('hidden', !currentPaymentCanModify);
    }

    function switchPaymentViewToEdit() {
        if (!currentPaymentCanModify) return;
        document.getElementById('<%= hfPaymentMode.ClientID %>').value = 'edit';
        applyPaymentModalMode('edit');
        setTimeout(() => document.getElementById('<%= ddlWizard.ClientID %>').focus(), 0);
    }

    function closePaymentModal() {
        const modal = document.getElementById('paymentModal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }

    function selectOptionValue(id, value) {
        const select = document.getElementById(id);
        if (!select) return;
        select.value = value || '';
        if (select.value !== value && select.options.length > 0) select.selectedIndex = 0;
    }

    function formatPaymentMoneyInput(input) {
        let value = input.value.replace(/\s/g, '').replace(/[^\d-]/g, '');
        const negative = value.indexOf('-') === 0;
        value = value.replace(/-/g, '');
        if (value) {
            input.value = (negative ? '-' : '') + value.replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
        } else {
            input.value = negative ? '-' : '';
        }
    }

    function parsePaymentMoney(value) {
        const normalized = String(value || '').replace(/\s/g, '').trim();
        if (!/^-?\d+$/.test(normalized)) return NaN;
        return parseInt(normalized, 10);
    }

    function validatePaymentModal() {
        const host = document.getElementById('<%= ddlHost.ClientID %>');
        const wizard = document.getElementById('<%= ddlWizard.ClientID %>');
        const money = parsePaymentMoney(document.getElementById('<%= txtMoney.ClientID %>').value);
        if (!host.value) {
            showToast('Vui lòng chọn cái.', false);
            return false;
        }
        if (!wizard.value) {
            showToast('Vui lòng chọn pháp sư.', false);
            return false;
        }
        if (!Number.isFinite(money) || money === 0) {
            showToast('Tiền phải là số nguyên khác 0.', false);
            return false;
        }
        if (host) host.disabled = false;
        return true;
    }

    function showToast(message, isSuccess) {
        const container = document.getElementById('toastContainer');
        if (!container) return;
        const toast = document.createElement('div');
        toast.className = [
            'pointer-events-auto flex items-start gap-3 rounded-lg border px-4 py-3 text-sm font-bold shadow-lg transition-all duration-200',
            isSuccess ? 'border-green-200 bg-green-50 text-green-700' : 'border-red-200 bg-red-50 text-red-700'
        ].join(' ');
        toast.innerHTML = `
            <i class="fa-solid ${isSuccess ? 'fa-circle-check' : 'fa-circle-exclamation'} mt-0.5"></i>
            <span class="min-w-0 flex-1">${escapeHtml(message || '')}</span>
            <button type="button" class="ml-2 text-current opacity-70 hover:opacity-100" onclick="this.closest('div').remove()" title="Đóng">
                <i class="fa-solid fa-xmark"></i>
            </button>`;
        container.appendChild(toast);
        setTimeout(() => {
            toast.classList.add('opacity-0', 'translate-y-[-4px]');
            setTimeout(() => toast.remove(), 250);
        }, 2800);
    }

    function escapeHtml(value) {
        return String(value)
            .replace(/&/g, '&amp;')
            .replace(/</g, '&lt;')
            .replace(/>/g, '&gt;')
            .replace(/"/g, '&quot;')
            .replace(/'/g, '&#039;');
    }
</script>
</body>
</html>
