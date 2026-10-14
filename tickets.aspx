<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>

<script runat="server">
    protected string UsersJson = "[]";
    protected string MatchesJson = "[]";
    protected string SeasonsJson = "[]";
    protected bool ShowFeeColumn = Lib.Config("ShowFeeColumn", true);
    
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null) 
		{
			Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
			return;
		}
        
        if (!IsPostBack)
        {
            LoadUsers();
            LoadMatches();
            LoadSeasons();
        }
        
        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }
    
    private void LoadUsers()
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand("SELECT id, name, comment FROM dbo.userinfo2 WHERE user_yn = 1 ORDER BY comment ", conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                
                System.Text.StringBuilder json = new System.Text.StringBuilder();
                json.Append("[");
                bool first = true;
                
                while (reader.Read())
                {
                    if (!first) json.Append(",");
                    first = false;
                    
                    int id = reader.GetInt32(reader.GetOrdinal("id"));
                    string name = reader["name"].ToString().Replace("\"", "\\\"");
                    string comment = reader["comment"].ToString().Replace("\"", "\\\"");
                    
                    json.AppendFormat("{{\"id\":{0},\"name\":\"{1}\",\"comment\":\"{2}\"}}", id, name, comment);
                }
                json.Append("]");
                reader.Close();
                
                UsersJson = json.ToString();
            }
        }
        catch { }
    }
    
    private void LoadMatches()
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand(@"
                    SELECT match, name, time, season
                    FROM (
                        SELECT match, name, time, season FROM vbet_match_total
                        UNION ALL
                        SELECT match_id AS match,
                               home_name + ' vs ' + way_name AS name,
                               match_time AS time,
                               season
                        FROM vbet_esport_match
                    ) data
                    ORDER BY time DESC", conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                
                System.Text.StringBuilder json = new System.Text.StringBuilder();
                json.Append("[");
                bool first = true;
                
                while (reader.Read())
                {
                    if (!first) json.Append(",");
                    first = false;
                    
                    string match = reader["match"].ToString().Replace("\"", "\\\"");
                    string name = reader["name"].ToString().Replace("\"", "\\\"");
                    string season = reader["season"].ToString().Replace("\"", "\\\"");
                    
                    string time = "";
                    if (reader["time"] != DBNull.Value)
                    {
                        DateTime dt = Convert.ToDateTime(reader["time"]);
                        time = dt.ToString("HH:mm dd/MM");
                    }
                    
                    json.AppendFormat("{{\"match\":\"{0}\",\"name\":\"{1}\",\"time\":\"{2}\",\"season\":\"{3}\"}}", match, name, time, season);
                }
                json.Append("]");
                reader.Close();
                
                MatchesJson = json.ToString();
            }
        }
        catch { }
    }
    
    private void LoadSeasons()
    {
        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand("SELECT rtrim(ltrim(season)) as season, season_name FROM bet_season", conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                
                System.Text.StringBuilder json = new System.Text.StringBuilder();
                json.Append("[");
                bool first = true;
                
                while (reader.Read())
                {
                    if (!first) json.Append(",");
                    first = false;
                    string season = reader["season"].ToString().Replace("\"", "\\\"");
                    string seasonName = reader["season_name"].ToString().Replace("\"", "\\\"");
                    json.AppendFormat("{{\"season\":\"{0}\",\"season_name\":\"{1}\"}}", season, seasonName);
                }
                json.Append("]");
                reader.Close();
                
                SeasonsJson = json.ToString();
            }
        }
        catch { }
    }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Vé cược</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
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
		
        /* Cho phép scroll ngang */
        .table-scroll-layout { width: 100% !important; table-layout: fixed !important; }
        
		
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
<body class="h-[100dvh] flex flex-col">
    <form runat="server" class="h-full flex flex-col">
        <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
            <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="tickets" PageTitle="Vé cược" />
        </nav>

        <div class="flex flex-1 overflow-hidden relative">
            <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>

            <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="tickets" />

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
                        <!-- Dòng 1: web=4 cột, mobile=2 cột -->
                        <div class="grid grid-cols-2 lg:grid-cols-4 gap-3">
                            <div class="col-span-1">
                                <label class="block text-xs font-bold text-gray-700 mb-1">Người cược</label>
                                <select id="filterUser" class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none">
                                    <option value="-1" selected>Tất cả</option>
                                </select>
                            </div>
                            
                            <div class="relative col-span-1">
                                <label class="block text-xs font-bold text-gray-700 mb-1">Trận đấu</label>
                                <input type="text" id="filterMatchSearch" 
                                    class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
                                    style="font-size:16px"
                                    placeholder="Tìm kiếm trận đấu..." 
                                    autocomplete="off"
                                    onfocus="showMatchDropdown()" 
                                    oninput="filterMatchOptions()" />
                                <input type="hidden" id="filterMatch" />
                                <div id="matchDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto"></div>
                            </div>

                            <div class="col-span-1">
                                <label class="block text-xs font-bold text-gray-700 mb-1">Từ ngày</label>
                                <div class="relative">
                                    <input type="datetime-local" id="pickerDateFrom"
                                        style="position:absolute;opacity:0;width:100%;height:100%;top:0;left:0;cursor:pointer;z-index:2;" />
                                    <input type="text" id="filterDateFrom" readonly placeholder="hh:mm dd/MM/yyyy"
                                        class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none cursor-pointer bg-white" />
                                    <input type="hidden" id="filterDateFromVal" />
                                </div>
                            </div>
							
                            <div class="col-span-1">
                                <label class="block text-xs font-bold text-gray-700 mb-1">Đến ngày</label>
                                <div class="relative">
                                    <input type="datetime-local" id="pickerDateTo"
                                        style="position:absolute;opacity:0;width:100%;height:100%;top:0;left:0;cursor:pointer;z-index:2;" />
                                    <input type="text" id="filterDateTo" readonly placeholder="hh:mm dd/MM/yyyy"
                                        class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none cursor-pointer bg-white" />
                                    <input type="hidden" id="filterDateToVal" />
                                </div>
                            </div>
                        </div>

                        <!-- Dòng 1b: Đến ngày + padding -->
                        <div class="grid grid-cols-1 lg:grid-cols-1 gap-3 mt-3">
                            <div class="relative col-span-1">
                                <label class="block text-xs font-bold text-gray-700 mb-1">Giải đấu</label>
                                <input type="text" id="filterSeasonSearch"
                                    class="w-full border rounded-lg p-2 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
                                    style="font-size:16px"
                                    placeholder="Tìm kiếm giải đấu..."
                                    onfocus="showSeasonDropdown()"
                                    oninput="filterSeasonOptions()" />
                                <input type="hidden" id="filterSeason" />
                                <div id="seasonDropdown" class="hidden absolute z-10 w-full mt-1 bg-white border rounded-lg shadow-lg max-h-60 overflow-auto"></div>
                            </div>
                        </div>

                        <!-- Dòng 2: web=3 cột, mobile=3 cột -->
                        <div class="grid grid-cols-3 gap-3 mt-3">
                            <div>
                                <label class="block text-xs font-bold text-gray-700 mb-1">Loại</label>
                                <div class="border rounded-lg p-2 bg-white space-y-1">
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterType" id="filterType" value="0" checked class="w-4 h-4 accent-blue-600" /> Chi tiết
                                    </label>
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterType" value="1" class="w-4 h-4 accent-blue-600" /> Tổng cộng
                                    </label>
                                </div>
                            </div>
                            
                            <div>
                                <label class="block text-xs font-bold text-gray-700 mb-1">Đã clear</label>
                                <div class="border rounded-lg p-2 bg-white space-y-1">
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterClear" id="filterClear" value="0" checked class="w-4 h-4 accent-blue-600" /> Chưa clear
                                    </label>
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterClear" value="1" class="w-4 h-4 accent-blue-600" /> Đã clear
                                    </label>
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterClear" value="2" class="w-4 h-4 accent-blue-600" /> Cả hai
                                    </label>
                                </div>
                            </div>

                            <div>
                                <label class="block text-xs font-bold text-gray-700 mb-1">Kết quả</label>
                                <div class="border rounded-lg p-2 bg-white space-y-1">
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterResult" id="filterResult" value="0" class="w-4 h-4 accent-blue-600" /> Chưa có
                                    </label>
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterResult" value="1" class="w-4 h-4 accent-blue-600" /> Đã có
                                    </label>
                                    <label class="flex items-center gap-2 cursor-pointer font-bold text-sm">
                                        <input type="radio" name="filterResult" value="2" checked class="w-4 h-4 accent-blue-600" /> Cả hai
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
                
                <div class="flex-1 p-3 lg:p-6 overflow-hidden">
                    <div class="h-full bg-white rounded-xl shadow-md border flex flex-col overflow-hidden">
                        <div class="flex-1 overflow-auto main-scroll">
                            <table id="ticketsTable" class="w-full table-fixed">
                                <thead class="grid-header">
                                    <tr>
                                        <th style="width: 15%"></th>
                                        <th style='width: <%= ShowFeeColumn ? "31%" : "44%" %>'>Vé cược</th>
                                        <th style="width: 13%">Tiền</th>
                                        <th style="width: 13%">Lãi/Lỗ</th>
										<% if (ShowFeeColumn) { %><th style="width: 13%">Phế</th><% } %>
                                    </tr>
                                </thead>
                                <tbody id="ticketsBody">
                                    <tr>
                                        <td colspan='<%= ShowFeeColumn ? "5" : "4" %>' class="text-center py-4 text-gray-400">Đang tải dữ liệu...</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    </form>

    <script>
        // Data từ server
        var usersData = <%= UsersJson %>;
        var matchesData = <%= MatchesJson %>;
        var seasonsData = <%= SeasonsJson %>;
        const showFeeColumn = <%= ShowFeeColumn ? "true" : "false" %>;
        
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
        
        // Load data khi trang load
        window.addEventListener('load', function() {
            renderUserDropdown();
            renderMatchDropdown();
            renderSeasonDropdown(seasonsData);
            loadTickets();
        });
        
        function renderUserDropdown() {
            const select = document.getElementById('filterUser');
            if (!select) return;
            
            select.innerHTML = '<option value="-1">Tất cả</option>';
            
            usersData.forEach(user => {
                const option = document.createElement('option');
                option.value = user.id;
                option.textContent = user.comment || user.name;
                select.appendChild(option);
            });
        }
        
        function renderMatchDropdown(filteredData) {
            const dropdown = document.getElementById('matchDropdown');
            if (!dropdown) return;
            
            const dataToRender = filteredData || matchesData;
            
            let html = '<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm border-b" onclick="selectMatch(\'\', \'-- Chọn trận đấu --\')">-- Chọn trận đấu --</div>';
            dataToRender.forEach(item => {
                const displayHtml = '<span style="color: #dc2626;">' + item.name + '</span> ' + 
                                    '<span style="color: #16a34a;">' + item.time + '</span> ' + 
                                    '<span style="color: #2563eb;">' + item.season + '</span>';
                
                html += '<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm border-b" onclick="selectMatch(\'' + item.match.replace(/'/g, "\\'") + '\', \'' + (item.name + ' ' + item.time + ' ' + item.season).replace(/'/g, "\\'") + '\')">' + displayHtml + '</div>';
            });
            
            dropdown.innerHTML = html;
        }
        
        function showMatchDropdown() {
            document.getElementById('matchDropdown').classList.remove('hidden');
            document.getElementById('seasonDropdown').classList.add('hidden');
        }
        
        function renderSeasonDropdown(data) {
            const dropdown = document.getElementById('seasonDropdown');
            if (!dropdown) return;
            let html = '<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm border-b" onclick="selectSeason(\'\', \'-- Chọn giải đấu --\')">-- Chọn giải đấu --</div>';
            data.forEach(item => {
                html += `<div class="p-2 hover:bg-blue-50 cursor-pointer font-bold text-sm border-b" onclick="selectSeason('${item.season.replace(/'/g,"\\'")}', '${item.season_name.replace(/'/g,"\\'")}')">${item.season_name}</div>`;
            });
            dropdown.innerHTML = html;
        }

        function showSeasonDropdown() {
            document.getElementById('seasonDropdown').classList.remove('hidden');
            document.getElementById('matchDropdown').classList.add('hidden');
        }

        function selectSeason(value, text) {
            document.getElementById('filterSeason').value = value;
            document.getElementById('filterSeasonSearch').value = text;
            document.getElementById('seasonDropdown').classList.add('hidden');
        }

        function filterSeasonOptions() {
            const searchText = document.getElementById('filterSeasonSearch').value.toLowerCase();
            const filtered = seasonsData.filter(item =>
                item.season_name.toLowerCase().includes(searchText) ||
                item.season.toLowerCase().includes(searchText)
            );
            renderSeasonDropdown(filtered);
            showSeasonDropdown();
        }
        
        function selectMatch(value, text) {
            document.getElementById('filterMatch').value = value;
            document.getElementById('filterMatchSearch').value = text;
            document.getElementById('matchDropdown').classList.add('hidden');
        }
        
        function filterMatchOptions() {
            const searchText = document.getElementById('filterMatchSearch').value.toLowerCase();
            
            if (searchText === '') {
                document.getElementById('filterMatch').value = '';
            }
            
            const filtered = matchesData.filter(item => {
                const displayText = ((item.name || '') + ' ' + (item.time || '') + ' ' + (item.season || '')).toLowerCase();
                return displayText.includes(searchText);
            });
            
            renderMatchDropdown(filtered);
            showMatchDropdown();
        }
        
        document.addEventListener('click', function(e) {
            // Đóng dropdown match khi click bên ngoài
            const matchDropdown = document.getElementById('matchDropdown');
            const matchSearchInput = document.getElementById('filterMatchSearch');
            const seasonDropdown = document.getElementById('seasonDropdown');
            const seasonSearchInput = document.getElementById('filterSeasonSearch');
            
            if (matchDropdown && matchSearchInput) {
                const isClickInsideMatch = e.target === matchSearchInput || 
                                          e.target.closest('#matchDropdown') || 
                                          matchSearchInput.contains(e.target);
                if (!isClickInsideMatch) matchDropdown.classList.add('hidden');
            }
            if (seasonDropdown && seasonSearchInput) {
                const isClickInsideSeason = e.target === seasonSearchInput ||
                                            e.target.closest('#seasonDropdown') ||
                                            seasonSearchInput.contains(e.target);
                if (!isClickInsideSeason) seasonDropdown.classList.add('hidden');
            }
        });
        
        function toggleFilter() {
            const content = document.getElementById('filterContent');
            const icon = document.getElementById('filterIcon');
            
            if (content.classList.contains('hidden')) {
                content.classList.remove('hidden');
                icon.classList.add('rotate-180');
            } else {
                content.classList.add('hidden');
                icon.classList.remove('rotate-180');
            }
        }
        
        function applyFilter() {
            loadTickets();
            toggleFilter(); // Thu gọn bộ lọc sau khi tìm kiếm
        }
        
        function loadTickets() {
            const userId = document.getElementById('filterUser') ? document.getElementById('filterUser').value : null;
			const match = document.getElementById('filterMatch').value != '' ? document.getElementById('filterMatch').value : document.getElementById('filterMatchSearch').value;
            const season = document.getElementById('filterSeason') ? document.getElementById('filterSeason').value : '';
            const type = document.querySelector('[name="filterType"]:checked') ? document.querySelector('[name="filterType"]:checked').value : '0';
            const clear = document.querySelector('[name="filterClear"]:checked') ? document.querySelector('[name="filterClear"]:checked').value : '0';
            const result = document.querySelector('[name="filterResult"]:checked') ? document.querySelector('[name="filterResult"]:checked').value : '2';
            const dateFrom = document.getElementById('filterDateFromVal') ? toSqlDateFormat(document.getElementById('filterDateFromVal').value) : null;
            const dateTo = document.getElementById('filterDateToVal') ? toSqlDateFormat(document.getElementById('filterDateToVal').value) : null;
            
            fetch('GetTicketList.aspx', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    userId: userId,
                    match: match,
                    season: season,
                    type: type,
                    clear: clear,
                    result: result,
                    dateFrom: dateFrom,
                    dateTo: dateTo
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.d) {
                    renderTickets(data.d);
                }
            })
            .catch(error => {
                console.error('Error loading tickets:', error);
                document.getElementById('ticketsBody').innerHTML = '<tr><td colspan="' + getTicketColspan() + '" class="text-center py-4 text-red-500">Có lỗi xảy ra khi tải dữ liệu</td></tr>';
            });
        }
        
        function renderTickets(tickets) {
            const tbody = document.getElementById('ticketsBody');
            
            if (!tickets || tickets.length === 0) {
                tbody.innerHTML = '<tr><td colspan="' + getTicketColspan() + '" class="text-center py-4 text-gray-400">Không có dữ liệu</td></tr>';
                return;
            }
            
            let html = '';
            tickets.forEach((item, index) => {
                const rowClass = index % 2 === 0 ? 'row-white' : 'row-gray';
                const rowStyle = item.rowColor ? 'background-color: ' + item.rowColor + ';' : '';
                const textStyle = item.textColor ? 'color: ' + item.textColor + ';' : '';
                const fontWeight = item.rowBold === '1' || item.rowBold === 'true' ? 'font-weight: bold;' : '';
                const combinedStyle = rowStyle + textStyle + fontWeight;
                
                html += '<tr class="row-style ' + rowClass + '" style="' + combinedStyle + '">';
                
                html += '<td class="text-center px-2 lg:px-4">';
                html += '<div class="flex gap-1 justify-center">';
                html += '<button type="button" class="btn-delete text-black px-2 py-1 rounded text-xs font-bold transition" ';
                html += 'data-match="' + (item.match || '') + '" ';
                html += 'data-userid="' + (item.user_id || 0) + '" ';
                html += 'data-code="' + (item.code || '') + '" ';
                html += 'data-ticket="' + (item.ticket || '') + '">';
                html += '<i class="fa-solid fa-trash"></i></button>';
                html += '<button type="button" class="btn-clear text-black px-2 py-1 rounded text-xs font-bold transition" ';
                html += 'data-match="' + (item.match || '') + '" ';
                html += 'data-userid="' + (item.user_id || 0) + '" ';
                html += 'data-code="' + (item.code || '') + '" ';
                html += 'data-ticket="' + (item.ticket || '') + '">';
                html += '<i class="fa-solid fa-eraser"></i></button>';
                html += '</div>';
                html += '</td>';
                
                // Vé cược
                html += '<td class="text-left px-2 lg:px-4">' + (item.ticket_name || '') + '</td>';
                
                // Tiền
                html += '<td class="text-right px-2 lg:px-4">' + formatMoney(item.money) + '</td>';
                
                // Lãi/Lỗ
                html += '<td class="text-right px-2 lg:px-4">' + formatMoneyWin(item.money_win) + '</td>';
                
                if (showFeeColumn) {
                    html += '<td class="text-right px-2 lg:px-4">' + formatMoneyWin(item.fee) + '</td>';
                }
                
                html += '</tr>';
            });
            
            tbody.innerHTML = html;
        }

        function getTicketColspan() {
            return showFeeColumn ? 5 : 4;
        }
        
        function formatNumber(value) {
            if (value === null || value === undefined || value === '') return '0';
            const num = parseFloat(value);
            if (isNaN(num)) return '0';
            return Math.round(num).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
        }
        
        function formatMoney(value) {
            return formatNumber(value);
        }
        
        function formatMoneyWin(value) {
            return formatNumber(value);
        }
        
        // Event delegation cho delete buttons
        document.addEventListener('click', function(e) {
            if (e.target.closest('.btn-delete')) {
                const btn = e.target.closest('.btn-delete');
                const match = btn.dataset.match;
                const userId = btn.dataset.userid;
                const code = btn.dataset.code;
                const ticket = btn.dataset.ticket;
                
                if (!confirm('Bạn có chắc chắn muốn xóa vé cược này?')) {
                    return;
                }
                
                fetch('DeleteTicket.aspx', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        match: match,
                        user_id: parseInt(userId),
                        code: code,
                        ticket: ticket
                    })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.msg) alert(data.msg);
                    if (data.isSuccess === 1) loadTickets();
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Có lỗi xảy ra khi xóa vé cược');
                });
            }
            
            if (e.target.closest('.btn-clear')) {
                const btn = e.target.closest('.btn-clear');
                const match = btn.dataset.match;
                const userId = btn.dataset.userid;
                const code = btn.dataset.code;
                const ticket = btn.dataset.ticket;
                
                fetch('ClearTicket.aspx', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        match: match,
                        user_id: parseInt(userId),
                        code: code,
                        ticket: ticket
                    })
                })
                .then(response => response.json())
                .then(data => {
                    if (data.msg) alert(data.msg);
                    if (data.isSuccess === 1) loadTickets();
                })
                .catch(error => {
                    console.error('Error:', error);
                    alert('Có lỗi xảy ra khi thanh toán vé cược');
                });
            }
        });
        // Convert ISO datetime-local value sang yyyyMMddHHmm
        function toSqlDateFormat(isoVal) {
            if (!isoVal) return '';
            // isoVal dạng: "2026-04-11T14:30"
            return isoVal.replace(/[-T:]/g, '').substring(0, 12);
        }

        // Init datetime pickers cho filter
        document.addEventListener('DOMContentLoaded', function() {
            function initDatePicker(pickerId, textId, hiddenId) {
                const picker = document.getElementById(pickerId);
                const text = document.getElementById(textId);
                const hidden = document.getElementById(hiddenId);
                if (!picker || !text || !hidden) return;

                picker.addEventListener('change', function() {
                    if (this.value) {
                        const dt = new Date(this.value);
                        const hh = String(dt.getHours()).padStart(2, '0');
                        const mm = String(dt.getMinutes()).padStart(2, '0');
                        const dd = String(dt.getDate()).padStart(2, '0');
                        const MM = String(dt.getMonth() + 1).padStart(2, '0');
                        const yyyy = dt.getFullYear();
                        text.value = `${hh}:${mm} ${dd}/${MM}/${yyyy}`;
                        hidden.value = this.value;
                    } else {
                        text.value = '';
                        hidden.value = '';
                    }
                });

                text.addEventListener('click', function() { picker.click(); });
            }

            initDatePicker('pickerDateFrom', 'filterDateFrom', 'filterDateFromVal');
            initDatePicker('pickerDateTo', 'filterDateTo', 'filterDateToVal');
        });

    </script>
</body>
</html>
