<%@ Control Language="C#" AutoEventWireup="true" %>
<div id="modalTicket" class="fixed inset-0 bg-gray-900/80 z-[60] hidden flex items-center justify-center p-4 font-sans">
    <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-2xl flex flex-col overflow-hidden animate-fade-in" style="max-height: 90vh; touch-action: manipulation;">
        
        <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4 text-white flex justify-between items-center shrink-0 shadow-lg">
            <h3 class="font-bold flex items-center text-[16px]">
                <i class="fa-solid fa-ticket mr-3 text-lg"></i> Đặt cược
            </h3>
            <button type="button" onclick="closeTicketModal()" class="text-white hover:text-gray-200 transition-colors">
                <i class="fa-solid fa-xmark text-2xl"></i>
            </button>
        </div>
        
        <div class="p-6 flex-grow overflow-auto">
            <div id="ticketFormGrid" class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
                <div id="ticketUserField" class="relative">
                    <label class="block text-sm font-bold text-gray-700 mb-2">Người cược <span class="text-red-600">*</span></label>
                    <input type="text" id="ticketUserSearch" 
                        class="w-full border-2 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
                        placeholder="Nhập để tìm kiếm..." 
                        autocomplete="off"
                        onfocus="showTicketUserDropdown()" 
                        oninput="filterTicketUsers()" />
                    <input type="hidden" id="ticketUserId" />
                    <div id="ticketUserDropdown" class="hidden absolute z-50 w-full mt-1 bg-white border-2 rounded-lg shadow-lg max-h-60 overflow-auto">
                    </div>
                    <div id="ticketUserError" class="hidden text-red-600 text-xs font-bold mt-1">
                        <i class="fa-solid fa-circle-exclamation mr-1"></i>Vui lòng chọn người cược
                    </div>
                </div>
                
                <div id="ticketMatchField" class="relative">
                    <label class="block text-sm font-bold text-gray-700 mb-2">Trận đấu <span class="text-red-600">*</span></label>
                    <input type="text" id="ticketMatchSearch" 
                        class="w-full border-2 rounded-lg p-3 text-sm font-bold focus:ring-2 focus:ring-blue-500 outline-none"
                        placeholder="Nhập để tìm kiếm..." 
                        autocomplete="off"
                        onfocus="showTicketMatchDropdown()" 
                        oninput="filterTicketMatches()" />
                    <input type="hidden" id="ticketMatchId" />
                    <div id="ticketMatchDropdown" class="hidden absolute z-50 w-full mt-1 bg-white border-2 rounded-lg shadow-lg max-h-60 overflow-auto">
                    </div>
                    <div id="ticketMatchError" class="hidden text-red-600 text-xs font-bold mt-1">
                        <i class="fa-solid fa-circle-exclamation mr-1"></i>Vui lòng chọn trận đấu
                    </div>
                </div>
            </div>
            
            <!-- Bảng chi tiết -->
            <div class="border-t pt-4">
                <!-- Bảng Desktop -->
                <div class="border rounded-lg overflow-hidden hidden md:block">
                    <div class="max-h-96 overflow-y-auto">
                        <table class="w-full text-sm">
                            <thead class="bg-gray-100 sticky top-0">
                                <tr>
                                    <th class="px-3 py-2 text-center font-bold text-gray-700 hidden">Mã vé cược</th>
                                    <th class="px-3 py-2 text-center font-bold text-gray-700 w-2/3">Vé cược</th>
                                    <th class="px-3 py-2 text-center font-bold text-gray-700">Tiền cược</th>
                                </tr>
                            </thead>
                            <tbody id="ticketCodesBodyDesktop">
                                <tr class="border-b hover:bg-gray-50">
                                    <td class="px-3 py-2 font-bold hidden">
                                        <input type="hidden" id="code_0" value="" />
                                    </td>
                                    <td class="px-3 py-2 font-bold">Thắng (Full Time)</td>
                                    <td class="px-3 py-2 text-right">
                                        <div class="flex items-center gap-1 justify-end">
                                            <button type="button" onclick="decreaseMoney(0)" class="bg-red-500 hover:bg-red-600 text-white font-bold px-3 py-1 rounded text-sm">-</button>
                                            <input type="text" inputmode="numeric" id="money_0" class="w-32 border rounded px-2 py-1 text-right font-bold" style="font-size:16px" value="0" oninput="formatMoneyInput(this)" />
                                            <button type="button" onclick="increaseMoney(0)" class="bg-green-500 hover:bg-green-600 text-white font-bold px-3 py-1 rounded text-sm">+</button>
                                        </div>
                                    </td>
                                </tr>
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
                                    <th class="px-2 py-2 text-center font-bold text-gray-700 hidden">Mã vé cược</th>
                                    <th class="px-2 py-2 text-center font-bold text-gray-700 w-1/2">Vé cược</th>
                                    <th class="px-2 py-2 text-center font-bold text-gray-700 w-1/2">Tiền cược</th>
                                </tr>
                            </thead>
                            <tbody id="ticketCodesBodyMobile">
                                <tr class="border-b">
                                    <td class="px-2 py-2 font-bold hidden">
                                        <input type="hidden" id="code_0_mobile" value="" />
                                    </td>
                                    <td class="px-2 py-2 font-bold">Thắng (Full Time)</td>
                                    <td class="px-2 py-2">
                                        <div class="flex items-center gap-1">
                                            <button type="button" onclick="decreaseMoney(0)" class="bg-red-500 hover:bg-red-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0">-</button>
                                            <input type="text" inputmode="numeric" id="money_0_mobile" class="flex-1 border rounded px-1 py-1 text-center font-bold text-xs min-w-0" style="font-size:16px" value="0" oninput="formatMoneyInput(this)" />
                                            <button type="button" onclick="increaseMoney(0)" class="bg-green-500 hover:bg-green-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0">+</button>
                                        </div>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>

        <div class="px-6 py-4 bg-gradient-to-r from-gray-50 to-gray-100 border-t flex justify-end items-center shrink-0 gap-3">
            <button type="button" onclick="closeTicketModal()" 
                class="px-5 py-2.5 rounded-lg font-bold text-gray-700 bg-white border-2 border-gray-300 hover:bg-gray-100 hover:border-gray-400 transition-all text-sm shadow-md active:scale-95">
                <i class="fa-solid fa-times mr-2"></i>Hủy bỏ
            </button>
            <button type="button" id="btnSaveTicket" onclick="saveTicketData()"
                class="px-5 py-2.5 bg-gradient-to-r from-blue-600 to-blue-700 text-white rounded-lg font-bold hover:from-blue-700 hover:to-blue-800 shadow-lg active:scale-95 text-sm cursor-pointer transition-all">
                <i class="fa-solid fa-check mr-2"></i>Lưu lại
            </button>
        </div>
    </div>
</div>

<script>
    // Chặn double-tap zoom trên toàn bộ popup Cược
    (function() {
        var lastTouchEnd = 0;
        document.addEventListener('touchend', function(e) {
            if (e.target.closest('#modalTicket')) {
                var now = Date.now();
                if (now - lastTouchEnd < 300) e.preventDefault();
                lastTouchEnd = now;
            }
        }, { passive: false });
        document.addEventListener('dblclick', function(e) {
            if (e.target.closest('#modalTicket')) e.preventDefault();
        });
    })();

    // Data nạp khi mở popup lần đầu để giảm tải lúc vào Home.
    var ticketUsers = [];
    var ticketMatches = [];
    var ticketEsportMatches = [];
    var currentUserId = 0;
    var currentUserIsAdmin = false;
    var currentTicketType = 'match';
    var currentTicketCanSelectAllUsers = false;
    var ticketBootstrapLoaded = false;
    var ticketBootstrapPromise = null;
    
    let scrollPositionTicket = 0;
    
    function ensureTicketBootstrapLoaded() {
        if (ticketBootstrapLoaded) return Promise.resolve();
        if (ticketBootstrapPromise) return ticketBootstrapPromise;

        ticketBootstrapPromise = fetch('GetTicketBootstrap.aspx', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: '{}'
        })
        .then(response => response.json())
        .then(data => {
            const payload = data && data.d ? data.d : {};
            currentUserId = payload.currentUserId || 0;
            currentUserIsAdmin = payload.currentUserIsAdmin === true;
            ticketUsers = payload.users || [];
            ticketMatches = payload.matches || [];
            ticketEsportMatches = payload.esportMatches || [];
            ticketBootstrapLoaded = true;
            initializeTicketDropdowns();
        })
        .catch(error => {
            console.error('Error loading ticket bootstrap:', error);
            ticketBootstrapPromise = null;
        });

        return ticketBootstrapPromise;
    }

    function initializeTicketDropdowns() {
        renderTicketUserDropdown();
        renderTicketMatchDropdown();

        selectCurrentTicketUser(false);
    }
    
    function renderTicketUserDropdown(filteredData) {
        const dropdown = document.getElementById('ticketUserDropdown');
        if (!dropdown) return;
        
        const dataToRender = filteredData || ticketUsers;
        
        let html = '';
        dataToRender.forEach(item => {
            const displayText = item.comment || item.name || '';
            html += '<div class="p-3 hover:bg-blue-50 cursor-pointer font-bold text-sm border-b last:border-b-0" onclick="selectTicketUser(' + item.id + ', \'' + escapeTicketJsString(displayText) + '\')">' + escapeTicketHtml(displayText) + '</div>';
        });
        
        if (html === '') {
            html = '<div class="p-3 text-gray-400 text-sm">Không tìm thấy kết quả</div>';
        }
        
        dropdown.innerHTML = html;
    }

    function escapeTicketJsString(value) {
        return String(value || '')
            .replace(/\\/g, '\\\\')
            .replace(/'/g, "\\'")
            .replace(/\r/g, '\\r')
            .replace(/\n/g, '\\n');
    }

    function normalizeTicketMatchId(value) {
        return String(value || '').trim();
    }

    function getCurrentTicketUser() {
        const currentUser = ticketUsers.find(u => parseInt(u.id) === parseInt(currentUserId));
        if (currentUser) return currentUser;
        return currentUserId > 0 ? { id: currentUserId, name: '', comment: '' } : null;
    }

    function selectCurrentTicketUser(reloadCodes) {
        const currentUser = getCurrentTicketUser();
        if (!currentUser) return;
        selectTicketUser(currentUser.id, currentUser.comment || currentUser.name || '', reloadCodes === true);
    }

    function getTicketMatchDisplayText(item) {
        if (!item) return '';
        return ((item.name || '') + ' ' + (item.time || '') + ' ' + (item.season || '')).trim();
    }

    function getCurrentTicketMatchList() {
        return currentTicketType === 'esport' ? ticketEsportMatches : ticketMatches;
    }

    function findTicketMatch(matchId) {
        const normalizedMatchId = normalizeTicketMatchId(matchId);
        if (!normalizedMatchId) return null;
        return getCurrentTicketMatchList().find(item => normalizeTicketMatchId(item.match) === normalizedMatchId) || null;
    }

    function canSelectTicketUserForMatch(matchId, explicitCanSelectAllUsers) {
        if (currentUserIsAdmin) return true;
        if (explicitCanSelectAllUsers === true) return true;

        const match = findTicketMatch(matchId);
        if (!match) return false;

        const hostUserId = parseInt(match.user_host || 0);
        return hostUserId > 0 && hostUserId === parseInt(currentUserId || 0);
    }

    function setTicketUserFieldVisible(isVisible) {
        const userField = document.getElementById('ticketUserField');
        const matchField = document.getElementById('ticketMatchField');
        const userDropdown = document.getElementById('ticketUserDropdown');

        if (userField) userField.classList.toggle('hidden', !isVisible);
        if (matchField) matchField.classList.toggle('md:col-span-2', !isVisible);
        if (!isVisible && userDropdown) userDropdown.classList.add('hidden');
    }

    function applyTicketUserPermission(matchId, explicitCanSelectAllUsers) {
        const canSelectAllUsers = canSelectTicketUserForMatch(matchId, explicitCanSelectAllUsers);
        setTicketUserFieldVisible(canSelectAllUsers);

        if (!canSelectAllUsers) {
            selectCurrentTicketUser(false);
        } else if (!document.getElementById('ticketUserId').value) {
            selectCurrentTicketUser(false);
        }

        return canSelectAllUsers;
    }
    
    function renderTicketMatchDropdown(filteredData) {
        const dropdown = document.getElementById('ticketMatchDropdown');
        if (!dropdown) return;
        
        const dataToRender = filteredData || getCurrentTicketMatchList();
        
        let html = '';
        dataToRender.forEach(item => {
            // Hiển thị: name (đỏ) + time (xanh lá) + season (xanh dương)
            const name = item.name || '';
            const time = item.time || '';
            const season = item.season || '';
            
            const displayHtml = '<span style="color: #dc2626;">' + escapeTicketHtml(name) + '</span> ' + 
                                '<span style="color: #16a34a;">' + escapeTicketHtml(time) + '</span> ' + 
                                '<span style="color: #2563eb;">' + escapeTicketHtml(season) + '</span>';
            
            const displayText = (name + ' ___ ' + time + ' ___ ' + season).trim();
            
            html += '<div class="p-3 hover:bg-blue-50 cursor-pointer font-bold text-sm border-b last:border-b-0" onclick="selectTicketMatch(\'' + escapeTicketJsString(normalizeTicketMatchId(item.match)) + '\', \'' + escapeTicketJsString(displayText) + '\')">' + displayHtml + '</div>';
        });
        
        if (html === '') {
            html = '<div class="p-3 text-gray-400 text-sm">Không tìm thấy kết quả</div>';
        }
        
        dropdown.innerHTML = html;
    }
    
    function showTicketUserDropdown() {
        const userField = document.getElementById('ticketUserField');
        if (userField && userField.classList.contains('hidden')) return;

        ensureTicketBootstrapLoaded();
        const dropdown = document.getElementById('ticketUserDropdown');
        const matchDropdown = document.getElementById('ticketMatchDropdown');
        
        dropdown.classList.remove('hidden');
        if (matchDropdown) matchDropdown.classList.add('hidden');
    }
    
    function showTicketMatchDropdown() {
        ensureTicketBootstrapLoaded();
        const dropdown = document.getElementById('ticketMatchDropdown');
        const userDropdown = document.getElementById('ticketUserDropdown');
        
        dropdown.classList.remove('hidden');
        if (userDropdown) userDropdown.classList.add('hidden');
    }
    
    function filterTicketUsers() {
        const userField = document.getElementById('ticketUserField');
        if (userField && userField.classList.contains('hidden')) return;

        ensureTicketBootstrapLoaded();
        const searchText = document.getElementById('ticketUserSearch').value.toLowerCase();
        
        // Nếu xóa hết text thì xóa luôn giá trị hidden
        if (searchText === '') {
            document.getElementById('ticketUserId').value = '';
        }
        
        const filtered = ticketUsers.filter(item => {
            const displayText = (item.comment || item.name || '').toLowerCase();
            return displayText.includes(searchText);
        });
        
        renderTicketUserDropdown(filtered);
        showTicketUserDropdown();
    }
    
    function filterTicketMatches() {
        ensureTicketBootstrapLoaded();
        const searchText = document.getElementById('ticketMatchSearch').value.toLowerCase();
        
        // Nếu xóa hết text thì xóa luôn giá trị hidden
        if (searchText === '') {
            document.getElementById('ticketMatchId').value = '';
        }
        
        const filtered = getCurrentTicketMatchList().filter(item => {
            // Tìm kiếm trong: name + time + season
            const displayText = ((item.name || '') + ' ' + (item.time || '') + ' ' + (item.season || '')).toLowerCase();
            return displayText.includes(searchText);
        });
        
        renderTicketMatchDropdown(filtered);
        showTicketMatchDropdown();
    }
    
    function selectTicketUser(id, text, reloadCodes) {
        document.getElementById('ticketUserId').value = id;
        document.getElementById('ticketUserSearch').value = text.trim();
        document.getElementById('ticketUserDropdown').classList.add('hidden');
        
        // Ẩn error message khi đã chọn
        document.getElementById('ticketUserError').classList.add('hidden');
        
        // Load lại ticket codes nếu đã chọn match
        const matchId = document.getElementById('ticketMatchId').value;
        if (reloadCodes !== false && matchId) {
            loadTicketCodes(matchId, id);
        }
    }
    
    function selectTicketMatch(matchId, text) {
        document.getElementById('ticketMatchId').value = normalizeTicketMatchId(matchId);
        document.getElementById('ticketMatchSearch').value = text.trim();
        document.getElementById('ticketMatchDropdown').classList.add('hidden');
        
        // Ẩn error message khi đã chọn
        document.getElementById('ticketMatchError').classList.add('hidden');

        applyTicketUserPermission(normalizeTicketMatchId(matchId), false);
        
        // Load ticket codes cho match này
        const userId = document.getElementById('ticketUserId').value;
        loadTicketCodes(normalizeTicketMatchId(matchId), userId);
    }
    
    function loadTicketCodes(matchId, userId) {
        if (!matchId) {
            renderEmptyTable();
            return;
        }
        
        // Nếu không có userId thì lấy từ input
        if (!userId) {
            userId = document.getElementById('ticketUserId').value;
        }
        
        // Call server để lấy data
        const ticketCodesUrl = currentTicketType === 'esport' ? 'GetEsportTicketCodes.aspx' : 'GetTicketCodes.aspx';
        fetch(ticketCodesUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ 
                match: matchId,
                userId: userId ? parseInt(userId) : 0
            })
        })
        .then(response => response.json())
        .then(data => {
            if (data.d) {
                renderTicketCodes(data.d);
            } else {
                renderEmptyTable();
            }
        })
        .catch(error => {
            console.error('Error loading ticket codes:', error);
            renderEmptyTable();
        });
    }
    
    function renderEmptyTable() {
        const desktopBody = document.getElementById('ticketCodesBodyDesktop');
        const mobileBody = document.getElementById('ticketCodesBodyMobile');
        
        if (desktopBody && mobileBody) {
            const emptyRow = '<tr><td colspan="3" class="px-3 py-4 text-center text-gray-400">Không có dữ liệu</td></tr>';
            desktopBody.innerHTML = emptyRow;
            mobileBody.innerHTML = emptyRow;
        }
    }
    
    function escapeTicketHtml(value) {
        return String(value || '').replace(/[&<>"']/g, function(ch) {
            return ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch];
        });
    }

    function formatTicketCodeName(code, codeName) {
        const text = escapeTicketHtml(codeName);
        if (currentTicketType !== 'esport') return text;

        const parts = String(code || '').split('.');
        if (parts.length < 3) return text;

        const iconMap = {
            FDT: '<i class="fa-solid fa-microchip mr-1 text-sky-600"></i>',
            FDCHEM: '<i class="fa-solid fa-flask-vial mr-1 text-lime-700"></i>',
            FDWIND: '<i class="fa-solid fa-wind mr-1 text-teal-600"></i>',
            FDWATER: '<i class="fa-solid fa-droplet mr-1 text-blue-600"></i>',
            FDFIRE: '<i class="fa-solid fa-fire-flame-curved mr-1 text-orange-600"></i>',
            FDEARTH: '<i class="fa-solid fa-mountain mr-1 text-amber-700"></i>'
        };
        return iconMap[parts[1]] ? iconMap[parts[1]] + text : text;
    }

    function getTicketCodeTextStyle(code, fallbackColor) {
        const parts = String(code || '').split('.');
        const colorMap = {
            FDT: '#0284c7',
            FDCHEM: '#4d7c0f',
            FDWIND: '#0f766e',
            FDWATER: '#2563eb',
            FDFIRE: '#ea580c',
            FDEARTH: '#92400e'
        };
        const color = parts.length >= 3 && colorMap[parts[1]] ? colorMap[parts[1]] : fallbackColor;
        return color ? 'color: ' + color + ';' : '';
    }

    function renderTicketCodes(ticketCodes) {
        const desktopBody = document.getElementById('ticketCodesBodyDesktop');
        const mobileBody = document.getElementById('ticketCodesBodyMobile');
        
        if (!desktopBody || !mobileBody) return;
        
        if (!ticketCodes || ticketCodes.length === 0) {
            renderEmptyTable();
            return;
        }
        
        let desktopHtml = '';
        let mobileHtml = '';
        
        ticketCodes.forEach((item, index) => {
            const code = item.code || '';
            const code_name = item.code_name || '';
            const codeNameHtml = formatTicketCodeName(code, code_name);
            const money = item.money || 0;
            const textColor = item.textColor || '';
            const rowColor = item.rowColor || '';
            
            // Tạo style cho row
            let rowStyle = '';
            if (rowColor) {
                rowStyle = 'background-color: ' + rowColor + ';';
            }
            
            // Tạo style cho text
            let textStyle = getTicketCodeTextStyle(code, textColor);
            
            // Desktop row
            desktopHtml += '<tr class="border-b hover:bg-gray-50" style="' + rowStyle + '">';
            desktopHtml += '<td class="px-3 py-2 font-bold hidden">';
            desktopHtml += '<input type="hidden" id="code_' + index + '" value="' + code + '" />';
            desktopHtml += '</td>';
            desktopHtml += '<td class="px-3 py-2 font-bold" style="' + textStyle + '">' + codeNameHtml + '</td>';
            desktopHtml += '<td class="px-3 py-2 text-right">';
            desktopHtml += '<div class="flex items-center gap-1 justify-end">';
            desktopHtml += '<button type="button" onclick="decreaseMoney(' + index + ')" class="bg-red-500 hover:bg-red-600 text-white font-bold px-3 py-1 rounded text-sm" style="touch-action:manipulation">-</button>';
            desktopHtml += '<input type="text" inputmode="numeric" id="money_' + index + '" class="w-32 border rounded px-2 py-1 text-right font-bold" style="font-size:16px;touch-action:manipulation" value="' + formatMoney(money) + '" oninput="formatMoneyInput(this)" />';
            desktopHtml += '<button type="button" onclick="increaseMoney(' + index + ')" class="bg-green-500 hover:bg-green-600 text-white font-bold px-3 py-1 rounded text-sm" style="touch-action:manipulation">+</button>';
            desktopHtml += '</div>';
            desktopHtml += '</td>';
            desktopHtml += '</tr>';
            
            // Mobile row
            mobileHtml += '<tr class="border-b" style="' + rowStyle + '">';
            mobileHtml += '<td class="px-2 py-2 font-bold hidden">';
            mobileHtml += '<input type="hidden" id="code_' + index + '_mobile" value="' + code + '" />';
            mobileHtml += '</td>';
            mobileHtml += '<td class="px-2 py-2 font-bold" style="' + textStyle + '">' + codeNameHtml + '</td>';
            mobileHtml += '<td class="px-2 py-2">';
            mobileHtml += '<div class="flex items-center gap-1">';
            mobileHtml += '<button type="button" onclick="decreaseMoney(' + index + ')" class="bg-red-500 hover:bg-red-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0" style="touch-action:manipulation">-</button>';
            mobileHtml += '<input type="text" inputmode="numeric" id="money_' + index + '_mobile" class="flex-1 border rounded px-1 py-1 text-center font-bold text-xs min-w-0" style="font-size:16px;touch-action:manipulation" value="' + formatMoney(money) + '" oninput="formatMoneyInput(this)" />';
            mobileHtml += '<button type="button" onclick="increaseMoney(' + index + ')" class="bg-green-500 hover:bg-green-600 text-white font-bold px-2 py-1 rounded text-xs flex-shrink-0" style="touch-action:manipulation">+</button>';
            mobileHtml += '</div>';
            mobileHtml += '</td>';
            mobileHtml += '</tr>';
        });
        
        desktopBody.innerHTML = desktopHtml;
        mobileBody.innerHTML = mobileHtml;
    }
    
    function formatMoney(value) {
        // Định dạng số theo ### ### ##0
        const num = parseInt(value) || 0;
        return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    }
    
    function formatMoneyInput(input) {
        // Lấy giá trị số thuần
        let value = input.value.replace(/\s/g, '');
        
        // Chỉ giữ lại số
        value = value.replace(/[^\d]/g, '');
        
        // Định dạng lại
        if (value) {
            input.value = formatMoney(value);
        } else {
            input.value = '0';
        }
        
        syncMoneyPair(input);

        // Kiểm tra và xử lý logic 2 ký tự đầu
        handleCodeGroupLogic(input);
    }

    function syncMoneyPair(input) {
        const match = input.id.match(/^money_(\d+)(_mobile)?$/);
        if (!match) return;

        const index = match[1];
        const pairId = 'money_' + index + (match[2] === '_mobile' ? '' : '_mobile');
        const pairInput = document.getElementById(pairId);
        if (pairInput && pairInput.value !== input.value) {
            pairInput.value = input.value;
        }
    }
    
    function parseMoney(formattedValue) {
        // Chuyển từ định dạng về số
        return parseInt(formattedValue.replace(/\s/g, '')) || 0;
    }
    
    function handleCodeGroupLogic(changedInput) {
        // Lấy index của input đang thay đổi
        const inputId = changedInput.id;
        const match = inputId.match(/money_(\d+)(_mobile)?/);
        if (!match) return;
        
        const changedIndex = parseInt(match[1]);
        const isMobile = match[2] === '_mobile';
        
        // Lấy code của dòng đang thay đổi
        const codeInput = document.getElementById('code_' + changedIndex + (isMobile ? '_mobile' : ''));
        if (!codeInput) return;
        
        const changedCode = codeInput.value;
        if (changedCode.length < 2) return;
        
        const groupEnd = changedCode.lastIndexOf('.');
        const codePrefix = currentTicketType === 'esport' && groupEnd > 0
            ? changedCode.substring(0, groupEnd)
            : changedCode.substring(0, 2);
        
        // Chỉ áp dụng logic cho code không thuộc 41, 42, 43
        if (codePrefix === '41' || codePrefix === '42' || codePrefix === '43') {
            return;
        }
        
        const changedMoney = parseMoney(changedInput.value);
        
        // Nếu money > 0, set các dòng khác có cùng 2 ký tự đầu về 0
        if (changedMoney > 0) {
            // Duyệt qua tất cả các dòng
            const tbody = document.getElementById(isMobile ? 'ticketCodesBodyMobile' : 'ticketCodesBodyDesktop');
            if (!tbody) return;
            
            const rows = tbody.getElementsByTagName('tr');
            for (let i = 0; i < rows.length; i++) {
                if (i === changedIndex) continue; // Bỏ qua dòng đang thay đổi
                
                const otherCodeInput = document.getElementById('code_' + i + (isMobile ? '_mobile' : ''));
                if (!otherCodeInput) continue;
                
                const otherCode = otherCodeInput.value;
                const otherGroupEnd = otherCode.lastIndexOf('.');
                const otherCodePrefix = currentTicketType === 'esport' && otherGroupEnd > 0
                    ? otherCode.substring(0, otherGroupEnd)
                    : otherCode.substring(0, 2);
                if (otherCode.length >= 2 && otherCodePrefix === codePrefix) {
                    // Set money về 0 cho cả desktop và mobile
                    const otherMoneyDesktop = document.getElementById('money_' + i);
                    const otherMoneyMobile = document.getElementById('money_' + i + '_mobile');
                    
                    if (otherMoneyDesktop) {
                        otherMoneyDesktop.value = formatMoney(0);
                    }
                    if (otherMoneyMobile) {
                        otherMoneyMobile.value = formatMoney(0);
                    }
                }
            }
        }
    }
    
    async function openTicketModal(matchId, displayText, canSelectAllUsers) {
        await ensureTicketBootstrapLoaded();
        currentTicketType = 'match';
        currentTicketCanSelectAllUsers = canSelectAllUsers === true;
        renderTicketMatchDropdown();
        const modal = document.getElementById('modalTicket');
        if (modal) {
            const normalizedMatchId = normalizeTicketMatchId(matchId);
            scrollPositionTicket = window.pageYOffset || document.documentElement.scrollTop;
            
            document.body.style.position = 'fixed';
            document.body.style.top = '-' + scrollPositionTicket + 'px';
            document.body.style.width = '100%';
            document.body.style.overflow = 'hidden';
            
            modal.classList.remove('hidden');
            modal.classList.add('flex');
            
            // Ẩn error messages khi mở popup
            document.getElementById('ticketUserError').classList.add('hidden');
            document.getElementById('ticketMatchError').classList.add('hidden');
            document.getElementById('ticketMatchId').value = '';
            document.getElementById('ticketMatchSearch').value = '';
            document.getElementById('ticketMatchDropdown').classList.add('hidden');
            renderEmptyTable();
            
            // Set match nếu có
            if (normalizedMatchId) {
                const match = findTicketMatch(normalizedMatchId);
                if (match) {
                    selectTicketMatch(match.match, getTicketMatchDisplayText(match));
                } else {
                    document.getElementById('ticketMatchId').value = normalizedMatchId;
                    document.getElementById('ticketMatchSearch').value = (displayText || normalizedMatchId).trim();
                    applyTicketUserPermission(normalizedMatchId, currentTicketCanSelectAllUsers);
                    const userId = document.getElementById('ticketUserId').value;
                    loadTicketCodes(normalizedMatchId, userId);
                }
            } else {
                applyTicketUserPermission('', currentTicketCanSelectAllUsers);
            }
        }
    }

    async function openEsportTicketModal(matchId, displayText, canSelectAllUsers) {
        await ensureTicketBootstrapLoaded();
        currentTicketType = 'esport';
        currentTicketCanSelectAllUsers = canSelectAllUsers === true;
        renderTicketMatchDropdown();
        const modal = document.getElementById('modalTicket');
        if (!modal) return;

        scrollPositionTicket = window.pageYOffset || document.documentElement.scrollTop;
        document.body.style.position = 'fixed';
        document.body.style.top = '-' + scrollPositionTicket + 'px';
        document.body.style.width = '100%';
        document.body.style.overflow = 'hidden';

        modal.classList.remove('hidden');
        modal.classList.add('flex');

        document.getElementById('ticketUserError').classList.add('hidden');
        document.getElementById('ticketMatchError').classList.add('hidden');
        const normalizedMatchId = normalizeTicketMatchId(matchId);
        if (normalizedMatchId) {
            const match = findTicketMatch(normalizedMatchId);
            if (match) {
                selectTicketMatch(match.match, getTicketMatchDisplayText(match));
            } else {
                document.getElementById('ticketMatchId').value = normalizedMatchId;
                document.getElementById('ticketMatchSearch').value = (displayText || normalizedMatchId).trim();
                document.getElementById('ticketMatchDropdown').classList.add('hidden');
                applyTicketUserPermission(normalizedMatchId, currentTicketCanSelectAllUsers);
                const userId = document.getElementById('ticketUserId').value;
                loadTicketCodes(normalizedMatchId, userId);
            }
        } else {
            document.getElementById('ticketMatchId').value = '';
            document.getElementById('ticketMatchSearch').value = '';
            document.getElementById('ticketMatchDropdown').classList.add('hidden');
            applyTicketUserPermission('', currentTicketCanSelectAllUsers);
            renderEmptyTable();
        }
    }

    function closeTicketModal() {
        const modal = document.getElementById('modalTicket');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
        
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        
        window.scrollTo(0, scrollPositionTicket);
    }
    
    // Đóng dropdown khi click bên ngoài
    document.addEventListener('click', function(e) {
        if (!e.target.closest('#ticketUserSearch') && !e.target.closest('#ticketUserDropdown')) {
            document.getElementById('ticketUserDropdown').classList.add('hidden');
        }
        if (!e.target.closest('#ticketMatchSearch') && !e.target.closest('#ticketMatchDropdown')) {
            document.getElementById('ticketMatchDropdown').classList.add('hidden');
        }
    });
    
    function toggleBetRow(index) {
        // Desktop
        const checkbox = document.getElementById('bet_' + index);
        const moneyInput = document.getElementById('money_' + index);
        
        // Mobile
        const checkboxMobile = document.getElementById('bet_' + index + '_mobile');
        const moneyInputMobile = document.getElementById('money_' + index + '_mobile');
        
        // Sync checkbox state
        if (checkbox && checkboxMobile) {
            checkbox.checked = checkboxMobile.checked;
            checkboxMobile.checked = checkbox.checked;
        }
        
        const isChecked = checkbox ? checkbox.checked : (checkboxMobile ? checkboxMobile.checked : false);
        
        // Enable/disable inputs
        if (moneyInput) {
            moneyInput.disabled = !isChecked;
            if (!isChecked) moneyInput.value = '0';
        }
        
        if (moneyInputMobile) {
            moneyInputMobile.disabled = !isChecked;
            if (!isChecked) moneyInputMobile.value = '0';
        }
    }
    
    function increaseMoney(index) {
        // Mobile input
        const moneyInputMobile = document.getElementById('money_' + index + '_mobile');
        // Desktop input
        const moneyInputDesktop = document.getElementById('money_' + index);
        
        // Lấy giá trị hiện tại (ưu tiên desktop nếu có, không check disabled)
        let currentValue = 0;
        if (moneyInputDesktop) {
            currentValue = parseMoney(moneyInputDesktop.value);
        } else if (moneyInputMobile) {
            currentValue = parseMoney(moneyInputMobile.value);
        }
        
        let newValue = currentValue + 50000;
        
        // Cập nhật cả 2
        if (moneyInputDesktop) {
            moneyInputDesktop.value = formatMoney(newValue);
            handleCodeGroupLogic(moneyInputDesktop);
        }
        if (moneyInputMobile) {
            moneyInputMobile.value = formatMoney(newValue);
            handleCodeGroupLogic(moneyInputMobile);
        }
    }
    
    function decreaseMoney(index) {
        // Mobile input
        const moneyInputMobile = document.getElementById('money_' + index + '_mobile');
        // Desktop input
        const moneyInputDesktop = document.getElementById('money_' + index);
        
        // Lấy giá trị hiện tại (ưu tiên desktop nếu có, không check disabled)
        let currentValue = 0;
        if (moneyInputDesktop) {
            currentValue = parseMoney(moneyInputDesktop.value);
        } else if (moneyInputMobile) {
            currentValue = parseMoney(moneyInputMobile.value);
        }
        
        let newValue = currentValue - 50000;
        
        // Không cho âm
        if (newValue < 0) newValue = 0;
        
        // Cập nhật cả 2
        if (moneyInputDesktop) {
            moneyInputDesktop.value = formatMoney(newValue);
            handleCodeGroupLogic(moneyInputDesktop);
        }
        if (moneyInputMobile) {
            moneyInputMobile.value = formatMoney(newValue);
            handleCodeGroupLogic(moneyInputMobile);
        }
    }
    
    function saveTicketData() {
        const userId = document.getElementById('ticketUserId').value;
        const matchId = document.getElementById('ticketMatchId').value;
        
        // Ẩn tất cả error messages trước
        document.getElementById('ticketUserError').classList.add('hidden');
        document.getElementById('ticketMatchError').classList.add('hidden');
        
        let hasError = false;
        
        // Validate Người cược
        if (!userId) {
            document.getElementById('ticketUserError').classList.remove('hidden');
            hasError = true;
        }
        
        // Validate Trận đấu
        if (!matchId) {
            document.getElementById('ticketMatchError').classList.remove('hidden');
            hasError = true;
        }
        
        if (hasError) {
            return;
        }
        
        // Thu thập dữ liệu từ bảng chi tiết
        const details = [];
        const tbody = document.getElementById('ticketCodesBodyDesktop');
        
        if (tbody) {
            const rows = tbody.getElementsByTagName('tr');
            
            for (let i = 0; i < rows.length; i++) {
                const codeInput = document.getElementById('code_' + i);
                const moneyInput = document.getElementById('money_' + i);
                
                if (codeInput && moneyInput) {
                    const code = codeInput.value;
                    const money = parseMoney(moneyInput.value);
                    
                    // Chỉ thêm những dòng có tiền cược > 0
                    if (money > 0) {
                        details.push({
                            code: code,
                            money: money
                        });
                    }
                }
            }
        }
        
        // Kiểm tra có dữ liệu để lưu không
        if (details.length === 0) {
            alert('Vui lòng nhập tiền cược cho ít nhất một vé');
            return;
        }
        
        // Disable button để tránh click nhiều lần
        const btnSave = document.getElementById('btnSaveTicket');
        btnSave.disabled = true;
        btnSave.innerHTML = '<i class="fa-solid fa-spinner fa-spin mr-2"></i>Đang lưu...';
        
        // Gọi API để lưu
        const saveTicketUrl = currentTicketType === 'esport' ? 'SaveEsportTicket.aspx' : 'SaveTicket.aspx';
        fetch(saveTicketUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                userId: parseInt(userId),
                matchId: matchId,
                details: details
            })
        })
        .then(response => response.json())
        .then(data => {
            // Hiển thị thông báo từ SQL
            if (data.msg) {
                alert(data.msg);
            }
            
            // Nếu thành công (isSuccess = 1) thì đóng popup
            if (data.isSuccess === 1) {
                closeTicketModal();
                // Reload trang nếu cần
                // window.location.reload();
            }
        })
        .catch(error => {
            console.error('Error saving ticket:', error);
            alert('Có lỗi xảy ra khi lưu dữ liệu');
        })
        .finally(() => {
            // Enable lại button
            btnSave.disabled = false;
            btnSave.innerHTML = '<i class="fa-solid fa-check mr-2"></i>Lưu lại';
        });
    }
</script>
