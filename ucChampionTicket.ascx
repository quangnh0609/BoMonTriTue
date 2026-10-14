<%@ Control Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Collections.Generic" %>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<script runat="server">
    protected int ChampCurrentUserId = 0;
    protected bool ChampCurrentUserIsAdmin = false;
    protected string ChampTicketUsersJson = "[]";
    protected string ChampTicketMatchesJson = "[]";

    public class ChampTicketMatchItem
    {
        public string season { get; set; }
        public string season_name { get; set; }
        public string time { get; set; }
        public string display_time { get; set; }
        public int user_host { get; set; }
        public string label { get; set; }
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack)
        {
            LoadChampCurrentUserId();
            LoadChampCurrentUserIsAdmin();
            LoadChampTicketUsers();
            LoadChampTicketMatches();
        }
    }

    private void LoadChampCurrentUserId()
    {
        try {
            if (Session["UserID"] != null)
                ChampCurrentUserId = Convert.ToInt32(Session["UserID"]);
            else if (Session["UserName"] != null)
            {
                string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
                using (SqlConnection conn = new SqlConnection(connStr))
                {
                    SqlCommand cmd = new SqlCommand("SELECT id FROM dbo.userinfo2 WHERE name = @name", conn);
                    cmd.Parameters.AddWithValue("@name", Session["UserName"].ToString());
                    conn.Open();
                    object result = cmd.ExecuteScalar();
                    if (result != null) ChampCurrentUserId = Convert.ToInt32(result);
                }
            }
        } catch { }
    }

    private void LoadChampCurrentUserIsAdmin()
    {
        try {
            if (ChampCurrentUserId == 0) return;
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand("SELECT ISNULL(admin, 0) FROM dbo.userinfo2 WHERE id = @id", conn))
            {
                cmd.Parameters.Add("@id", SqlDbType.Int).Value = ChampCurrentUserId;
                conn.Open();
                object result = cmd.ExecuteScalar();
                ChampCurrentUserIsAdmin = result != null && result != DBNull.Value && Convert.ToBoolean(result);
            }
        } catch { }
    }

    private void LoadChampTicketUsers()
    {
        try {
            if (ChampCurrentUserId == 0) return;
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand("bet_ticket_user", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@userID", ChampCurrentUserId);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                System.Text.StringBuilder json = new System.Text.StringBuilder("[");
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
                ChampTicketUsersJson = json.ToString();
            }
        } catch { }
    }

    private void LoadChampTicketMatches()
    {
        try {
            if (ChampCurrentUserId == 0) return;
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            using (SqlCommand cmd = new SqlCommand(@"
                SELECT x.season, ISNULL(s.season_name, '') AS season_name, x.time, x.user_host
                FROM (
                    SELECT season, time, MAX(user_host) AS user_host,
                        CASE WHEN DATEDIFF(MINUTE, MAX(time_lock), GETDATE()) <= 0 THEN 1 ELSE 2 END AS status
                    FROM bet_champion
                    GROUP BY season, time
                ) x
                LEFT JOIN bet_season s ON x.season = s.season
                WHERE @admin = 1 OR x.status = 1 OR x.user_host = @userID
                ORDER BY x.time DESC, x.season", conn))
            {
                cmd.Parameters.Add("@admin", SqlDbType.Bit).Value = ChampCurrentUserIsAdmin;
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = ChampCurrentUserId;
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();
                List<ChampTicketMatchItem> matches = new List<ChampTicketMatchItem>();
                while (reader.Read())
                {
                    DateTime time = reader["time"] != DBNull.Value ? Convert.ToDateTime(reader["time"]) : DateTime.MinValue;
                    string season = reader["season"] != DBNull.Value ? Convert.ToString(reader["season"]) : "";
                    string seasonName = reader["season_name"] != DBNull.Value ? Convert.ToString(reader["season_name"]) : "";
                    string timeValue = time == DateTime.MinValue ? "" : time.ToString("yyyy-MM-dd");
                    string displayTime = time == DateTime.MinValue ? "" : time.ToString("dd/MM/yyyy");
                    matches.Add(new ChampTicketMatchItem {
                        season = season,
                        season_name = seasonName,
                        time = timeValue,
                        display_time = displayTime,
                        user_host = reader["user_host"] != DBNull.Value ? Convert.ToInt32(reader["user_host"]) : 0,
                        label = ((seasonName == "" ? season : seasonName) + " " + displayTime).Trim()
                    });
                }
                reader.Close();
                ChampTicketMatchesJson = new JavaScriptSerializer().Serialize(matches);
            }
        } catch { }
    }
</script>

<div id="modalChampionTicket" class="fixed inset-0 bg-gray-900/80 z-[60] hidden flex items-center justify-center p-4 font-sans">
    <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-2xl flex flex-col overflow-hidden" style="max-height: 90vh;">

        <div class="bg-gradient-to-r from-green-600 to-green-700 px-6 py-4 text-white flex justify-between items-center shrink-0 shadow-lg">
            <h3 class="font-bold flex items-center text-[16px]">
                <i class="fa-solid fa-trophy mr-3 text-lg"></i> Đặt cược chung cuộc
            </h3>
            <button type="button" onclick="closeChampionTicketModal()" class="text-white hover:text-gray-200 transition-colors">
                <i class="fa-solid fa-xmark text-2xl"></i>
            </button>
        </div>

        <div class="p-6 flex-grow overflow-auto">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div id="champTicketUserField" class="relative">
                    <label class="block text-sm font-bold text-gray-700 mb-2">Người cược <span class="text-red-600">*</span></label>
                    <input type="text" id="champTicketUserSearch"
                        class="w-full border-2 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-green-500 outline-none"
                        placeholder="Nhập để tìm kiếm..."
                        autocomplete="off"
                        onfocus="showChampTicketUserDropdown()"
                        oninput="filterChampTicketUsers()" />
                    <input type="hidden" id="champTicketUserId" />
                    <input type="hidden" id="champTicketSeason" />
                    <input type="hidden" id="champTicketTime" />
                    <div id="champTicketUserDropdown" class="hidden absolute z-50 w-full mt-1 bg-white border-2 rounded-lg shadow-lg max-h-60 overflow-auto"></div>
                    <div id="champTicketUserError" class="hidden text-red-600 text-xs font-bold mt-1">
                        <i class="fa-solid fa-circle-exclamation mr-1"></i>Vui lòng chọn người cược
                    </div>
                </div>
                <div id="champTicketMatchField" class="relative">
                    <label class="block text-sm font-bold text-gray-700 mb-2">Trận champion <span class="text-red-600">*</span></label>
                    <input type="text" id="champTicketMatchSearch"
                        class="w-full border-2 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-green-500 outline-none"
                        placeholder="Nhập để tìm kiếm..."
                        autocomplete="off"
                        onfocus="showChampTicketMatchDropdown()"
                        oninput="filterChampTicketMatches()" />
                    <div id="champTicketMatchDropdown" class="hidden absolute z-50 w-full mt-1 bg-white border-2 rounded-lg shadow-lg max-h-60 overflow-auto"></div>
                    <div id="champTicketMatchError" class="hidden text-red-600 text-xs font-bold mt-1">
                        <i class="fa-solid fa-circle-exclamation mr-1"></i>Vui lòng chọn trận champion
                    </div>
                </div>
            </div>

            <!-- Bảng chi tiết Desktop -->
            <div class="border-t pt-4">
                <div class="border rounded-lg overflow-hidden hidden md:block">
                    <div class="max-h-96 overflow-y-auto">
                        <table class="w-full text-sm">
                            <thead class="bg-gray-100 sticky top-0">
                                <tr>
                                    <th class="px-3 py-2 text-center font-bold text-gray-700 w-2/3">Vé cược</th>
                                    <th class="px-3 py-2 text-center font-bold text-gray-700">Tiền cược</th>
                                </tr>
                            </thead>
                            <tbody id="champTicketCodesBodyDesktop">
                                <tr><td colspan="2" class="px-3 py-4 text-center text-gray-400">Chọn trận đấu để tải vé cược</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Bảng Mobile -->
                <div class="border rounded-lg overflow-hidden md:hidden">
                    <div class="max-h-96 overflow-y-auto">
                        <table class="w-full text-sm table-fixed">
                            <thead class="bg-gray-100 sticky top-0">
                                <tr>
                                    <th class="px-2 py-2 text-center font-bold text-gray-700 w-1/2">Vé cược</th>
                                    <th class="px-2 py-2 text-center font-bold text-gray-700 w-1/2">Tiền cược</th>
                                </tr>
                            </thead>
                            <tbody id="champTicketCodesBodyMobile">
                                <tr><td colspan="2" class="px-2 py-4 text-center text-gray-400">Chọn trận đấu để tải vé cược</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="px-6 py-4 bg-gradient-to-r from-gray-50 to-gray-100 border-t flex justify-end items-center shrink-0 gap-3">
            <button type="button" onclick="closeChampionTicketModal()"
                class="px-5 py-2.5 rounded-lg font-bold text-gray-700 bg-white border-2 border-gray-300 hover:bg-gray-100 hover:border-gray-400 transition-all text-sm shadow-md active:scale-95">
                <i class="fa-solid fa-times mr-2"></i>Hủy bỏ
            </button>
            <button type="button" id="btnSaveChampionTicket" onclick="saveChampionTicketData()"
                class="px-5 py-2.5 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg font-bold hover:from-green-700 hover:to-green-800 shadow-lg active:scale-95 text-sm cursor-pointer transition-all">
                <i class="fa-solid fa-check mr-2"></i>Lưu lại
            </button>
        </div>
    </div>
</div>

<script>
    var champTicketUsers  = <%= ChampTicketUsersJson %>;
    var champTicketMatches = <%= ChampTicketMatchesJson %>;
    var champCurrentUserId = <%= ChampCurrentUserId %>;
    var champCurrentUserIsAdmin = <%= ChampCurrentUserIsAdmin ? "true" : "false" %>;
    var champCanSelectAllUsers = false;
    var scrollPositionChampTicket = 0;

    window.addEventListener('load', function () {
        renderChampTicketUserDropdown();
        renderChampTicketMatchDropdown();
        selectChampCurrentUser(false);
    });

    function escapeChampHtml(value) {
        return String(value || '').replace(/[&<>"']/g, function(ch) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch];
        });
    }

    function escapeChampJs(value) {
        return String(value || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\r/g, '\\r').replace(/\n/g, '\\n');
    }

    function getChampCurrentUser() {
        const user = champTicketUsers.find(u => parseInt(u.id) === parseInt(champCurrentUserId));
        if (user) return user;
        return champCurrentUserId > 0 ? { id: champCurrentUserId, name: '', comment: '' } : null;
    }

    function selectChampCurrentUser(reloadCodes) {
        const user = getChampCurrentUser();
        if (!user) return;
        selectChampTicketUser(user.id, user.comment || user.name || '', reloadCodes === true);
    }

    function findChampTicketMatch(season, time) {
        return champTicketMatches.find(m => String(m.season || '') === String(season || '') && String(m.time || '') === String(time || '')) || null;
    }

    function setChampTicketUserFieldVisible(isVisible) {
        const userField = document.getElementById('champTicketUserField');
        const matchField = document.getElementById('champTicketMatchField');
        const userDropdown = document.getElementById('champTicketUserDropdown');
        if (userField) userField.classList.toggle('hidden', !isVisible);
        if (matchField) matchField.classList.toggle('md:col-span-2', !isVisible);
        if (!isVisible && userDropdown) userDropdown.classList.add('hidden');
    }

    function applyChampTicketUserPermission(season, time, explicitCanSelectAllUsers) {
        const match = findChampTicketMatch(season, time);
        const isHost = match && parseInt(match.user_host || 0) === parseInt(champCurrentUserId || 0);
        const canSelect = champCurrentUserIsAdmin || explicitCanSelectAllUsers === true || isHost;
        setChampTicketUserFieldVisible(canSelect);
        if (!canSelect || !document.getElementById('champTicketUserId').value) selectChampCurrentUser(false);
        return canSelect;
    }

    // ── Dropdown Users ────────────────────────────────────────────────────────
    function renderChampTicketUserDropdown(data) {
        const dropdown = document.getElementById('champTicketUserDropdown');
        if (!dropdown) return;
        const list = data || champTicketUsers;
        let html = '';
        list.forEach(item => {
            const txt = item.comment || item.name || '';
            html += `<div class="p-3 hover:bg-green-50 cursor-pointer font-bold text-sm border-b last:border-b-0" onclick="selectChampTicketUser(${item.id},'${escapeChampJs(txt)}')">${escapeChampHtml(txt)}</div>`;
        });
        dropdown.innerHTML = html || '<div class="p-3 text-gray-400 text-sm">Không tìm thấy kết quả</div>';
    }

    function showChampTicketUserDropdown() {
        const userField = document.getElementById('champTicketUserField');
        if (userField && userField.classList.contains('hidden')) return;
        document.getElementById('champTicketUserDropdown').classList.remove('hidden');
    }

    function filterChampTicketUsers() {
        const userField = document.getElementById('champTicketUserField');
        if (userField && userField.classList.contains('hidden')) return;
        const q = document.getElementById('champTicketUserSearch').value.toLowerCase();
        if (!q) document.getElementById('champTicketUserId').value = '';
        renderChampTicketUserDropdown(champTicketUsers.filter(u => (u.comment || u.name || '').toLowerCase().includes(q)));
        showChampTicketUserDropdown();
    }

    function selectChampTicketUser(id, text, reloadCodes) {
        document.getElementById('champTicketUserId').value = id;
        document.getElementById('champTicketUserSearch').value = text.trim();
        document.getElementById('champTicketUserDropdown').classList.add('hidden');
        document.getElementById('champTicketUserError').classList.add('hidden');
        const season = document.getElementById('champTicketSeason').value;
        const time   = document.getElementById('champTicketTime').value;
        if (reloadCodes !== false) loadChampTicketCodes(season, time, id);
    }

    function renderChampTicketMatchDropdown(data) {
        const dropdown = document.getElementById('champTicketMatchDropdown');
        if (!dropdown) return;
        const list = data || champTicketMatches;
        let html = '';
        list.forEach(item => {
            const label = item.label || ((item.season_name || item.season || '') + ' ' + (item.display_time || '')).trim();
            html += `<div class="p-3 hover:bg-green-50 cursor-pointer font-bold text-sm border-b last:border-b-0" onclick="selectChampTicketMatch('${escapeChampJs(item.season)}','${escapeChampJs(item.time)}','${escapeChampJs(label)}')">${escapeChampHtml(label)}</div>`;
        });
        dropdown.innerHTML = html || '<div class="p-3 text-gray-400 text-sm">Không tìm thấy kết quả</div>';
    }

    function showChampTicketMatchDropdown() {
        document.getElementById('champTicketMatchDropdown').classList.remove('hidden');
        document.getElementById('champTicketUserDropdown').classList.add('hidden');
    }

    function filterChampTicketMatches() {
        const q = document.getElementById('champTicketMatchSearch').value.toLowerCase();
        if (!q) {
            document.getElementById('champTicketSeason').value = '';
            document.getElementById('champTicketTime').value = '';
        }
        renderChampTicketMatchDropdown(champTicketMatches.filter(m => (m.label || m.season || '').toLowerCase().includes(q)));
        showChampTicketMatchDropdown();
    }

    function selectChampTicketMatch(season, time, label) {
        document.getElementById('champTicketSeason').value = season || '';
        document.getElementById('champTicketTime').value = time || '';
        document.getElementById('champTicketMatchSearch').value = (label || season || '').trim();
        document.getElementById('champTicketMatchDropdown').classList.add('hidden');
        document.getElementById('champTicketMatchError').classList.add('hidden');
        applyChampTicketUserPermission(season, time, champCanSelectAllUsers);
        loadChampTicketCodes(season, time, document.getElementById('champTicketUserId').value);
    }

    // ── Load ticket codes ─────────────────────────────────────────────────────
    function loadChampTicketCodes(season, time, userId) {
        if (!season) { renderChampEmptyTable(); return; }
        if (!userId) userId = document.getElementById('champTicketUserId').value;
        fetch('GetChampionTicketCodes.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ season: season, time: time || '', userId: userId ? parseInt(userId) : 0 })
        })
        .then(r => r.json())
        .then(data => { data.d ? renderChampTicketCodes(data.d) : renderChampEmptyTable(); })
        .catch(() => renderChampEmptyTable());
    }

    function renderChampEmptyTable() {
        const empty = '<tr><td colspan="2" class="px-3 py-4 text-center text-gray-400">Không có dữ liệu</td></tr>';
        document.getElementById('champTicketCodesBodyDesktop').innerHTML = empty;
        document.getElementById('champTicketCodesBodyMobile').innerHTML  = empty;
    }

    function renderChampTicketCodes(codes) {
        if (!codes || codes.length === 0) { renderChampEmptyTable(); return; }
        let dHtml = '', mHtml = '';
        codes.forEach((item, i) => {
            const code      = item.code      || '';
            const code_name = item.code_name || '';
            const money     = item.money     || 0;
            const rowStyle  = item.rowColor  ? `background-color:${item.rowColor};` : '';
            const txtStyle  = item.textColor ? `color:${item.textColor};`           : '';

            dHtml += `<tr class="border-b hover:bg-gray-50" style="${rowStyle}">
                <td class="px-3 py-2 font-bold hidden"><input type="hidden" id="champ_code_${i}" value="${code}" /></td>
                <td class="px-3 py-2 font-bold" style="${txtStyle}">${code_name}</td>
                <td class="px-3 py-2 text-right">
                    <div class="flex items-center gap-1 justify-end">
                        <button type="button" onclick="decreaseChampMoney(${i})" class="bg-red-500 hover:bg-red-600 text-white font-bold px-3 py-1 rounded text-sm">-</button>
                        <input type="text" inputmode="numeric" id="champ_money_${i}" class="w-32 border rounded px-2 py-1 text-right font-bold" style="font-size:16px" value="${formatChampMoney(money)}" oninput="formatChampMoneyInput(this)" />
                        <button type="button" onclick="increaseChampMoney(${i})" class="bg-green-500 hover:bg-green-600 text-white font-bold px-3 py-1 rounded text-sm">+</button>
                    </div>
                </td>
            </tr>`;

            mHtml += `<tr class="border-b" style="${rowStyle}">
                <td class="px-2 py-2 font-bold hidden"><input type="hidden" id="champ_code_${i}_mobile" value="${code}" /></td>
                <td class="px-2 py-2 font-bold" style="${txtStyle}">${code_name}</td>
                <td class="px-2 py-2">
                    <div class="flex items-center gap-1">
                        <button type="button" onclick="decreaseChampMoney(${i})" class="bg-red-500 hover:bg-red-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0">-</button>
                        <input type="text" inputmode="numeric" id="champ_money_${i}_mobile" class="flex-1 border rounded px-1 py-1 text-center font-bold text-xs min-w-0" style="font-size:16px" value="${formatChampMoney(money)}" oninput="formatChampMoneyInput(this)" />
                        <button type="button" onclick="increaseChampMoney(${i})" class="bg-green-500 hover:bg-green-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0">+</button>
                    </div>
                </td>
            </tr>`;
        });
        document.getElementById('champTicketCodesBodyDesktop').innerHTML = dHtml;
        document.getElementById('champTicketCodesBodyMobile').innerHTML  = mHtml;
    }

    // ── Money helpers ─────────────────────────────────────────────────────────
    function formatChampMoney(v) {
        return (parseInt(v) || 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    }
    function parseChampMoney(v) {
        return parseInt((v || '0').replace(/\s/g, '')) || 0;
    }
    function formatChampMoneyInput(input) {
        let v = input.value.replace(/\s/g, '').replace(/[^\d]/g, '');
        input.value = v ? formatChampMoney(v) : '0';
        syncChampMoneyPair(input);
    }
    function syncChampMoneyPair(input) {
        const m = input.id.match(/^champ_money_(\d+)(_mobile)?$/);
        if (!m) return;
        const pairId = 'champ_money_' + m[1] + (m[2] === '_mobile' ? '' : '_mobile');
        const pair = document.getElementById(pairId);
        if (pair && pair.value !== input.value) pair.value = input.value;
    }
    function increaseChampMoney(i) {
        const d = document.getElementById('champ_money_' + i);
        const m = document.getElementById('champ_money_' + i + '_mobile');
        const cur = d ? parseChampMoney(d.value) : (m ? parseChampMoney(m.value) : 0);
        const nv = formatChampMoney(cur + 50000);
        if (d) d.value = nv;
        if (m) m.value = nv;
    }
    function decreaseChampMoney(i) {
        const d = document.getElementById('champ_money_' + i);
        const m = document.getElementById('champ_money_' + i + '_mobile');
        const cur = d ? parseChampMoney(d.value) : (m ? parseChampMoney(m.value) : 0);
        const nv = formatChampMoney(Math.max(0, cur - 50000));
        if (d) d.value = nv;
        if (m) m.value = nv;
    }

    // ── Open / Close modal ────────────────────────────────────────────────────
    function openChampionTicketModal(season, time, canSelectAllUsers) {
        const modal = document.getElementById('modalChampionTicket');
        if (!modal) return;
        champCanSelectAllUsers = canSelectAllUsers === true;
        scrollPositionChampTicket = window.pageYOffset || document.documentElement.scrollTop;
        document.body.style.position = 'fixed';
        document.body.style.top = `-${scrollPositionChampTicket}px`;
        document.body.style.width = '100%';
        document.body.style.overflow = 'hidden';
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        document.getElementById('champTicketUserError').classList.add('hidden');
        document.getElementById('champTicketMatchError').classList.add('hidden');

        const match = findChampTicketMatch(season, time);
        if (match) {
            selectChampTicketMatch(match.season, match.time, match.label);
        } else if (season) {
            document.getElementById('champTicketSeason').value = season || '';
            document.getElementById('champTicketTime').value = time || '';
            document.getElementById('champTicketMatchSearch').value = season || '';
            document.getElementById('champTicketMatchDropdown').classList.add('hidden');
            applyChampTicketUserPermission(season, time, champCanSelectAllUsers);
            loadChampTicketCodes(season, time, document.getElementById('champTicketUserId').value);
        } else {
            document.getElementById('champTicketSeason').value = '';
            document.getElementById('champTicketTime').value = '';
            document.getElementById('champTicketMatchSearch').value = '';
            applyChampTicketUserPermission('', '', champCanSelectAllUsers);
            renderChampEmptyTable();
        }
    }

    function closeChampionTicketModal() {
        const modal = document.getElementById('modalChampionTicket');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        window.scrollTo(0, scrollPositionChampTicket);
    }

    // ── Close on outside click ────────────────────────────────────────────────
    document.addEventListener('click', function (e) {
        if (!e.target.closest('#champTicketUserSearch') && !e.target.closest('#champTicketUserDropdown'))
            document.getElementById('champTicketUserDropdown').classList.add('hidden');
        if (!e.target.closest('#champTicketMatchSearch') && !e.target.closest('#champTicketMatchDropdown'))
            document.getElementById('champTicketMatchDropdown').classList.add('hidden');
    });

    // ── Save ──────────────────────────────────────────────────────────────────
    function saveChampionTicketData() {
        const userId = document.getElementById('champTicketUserId').value;
        const season = document.getElementById('champTicketSeason').value;
        const time   = document.getElementById('champTicketTime').value;
        document.getElementById('champTicketUserError').classList.add('hidden');
        document.getElementById('champTicketMatchError').classList.add('hidden');
        if (!userId) { document.getElementById('champTicketUserError').classList.remove('hidden'); return; }
        if (!season) { document.getElementById('champTicketMatchError').classList.remove('hidden'); return; }

        const details = [];
        const tbody = document.getElementById('champTicketCodesBodyDesktop');
        if (tbody) {
            Array.from(tbody.getElementsByTagName('tr')).forEach((_, i) => {
                const codeEl  = document.getElementById('champ_code_' + i);
                const moneyEl = document.getElementById('champ_money_' + i);
                if (codeEl && moneyEl) {
                    const money = parseChampMoney(moneyEl.value);
                    if (money > 0) details.push({ code: codeEl.value, money: money });
                }
            });
        }
        if (details.length === 0) { alert('Vui lòng nhập tiền cược cho ít nhất một vé'); return; }

        const btn = document.getElementById('btnSaveChampionTicket');
        btn.disabled = true;
        btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin mr-2"></i>Đang lưu...';

        fetch('SaveChampionTicket.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: parseInt(userId), season: season, time: time, details: details })
        })
        .then(r => r.json())
        .then(data => {
            if (data.msg) alert(data.msg);
            if (data.isSuccess === 1) closeChampionTicketModal();
        })
        .catch(() => alert('Có lỗi xảy ra khi lưu dữ liệu'))
        .finally(() => {
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-check mr-2"></i>Lưu lại';
        });
    }
</script>
