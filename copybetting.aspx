<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    protected string CopyUsersJsonFrom = "[]";
	protected string CopyUsersJsonTo = "[]";
    protected int CurrentUserId = 0;

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null)
        {
            Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
            return;
        }

        if (!IsPostBack)
        {
            LoadCurrentUserId();
            LoadCopyUsersFrom();
			LoadCopyUsersTo();
        }

        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }

    private void LoadCurrentUserId()
    {
        try {
            if (Session["UserID"] != null)
                CurrentUserId = Convert.ToInt32(Session["UserID"]);
        } catch { }
    }
	
	private void LoadCopyUsersFrom()
    {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
				SqlCommand cmd = new SqlCommand("SELECT * FROM dbo.userinfo2 WHERE user_yn = 1 ORDER BY name", conn);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                System.Text.StringBuilder json = new System.Text.StringBuilder();
                json.Append("[");
                bool first = true;
                while (reader.Read()) {
                    if (!first) json.Append(",");
                    first = false;
                    int id = reader.GetInt32(reader.GetOrdinal("id"));
                    string comment = reader["comment"].ToString().Replace("\"", "\\\"");
                    json.AppendFormat("{{\"id\":{0},\"comment\":\"{1}\"}}", id, comment);
                }
                json.Append("]");
                reader.Close();
                CopyUsersJsonFrom = json.ToString();
            }
        } catch { }
    }

    private void LoadCopyUsersTo()
    {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("bet_ticket_user", conn);
                cmd.CommandType = System.Data.CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@userID", CurrentUserId);
                conn.Open();
                SqlDataReader reader = cmd.ExecuteReader();

                System.Text.StringBuilder json = new System.Text.StringBuilder();
                json.Append("[");
                bool first = true;
                while (reader.Read()) {
                    if (!first) json.Append(",");
                    first = false;
                    int id = reader.GetInt32(reader.GetOrdinal("id"));
                    string comment = reader["comment"].ToString().Replace("\"", "\\\"");
                    json.AppendFormat("{{\"id\":{0},\"comment\":\"{1}\"}}", id, comment);
                }
                json.Append("]");
                reader.Close();
                CopyUsersJsonTo = json.ToString();
            }
        } catch { }
    }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover" />
    <title>Chép bài</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" />
    <style>
        body { font-family: sans-serif; height: 100dvh; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .breadcrumb-link { color: #2563eb; text-decoration: none; }
        .breadcrumb-current { color: #4b5563; cursor: default; }
        /* Sidebar không bị lệch và icon thẳng hàng */
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
        /* Cố định kích thước icon */
        .nav-item i {
            width: 20px; 
            text-align: center;
            margin-right: 12px;
        }
    </style>
</head>
<body>
<form runat="server" class="h-full flex flex-col">
    <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
        <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="copybetting" PageTitle="Chép bài" />
    </nav>

    <div class="flex flex-1 overflow-hidden relative">
        <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>
        <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="copybetting" />

        <main class="flex-1 flex flex-col overflow-hidden bg-[#f8fafc]">
            <div class="flex-none bg-white border-b px-4 py-3">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-3 max-w-2xl">
                    <div>
                        <label class="block text-sm font-bold text-gray-700 mb-1">Người cược</label>
                        <select id="ddlCopyUser" class="w-full border rounded-lg p-2.5 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none bg-white"></select>
                    </div>
                    <div>
                        <label class="block text-sm font-bold text-gray-700 mb-1">Chọn học sinh giỏi</label>
                        <select id="ddlCopyUser0" onchange="loadCopyBettingData()" class="w-full border rounded-lg p-2.5 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none bg-white">
                            <option value="0">Chọn học sinh giỏi</option>
                        </select>
                    </div>
                </div>
            </div>

            <div class="flex-1 p-3 lg:p-4 overflow-hidden flex flex-col">
                <div class="h-full bg-white rounded-xl shadow-md border flex flex-col overflow-hidden">
                    <div class="px-4 py-2 border-b bg-gray-50 flex items-center justify-between flex-none">
                        <h4 class="text-sm font-bold text-gray-700">Chi tiết vé cược</h4>
                        <div class="flex gap-2">
                            <button type="button" onclick="saveCopyBetting()"
                                class="px-4 py-2 rounded-lg bg-blue-600 text-white font-bold hover:bg-blue-700 transition text-sm">
                                <i class="fa-solid fa-save mr-1"></i>Lưu
                            </button>
                        </div>
                    </div>

                    <!-- Bảng Desktop -->
                    <div class="flex-1 overflow-auto main-scroll hidden md:block">
                        <table class="w-full text-sm">
                            <thead class="bg-blue-700 text-white sticky top-0 z-10">
                                <tr>
                                    <th class="px-3 py-2 text-center font-bold" style="width:60px">
                                        <input type="checkbox" id="checkAll" onclick="toggleAllCheckboxes(this)" class="w-4 h-4 cursor-pointer" />
                                    </th>
                                    <th class="px-3 py-2 text-left font-bold w-2/3">Vé cược</th>
                                    <th class="px-3 py-2 text-center font-bold">Tiền cược</th>
                                </tr>
                            </thead>
                            <tbody id="copyBettingTableBodyDesktop">
                                <tr><td colspan="3" class="text-center py-4 text-gray-400">Chưa có dữ liệu</td></tr>
                            </tbody>
                        </table>
                    </div>

                    <!-- Bảng Mobile -->
                    <div class="flex-1 overflow-auto main-scroll md:hidden">
                        <table class="w-full text-sm table-fixed">
                            <thead class="bg-blue-700 text-white sticky top-0 z-10">
                                <tr>
                                    <th class="px-2 py-2 text-center font-bold" style="width:40px">
                                        <input type="checkbox" id="checkAllMobile" onclick="toggleAllCheckboxes(this)" class="w-4 h-4 cursor-pointer" />
                                    </th>
                                    <th class="px-2 py-2 text-left font-bold w-1/2">Vé cược</th>
                                    <th class="px-2 py-2 text-center font-bold w-1/2">Tiền cược</th>
                                </tr>
                            </thead>
                            <tbody id="copyBettingTableBodyMobile">
                                <tr><td colspan="3" class="text-center py-4 text-gray-400">Chưa có dữ liệu</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </main>
    </div>
</form>

<script>
    var copyUsersFrom = <%= CopyUsersJsonFrom %>;
	var copyUsersTo = <%= CopyUsersJsonTo %>;
    var currentUserId = <%= CurrentUserId %>;

    window.addEventListener('load', function() {
        // Populate dropdowns
        copyUsersFrom.forEach(function(u) {
            var opt = new Option(u.comment, u.id);
            document.getElementById('ddlCopyUser0').appendChild(opt);
        });
        copyUsersTo.forEach(function(u) {
            var opt = new Option(u.comment, u.id);
            document.getElementById('ddlCopyUser').appendChild(opt);
        });

        // Set default người cược theo user đăng nhập
        if (currentUserId > 0) {
            document.getElementById('ddlCopyUser').value = currentUserId;
        }
    });

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

    function toggleAllCheckboxes(source) {
        const checkboxes = document.querySelectorAll('.copy-betting-checkbox:not(:disabled)');
        checkboxes.forEach(function(cb) { cb.checked = source.checked; });
        var checkAll = document.getElementById('checkAll');
        var checkAllMobile = document.getElementById('checkAllMobile');
        if (checkAll) checkAll.checked = source.checked;
        if (checkAllMobile) checkAllMobile.checked = source.checked;
    }

    function loadCopyBettingData() {
        var userId = document.getElementById('ddlCopyUser0').value;
        if (!userId || userId === '0') {
            document.getElementById('copyBettingTableBodyDesktop').innerHTML = '<tr><td colspan="3" class="text-center py-4 text-gray-400">Chưa có dữ liệu</td></tr>';
            document.getElementById('copyBettingTableBodyMobile').innerHTML = '<tr><td colspan="3" class="text-center py-4 text-gray-400">Chưa có dữ liệu</td></tr>';
            return;
        }

        fetch('GetCopyBettingList.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: parseInt(userId) })
        })
        .then(function(r) { return r.text(); })
        .then(function(text) {
            var data;
            try { data = JSON.parse(text); } catch(e) { console.error('JSON parse error:', e, text); alert('Lỗi parse JSON'); return; }
            var items = Array.isArray(data) ? data : (data.d || data.D || []);
            renderCopyBettingTable(items);
        })
        .catch(function(err) {
            console.error('Error:', err);
            alert('Có lỗi xảy ra khi tải dữ liệu');
        });
    }

    function renderCopyBettingTable(tickets) {
        var desktopBody = document.getElementById('copyBettingTableBodyDesktop');
        var mobileBody = document.getElementById('copyBettingTableBodyMobile');

        if (!tickets || tickets.length === 0) {
            desktopBody.innerHTML = '<tr><td colspan="3" class="text-center py-4 text-gray-400">Không có dữ liệu</td></tr>';
            mobileBody.innerHTML = '<tr><td colspan="3" class="text-center py-4 text-gray-400">Không có dữ liệu</td></tr>';
            return;
        }

        var desktopHtml = '';
        var mobileHtml = '';

        tickets.forEach(function(item, index) {
            var rowStyle = item.rowColor ? 'background-color:' + item.rowColor + ';' : '';
            var textStyle = getCopyTicketCodeTextStyle(item.code || '', item.textColor || '');
            var codeNameHtml = formatCopyTicketCodeName(item.code || '', item.code_name || '');
            var isDisabled = !item.code || item.code === '';

            // Desktop
            desktopHtml += '<tr class="border-b hover:bg-gray-50" style="' + rowStyle + '">';
            desktopHtml += '<td class="hidden"><input type="hidden" id="code_' + index + '" value="' + (item.code || '') + '" /></td>';
            desktopHtml += '<td class="hidden"><input type="hidden" id="match_' + index + '" value="' + (item.match || '') + '" /></td>';
            desktopHtml += '<td class="px-3 py-2 text-center">';
            if (isDisabled) {
                desktopHtml += '<input type="checkbox" class="copy-betting-checkbox w-4 h-4 cursor-not-allowed opacity-50" disabled />';
            } else {
                desktopHtml += '<input type="checkbox" class="copy-betting-checkbox w-4 h-4 cursor-pointer" data-index="' + index + '" />';
            }
            desktopHtml += '</td>';
            desktopHtml += '<td class="px-3 py-2 font-bold" style="' + textStyle + '">' + codeNameHtml + '</td>';
            desktopHtml += '<td class="px-3 py-2 text-right"><div class="flex items-center gap-1 justify-end">';
            desktopHtml += '<button type="button" onclick="decreaseCopyMoney(' + index + ')" class="bg-red-500 hover:bg-red-600 text-white font-bold px-3 py-1 rounded text-sm' + (isDisabled ? ' opacity-50 cursor-not-allowed' : '') + '"' + (isDisabled ? ' disabled' : '') + '>-</button>';
            desktopHtml += '<input type="text" inputmode="numeric" id="copyMoney_' + index + '" class="w-32 border rounded px-2 py-1 text-right font-bold' + (isDisabled ? ' opacity-50 cursor-not-allowed bg-gray-100' : '') + '" value="' + formatMoneyWithSpaces(item.money) + '" data-match="' + (item.match || '') + '" oninput="formatCopyMoneyInput(this,' + index + ')" style="font-size:16px;' + textStyle + '"' + (isDisabled ? ' disabled' : '') + ' />';
            desktopHtml += '<button type="button" onclick="increaseCopyMoney(' + index + ')" class="bg-green-500 hover:bg-green-600 text-white font-bold px-3 py-1 rounded text-sm' + (isDisabled ? ' opacity-50 cursor-not-allowed' : '') + '"' + (isDisabled ? ' disabled' : '') + '>+</button>';
            desktopHtml += '</div></td></tr>';

            // Mobile
            mobileHtml += '<tr class="border-b" style="' + rowStyle + '">';
            mobileHtml += '<td class="hidden"><input type="hidden" id="code_' + index + '_mobile" value="' + (item.code || '') + '" /></td>';
            mobileHtml += '<td class="hidden"><input type="hidden" id="match_' + index + '_mobile" value="' + (item.match || '') + '" /></td>';
            mobileHtml += '<td class="px-2 py-2 text-center">';
            if (isDisabled) {
                mobileHtml += '<input type="checkbox" class="copy-betting-checkbox w-4 h-4 cursor-not-allowed opacity-50" disabled />';
            } else {
                mobileHtml += '<input type="checkbox" class="copy-betting-checkbox w-4 h-4 cursor-pointer" data-index="' + index + '" />';
            }
            mobileHtml += '</td>';
            mobileHtml += '<td class="px-2 py-2 font-bold" style="' + textStyle + '">' + codeNameHtml + '</td>';
            mobileHtml += '<td class="px-2 py-2"><div class="flex items-center gap-1">';
            mobileHtml += '<button type="button" onclick="decreaseCopyMoney(' + index + ')" class="bg-red-500 hover:bg-red-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0' + (isDisabled ? ' opacity-50 cursor-not-allowed' : '') + '"' + (isDisabled ? ' disabled' : '') + '>-</button>';
            mobileHtml += '<input type="text" inputmode="numeric" id="copyMoney_' + index + '_mobile" class="flex-1 border rounded px-1 py-1 text-center font-bold text-xs min-w-0' + (isDisabled ? ' opacity-50 cursor-not-allowed bg-gray-100' : '') + '" value="' + formatMoneyWithSpaces(item.money) + '" data-match="' + (item.match || '') + '" oninput="formatCopyMoneyInput(this,' + index + ')" style="font-size:16px;' + textStyle + '"' + (isDisabled ? ' disabled' : '') + ' />';
            mobileHtml += '<button type="button" onclick="increaseCopyMoney(' + index + ')" class="bg-green-500 hover:bg-green-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0' + (isDisabled ? ' opacity-50 cursor-not-allowed' : '') + '"' + (isDisabled ? ' disabled' : '') + '>+</button>';
            mobileHtml += '</div></td></tr>';
        });

        desktopBody.innerHTML = desktopHtml;
        mobileBody.innerHTML = mobileHtml;

        document.getElementById('checkAll').checked = false;
        document.getElementById('checkAllMobile').checked = false;
    }

    function escapeCopyTicketHtml(value) {
        return String(value || '').replace(/[&<>"']/g, function(ch) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch];
        });
    }

    function formatCopyTicketCodeName(code, codeName) {
        var text = escapeCopyTicketHtml(codeName);
        var parts = String(code || '').split('.');
        if (parts.length < 3) return text;

        var iconMap = {
            FDT: '<i class="fa-solid fa-microchip mr-1 text-sky-600"></i>',
            FDCHEM: '<i class="fa-solid fa-flask-vial mr-1 text-lime-700"></i>',
            FDWIND: '<i class="fa-solid fa-wind mr-1 text-teal-600"></i>',
            FDWATER: '<i class="fa-solid fa-droplet mr-1 text-blue-600"></i>',
            FDFIRE: '<i class="fa-solid fa-fire-flame-curved mr-1 text-orange-600"></i>',
            FDEARTH: '<i class="fa-solid fa-mountain mr-1 text-amber-700"></i>'
        };
        return iconMap[parts[1]] ? iconMap[parts[1]] + text : text;
    }

    function getCopyTicketCodeTextStyle(code, fallbackColor) {
        var parts = String(code || '').split('.');
        var colorMap = {
            FDT: '#0284c7',
            FDCHEM: '#4d7c0f',
            FDWIND: '#0f766e',
            FDWATER: '#2563eb',
            FDFIRE: '#ea580c',
            FDEARTH: '#92400e'
        };
        var color = parts.length >= 3 && colorMap[parts[1]] ? colorMap[parts[1]] : fallbackColor;
        return color ? 'color:' + color + ';' : '';
    }

    function formatMoneyWithSpaces(value) {
        var num = parseInt(value) || 0;
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    }

    function parseCopyMoney(val) {
        return parseInt(val.replace(/\s/g, '')) || 0;
    }

    function formatCopyMoneyInput(input, index) {
        var value = input.value.replace(/\s/g, '').replace(/[^\d]/g, '');
        input.value = value ? formatMoneyWithSpaces(value) : '0';
        syncCopyMoney(index);
    }

    function increaseCopyMoney(index) {
        var d = document.getElementById('copyMoney_' + index);
        var m = document.getElementById('copyMoney_' + index + '_mobile');
        var cur = d ? parseCopyMoney(d.value) : (m ? parseCopyMoney(m.value) : 0);
        cur += 50000;
        if (d) d.value = formatMoneyWithSpaces(cur);
        if (m) m.value = formatMoneyWithSpaces(cur);
        recalcMatchTotalByIndex(index);
    }

    function decreaseCopyMoney(index) {
        var d = document.getElementById('copyMoney_' + index);
        var m = document.getElementById('copyMoney_' + index + '_mobile');
        var cur = d ? parseCopyMoney(d.value) : (m ? parseCopyMoney(m.value) : 0);
        cur = Math.max(0, cur - 50000);
        if (d) d.value = formatMoneyWithSpaces(cur);
        if (m) m.value = formatMoneyWithSpaces(cur);
        recalcMatchTotalByIndex(index);
    }

    function syncCopyMoney(index) {
        var d = document.getElementById('copyMoney_' + index);
        var m = document.getElementById('copyMoney_' + index + '_mobile');
        if (d && m) {
            if (document.activeElement === d) m.value = d.value;
            else if (document.activeElement === m) d.value = m.value;
        }
        var matchInput = document.getElementById('match_' + index);
        if (matchInput) recalcMatchTotal(matchInput.value);
    }

    function recalcMatchTotalByIndex(index) {
        var matchInput = document.getElementById('match_' + index);
        if (matchInput) recalcMatchTotal(matchInput.value);
    }

    function recalcMatchTotal(matchValue) {
        if (!matchValue) return;
        var detailInputs = document.querySelectorAll('#copyBettingTableBodyDesktop input[type="text"][data-match="' + matchValue + '"]:not(:disabled)');
        var total = 0;
        detailInputs.forEach(function(inp) { total += parseCopyMoney(inp.value); });
        var td = document.querySelector('#copyBettingTableBodyDesktop input[type="text"][data-match="' + matchValue + '"]:disabled');
        var tm = document.querySelector('#copyBettingTableBodyMobile input[type="text"][data-match="' + matchValue + '"]:disabled');
        if (td) td.value = formatMoneyWithSpaces(total);
        if (tm) tm.value = formatMoneyWithSpaces(total);
    }

    function saveCopyBetting() {
        var userId = document.getElementById('ddlCopyUser').value;
        if (!userId || userId === '0') {
            alert('Vui lòng chọn người cược');
            return;
        }

        var isDesktop = window.innerWidth >= 768;
        var bodyId = isDesktop ? 'copyBettingTableBodyDesktop' : 'copyBettingTableBodyMobile';
        var suffix = isDesktop ? '' : '_mobile';
        var checkboxes = document.querySelectorAll('#' + bodyId + ' .copy-betting-checkbox:checked:not(:disabled)');

        if (checkboxes.length === 0) {
            alert('Vui lòng chọn ít nhất một vé cược');
            return;
        }

        var details = [];
        checkboxes.forEach(function(cb) {
            var index = cb.getAttribute('data-index');
            var codeInput = document.getElementById('code_' + index + suffix);
            var matchInput = document.getElementById('match_' + index + suffix);
            var moneyInput = document.getElementById('copyMoney_' + index + suffix);
            if (codeInput && matchInput && moneyInput) {
                details.push({
                    code: codeInput.value,
                    match: matchInput.value,
                    money: parseCopyMoney(moneyInput.value),
                    selected: true
                });
            }
        });

        if (details.length === 0) {
            alert('Không có dữ liệu hợp lệ để lưu');
            return;
        }

        fetch('SaveCopyBetting.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ userId: parseInt(userId), details: details })
        })
        .then(function(r) { return r.json(); })
        .then(function(data) {
            if (data.msg) alert(data.msg);
            if (data.isSuccess === 1) window.location.reload();
        })
        .catch(function(err) {
            console.error('Error:', err);
            alert('Có lỗi xảy ra khi lưu dữ liệu');
        });
    }
</script>
</body>
</html>
