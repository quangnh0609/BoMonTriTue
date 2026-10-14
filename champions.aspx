<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Register Src="~/ucAddChampion.ascx" TagPrefix="uc" TagName="AddChampion" %>
<%@ Register Src="~/ucChampionTicket.ascx" TagPrefix="uc" TagName="ChampionTicket" %>
<%@ Register Src="~/ucTicketMatch.ascx" TagPrefix="uc" TagName="TicketMatch" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Collections.Generic" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Xml.Linq" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null)
        {
            Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
            return;
        }

        if (!IsPostBack)
        {
            BindData();
            LoadFilterData();
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
        } catch { return false; }
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
        } catch { return false; }
    }

    private void BindData()
    {
        // Data được load qua JS/fetch khi page load
    }

    private void LoadFilterData()
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                string sqlSeason = "SELECT rtrim(ltrim(season)) as season, season_name FROM bet_season";
                SqlDataAdapter daSeason = new SqlDataAdapter(sqlSeason, conn);
                DataTable dtSeason = new DataTable();
                daSeason.Fill(dtSeason);

                string sqlTeam = "SELECT rtrim(ltrim(team)) as team, team_name FROM bet_team";
                SqlDataAdapter daTeam = new SqlDataAdapter(sqlTeam, conn);
                DataTable dtTeam = new DataTable();
                daTeam.Fill(dtTeam);

                var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();

                var listS = new List<Dictionary<string, object>>();
                foreach (DataRow r in dtSeason.Rows)
                    listS.Add(new Dictionary<string, object> { { "season", r["season"] }, { "season_name", r["season_name"] } });

                var listT = new List<Dictionary<string, object>>();
                foreach (DataRow r in dtTeam.Rows)
                    listT.Add(new Dictionary<string, object> { { "team", r["team"] }, { "team_name", r["team_name"] } });

                string script = "var dataSeason = " + serializer.Serialize(listS) + "; var dataTeam = " + serializer.Serialize(listT) + ";";
                ClientScript.RegisterStartupScript(this.GetType(), "InitData", script, true);
            }
        }
        catch { }
    }

    [System.Web.Services.WebMethod]
    public static string DeleteChampion(string season, string time)
    {
        try
        {
            if (HttpContext.Current.Session["UserID"] == null)
            {
                var s = new System.Web.Script.Serialization.JavaScriptSerializer();
                return s.Serialize(new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", "Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại." } });
            }

            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand("exec bet_champion_delete @season, @time, @userID", conn);
                cmd.Parameters.AddWithValue("@season", season);
                cmd.Parameters.AddWithValue("@time", string.IsNullOrEmpty(time) ? (object)DBNull.Value : (object)Convert.ToDateTime(time));
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
                else { isSuccess = 0; msg = "Stored procedure không trả về kết quả"; }
                reader.Close();

                var res = new Dictionary<string, object> { { "isSuccess", isSuccess }, { "msg", msg } };
                return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(res);
            }
        }
        catch (Exception ex)
        {
            var err = new Dictionary<string, object> { { "isSuccess", 0 }, { "msg", "Lỗi: " + ex.Message } };
            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(err);
        }
    }

    [System.Web.Services.WebMethod]
    public static string FilterChampions(string team, string season, string dateFrom, string dateTo)
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand("bet_champions", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@team",     string.IsNullOrEmpty(team)     ? "" : team);
                cmd.Parameters.AddWithValue("@season",   string.IsNullOrEmpty(season)   ? "" : season);
                cmd.Parameters.AddWithValue("@datefrom", string.IsNullOrEmpty(dateFrom) ? (object)DBNull.Value : dateFrom);
                cmd.Parameters.AddWithValue("@dateto",   string.IsNullOrEmpty(dateTo)   ? (object)DBNull.Value : dateTo);

                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                var list = new List<Dictionary<string, object>>();
                while (reader.Read())
                {
                    var row = new Dictionary<string, object>();
                    for (int i = 0; i < reader.FieldCount; i++)
                        row[reader.GetName(i)] = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    list.Add(row);
                }
                reader.Close();
                return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(list);
            }
        }
        catch (Exception ex)
        {
            var err = new Dictionary<string, object> { { "error", ex.Message } };
            return new System.Web.Script.Serialization.JavaScriptSerializer().Serialize(err);
        }
    }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Champions</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .menu-font { font-size: 16px; font-weight: bold; }
        .nav-item { border-right: 4px solid transparent; display: flex; align-items: center; padding: 0.75rem 1rem; font-weight: bold; transition: all 0.2s; }
        .nav-item-active { border-right-color: #1d4ed8; background-color: #eff6ff; color: #1d4ed8 !important; }
        .nav-item i { width: 20px; text-align: center; margin-right: 12px; }
        .breadcrumb-link { color: #2563eb; text-decoration: none; }
        .breadcrumb-current { color: #4b5563; cursor: default; }
    </style>
</head>
<body class="h-[100dvh] flex flex-col">
    <form runat="server" class="h-full flex flex-col">
        <asp:ScriptManager runat="server" EnablePageMethods="true" />

        <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
            <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="champions" PageTitle="Kèo chung cuộc" />
        </nav>

        <div class="flex flex-1 overflow-hidden relative">
            <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>

            <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="champions" />

            <main class="flex-1 flex flex-col overflow-hidden bg-[#f8fafc]">
                <!-- Bộ lọc -->
                <div class="flex-none bg-white border-b">
                    <div class="p-3 lg:p-6 pb-3 flex items-center justify-between cursor-pointer hover:bg-gray-50 transition-colors" onclick="toggleFilter()">
                        <h3 class="text-sm font-bold text-gray-700 flex items-center gap-2">
                            <i class="fa-solid fa-filter text-blue-600"></i>
                            Bộ lọc
                        </h3>
                        <i id="filterIcon" class="fa-solid fa-chevron-down text-gray-600 transition-transform"></i>
                    </div>

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
                                    <div id="teamDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto"></div>
                                </div>
                                <div class="relative">
                                    <label class="block text-xs font-bold text-gray-700 mb-1">Giải đấu</label>
                                    <input type="text" id="filterSeasonSearch"
                                        class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
                                        placeholder="Tìm kiếm giải đấu..."
                                        onfocus="showSeasonDropdown()"
                                        oninput="filterSeasonOptions()" />
                                    <input type="hidden" id="filterSeason" name="filterSeason" />
                                    <div id="seasonDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto"></div>
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
							
							<div class="mt-3 flex justify-end">
								<button type="button" onclick="applyFilter()" 
									class="bg-blue-600 hover:bg-blue-700 text-white px-6 py-2 rounded-lg font-bold text-sm transition-all active:scale-95 flex items-center gap-2">
									<i class="fa-solid fa-search"></i>
									Tìm kiếm
								</button>
							</div>
                        </div>
                    </div>
                </div>

                <!-- Bảng dữ liệu -->
                <div class="flex-1 overflow-auto main-scroll p-3 lg:p-6">
                    <div class="mb-3 flex items-center justify-between">
                        <% if (CheckRight("bet_champions_insert")) { %>
                        <button type="button" onclick="openAddModal()"
                            class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2.5 rounded-xl shadow-lg flex items-center transition-all active:scale-95 group border-2 border-white">
                            <i class="fa-solid fa-plus mr-2 group-hover:rotate-90 transition-transform"></i>
                            <span class="font-bold text-[11px] lg:text-xs tracking-wide">Thêm mới</span>
                        </button>
                        <% } %>
                        <span class="text-sm font-bold text-gray-500">
                            Tổng: <span id="totalCount"><asp:Literal runat="server" ID="litCount" /></span> bản ghi
                        </span>
                    </div>

                    <div id="championList" class="grid grid-cols-1 lg:grid-cols-2 gap-4"></div>
                </div>
            </main>
        </div>
        <uc:AddChampion runat="server" ID="ucAddChampion" />
        <uc:ChampionTicket runat="server" ID="ucChampionTicket" />
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

        let teamData = [];
        let seasonData = [];

        window.addEventListener('load', function () {
            if (typeof dataTeam !== 'undefined') {
                teamData = dataTeam;
                renderTeamDropdown(teamData);
            }
            if (typeof dataSeason !== 'undefined') {
                seasonData = dataSeason;
                renderSeasonDropdown(seasonData);
            }
            // Load dữ liệu ban đầu
            loadData('', '', '', '');
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
            document.getElementById('teamDropdown').classList.remove('hidden');
        }

        function filterSeasonOptions() {
            const searchText = document.getElementById('filterSeasonSearch').value.toLowerCase();
            const filtered = seasonData.filter(item =>
                item.season_name.toLowerCase().includes(searchText) ||
                item.season.toLowerCase().includes(searchText)
            );
            renderSeasonDropdown(filtered);
            document.getElementById('seasonDropdown').classList.remove('hidden');
        }

        document.addEventListener('click', function (e) {
            if (!e.target.closest('#filterTeamSearch') && !e.target.closest('#teamDropdown'))
                document.getElementById('teamDropdown').classList.add('hidden');
            if (!e.target.closest('#filterSeasonSearch') && !e.target.closest('#seasonDropdown'))
                document.getElementById('seasonDropdown').classList.add('hidden');
        });

        function applyFilter() {
            const team     = document.getElementById('filterTeam').value;
            const season   = document.getElementById('filterSeason').value;
            const dateFrom = document.getElementById('filterDateFrom').value;
            const dateTo   = document.getElementById('filterDateTo').value;

            toggleFilter();
            loadData(team, season, dateFrom, dateTo);
        }

        let _cachedChampionRows = [];

        function loadData(team, season, dateFrom, dateTo) {
            const list = document.getElementById('championList');
            list.innerHTML = '<div class="col-span-2 text-center py-10 text-gray-400"><i class="fa-solid fa-spinner fa-spin text-3xl"></i></div>';

            fetch('champions.aspx/FilterChampions', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ team: team, season: season, dateFrom: dateFrom, dateTo: dateTo })
            })
            .then(r => r.json())
            .then(data => {
                const rows = JSON.parse(data.d);
                _cachedChampionRows = rows;
                renderTable(rows);
            })
            .catch(() => {
                list.innerHTML = '<div class="col-span-2 text-center py-10 text-red-500 font-bold">Lỗi khi tải dữ liệu</div>';
            });
        }

        function openAddModal() {
            openAddChampionModal();
        }

        function reloadChampionsData() {
            loadData('', '', '', '');
        }

        function fillChampionForm(groupKey, isEdit) {
            const rows = _cachedChampionRows;
            const groupRows = rows.filter(r => (r.season || '') + '|' + (r.time || '') === groupKey);
            if (!groupRows || groupRows.length === 0) { alert('Không tìm thấy dữ liệu'); return false; }

            const first = groupRows[0];

            // Clear form trước
            clearAddChampionForm();

            // Fill champion id
            const hdnChampion = document.querySelector('[id$="champion"]');
            if (hdnChampion) hdnChampion.value = isEdit ? (first.champion || '') : '';

            // Fill season
            const hdnSeasonCode = document.querySelector('[id$="hdnSeasonCode"]');
            const seasonInput   = document.querySelector('[id$="season"]');
            if (hdnSeasonCode) hdnSeasonCode.value = first.season || '';
            if (seasonInput)   seasonInput.value   = first.season_name || first.season || '';

            // Fill time
            const hdnTimeValue = document.querySelector('[id$="hdnTimeValue"]');
            const timeInput    = document.querySelector('[id$="time"]');
            if (first.time) {
                let dt;
                if (typeof first.time === 'string' && first.time.startsWith('/Date(')) {
                    dt = new Date(parseInt(first.time.match(/\d+/)[0]));
                } else {
                    dt = new Date(first.time);
                }
                if (!isNaN(dt.getTime())) {
                    const dd   = String(dt.getDate()).padStart(2,'0');
                    const mm   = String(dt.getMonth()+1).padStart(2,'0');
                    const yyyy = dt.getFullYear();
                    if (timeInput)    timeInput.value    = `${dd}/${mm}/${yyyy}`;
                    if (hdnTimeValue) hdnTimeValue.value = `${yyyy}-${mm}-${dd}`;
                    const picker = document.getElementById('championDatePickerHidden');
                    if (picker) picker.value = `${yyyy}-${mm}-${dd}`;
                }
            }

            // Fill name
            const nameInput = document.querySelector('[id$="name"]');
            if (nameInput) nameInput.value = first.name || '';

            // Fill detail rows
            const tbody = document.getElementById('championDetailBody');
            tbody.innerHTML = '';
            groupRows.forEach(function(r) {
                if (!r.team) return;
                addChampionDetailRow();
                const lastRow = tbody.lastElementChild;
                const codeInput = lastRow.querySelector('.champion-team-code');
                const nameInput = lastRow.querySelector('.champion-team-input');
                const rateInput = lastRow.querySelector('.champion-rate-input');
                const idInput   = lastRow.querySelector('.champion-detail-id');
                if (idInput)   idInput.value   = isEdit && r.id !== undefined && r.id !== null ? r.id : '';
                if (codeInput) codeInput.value = r.team || '';
                if (nameInput) nameInput.value = r.team_name || r.team || '';
                if (rateInput) rateInput.value = r.rate_win || '';
            });
            if (tbody.children.length === 0) for (let i = 0; i < 3; i++) addChampionDetailRow();

            // Set edit mode
            const editYn = document.querySelector('[id$="editYn"]');
            if (editYn) editYn.value = isEdit ? 'true' : 'false';

            // Fill time_lock
            const hdnTimeLock = document.querySelector('[id$="hdnTimeLockValue"]');
            const tlPicker    = document.getElementById('timeLockPicker');
            const tlText      = document.querySelector('[id$="time_lock"]');
            if (first.time_lock) {
                let dtl;
                if (typeof first.time_lock === 'string' && first.time_lock.startsWith('/Date(')) {
                    dtl = new Date(parseInt(first.time_lock.match(/\d+/)[0]));
                } else {
                    dtl = new Date(first.time_lock);
                }
                if (!isNaN(dtl.getTime())) {
                    const yyyy = dtl.getFullYear();
                    const mm   = String(dtl.getMonth()+1).padStart(2,'0');
                    const dd   = String(dtl.getDate()).padStart(2,'0');
                    const HH   = String(dtl.getHours()).padStart(2,'0');
                    const MM   = String(dtl.getMinutes()).padStart(2,'0');
                    const isoLocal = `${yyyy}-${mm}-${dd}T${HH}:${MM}`;
                    if (hdnTimeLock) hdnTimeLock.value = isoLocal;
                    if (tlPicker)    tlPicker.value    = isoLocal;
                    if (tlText)      tlText.value      = `${HH}:${MM} ${dd}/${mm}/${yyyy}`;
                }
            } else {
                if (hdnTimeLock) hdnTimeLock.value = '';
                if (tlPicker)    tlPicker.value    = '';
                if (tlText)      tlText.value      = '';
            }

            // Cập nhật tiêu đề modal
            const title = document.getElementById('championModalTitle');
            if (title) title.innerHTML = '<i class="fa-solid fa-trophy mr-3 text-lg"></i> ' + (isEdit ? 'Sửa kèo chung cuộc' : 'Sao chép kèo chung cuộc');

            return true;
        }

        function editChampion(groupKey) {
            if (!fillChampionForm(groupKey, true)) return;
            openAddChampionModal();
        }

        function copyChampion(groupKey) {
            if (!fillChampionForm(groupKey, false)) return;
            openAddChampionModal();
        }

        function deleteChampion(groupKey) {
            if (!confirm('Bạn có chắc chắn muốn xóa kèo chung cuộc này?')) return;

            const parts  = groupKey.split('|');
            const season = parts[0];
            const rawTime = parts[1] || '';

            // Convert raw time sang ISO datetime string
            let timeStr = '';
            if (rawTime) {
                let dt;
                if (rawTime.startsWith('/Date(')) {
                    dt = new Date(parseInt(rawTime.match(/\d+/)[0]));
                } else {
                    dt = new Date(rawTime);
                }
                if (!isNaN(dt.getTime())) {
                    timeStr = dt.toISOString(); // yyyy-MM-ddTHH:mm:ss.sssZ
                }
            }

            fetch('champions.aspx/DeleteChampion', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ season: season, time: timeStr })
            })
            .then(r => r.json())
            .then(data => {
                const result = JSON.parse(data.d);
                alert(result.msg);
                if (result.isSuccess == 1) reloadChampionsData();
            })
            .catch(err => { alert('Lỗi khi xóa: ' + err); });
        }

        let _champTicketIndex = [];

        function openChampionTicketByIndex(idx) {
            const item = _champTicketIndex[idx];
            if (!item) return;
            openChampionTicketModal(item.season, item.time, item.canSelectAllUsers === true);
        }

        function openChampionTicketListByIndex(idx) {
            const item = _champTicketIndex[idx];
            if (!item) return;
            const matchKey = `CHAMP|${encodeURIComponent(item.season)}|${encodeURIComponent(item.timeLock)}`;
            openTicketMatchModal(matchKey, item.label || item.season);
        }

        function toIsoDate(raw) {
            if (!raw) return '';
            let dt;
            if (typeof raw === 'string' && raw.startsWith('/Date(')) {
                dt = new Date(parseInt(raw.match(/\d+/)[0]));
            } else {
                dt = new Date(raw);
            }
            if (isNaN(dt.getTime())) return '';
            return dt.getFullYear() + '-' + String(dt.getMonth()+1).padStart(2,'0') + '-' + String(dt.getDate()).padStart(2,'0');
        }

        function toSqlDateTime(raw) {
            if (!raw) return '';
            let dt;
            if (typeof raw === 'string' && raw.startsWith('/Date(')) {
                dt = new Date(parseInt(raw.match(/\d+/)[0]));
            } else {
                dt = new Date(raw);
            }
            if (isNaN(dt.getTime())) return '';
            return dt.getFullYear() + '-' + String(dt.getMonth()+1).padStart(2,'0') + '-' + String(dt.getDate()).padStart(2,'0') +
                ' ' + String(dt.getHours()).padStart(2,'0') + ':' + String(dt.getMinutes()).padStart(2,'0') + ':' + String(dt.getSeconds()).padStart(2,'0');
        }

        const canViewTickets = <%= CheckRight("bet_ticket_result") ? "true" : "false" %>;
        const canInsertChampion = <%= CheckRight("bet_champions_insert") ? "true" : "false" %>;
        const isAdmin = <%= IsAdminUser() ? "true" : "false" %>;
        const currentUserId = <%= GetCurrentUserId() %>;

        function buildChampTicketBtn(idx, rawTimeLock, canManage) {
            if (canManage) {
                // luôn hiện
            } else {
                // chỉ hiện nếu time_lock tồn tại và chưa qua
                if (!rawTimeLock) return '';
                let dtl;
                if (typeof rawTimeLock === 'string' && rawTimeLock.startsWith('/Date(')) {
                    dtl = new Date(parseInt(rawTimeLock.match(/\d+/)[0]));
                } else {
                    dtl = new Date(rawTimeLock);
                }
                if (isNaN(dtl.getTime()) || dtl <= new Date()) return '';
            }
            return `<button type="button" onclick="openChampionTicketByIndex(${idx})" class="bg-green-600 hover:bg-green-700 text-white px-2 py-0.5 rounded text-[11px] transition-all"><i class="fa-solid fa-ticket mr-1"></i>Cược</button>`;
        }

        function buildChampTicketListBtn(idx) {
            if (!canViewTickets) return '';
            return `<button type="button" onclick="openChampionTicketListByIndex(${idx})" class="bg-yellow-500 hover:bg-yellow-600 text-white px-2 py-0.5 rounded text-[11px] transition-all"><i class="fa-solid fa-ticket mr-1"></i>Vé cược</button>`;
        }

        function buildChampCopyBtn(groupKey) {
            if (!canInsertChampion) return '';
            return `<button type="button" onclick="copyChampion('${groupKey}')" class="bg-green-500 hover:bg-green-600 text-white px-2 py-0.5 rounded text-[11px] transition-all"><i class="fa-solid fa-copy mr-1"></i>Sao chép</button>`;
        }

        function renderTable(data) {
            const container = document.getElementById('championList');

            if (!data || data.length === 0) {
                document.getElementById('totalCount').textContent = '0';
                container.innerHTML = '<div class="col-span-2 text-center py-10 text-gray-400"><i class="fa-solid fa-inbox text-3xl mb-2 block"></i>Không có dữ liệu</div>';
                return;
            }

            // Group theo season + time
            const groups = {};
            const order  = [];
            data.forEach(row => {
                const key = (row.season || '') + '|' + (row.time || '');
                if (!groups[key]) {
                    groups[key] = { season: row.season_name || row.season || '', name: row.name || '', time: row.time || '', champion: row.champion || '', time_lock: row.time_lock || '', status: row.status || '', user_host: row.user_host || 0, host_name: row.host_name || '', details: [] };
                    order.push(key);
                }
                if (!groups[key].name && row.name) groups[key].name = row.name;
                if (!groups[key].status && row.status) groups[key].status = row.status;
                if (!groups[key].user_host && row.user_host) groups[key].user_host = row.user_host;
                if (!groups[key].host_name && row.host_name) groups[key].host_name = row.host_name;
                if (row.team) {
                    groups[key].details.push({ team: row.team_name || row.team, rate_win: row.rate_win || '', result_win: row.result_win });
                }
            });

            document.getElementById('totalCount').textContent = order.length;

            _champTicketIndex = [];
            let html = '';
            order.forEach((key, idx) => {
                const g = groups[key];
                const canManage = isAdmin || Number(g.user_host || 0) === currentUserId;
                _champTicketIndex.push({ season: key.split('|')[0], time: toIsoDate(g.time), timeLock: toSqlDateTime(g.time_lock), label: g.name || g.season, canSelectAllUsers: canManage });

                // Format time
                let timeDisplay = '';
                if (g.time) {
                    try {
                        let dt;
                        if (typeof g.time === 'string' && g.time.startsWith('/Date(')) {
                            dt = new Date(parseInt(g.time.match(/\d+/)[0]));
                        } else {
                            dt = new Date(g.time);
                        }
                        if (!isNaN(dt.getTime())) {
                            const dd = String(dt.getDate()).padStart(2,'0');
                            const mm = String(dt.getMonth()+1).padStart(2,'0');
                            const yyyy = dt.getFullYear();
                            timeDisplay = `${dd}/${mm}/${yyyy}`;
                        }
                    } catch(e) {}
                }

                // Detail rows
                let detailRows = '';
                if (g.details.length > 0) {
                    g.details.forEach(d => {
                        const checked_win = (d.result_win == 1 || d.result_win === true || d.result_win === 'true') ? 'checked' : '';
						const checked_lost = (d.result_win == 0 || d.result_win === false || d.result_win === 'false') ? 'checked' : '';
                        detailRows += `<tr class="border-b last:border-0">
                            <td class="py-1 px-2 text-gray-700 font-bold text-[12px]">${d.team}</td>
                            <td class="py-1 px-2 text-right text-blue-600 font-bold text-[12px]">${d.rate_win}</td>
							<td class="py-1 px-2 text-center"><input type="checkbox" ${checked_win} onclick="return false;" class="w-4 h-4 accent-green-600 cursor-default" /></td>
							<td class="py-1 px-2 text-center"><input type="checkbox" ${checked_lost} onclick="return false;" class="w-4 h-4 accent-red-600 cursor-default" /></td>							
                        </tr>`;
                    });
                }

                // Format time_lock
                let timeLockDisplay = '';
                if (g.time_lock) {
                    try {
                        let dtl;
                        if (typeof g.time_lock === 'string' && g.time_lock.startsWith('/Date(')) {
                            dtl = new Date(parseInt(g.time_lock.match(/\d+/)[0]));
                        } else {
                            dtl = new Date(g.time_lock);
                        }
                        if (!isNaN(dtl.getTime())) {
                            const dd = String(dtl.getDate()).padStart(2,'0');
                            const mm = String(dtl.getMonth()+1).padStart(2,'0');
                            const yyyy = dtl.getFullYear();
                            const HH = String(dtl.getHours()).padStart(2,'0');
                            const MM = String(dtl.getMinutes()).padStart(2,'0');
                            timeLockDisplay = `${dd}/${mm}/${yyyy} ${HH}:${MM}`;
                        }
                    } catch(e) {}
                }

                const statusDisplay = Number(g.status || 0) === 1 ? 'Sắp tới' : (g.status ? 'Đã khóa' : '');

                html += `
                <div class="${(() => {
                    if (!g.time_lock) return 'bg-gray-100 rounded-xl shadow-sm border border-gray-200 overflow-hidden';
                    let dtl;
                    if (typeof g.time_lock === 'string' && g.time_lock.startsWith('/Date(')) {
                        dtl = new Date(parseInt(g.time_lock.match(/\d+/)[0]));
                    } else {
                        dtl = new Date(g.time_lock);
                    }
                    return (!isNaN(dtl.getTime()) && dtl >= new Date())
                        ? 'bg-green-50 rounded-xl shadow-sm border border-green-300 overflow-hidden'
                        : 'bg-gray-100 rounded-xl shadow-sm border border-gray-200 overflow-hidden';
                })()}">
                    <div class="px-4 py-3">
						<div class="flex justify-end items-center gap-2 mb-3">
							${buildChampTicketListBtn(idx)}
                            <button type="button" onclick="openResultModal('${key}')" class="bg-purple-600 hover:bg-purple-700 text-white px-2 py-0.5 rounded text-[11px] transition-all"><i class="fa-solid fa-flag-checkered mr-1"></i>Kết quả</button>
                            ${buildChampCopyBtn(key)}
							${canManage ? `<button type="button" onclick="editChampion('${key}')" class="bg-blue-500 hover:bg-blue-600 text-white px-2 py-0.5 rounded text-[11px] transition-all"><i class="fa-solid fa-pen-to-square mr-1"></i>Sửa</button>` : ''}
                            ${canManage ? `<button type="button" onclick="deleteChampion('${key}')" class="bg-red-500 hover:bg-red-600 text-white px-2 py-0.5 rounded text-[11px] transition-all"><i class="fa-solid fa-trash mr-1"></i>Xóa</button>` : ''}
						</div>

                        <div class="flex items-center justify-between gap-3 mb-1">
                            <div class="min-w-0 text-left">${g.host_name ? `<span class="inline-block bg-gray-100 px-2 py-0.5 rounded text-[12px] border border-gray-200 font-bold text-gray-800">Cái: ${g.host_name}</span>` : ''}</div>
                            <span class="text-gray-700 font-bold text-[12px] text-right whitespace-nowrap">${statusDisplay}</span>
                        </div>
                        <div class="flex items-center justify-between gap-3 mb-2">
                            <span class="font-bold text-gray-800 text-[13px]">${g.season}</span>
                            <span class="text-gray-500 text-[12px] text-right whitespace-nowrap">${timeDisplay}</span>
                        </div>
                        ${(g.name || timeLockDisplay) ? `
                        <div class="flex items-center justify-between gap-3 mb-1">
                            <span class="min-w-0 font-bold text-gray-800 text-[13px] truncate">${g.name || ''}</span>
                            ${timeLockDisplay ? `<span class="text-[11px] text-orange-600 font-bold text-right whitespace-nowrap"><span class="text-gray-500 font-semibold">Khóa:</span> ${timeLockDisplay}</span>` : '<span></span>'}
                        </div>` : ''}
                        
                        ${detailRows ? `
                        <div class="border rounded-lg overflow-hidden mt-2">
                            <table class="w-full">
                                <tbody>${detailRows}</tbody>
                            </table>
                        </div>` : ''}
                    </div>
                </div>`;
            });

            container.innerHTML = html;
        }

        function openResultModal(groupKey) {
            const rows = _cachedChampionRows;
            const groupRows = rows.filter(r => (r.season || '') + '|' + (r.time || '') === groupKey);
            if (!groupRows || groupRows.length === 0) { alert('Không tìm thấy dữ liệu'); return; }
            openChampionResultModal(groupKey, groupRows);
        }
    </script>
</body>
</html>
