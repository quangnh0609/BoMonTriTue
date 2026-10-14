<%@ Control Language="C#" AutoEventWireup="true" %>
<%@ Register Src="~/ucNumericKeyboard.ascx" TagPrefix="uc" TagName="NumericKeyboard" %>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<style>
    @media screen and (max-width: 768px) {
        input, textarea, select { font-size: 16px !important; }

        #modalAddChampion input[id$='time'],
        #modalAddChampion input[id$='time_lock'] {
            font-size: 12px !important;
        }
    }
</style>

<asp:UpdatePanel ID="upnlAddChampion" runat="server">
    <ContentTemplate>
        <div id="modalAddChampion" class="fixed inset-0 bg-gray-900/80 z-[60] hidden flex items-center justify-center p-4 font-sans">
            <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-lg flex flex-col overflow-hidden text-[12px] max-h-[90vh]">

                <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4 text-white flex justify-between items-center shrink-0 shadow-lg">
                    <h3 id="championModalTitle" class="font-bold flex items-center text-[14px]">
                        <i class="fa-solid fa-trophy mr-3 text-lg"></i> Thêm mới kèo chung cuộc
                    </h3>
                </div>

                <!-- Toàn bộ form là 1 vùng scroll duy nhất, giống ucAddMatch -->
                <div id="modalChampionFormContent" class="p-5 flex-grow overflow-y-auto relative">
                    <input type="hidden" id="champion" runat="server" />
                    <asp:HiddenField ID="editYn" runat="server" Value="false" />
                    <asp:HiddenField ID="hdnTimeValue" runat="server" />
                    <asp:HiddenField ID="hdnShouldCloseModal" runat="server" Value="false" />
                    <asp:HiddenField ID="hdnDetails" runat="server" />

                    <!-- Dòng 1: Season + Time -->
                    <div class="grid grid-cols-2 gap-3 mb-4 items-start">
                        <div class="relative">
                            <asp:HiddenField ID="hdnSeasonCode" runat="server" />
                            <asp:TextBox ID="season" runat="server"
                                onkeyup="filterChampionData(this, 'listChampionSeason')"
                                onfocus="showAllChampionData(this, 'listChampionSeason')"
                                onblur="validateChampionSelection(this, 'listChampionSeason')"
                                autocomplete="off" placeholder="Giải đấu"
                                class="w-full h-9 border border-gray-300 rounded px-3 outline-none font-bold text-[12px] focus:border-blue-500 bg-gray-50/50"></asp:TextBox>
                            <div id="listChampionSeason" class="absolute z-[100] w-full bg-white shadow-xl border rounded mt-1 max-h-60 overflow-y-auto hidden"></div>
                            <span id="msg_champion_season" class="text-[10px] text-red-500 absolute left-0 -bottom-4 hidden font-semibold">! Vui lòng chọn giải đấu hợp lệ</span>
                        </div>

                        <div class="relative">
                            <input type="date" id="championDatePickerHidden"
                                style="position: absolute; opacity: 0; width: 100%; height: 100%; top: 0; left: 0; cursor: pointer; z-index: 2;" />
                            <asp:TextBox ID="time" runat="server"
                                placeholder="dd/MM/yyyy" ReadOnly="true"
                                class="w-full h-9 border border-gray-300 rounded px-3 outline-none font-bold text-[12px] bg-gray-50/50 cursor-pointer"></asp:TextBox>
                            <span id="msg_champion_time" class="text-[10px] text-red-500 absolute left-0 -bottom-4 hidden font-semibold">! Vui lòng chọn ngày</span>
                        </div>
                    </div>

                    <!-- Dòng 2: Name + Thời gian khóa -->
                    <div class="grid grid-cols-2 gap-3 mb-4 items-start">
                        <div class="relative">
                            <label class="block text-[11px] font-bold text-gray-600 mb-1">Tên kèo</label>
                            <asp:TextBox ID="name" runat="server"
                                autocomplete="off" placeholder="Tên kèo"
                                class="w-full h-9 border border-gray-300 rounded px-3 outline-none font-bold text-[12px] focus:border-blue-500 bg-gray-50/50"></asp:TextBox>
                        </div>
                        <div class="relative">
                            <label class="block text-[11px] font-bold text-gray-600 mb-1">Thời gian khóa</label>
                            <input type="hidden" id="hdnTimeLockValue" runat="server" />
                            <div class="relative">
                                <input type="datetime-local" id="timeLockPicker"
                                    style="position: absolute; opacity: 0; width: 100%; height: 100%; top: 0; left: 0; cursor: pointer; z-index: 2;" />
                                <asp:TextBox ID="time_lock" runat="server"
                                    placeholder="hh:mm dd/MM/yyyy" ReadOnly="true"
                                    class="w-full h-9 border border-gray-300 rounded px-3 outline-none font-bold text-[12px] bg-gray-50/50 cursor-pointer"></asp:TextBox>
                            </div>
                        </div>
                    </div>

                    <!-- Bảng chi tiết: KHÔNG có scroll riêng, nằm trong vùng scroll chung -->
                    <div>
                        <div class="flex items-center justify-between mb-2">
                            <button type="button" onclick="addChampionDetailRow()"
                                class="flex items-center gap-1 px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded text-[11px] font-bold transition-all active:scale-95">
                                <i class="fa-solid fa-plus"></i> Thêm dòng
                            </button>
                        </div>
                        <div class="border rounded-lg overflow-hidden">
                            <table class="w-full text-[12px] border-collapse table-fixed">
                                <colgroup>
                                    <col style="width:60%">
                                    <col style="width:30%">
                                    <col style="width:10%">
                                </colgroup>
                                <thead class="bg-gray-100 border-b">
                                    <tr>
                                        <th class="p-2 text-center font-bold text-gray-600 border-r">Đội</th>
                                        <th class="p-2 text-center font-bold text-gray-600 border-r">Rate</th>
                                        <th class="p-2"></th>
                                    </tr>
                                </thead>
                                <tbody id="championDetailBody"></tbody>
                            </table>
                        </div>
                    </div>
                </div>

                <div class="px-6 py-4 bg-gradient-to-r from-gray-50 to-gray-100 border-t flex justify-end gap-3 shrink-0">
                    <button type="button" onclick="clearAddChampionForm(); closeAddChampionModal();"
                        class="px-6 py-2.5 rounded-lg font-bold text-gray-600 bg-white border-2 border-gray-300 hover:bg-gray-50 hover:border-gray-400 transition-all text-[12px] shadow-sm active:scale-95 flex items-center gap-2">
                        <i class="fa-solid fa-times"></i> Hủy bỏ
                    </button>
                    <button type="button" id="btnSaveChampion" onclick="saveChampionData(); return false;"
                        class="px-8 py-2.5 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg font-bold hover:from-green-700 hover:to-green-800 shadow-lg active:scale-95 text-[12px] cursor-pointer transition-all">
                        ✓ Lưu lại
                    </button>
                </div>
            </div>
        </div>
    </ContentTemplate>
</asp:UpdatePanel>

<uc:NumericKeyboard runat="server" ID="ucNumericKeyboard" />

<script>
    let championScrollPosition = 0;

    // ── Modal ─────────────────────────────────────────────────────────────────
    function openAddChampionModal() {
        const modal = document.getElementById('modalAddChampion');
        if (!modal) return;
        championScrollPosition = window.pageYOffset || document.documentElement.scrollTop;
        document.body.style.position = 'fixed';
        document.body.style.top = `-${championScrollPosition}px`;
        document.body.style.width = '100%';
        document.body.style.overflow = 'hidden';
        modal.classList.remove('hidden');
        modal.classList.add('flex');
        if (document.getElementById('championDetailBody').children.length === 0)
            for (let i = 0; i < 5; i++) addChampionDetailRow();
    }

    function closeAddChampionModal() {
        const modal = document.getElementById('modalAddChampion');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        window.scrollTo(0, championScrollPosition);
    }

    function formatChampionDateTimeText(value) {
        if (!value) return '';
        const dt = new Date(value);
        if (isNaN(dt.getTime())) return '';
        const hh = String(dt.getHours()).padStart(2, '0');
        const mm = String(dt.getMinutes()).padStart(2, '0');
        const dd = String(dt.getDate()).padStart(2, '0');
        const MM = String(dt.getMonth() + 1).padStart(2, '0');
        const yyyy = dt.getFullYear();
        return `${hh}:${mm} ${dd}/${MM}/${yyyy}`;
    }

    function onTimeLockPickerChange(picker) {
        const hdnTL = document.querySelector('[id$="hdnTimeLockValue"]');
        const textBox = document.querySelector('[id$="time_lock"]');
        if (hdnTL) hdnTL.value = picker.value; // yyyy-MM-ddTHH:mm
        if (textBox) textBox.value = formatChampionDateTimeText(picker.value);
    }

    function clearAddChampionForm() {
        ['season','time','name'].forEach(id => {
            const el = document.querySelector('[id$="' + id + '"]');
            if (el) el.value = '';
        });
        ['hdnTimeValue','champion','editYn','hdnSeasonCode','hdnTimeLockValue'].forEach(id => {
            const el = document.querySelector('[id$="' + id + '"]');
            if (el) el.value = id === 'editYn' ? 'false' : '';
        });
        const tlPicker = document.getElementById('timeLockPicker');
        if (tlPicker) tlPicker.value = '';
        const tlText = document.querySelector('[id$="time_lock"]');
        if (tlText) tlText.value = '';
        const title = document.getElementById('championModalTitle');
        if (title) title.innerHTML = '<i class="fa-solid fa-trophy mr-3 text-lg"></i> Thêm mới kèo chung cuộc';
        const tbody = document.getElementById('championDetailBody');
        tbody.innerHTML = '';
        for (let i = 0; i < 5; i++) addChampionDetailRow();
        document.querySelectorAll('#modalAddChampion [id^="msg_"]').forEach(m => m.classList.add('hidden'));
        document.querySelectorAll('#modalAddChampion [id^="list"]').forEach(l => l.classList.add('hidden'));
    }

    // ── Date picker ───────────────────────────────────────────────────────────
    document.addEventListener('DOMContentLoaded', function () {
        const picker  = document.getElementById('championDatePickerHidden');
        const textBox = document.querySelector('[id$="time"]');
        const hdnTV   = document.querySelector('[id$="hdnTimeValue"]');
        if (picker && textBox && hdnTV) {
            picker.addEventListener('change', function () {
                if (this.value) {
                    const [yyyy, MM, dd] = this.value.split('-');
                    textBox.value = `${dd}/${MM}/${yyyy}`;
                    hdnTV.value   = this.value;
                }
            });
            textBox.addEventListener('click', function () { picker.click(); });
        }

        const timeLockPicker = document.getElementById('timeLockPicker');
        const timeLockTextBox = document.querySelector('[id$="time_lock"]');
        const hdnTL = document.querySelector('[id$="hdnTimeLockValue"]');
        if (timeLockPicker && timeLockTextBox && hdnTL) {
            timeLockPicker.addEventListener('change', function () {
                onTimeLockPickerChange(this);
            });
            timeLockTextBox.addEventListener('click', function () {
                timeLockPicker.click();
            });
        }
    });

    // ── Detail table ──────────────────────────────────────────────────────────
    function addChampionDetailRow() {
        const tbody = document.getElementById('championDetailBody');
        const tr = document.createElement('tr');
        tr.className = 'border-b champion-detail-row';
        tr.innerHTML = `
            <td class="p-1 border-r">
                <input type="hidden" class="champion-detail-id" value="" />
                <input type="hidden" class="champion-team-code" value="" />
                <input type="text"
                    class="champion-team-input w-full py-1 px-2 outline-none bg-transparent font-bold text-[12px]"
                    placeholder="Chọn đội" autocomplete="off"
                    onkeyup="filterChampionTeamInRow(this)"
                    onfocus="showAllChampionTeamInRow(this)"
                    onblur="hideChampionTeamDropdown(this)" />
            </td>
            <td class="p-1 border-r">
                <input type="text" inputmode="decimal"
                    class="champion-rate-input w-full text-right py-1 px-2 outline-none bg-transparent font-bold text-[12px]"
                    placeholder="0.00" />
            </td>
            <td class="p-1 text-center">
                <button type="button" onclick="removeChampionDetailRow(this)"
                    class="text-red-400 hover:text-red-600 transition-colors">
                    <i class="fa-solid fa-trash text-[11px]"></i>
                </button>
            </td>`;
        tbody.appendChild(tr);
        attachChampionRateInput(tr.querySelector('.champion-rate-input'));
    }

    function removeChampionDetailRow(btn) { btn.closest('tr').remove(); }

    function normalizeChampionRate(value) {
        return String(value || '').replace(/,/g, '.');
    }

    function attachChampionRateInput(input) {
        if (!input) return;
        input.addEventListener('input', function () {
            const normalized = normalizeChampionRate(input.value);
            if (normalized !== input.value) input.value = normalized;
        });
        input.addEventListener('blur', function () {
            input.value = normalizeChampionRate(input.value).trim();
        });
        input.addEventListener('focus', function () {
            setTimeout(() => input.setSelectionRange(0, input.value.length), 10);
        });
        input.addEventListener('click', function () {
            setTimeout(() => input.setSelectionRange(0, input.value.length), 10);
        });
    }

    // ── Team dropdown trong từng dòng (giống listHome/listWay trong ucAddMatch) ─
    // Dùng 1 dropdown chung trong vùng scroll của modal để không bị lệch khi bàn phím mobile mở.
    (function () {
        const dropdown = document.createElement('div');
        dropdown.id = 'championTeamDropdownFixed';
        dropdown.className = 'bg-white shadow-xl border rounded overflow-y-auto hidden';
        dropdown.style.cssText = 'position:absolute; z-index:9999; min-width:180px;';

        function getDropdownHost() {
            return document.getElementById('modalChampionFormContent') || document.body;
        }

        function ensureDropdownHost() {
            const host = getDropdownHost();
            if (dropdown.parentElement !== host) host.appendChild(dropdown);
            return host;
        }

        function hideDropdown() {
            dropdown.classList.add('hidden');
            const host = getDropdownHost();
            if (host && host !== document.body) host.style.paddingBottom = '';
        }

        let currentTeamInput = null;

        window.filterChampionTeamInRow = function (input, forceAll) {
            currentTeamInput = input;
            const value = input.value.toLowerCase();
            const data  = typeof dataTeam !== 'undefined' ? dataTeam : [];
            let html = '';
            data.forEach(function (item) {
                const text = String(item.team_name);
                const code = String(item.team);
                if (forceAll || value === '' || text.toLowerCase().includes(value) || code.toLowerCase().includes(value)) {
                    html += `<div class="px-3 py-2 hover:bg-blue-100 cursor-pointer border-b text-[12px] font-bold"
                                  onclick="selectChampionTeamFixed('${code.replace(/'/g, "\\'")}','${text.replace(/'/g, "\\'")}')">${text}</div>`;
                }
            });
            dropdown.innerHTML = html || '<div class="px-3 py-2 text-gray-400 text-[12px]">Không có dữ liệu</div>';
            positionChampionDropdown(input);
            dropdown.classList.remove('hidden');
        };

        window.showAllChampionTeamInRow = function (input) {
            filterChampionTeamInRow(input, true);
        };

        window.hideChampionTeamDropdown = function (input) {
            setTimeout(hideDropdown, 200);
        };

        window.selectChampionTeamFixed = function (code, name) {
            if (currentTeamInput) {
                currentTeamInput.value = name;
                const codeInput = currentTeamInput.closest('td').querySelector('.champion-team-code');
                if (codeInput) codeInput.value = code;
            }
            hideDropdown();
        };

        function positionChampionDropdown(input) {
            const host = ensureDropdownHost();
            const rect = input.getBoundingClientRect();
            const hostRect = host.getBoundingClientRect();
            const scrollTop = host === document.body ? window.scrollY : host.scrollTop;
            const scrollLeft = host === document.body ? window.scrollX : host.scrollLeft;
            const inputTop = rect.top - hostRect.top + scrollTop;
            const inputLeft = rect.left - hostRect.left + scrollLeft;
            const dropH = Math.min(192, Math.max(96, dropdown.scrollHeight || 96));

            if (host !== document.body) {
                host.style.paddingBottom = (dropH + 24) + 'px';
                const neededScrollTop = inputTop + rect.height + 2 + dropH + 8 - host.clientHeight;
                if (neededScrollTop > host.scrollTop + 1) {
                    host.scrollTop = neededScrollTop;
                    requestAnimationFrame(function () { positionChampionDropdown(input); });
                    return;
                }
            }

            dropdown.style.width = rect.width + 'px';
            dropdown.style.left  = Math.max(scrollLeft + 8, inputLeft) + 'px';
            dropdown.style.maxHeight = dropH + 'px';
            dropdown.style.top = (inputTop + rect.height + 2) + 'px';
            dropdown.style.bottom = 'auto';
        }

        document.addEventListener('click', function (e) {
            if (!e.target.closest('.champion-team-input') && e.target !== dropdown && !dropdown.contains(e.target))
                hideDropdown();
        });

        // Reposition khi scroll modal
        document.getElementById('modalChampionFormContent') && document.getElementById('modalChampionFormContent').addEventListener('scroll', function () {
            if (!dropdown.classList.contains('hidden') && currentTeamInput)
                positionChampionDropdown(currentTeamInput);
        });

        if (window.visualViewport) {
            window.visualViewport.addEventListener('resize', function () {
                if (!dropdown.classList.contains('hidden') && currentTeamInput)
                    setTimeout(function () { positionChampionDropdown(currentTeamInput); }, 50);
            });
            window.visualViewport.addEventListener('scroll', function () {
                if (!dropdown.classList.contains('hidden') && currentTeamInput)
                    positionChampionDropdown(currentTeamInput);
            });
        }
    })();

    // ── Season autocomplete ───────────────────────────────────────────────────
    function removeChampionAccents(str) {
        return str.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
    }

    function filterChampionData(input, listId, forceAll) {
        const value = input.value.toLowerCase();
        const list  = document.querySelector(`[id$='${listId}']`);
        if (!list) return;
        const data = typeof dataSeason !== 'undefined' ? dataSeason : [];
        let html = '';
        data.forEach(function (item) {
            const code = String(item.season);
            const name = String(item.season_name);
            if (forceAll || value === '' || name.toLowerCase().includes(value) || code.toLowerCase().includes(value)) {
                html += `<div class="px-3 py-2 hover:bg-blue-100 cursor-pointer border-b text-[12px]"
                              onclick="selectChampionSeasonItem('${code.replace(/'/g, "\\'")}','${name.replace(/'/g, "\\'")}')">${name}</div>`;
            }
        });
        list.innerHTML = html;
        list.classList.remove('hidden');
    }

    function showAllChampionData(input, listId) {
        document.querySelectorAll('[id^="listChampion"]').forEach(el => el.classList.add('hidden'));
        filterChampionData(input, listId, true);
        setTimeout(function () { input.select(); }, 10);
    }

    function selectChampionSeasonItem(code, name) {
        const input   = document.querySelector('[id$="season"]');
        const hdnCode = document.querySelector('[id$="hdnSeasonCode"]');
        if (input)   input.value   = name;
        if (hdnCode) hdnCode.value = code;
        document.querySelectorAll('[id$="listChampionSeason"]').forEach(l => l.classList.add('hidden'));
    }

    // giữ lại để onblur gọi được
    function selectChampionItem(val, inputId, listId) {
        const input = document.getElementById(inputId);
        if (input) input.value = val;
        const list = document.querySelector(`[id$='${listId}']`);
        if (list) list.classList.add('hidden');
    }

    function validateChampionSelection(input, listId) {
        setTimeout(function () {
            const list = document.querySelector(`[id$='${listId}']`);
            if (list) list.classList.add('hidden');
        }, 200);
    }

    document.addEventListener('click', function (e) {
        if (!e.target.closest('[id$="season"]') && !e.target.closest('[id$="listChampionSeason"]'))
            document.querySelectorAll('[id$="listChampionSeason"]').forEach(l => l.classList.add('hidden'));
    });

    // ── Auto-select khi click/focus vào tất cả input text trong modal ─────────
    document.addEventListener('DOMContentLoaded', function () {
        // season, note - dùng event delegation vì season là ASP TextBox
        document.getElementById('modalAddChampion').addEventListener('focus', function (e) {
            if (e.target.tagName === 'INPUT' && e.target.type === 'text' && !e.target.readOnly) {
                setTimeout(function () { e.target.select(); }, 10);
            }
        }, true);
        document.getElementById('modalAddChampion').addEventListener('click', function (e) {
            if (e.target.tagName === 'INPUT' && e.target.type === 'text' && !e.target.readOnly) {
                e.target.select();
            }
        }, true);
    });

    // ── Save ──────────────────────────────────────────────────────────────────
    function validateChampionBeforeSubmit() {
        document.querySelectorAll('#modalAddChampion [id^="msg_"]').forEach(m => m.classList.add('hidden'));
        let hasError = false;
        const seasonCode = document.querySelector('[id$="hdnSeasonCode"]');
        const seasonEl   = document.querySelector('[id$="season"]');
        if (!seasonCode || !seasonCode.value.trim()) {
            if (!seasonEl || !seasonEl.value.trim()) {
                const msg = document.getElementById('msg_champion_season');
                if (msg) { msg.classList.remove('hidden'); msg.innerText = '! Vui lòng chọn giải đấu'; }
                hasError = true;
            }
        }
        const timeEl = document.querySelector('[id$="hdnTimeValue"]');
        if (!timeEl || !timeEl.value.trim()) {
            const msg = document.getElementById('msg_champion_time');
            if (msg) { msg.classList.remove('hidden'); }
            hasError = true;
        }
        return !hasError;
    }

    function collectChampionDetails() {
        const details = [];
        document.querySelectorAll('#championDetailBody .champion-detail-row').forEach(function (row) {
            const idInput   = row.querySelector('.champion-detail-id');
            const codeInput = row.querySelector('.champion-team-code');
            const nameInput = row.querySelector('.champion-team-input');
            const team = codeInput && codeInput.value.trim() ? codeInput.value.trim() : nameInput.value.trim();
            const rateInput = row.querySelector('.champion-rate-input');
            const rate = normalizeChampionRate(rateInput.value).trim();
            rateInput.value = rate;
            if (team || rate) details.push({ id: idInput ? idInput.value.trim() : '', team: team, rate: rate });
        });
        return details;
    }

    function saveChampionData() {
        if (!validateChampionBeforeSubmit()) return false;
        const btnSave = document.getElementById('btnSaveChampion');
        btnSave.disabled = true; btnSave.innerText = 'Đang lưu...';
        const details = collectChampionDetails();
        const hdnDetails = document.querySelector('[id$="hdnDetails"]');
        if (hdnDetails) hdnDetails.value = JSON.stringify(details);
        const championData = {
            champion : document.querySelector('[id$="champion"]').value,
            name     : document.querySelector('[id$="name"]') ? document.querySelector('[id$="name"]').value.trim() : '',
            season   : document.querySelector('[id$="hdnSeasonCode"]').value,
            time     : document.querySelector('[id$="hdnTimeValue"]').value,
            time_lock: document.querySelector('[id$="hdnTimeLockValue"]') ? document.querySelector('[id$="hdnTimeLockValue"]').value : '',
            details  : details,
            editYn   : document.querySelector('[id$="editYn"]').value
        };
        fetch('SaveChampion.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(championData)
        })
        .then(function (r) {
            return r.text().then(function(text) {
                try { return JSON.parse(text); }
                catch(e) { throw new Error('Server response: ' + text.substring(0, 200)); }
            });
        })
        .then(function (data) {
            btnSave.disabled = false; btnSave.innerText = '✓ Lưu lại';
            if (data.isSuccess == 1) {
                alert(data.msg);
                closeAddChampionModal(); clearAddChampionForm();
                if (typeof reloadChampionsData === 'function') reloadChampionsData(); else location.reload();
            } else { alert(data.msg); }
        })
        .catch(function (err) {
            btnSave.disabled = false; btnSave.innerText = '✓ Lưu lại';
            alert('Lỗi khi lưu dữ liệu: ' + err);
        });
        return false;
    }

    (function () {
        function attachPrm() {
            var prm = typeof Sys !== 'undefined' && Sys.WebForms ? Sys.WebForms.PageRequestManager.getInstance() : null;
            if (!prm) return;
            prm.add_endRequest(function () {
                const hdnShouldClose = document.querySelector('[id$="hdnShouldCloseModal"]');
                const modal = document.getElementById('modalAddChampion');
                if (hdnShouldClose && modal && hdnShouldClose.value === 'false' && modal.classList.contains('hidden')) {
                    modal.classList.remove('hidden');
                    modal.classList.add('flex');
                    document.body.style.position = 'fixed';
                    document.body.style.top = `-${championScrollPosition}px`;
                    document.body.style.width = '100%';
                    document.body.style.overflow = 'hidden';
                }
            });
        }
        if (typeof Sys !== 'undefined') {
            attachPrm();
        } else {
            document.addEventListener('DOMContentLoaded', attachPrm);
        }
    })();

    if (window.innerWidth <= 768) {
        let focusTimeout = null;

        document.addEventListener('focus', function (e) {
            const t = e.target;
            // Giữ input đang nhập nằm trong vùng nhìn thấy khi bàn phím mobile mở.
            if (t.tagName === 'INPUT' || t.tagName === 'TEXTAREA') {
                if (focusTimeout) clearTimeout(focusTimeout);
                focusTimeout = setTimeout(function () {
                    const modal        = document.getElementById('modalAddChampion');
                    const modalContent = document.getElementById('modalChampionFormContent');
                    if (modal && modalContent && !modal.classList.contains('hidden')) {
                        const inputRect    = t.getBoundingClientRect();
                        const modalRect    = modalContent.getBoundingClientRect();
                        const inputTop     = inputRect.top - modalRect.top + modalContent.scrollTop;
                        const targetScroll = inputTop - (modalRect.height / 3);
                        modalContent.scrollTo({ top: Math.max(0, targetScroll), behavior: 'smooth' });
                    }
                }, 300);
            }
        }, true);

        document.addEventListener('blur', function (e) {
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                if (focusTimeout) { clearTimeout(focusTimeout); focusTimeout = null; }
            }
        }, true);
    }
</script>

<!-- ── Modal Kết quả ──────────────────────────────────────────────────────── -->
<div id="modalChampionResult" class="fixed inset-0 bg-gray-900/80 z-[60] hidden flex items-center justify-center p-4 font-sans">
    <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-lg flex flex-col overflow-hidden text-[12px] max-h-[90vh]">

        <div class="bg-gradient-to-r from-purple-600 to-purple-700 px-6 py-4 text-white flex justify-between items-center shrink-0 shadow-lg">
            <h3 class="font-bold flex items-center text-[14px]">
                <i class="fa-solid fa-flag-checkered mr-3 text-lg"></i> Kết quả kèo chung cuộc
            </h3>
        </div>

        <div id="modalResultFormContent" class="p-5 flex-grow overflow-y-auto">
            <!-- Dòng 1: Season + Time (readonly) -->
            <div class="grid grid-cols-2 gap-3 mb-4 items-start">
                <div>
                    <label class="block text-[11px] font-bold text-gray-600 mb-1">Giải đấu</label>
                    <input type="text" id="resultSeason" readonly
                        class="w-full h-9 border border-gray-200 rounded px-3 outline-none font-bold text-[12px] bg-gray-100 cursor-default" />
                </div>
                <div>
                    <label class="block text-[11px] font-bold text-gray-600 mb-1">Ngày</label>
                    <input type="text" id="resultTime" readonly
                        class="w-full h-9 border border-gray-200 rounded px-3 outline-none font-bold text-[12px] bg-gray-100 cursor-default" />
                </div>
            </div>

            <!-- Thời gian khóa (readonly) -->
            <div class="grid grid-cols-1 gap-3 mb-4 items-start">
                <div>
                    <label class="block text-[11px] font-bold text-gray-600 mb-1">Thời gian khóa</label>
                    <input type="text" id="resultTimeLock" readonly
                        class="w-full h-9 border border-gray-200 rounded px-3 outline-none font-bold text-[12px] bg-gray-100 cursor-default" />
                </div>
            </div>

            <!-- Bảng chi tiết: team (readonly), rate_win (readonly), result_win (checkbox), result_lost (checkbox) -->
            <div>
                <div class="border rounded-lg overflow-hidden">
                    <table class="w-full text-[12px] border-collapse table-fixed">
                        <colgroup>
                            <col style="width:50%">
                            <col style="width:20%">
                            <col style="width:15%">
                            <col style="width:15%">
                        </colgroup>
                        <thead class="bg-gray-100 border-b">
                            <tr>
                                <th class="p-2 text-center font-bold text-gray-600 border-r">Đội</th>
                                <th class="p-2 text-center font-bold text-gray-600 border-r">Rate</th>
                                <th class="p-2 text-center font-bold text-gray-600 border-r">Thắng</th>
								<th class="p-2 text-center font-bold text-gray-600 border-r">Thua</th>
                            </tr>
                        </thead>
                        <tbody id="resultDetailBody"></tbody>
                    </table>
                </div>
            </div>
        </div>

        <div class="px-6 py-4 bg-gradient-to-r from-gray-50 to-gray-100 border-t flex justify-end gap-3 shrink-0">
            <button type="button" onclick="closeChampionResultModal();"
                class="px-6 py-2.5 rounded-lg font-bold text-gray-600 bg-white border-2 border-gray-300 hover:bg-gray-50 hover:border-gray-400 transition-all text-[12px] shadow-sm active:scale-95 flex items-center gap-2">
                <i class="fa-solid fa-times"></i> Đóng
            </button>
            <button type="button" id="btnSaveResult" onclick="saveResultData(); return false;"
                class="px-8 py-2.5 bg-gradient-to-r from-purple-600 to-purple-700 text-white rounded-lg font-bold hover:from-purple-700 hover:to-purple-800 shadow-lg active:scale-95 text-[12px] cursor-pointer transition-all">
                ✓ Lưu kết quả
            </button>
        </div>
    </div>
</div>

<script>
    let resultScrollPosition = 0;
    let _resultGroupKey = '';

    function openChampionResultModal(groupKey, groupRows) {
        _resultGroupKey = groupKey;
        const first = groupRows[0];

        // Fill season
        const seasonEl = document.getElementById('resultSeason');
        if (seasonEl) seasonEl.value = first.season_name || first.season || '';

        // Fill time
        const timeEl = document.getElementById('resultTime');
        if (timeEl && first.time) {
            let dt;
            if (typeof first.time === 'string' && first.time.startsWith('/Date(')) {
                dt = new Date(parseInt(first.time.match(/\d+/)[0]));
            } else {
                dt = new Date(first.time);
            }
            if (!isNaN(dt.getTime())) {
                const dd = String(dt.getDate()).padStart(2,'0');
                const mm = String(dt.getMonth()+1).padStart(2,'0');
                const yyyy = dt.getFullYear();
                timeEl.value = `${dd}/${mm}/${yyyy}`;
            }
        } else if (timeEl) { timeEl.value = ''; }

        // Fill time_lock
        const timeLockEl = document.getElementById('resultTimeLock');
        if (timeLockEl && first.time_lock) {
            let dtl;
            if (typeof first.time_lock === 'string' && first.time_lock.startsWith('/Date(')) {
                dtl = new Date(parseInt(first.time_lock.match(/\d+/)[0]));
            } else {
                dtl = new Date(first.time_lock);
            }
            if (!isNaN(dtl.getTime())) {
                const dd = String(dtl.getDate()).padStart(2,'0');
                const mm = String(dtl.getMonth()+1).padStart(2,'0');
                const yyyy = dtl.getFullYear();
                const HH = String(dtl.getHours()).padStart(2,'0');
                const MM = String(dtl.getMinutes()).padStart(2,'0');
                timeLockEl.value = `${dd}/${mm}/${yyyy} ${HH}:${MM}`;
            } else { timeLockEl.value = ''; }
        } else if (timeLockEl) { timeLockEl.value = ''; }

        // Fill detail rows
        const tbody = document.getElementById('resultDetailBody');
        tbody.innerHTML = '';
        groupRows.forEach(function(r) {
            if (!r.team) return;
            const checked_win = (r.result_win == 1 || r.result_win === true || r.result_win === 'true') ? 'checked' : '';
			const checked_lost = (r.result_win == 0 || r.result_win === false || r.result_win === 'false') ? 'checked' : '';
            const rowId = (r.id !== undefined && r.id !== null) ? r.id : r.team;
            const tr = document.createElement('tr');
            tr.className = 'border-b last:border-0 result-detail-row';
            tr.innerHTML = `
                <td class="p-1 border-r">
                    <input type="hidden" class="result-row-id" value="${String(rowId).replace(/"/g,'&quot;')}" />
                    <input type="text" readonly value="${(r.team_name || r.team || '').replace(/"/g,'&quot;')}"
                        class="w-full py-1 px-2 outline-none bg-transparent font-bold text-[12px] cursor-default" />
                </td>
                <td class="p-1 border-r">
                    <input type="text" readonly value="${(r.rate_win || '').toString().replace(/"/g,'&quot;')}"
                        class="w-full text-right py-1 px-2 outline-none bg-transparent font-bold text-[12px] cursor-default" />
                </td>
                <td class="p-1 text-center">
                    <input type="checkbox" class="result-win-check w-4 h-4 accent-green-600 cursor-pointer" ${checked_win} />
                </td>
                <td class="p-1 text-center">
                    <input type="checkbox" class="result-lost-check w-4 h-4 accent-red-600 cursor-pointer" ${checked_lost} />
                </td>`;
            tbody.appendChild(tr);
        });

        // Open modal
        resultScrollPosition = window.pageYOffset || document.documentElement.scrollTop;
        document.body.style.position = 'fixed';
        document.body.style.top = `-${resultScrollPosition}px`;
        document.body.style.width = '100%';
        document.body.style.overflow = 'hidden';
        const modal = document.getElementById('modalChampionResult');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }

    function closeChampionResultModal() {
        const modal = document.getElementById('modalChampionResult');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        window.scrollTo(0, resultScrollPosition);
    }

    function saveResultData() {
        const btnSave = document.getElementById('btnSaveResult');
        btnSave.disabled = true; btnSave.innerText = 'Đang lưu...';

        const parts = _resultGroupKey.split('|');
        const season = parts[0];
        const rawTime = parts[1] || '';
        let timeStr = '';
        if (rawTime) {
            let dt;
            if (rawTime.startsWith('/Date(')) {
                dt = new Date(parseInt(rawTime.match(/\d+/)[0]));
            } else {
                dt = new Date(rawTime);
            }
            if (!isNaN(dt.getTime())) timeStr = dt.toISOString();
        }

        const details = [];
        document.querySelectorAll('#resultDetailBody .result-detail-row').forEach(function(row) {
            const idInput = row.querySelector('.result-row-id');
            const resultCheck_win = row.querySelector('.result-win-check');
			const resultCheck_lost = row.querySelector('.result-lost-check');
            details.push({
                id: idInput ? idInput.value : '',
                result_win: resultCheck_win && resultCheck_win.checked ? 1 : 0,
                result_lost: resultCheck_lost && resultCheck_lost.checked ? 1 : 0
            });
        });

        fetch('SaveChampion.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ season: season, time: timeStr, resultDetails: details, saveResultYn: 'true' })
        })
        .then(function(r) {
            return r.text().then(function(text) {
                try { return JSON.parse(text); }
                catch(e) { throw new Error('Server response: ' + text.substring(0, 200)); }
            });
        })
        .then(function(data) {
            btnSave.disabled = false; btnSave.innerText = '✓ Lưu kết quả';
            if (data.isSuccess == 1) {
                alert(data.msg);
                closeChampionResultModal();
                if (typeof reloadChampionsData === 'function') reloadChampionsData(); else location.reload();
            } else { alert(data.msg); }
        })
        .catch(function(err) {
            btnSave.disabled = false; btnSave.innerText = '✓ Lưu kết quả';
            alert('Lỗi khi lưu kết quả: ' + err);
        });
        return false;
    }
</script>
