<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null)
        {
            Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
            return;
        }

        if (!IsAdminUser())
        {
            Response.Redirect("home.aspx");
            return;
        }

        hfTeamFilter.Value = Request.Form[hfTeamFilter.UniqueID] ?? Request.Form["teamQuickSearch"] ?? "";

        if (!IsPostBack || IsGridCommandPostBack(gvTeams.UniqueID)) BindTeamTable();

        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }

    private bool IsAdminUser()
    {
        if (Session["UserID"] == null) return false;

        int userId;
        if (!Int32.TryParse(Session["UserID"].ToString(), out userId)) return false;

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.userinfo2 WHERE id = @userID AND admin = 1", conn))
            {
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = userId;
                conn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }
        catch
        {
            return false;
        }
    }

    private bool IsGridCommandPostBack(string gridUniqueID)
    {
        string eventTarget = Request.Form["__EVENTTARGET"] ?? "";
        return eventTarget.StartsWith(gridUniqueID + "$", StringComparison.Ordinal);
    }

    private void BindTeamTable()
    {
        try
        {
            string sql = @"
                WITH used_team AS (
                    SELECT home AS team FROM bet_match WHERE home IS NOT NULL
                    UNION
                    SELECT way AS team FROM bet_match WHERE way IS NOT NULL
                    UNION
                    SELECT home AS team FROM bet_esport_match WHERE home IS NOT NULL
                    UNION
                    SELECT way AS team FROM bet_esport_match WHERE way IS NOT NULL
                )
                SELECT RTRIM(LTRIM(t.team)) AS team,
                       t.team_name,
                       CAST(CASE WHEN u.team IS NULL THEN 0 ELSE 1 END AS BIT) AS is_used
                FROM bet_team t
                LEFT JOIN used_team u ON u.team = t.team
                ORDER BY t.team_name, t.team";

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                conn.Open();
                DataTable dt = new DataTable();
                dt.Load(cmd.ExecuteReader());
                gvTeams.DataSource = dt;
                gvTeams.DataBind();
            }
        }
        catch
        {
            gvTeams.DataSource = null;
            gvTeams.DataBind();
        }
    }

    protected void btnSaveTeam_Click(object sender, EventArgs e)
    {
        string mode = hfTeamMode.Value;
        string originalCode = NormalizeCode(hfOriginalTeam.Value);
        string code = NormalizeCode(txtTeamCode.Text);
        string name = txtTeamName.Text.Trim();

        if (!ValidateInput(code, name)) return;

        if (mode == "edit")
        {
            UpdateTeam(originalCode, code, name);
        }
        else
        {
            InsertTeam(code, name);
        }
    }

    private void InsertTeam(string code, string name)
    {
        if (TeamExists(code))
        {
            ShowMessage("Mã đội đã tồn tại.", false);
            ReopenTeamModal("add", "", code, name, false);
            return;
        }

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("INSERT INTO bet_team (team, team_name) VALUES (@team, @name)", conn))
            {
                cmd.Parameters.Add("@team", SqlDbType.Char, 16).Value = code;
                cmd.Parameters.Add("@name", SqlDbType.NVarChar, 128).Value = name;
                conn.Open();
                cmd.ExecuteNonQuery();
            }

            BindTeamTable();
            ShowMessage("Đã thêm đội.", true);
        }
        catch
        {
            ShowMessage("Không thể thêm đội.", false);
            ReopenTeamModal("add", "", code, name, false);
        }
    }

    private void UpdateTeam(string originalCode, string code, string name)
    {
        if (String.IsNullOrWhiteSpace(originalCode) || !TeamExists(originalCode))
        {
            ShowMessage("Không tìm thấy đội cần sửa.", false);
            return;
        }

        bool used = TeamHasMatchData(originalCode);
        if (used && originalCode != code)
        {
            ShowMessage("Đội đã phát sinh trận đấu. Chỉ được sửa tên đội.", false);
            ReopenTeamModal("edit", originalCode, originalCode, name, true);
            return;
        }

        if (originalCode != code && TeamExists(code))
        {
            ShowMessage("Mã đội mới đã tồn tại.", false);
            ReopenTeamModal("edit", originalCode, code, name, false);
            return;
        }

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("UPDATE bet_team SET team = @team, team_name = @name WHERE team = @originalTeam", conn))
            {
                cmd.Parameters.Add("@team", SqlDbType.Char, 16).Value = used ? originalCode : code;
                cmd.Parameters.Add("@name", SqlDbType.NVarChar, 128).Value = name;
                cmd.Parameters.Add("@originalTeam", SqlDbType.Char, 16).Value = originalCode;
                conn.Open();
                cmd.ExecuteNonQuery();
            }

            BindTeamTable();
            ShowMessage("Đã cập nhật đội.", true);
        }
        catch
        {
            ShowMessage("Không thể cập nhật đội.", false);
            ReopenTeamModal("edit", originalCode, code, name, used);
        }
    }

    protected void gvTeams_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        if (e.CommandName != "DeleteTeam") return;

        string code = NormalizeCode(e.CommandArgument.ToString());
        if (TeamHasMatchData(code))
        {
            ShowMessage("Đội đã phát sinh trận đấu nên không thể xóa.", false);
            return;
        }

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("DELETE FROM bet_team WHERE team = @team", conn))
            {
                cmd.Parameters.Add("@team", SqlDbType.Char, 16).Value = code;
                conn.Open();
                cmd.ExecuteNonQuery();
            }

            BindTeamTable();
            ShowMessage("Đã xóa đội.", true);
        }
        catch
        {
            ShowMessage("Không thể xóa đội.", false);
        }
    }

    private bool ValidateInput(string code, string name)
    {
        if (String.IsNullOrWhiteSpace(code) || String.IsNullOrWhiteSpace(name))
        {
            ShowMessage("Vui lòng nhập đủ mã và tên đội.", false);
            ReopenCurrentModal(code, name);
            return false;
        }

        if (code.Length > 16)
        {
            ShowMessage("Mã đội không được vượt quá 16 ký tự.", false);
            ReopenCurrentModal(code, name);
            return false;
        }

        if (name.Length > 128)
        {
            ShowMessage("Tên đội không được vượt quá 128 ký tự.", false);
            ReopenCurrentModal(code, name);
            return false;
        }

        return true;
    }

    private bool TeamExists(string code)
    {
        return ExecuteCount("SELECT COUNT(1) FROM bet_team WHERE team = @team", "@team", code) > 0;
    }

    private bool TeamHasMatchData(string code)
    {
        string sql = @"
            SELECT CASE WHEN EXISTS (SELECT 1 FROM bet_match WHERE home = @team OR way = @team)
                         OR EXISTS (SELECT 1 FROM bet_esport_match WHERE home = @team OR way = @team)
                        THEN 1 ELSE 0 END";
        return ExecuteCount(sql, "@team", code) != 0;
    }

    private int ExecuteCount(string sql, string parameterName, string value)
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(sql, conn))
            {
                cmd.Parameters.Add(parameterName, SqlDbType.Char, 16).Value = value;
                conn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar());
            }
        }
        catch
        {
            return -1;
        }
    }

    private string NormalizeCode(string code)
    {
        return (code ?? "").Trim().ToUpperInvariant();
    }

    private void ShowMessage(string text, bool isSuccess)
    {
        string script = "showToast('" + Js(text) + "', " + (isSuccess ? "true" : "false") + ");";
        ClientScript.RegisterStartupScript(this.GetType(), "ToastMessage", script, true);
    }

    protected string InitialFilterValue()
    {
        return Attr(hfTeamFilter.Value);
    }

    private void ReopenCurrentModal(string code, string name)
    {
        bool isEdit = hfTeamMode.Value == "edit";
        string originalCode = NormalizeCode(hfOriginalTeam.Value);
        ReopenTeamModal(isEdit ? "edit" : "add", originalCode, code, name, isEdit && TeamHasMatchData(originalCode));
    }

    private void ReopenTeamModal(string mode, string originalCode, string code, string name, bool lockCode)
    {
        string script = "openTeamModal('" + Js(mode) + "','" + Js(originalCode) + "','" + Js(code) + "','" + Js(name) + "'," + (lockCode ? "true" : "false") + ");";
        ClientScript.RegisterStartupScript(this.GetType(), "ReopenTeamModal", script, true);
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
    <title>Danh mục đội</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" />
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .breadcrumb-link { color: #2563eb; text-decoration: none; }
        .breadcrumb-current { color: #4b5563; cursor: default; }
        .nav-item { border-right: 4px solid transparent; display: flex; align-items: center; padding: 0.75rem 1rem; font-weight: bold; transition: all 0.2s; }
        .nav-item-active { border-right-color: #1d4ed8; background-color: #eff6ff; color: #1d4ed8 !important; }
        .nav-item i { width: 20px; text-align: center; margin-right: 12px; }
        .master-grid { table-layout: fixed; width: 100%; }
        .master-grid td { vertical-align: top; }
        .master-value { min-width: 0; overflow-wrap: anywhere; }
    </style>
</head>
<body class="h-[100dvh] flex flex-col">
<form runat="server" class="h-full flex flex-col">
    <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
        <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="teams" PageTitle="Đội" />
    </nav>

    <div class="flex flex-1 overflow-hidden relative">
        <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>
        <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="teams" />

        <main class="flex-1 p-4 lg:p-6 overflow-auto main-scroll bg-[#f8fafc]">
            <section class="max-w-6xl mx-auto bg-white rounded-lg shadow-md border overflow-hidden">
                <div class="px-5 py-4 border-b flex flex-wrap items-center justify-between gap-3">
                    <div>
                        <h1 class="text-lg font-bold text-gray-800">Danh mục đội</h1>
                    </div>
                    <button type="button" onclick="openTeamModal('add','','','',false)"
                        class="px-4 py-2 rounded-lg bg-emerald-600 text-white font-bold hover:bg-emerald-700 transition">
                        <i class="fa-solid fa-plus mr-2"></i>Thêm đội
                    </button>
                </div>
                <div class="grid gap-3 border-b p-4 sm:grid-cols-[minmax(0,1fr)_20rem]">
                    <asp:HiddenField ID="hfTeamFilter" runat="server" />
                    <label class="relative block sm:col-start-2">
                        <span class="sr-only">Tìm đội</span>
                        <i class="fa-solid fa-magnifying-glass absolute left-3 top-1/2 -translate-y-1/2 text-sm text-gray-400"></i>
                        <input id="teamQuickSearch" name="teamQuickSearch" type="search" value="<%= InitialFilterValue() %>"
                            oninput="filterTeams(this.value)" onkeydown="return suppressSearchSubmit(event)"
                            placeholder="Tìm theo mã hoặc tên đội"
                            class="w-full rounded-lg border py-2.5 pl-9 pr-3 text-sm font-bold outline-none focus:ring-2 focus:ring-emerald-500" />
                    </label>
                </div>
                <div class="max-h-[calc(100dvh-18rem)] overflow-auto main-scroll">
                    <asp:GridView ID="gvTeams" runat="server" AutoGenerateColumns="false" GridLines="None"
                        ShowHeader="false" EnableViewState="false" CssClass="master-grid text-sm" OnRowCommand="gvTeams_RowCommand">
                        <Columns>
                            <asp:TemplateField ItemStyle-CssClass="w-24 border-b px-2 py-3 text-left align-top sm:w-28 sm:px-4">
                                <ItemTemplate>
                                    <div class="flex items-start gap-1">
                                    <button type="button" title="Sửa"
                                        onclick='openTeamModal("edit","<%# Js(Eval("team")) %>","<%# Js(Eval("team")) %>","<%# Js(Eval("team_name")) %>",<%# Convert.ToBoolean(Eval("is_used")).ToString().ToLowerInvariant() %>)'
                                        class="h-9 w-9 shrink-0 rounded border border-blue-100 text-blue-600 hover:bg-blue-50 hover:text-blue-800">
                                        <i class="fa-solid fa-pen-to-square"></i>
                                    </button>
                                    <asp:LinkButton ID="btnDeleteTeam" runat="server" CommandName="DeleteTeam"
                                        CommandArgument='<%# Eval("team") %>' OnClientClick="persistTeamFilter(); return confirm('Xóa đội này?');"
                                        ToolTip="Xóa" Visible='<%# !Convert.ToBoolean(Eval("is_used")) %>'
                                        CssClass="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded border border-red-100 text-red-600 hover:bg-red-50 hover:text-red-800">
                                        <i class="fa-solid fa-trash"></i>
                                    </asp:LinkButton>
                                    </div>
                                </ItemTemplate>
                            </asp:TemplateField>
                            <asp:TemplateField ItemStyle-CssClass="master-value border-b px-2 py-3 sm:px-4">
                                <ItemTemplate>
                                    <div class="team-row grid min-w-0 gap-2"
                                        data-code="<%# Attr(Eval("team")) %>"
                                        data-name="<%# Attr(Eval("team_name")) %>">
                                        <div class="flex w-full min-w-0 flex-wrap items-center justify-between">
											<span class="min-w-0 font-bold text-emerald-700">
												<%# Eval("team") %>
											</span>
										</div>
                                        <div class="flex min-w-0 gap-2">
                                            <span class="min-w-0 text-gray-700"><%# Eval("team_name") %></span>
                                        </div>
                                        <div>
                                            <span class="<%# Convert.ToBoolean(Eval("is_used")) ? "inline-flex rounded bg-amber-100 px-2 py-1 text-xs font-bold text-amber-700" : "inline-flex rounded bg-gray-100 px-2 py-1 text-xs font-bold text-gray-600" %>">
                                                <%# Convert.ToBoolean(Eval("is_used")) ? "Đã phát sinh" : "Chưa dùng" %>
                                            </span>
                                        </div>
                                    </div>
                                </ItemTemplate>
                            </asp:TemplateField>
                        </Columns>
                        <EmptyDataTemplate>
                            <div class="px-5 py-10 text-center text-gray-500">Chưa có đội.</div>
                        </EmptyDataTemplate>
                    </asp:GridView>
                </div>
            </section>
        </main>
    </div>

    <div id="teamModal" class="fixed inset-0 z-[70] hidden items-center justify-center bg-gray-900/70 p-4">
        <div class="w-full max-w-lg rounded-lg border bg-white shadow-xl">
            <div class="flex items-center justify-between border-b px-5 py-4">
                <h2 id="teamModalTitle" class="text-lg font-bold text-gray-800">Thêm đội</h2>
                <button type="button" onclick="closeTeamModal()" title="Đóng" class="p-2 text-gray-500 hover:text-gray-800">
                    <i class="fa-solid fa-xmark"></i>
                </button>
            </div>
            <div class="grid gap-4 p-5">
                <asp:HiddenField ID="hfTeamMode" runat="server" />
                <asp:HiddenField ID="hfOriginalTeam" runat="server" />
                <div>
                    <label class="mb-2 block text-sm font-bold text-gray-700">Mã đội</label>
                    <asp:TextBox ID="txtTeamCode" runat="server" MaxLength="16"
                        CssClass="w-full rounded-lg border p-2.5 text-sm font-bold uppercase outline-none focus:ring-2 focus:ring-blue-500">
                    </asp:TextBox>
                    <p id="teamCodeHint" class="hidden mt-2 text-xs font-bold text-amber-700">Mã đã dùng trong trận đấu nên bị khóa.</p>
                </div>
                <div>
                    <label class="mb-2 block text-sm font-bold text-gray-700">Tên đội</label>
                    <asp:TextBox ID="txtTeamName" runat="server" MaxLength="128"
                        CssClass="w-full rounded-lg border p-2.5 text-sm font-bold outline-none focus:ring-2 focus:ring-blue-500">
                    </asp:TextBox>
                </div>
            </div>
            <div class="flex justify-end gap-2 border-t px-5 py-4">
                <button type="button" onclick="closeTeamModal()" class="rounded-lg border px-4 py-2 font-bold text-gray-700 hover:bg-gray-50">Hủy</button>
                <asp:Button ID="btnSaveTeam" runat="server" Text="Lưu" OnClick="btnSaveTeam_Click" OnClientClick="persistTeamFilter();"
                    CssClass="rounded-lg bg-blue-600 px-5 py-2 font-bold text-white hover:bg-blue-700 transition" />
            </div>
        </div>
    </div>

    <div id="toastContainer" class="pointer-events-none fixed right-3 top-20 z-[90] flex w-[calc(100%-1.5rem)] max-w-sm flex-col gap-2 sm:right-5"></div>
</form>

<script>
    const TEAM_FILTER_KEY = 'teams_master_filter';

    function toggleSidebar() {
        const sidebar = document.getElementById('sidebar');
        const overlay = document.getElementById('overlay');
        sidebar.classList.toggle('-translate-x-full');
        overlay.classList.toggle('hidden');
    }

    function openTeamModal(mode, originalCode, code, name, lockCode) {
        document.getElementById('<%= hfTeamMode.ClientID %>').value = mode;
        document.getElementById('<%= hfOriginalTeam.ClientID %>').value = originalCode || '';
        const codeInput = document.getElementById('<%= txtTeamCode.ClientID %>');
        codeInput.value = code || '';
        codeInput.readOnly = !!lockCode;
        codeInput.classList.toggle('bg-gray-100', !!lockCode);
        document.getElementById('<%= txtTeamName.ClientID %>').value = name || '';
        document.getElementById('teamCodeHint').classList.toggle('hidden', !lockCode);
        document.getElementById('teamModalTitle').textContent = mode === 'edit' ? 'Sửa đội' : 'Thêm đội';
        const modal = document.getElementById('teamModal');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        setTimeout(() => (lockCode ? document.getElementById('<%= txtTeamName.ClientID %>') : codeInput).focus(), 0);
    }

    function closeTeamModal() {
        const modal = document.getElementById('teamModal');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
    }

    function filterTeams(value) {
        const keyword = (value || '').trim().toLocaleLowerCase();
        const hidden = document.getElementById('<%= hfTeamFilter.ClientID %>');
        if (hidden) hidden.value = value || '';
        sessionStorage.setItem(TEAM_FILTER_KEY, value || '');
        document.querySelectorAll('.team-row').forEach(row => {
            const text = `${row.dataset.code || ''} ${row.dataset.name || ''}`.toLocaleLowerCase();
            const tableRow = row.closest('tr');
            if (tableRow) tableRow.classList.toggle('hidden', keyword !== '' && !text.includes(keyword));
        });
    }

    function suppressSearchSubmit(event) {
        if (event.key === 'Enter') {
            event.preventDefault();
            return false;
        }
        return true;
    }

    function persistTeamFilter() {
        const input = document.getElementById('teamQuickSearch');
        const hidden = document.getElementById('<%= hfTeamFilter.ClientID %>');
        if (input && hidden) hidden.value = input.value || '';
        if (input) sessionStorage.setItem(TEAM_FILTER_KEY, input.value || '');
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

    document.addEventListener('DOMContentLoaded', function () {
        const hidden = document.getElementById('<%= hfTeamFilter.ClientID %>');
        const input = document.getElementById('teamQuickSearch');
        if (hidden && input) {
            const stored = sessionStorage.getItem(TEAM_FILTER_KEY) || '';
            const nextValue = hidden.value || stored;
            if (nextValue) input.value = nextValue;
            filterTeams(input.value);
        }
    });
</script>
</body>
</html>
