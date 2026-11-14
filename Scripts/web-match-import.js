(function () {
    'use strict';
    const el = id => document.getElementById(id);
    let busy = false, loaded = false, opener, snapshot = '', selectedDays = new Set(), source = 'the-odds-api', previewToken = '', previewDrafts = {};
    const dialogs = ['webMatchSource', 'webMatchFilter', 'webMatchResults', 'webMatchTeams', 'webMatchPreview'];
    let pendingIds = [], teamChoices = {}, newTeamCodes = {}, requiredTeams = [];
    function renderDays(defaultSelection = true) {
        const today = new Date(Date.now() + 7 * 3600000).toISOString().slice(0, 10);
        const dates = Array.from({ length: 7 }, (_, i) => new Date(Date.parse(today + 'T00:00:00Z') + i * 86400000).toISOString().slice(0, 10));
        selectedDays = new Set(Array.from(selectedDays).filter(day => dates.includes(day)));
        if (defaultSelection && !selectedDays.size) selectedDays.add(today);
        el('webMatchDays').replaceChildren();
        dates.forEach(day => {
            const button = document.createElement('button'); button.type = 'button'; button.dataset.day = day;
            button.textContent = day.slice(8, 10) + '/' + day.slice(5, 7);
            button.setAttribute('aria-pressed', String(selectedDays.has(day)));
            button.className = 'py-2 rounded-lg border text-xs font-semibold ' + (selectedDays.has(day) ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-gray-700 hover:bg-blue-50');
            button.onclick = () => { if (!busy) { if (selectedDays.has(day)) selectedDays.delete(day); else selectedDays.add(day); renderDays(false); el('webMatchDays').querySelector('[data-day="' + day + '"]').focus(); } };
            el('webMatchDays').appendChild(button);
        });
    }
    function show(id) {
        dialogs.forEach(x => el(x).classList.toggle('hidden', x !== id));
        document.body.style.overflow = id ? 'hidden' : '';
        if (id) el(id).querySelector('input,button').focus();
        else if (opener) opener.focus();
    }
    async function api(data, tokenRetried = false) {
        const response = await fetch('WebMatches.aspx', { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(Object.assign({ token: window.webMatchToken, source }, data)) });
        let result;
        try { result = await response.json(); } catch (_) { throw new Error('Không nhận được dữ liệu. Vui lòng kiểm tra kết nối hoặc đăng nhập lại.'); }
        if (!result.ok && result.code === 'WEB_MATCH_TOKEN_CHANGED' && !tokenRetried) {
            const refresh = await fetch('WebMatches.aspx?action=token', { credentials: 'same-origin', cache: 'no-store' });
            let session;
            try { session = await refresh.json(); } catch (_) { throw new Error('Không nhận được dữ liệu. Vui lòng kiểm tra kết nối hoặc đăng nhập lại.'); }
            if (!session.ok || !session.token) throw new Error(session.message || 'Vui lòng đăng nhập lại.');
            window.webMatchToken = session.token;
            // Retry only an explicitly rejected token, never a timeout or an ambiguous create response.
            return api(data, true);
        }
        const quota = result.quota;
        const quotaLabel = result.quotaUnit || (source === 'api-football' ? 'Lượt gọi hôm nay' : 'Credits còn lại');
        const quotaText = (quota ? quotaLabel + ': ' + Number(quota.Remaining).toLocaleString('vi-VN') + ' / ' + Number(quota.Total).toLocaleString('vi-VN') : quotaLabel + ': — / —') + ' · Reset: ' + (result.quotaResetDate || '—');
        ['webMatchFilterQuota', 'webMatchResultsQuota', 'webMatchPreviewQuota'].forEach(id => { el(id).textContent = quotaText; });
        if (!result.ok) throw new Error(result.message || 'Không thể xử lý yêu cầu.');
        return result;
    }
    function selected() { return Array.from(el('webMatchList').querySelectorAll('input:checked')).map(x => x.value); }
    function update() {
        const checks = Array.from(el('webMatchList').querySelectorAll('input'));
        const n = selected().length;
        el('webMatchCreate').disabled = busy || n === 0;
        el('webMatchCreate').textContent = busy ? 'Đang xử lý…' : (source === 'api-football' ? 'Xem trước kèo (' : 'Lấy kèo và tạo (') + n + ')';
        el('webMatchPreviewCreate').disabled = busy || !previewToken;
        el('webMatchSelectAll').checked = n > 0 && n === checks.length;
        el('webMatchSelectAll').indeterminate = n > 0 && n < checks.length;
    }
    function lock(value) {
        busy = value;
        ['webMatchPreviewBack', 'webMatchPreviewCreate', 'webMatchSourceOdds', 'webMatchSourceFootball', 'webMatchSourceClose', 'webMatchChangeSource', 'webMatchSearch', 'webMatchFilterClose', 'webMatchBack', 'webMatchResultsClose', 'webMatchSelectAll', 'webMatchTeamsBack', 'webMatchTeamsCreate'].forEach(id => { el(id).disabled = value; });
        el('webMatchPreviewList').querySelectorAll('input,button').forEach(x => { x.disabled = value; });
        el('webMatchTeamList').querySelectorAll('select,input').forEach(x => { x.disabled = value; });
        el('webMatchList').querySelectorAll('input').forEach(x => { x.disabled = value; });
        el('webMatchDays').querySelectorAll('button').forEach(x => { x.disabled = value; });
        el('webMatchLeague').disabled = value;
        update();
    }
    window.webMatchOpen = async function () {
        if (busy) return;
        opener = document.activeElement;
        show('webMatchSource');
    };
    async function chooseSource(value) {
        if (busy) return;
        source = value; loaded = false; snapshot = ''; previewToken = ''; previewDrafts = {};  pendingIds = []; teamChoices = {}; newTeamCodes = {};
        el('webMatchList').replaceChildren();
        el('webMatchLeague').replaceChildren();
        const placeholder = document.createElement('option'); placeholder.value = ''; placeholder.textContent = 'Chọn giải đấu'; el('webMatchLeague').appendChild(placeholder);
        const name = source === 'api-football' ? 'API-Football' : 'The Odds API';
        el('webMatchFilterTitle').textContent = 'Lấy trận đấu từ ' + name;
        el('webMatchResultsTitle').textContent = 'Chọn trận đấu từ ' + name;
        el('webMatchSourceNote').textContent = source === 'api-football' ? 'Lấy danh sách trận cũng tính lượt gọi API. Quyền truy cập mùa giải và kèo phụ thuộc gói tài khoản.' : 'Lấy danh sách trận không mất credits. Chỉ lấy kèo cho các trận được chọn.';
        ['webMatchFilterQuota', 'webMatchResultsQuota', 'webMatchPreviewQuota'].forEach(id => { el(id).textContent = source === 'api-football' ? 'Lượt gọi hôm nay: — / —' : 'Credits còn lại: — / —'; });
        renderDays(); show('webMatchFilter');
        if (loaded) return;
        lock(true); el('webMatchFilterMessage').textContent = 'Đang tải giải đấu…';
        try {
            const data = await api({ action: 'leagues' });
            data.leagues.forEach(l => { const option = document.createElement('option'); option.value = l.id; option.textContent = l.name; el('webMatchLeague').appendChild(option); });
            loaded = true; el('webMatchFilterMessage').textContent = '';
        } catch (e) { el('webMatchFilterMessage').textContent = e.message; }
        finally { lock(false); }
    };
    el('webMatchSourceOdds').onclick = () => chooseSource('the-odds-api');
    el('webMatchSourceFootball').onclick = () => chooseSource('api-football');
    el('webMatchSourceClose').onclick = () => { if (!busy) show(null); };
    el('webMatchChangeSource').onclick = () => { if (!busy) show('webMatchSource'); };
    el('webMatchSearch').onclick = async function () {
        if (busy) return;
        if (!el('webMatchLeague').value) { el('webMatchFilterMessage').textContent = 'Vui lòng chọn một giải đấu.'; el('webMatchLeague').focus(); return; }
        if (!selectedDays.size) { el('webMatchFilterMessage').textContent = 'Vui lòng chọn ít nhất một ngày.'; return; }
        lock(true); el('webMatchFilterMessage').textContent = 'Đang lấy danh sách trận…';
        try {
            const data = await api({ action: 'search', dates: Array.from(selectedDays).sort(), league: el('webMatchLeague').value });
            snapshot = data.snapshot; previewDrafts = {}; teamChoices = {}; newTeamCodes = {}; pendingIds = []; el('webMatchList').replaceChildren();
            data.matches.forEach(m => {
                const row = document.createElement('div'); row.className = 'p-3 border-b';
                const label = document.createElement('label'); label.className = 'flex gap-3 items-start cursor-pointer';
                const check = document.createElement('input'); check.type = 'checkbox'; check.value = m.Id; check.onchange = update;
                const text = document.createElement('span'); text.className = 'font-semibold'; text.textContent = m.Time + ' | ' + m.Home + ' – ' + m.Away;
                label.append(check, text); row.appendChild(label);
                el('webMatchList').appendChild(row);
            });
            el('webMatchResultsMessage').textContent = data.matches.length ? 'Tìm thấy ' + data.matches.length + ' trận. ' + (source === 'api-football' ? 'Chọn trận để xem trước kèo.' : 'Chọn trận để lấy kèo và tạo.') : 'Không có trận phù hợp trong các ngày đã chọn.';
            el('webMatchFilterMessage').textContent = ''; show('webMatchResults');
        } catch (e) { el('webMatchFilterMessage').textContent = e.message; }
        finally { lock(false); }
    };
    function renderTeamChoices(data) {
        requiredTeams = data.requiredTeams; el('webMatchTeamList').replaceChildren();
        requiredTeams.forEach((team, index) => {
            const kind = team.kind || 'đội';
            const candidates = team.candidates || [], all = team.allOptions || [];
            let pool = candidates.length ? candidates : all;
            const row = document.createElement('div');
            const label = document.createElement('label'); label.className = 'block font-semibold text-sm mb-1';
            label.htmlFor = 'entityChoice_' + index;
            label.textContent = (kind === 'giải' ? 'Giải đấu: ' : 'Đội: ') + team.name;
            const search = document.createElement('input'); search.type = 'search'; search.placeholder = 'Tìm ' + kind + ' theo tên hoặc mã'; search.className = 'w-full border rounded-lg p-2 mb-2 text-sm'; search.setAttribute('aria-label', 'Tìm ' + kind + ' cho ' + team.name);
            const select = document.createElement('select'); select.id = label.htmlFor; select.className = 'w-full border rounded-lg p-2 text-sm';
            const add = (value, text) => { const option = document.createElement('option'); option.value = value; option.textContent = text; select.appendChild(option); };
            const codeInput = document.createElement('input'); codeInput.type = 'text'; codeInput.maxLength = 16;
            codeInput.placeholder = 'Mã ' + kind + ' mới (tối đa 16 ký tự)'; codeInput.value = newTeamCodes[team.key] || '';
            codeInput.className = 'w-full border rounded-lg p-2 mt-2 text-sm'; codeInput.setAttribute('aria-label', 'Mã ' + kind + ' mới cho ' + team.name);
            const normalize = text => String(text).normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
            const renderOptions = () => {
                const term = normalize(search.value.trim()), previous = teamChoices[team.key] || '';
                const searchPool = term ? all : pool;
                const filtered = searchPool.filter(t => normalize([t.name, t.id, t.theOddsApiName || '', t.apiFootballName || ''].join(' ')).includes(term));
                select.replaceChildren();
                add('', filtered.length ? 'Chọn ' + kind + ' đang có hoặc tạo mới' : 'Không tìm thấy ' + kind + ' phù hợp');
                add('__new__', 'Không chọn thủ công — Tạo ' + kind + ' mới: ' + team.name);
                filtered.forEach(t => add(t.id, t.name + ' (' + t.id + ')'));
                const chosen = all.find(t => t.id === previous);
                if (chosen && !filtered.some(t => t.id === previous)) add(chosen.id, chosen.name + ' (' + chosen.id + ')');
                select.value = previous === '__new__' || filtered.some(t => t.id === previous) || chosen ? previous : '';
                teamChoices[team.key] = select.value;
                codeInput.hidden = select.value !== '__new__';
                select.size = Math.min(6, select.options.length);
            };
            renderOptions();
            codeInput.oninput = () => { newTeamCodes[team.key] = codeInput.value.trim(); };
            select.onchange = () => { teamChoices[team.key] = select.value; codeInput.hidden = select.value !== '__new__'; if (!codeInput.hidden) codeInput.focus(); };
            search.oninput = renderOptions;
            const manual = document.createElement('button'); manual.type = 'button'; manual.className = 'text-blue-600 text-sm mt-2'; manual.textContent = 'Chọn thủ công từ toàn bộ danh sách'; manual.hidden = !candidates.length;
            manual.onclick = () => { if (busy) return; pool = all; search.value = ''; manual.hidden = true; renderOptions(); search.focus(); };
            row.append(label, search, select, codeInput, manual); el('webMatchTeamList').appendChild(row);
        });
        el('webMatchTeamsMessage').textContent = ''; show('webMatchTeams');
    }
    async function createMatches(messageId) {
        lock(true); el(messageId).textContent = (source === 'api-football' ? 'Đang tạo các kèo đã xem trước…' : 'Đang lấy kèo cho trận đã chọn và tạo trận đấu…');
        try {
            const data = await api({ action: 'create', ids: pendingIds, snapshot, previewToken, edits: source === 'api-football' ? collectPreviewEdits() : undefined, teamChoices, newTeamCodes });
            if (data.needsTeams) { el(messageId).textContent = ''; renderTeamChoices(data); return; }
            show(null); window.location.reload();
        }
        catch (e) { el(messageId).textContent = e.message; }
        finally { lock(false); }
    }
    function collectPreviewEdits() {
        const edits = {};
        pendingIds.forEach(id => {
            const draft = previewDrafts[id] || {};
            edits[id] = Object.values(draft).filter(k => k.Code[0] === '4' ? [k.Home, k.Draw, k.Away].some(value => String(value).trim() !== '') : String(k.Line).trim() !== '').map(k => Object.assign({}, k));
        });
        return edits;
    }
    function renderPreview(matches) {
        el('webMatchPreviewList').replaceChildren();
        matches.forEach(m => {
            const originals = {};
            m.Markets.filter(k => !k.Code.endsWith('2')).forEach(k => { originals[k.Code] = k; });
            const draft = previewDrafts[m.Id] || {};
            previewDrafts[m.Id] = draft;
            const section = document.createElement('section'); section.className = 'border rounded-xl mb-4 overflow-hidden';
            const title = document.createElement('h4'); title.className = 'font-bold p-3 bg-blue-600 text-white'; title.textContent = m.Time + ' | ' + m.Home + ' – ' + m.Away;
            section.appendChild(title);
            const table = document.createElement('table'); table.className = 'w-full table-fixed border-collapse text-xs';
            const head = document.createElement('tr');
            ['Loại kèo', 'Hiệp 1', 'Cả trận'].forEach((text, index) => { const th = document.createElement('th'); th.textContent = text; th.className = 'p-2 border text-right ' + (index === 2 ? 'bg-blue-50 text-blue-700' : 'bg-gray-100'); head.appendChild(th); });
            table.appendChild(head);
            const rateRows = [];
            const rateButton = document.createElement('button'); rateButton.type = 'button'; rateButton.textContent = 'Rate'; rateButton.className = 'ml-2 rounded bg-red-500 text-white px-2 py-1';
            let showRates = true;
            rateButton.onclick = () => { if (busy) return; showRates = !showRates; rateRows.forEach(row => row.classList.toggle('hidden', !showRates)); };
            head.children[0].appendChild(rateButton);
            function market(type, period) {
                const code = type + period;
                if (!draft[code]) {
                    const original = originals[code];
                    draft[code] = { Code: code, Line: original && original.Line != null ? String(original.Line) : '', Home: original ? String(original.Home) : type === '4' ? '' : '0.9', Away: original ? String(original.Away) : type === '4' ? '' : '0.9', Draw: original && type === '4' ? String(original.Draw) : '' };
                }
                return draft[code];
            }
            function row(type, property, label, rate = false) {
                const tr = document.createElement('tr'); if (rate) rateRows.push(tr);
                const labelCell = document.createElement('td'); labelCell.className = 'p-2 border text-right ' + (rate ? 'text-red-500' : 'bg-gray-50 font-bold'); labelCell.textContent = label; tr.appendChild(labelCell);
                ['1', '3'].forEach(period => {
                    const td = document.createElement('td'); td.className = 'p-1 border ' + (period === '3' ? 'bg-blue-50/30 text-blue-700' : '');
                    if (type === '7' && period === '3') { td.textContent = '—'; tr.appendChild(td); return; }
                    const item = market(type, period), original = originals[item.Code];
                    const input = document.createElement('input'); input.type = 'text'; input.inputMode = 'decimal'; input.autocomplete = 'off'; input.maxLength = 24;
                    input.className = 'w-full min-w-0 p-2 text-right bg-transparent outline-none focus:bg-white focus:ring-1 focus:ring-blue-400'; input.value = item[property];
                    input.dataset.fixture = m.Id; input.dataset.code = item.Code; input.dataset.field = property;
                    input.setAttribute('aria-label', m.Home + ' – ' + m.Away + ': ' + label + ' ' + (period === '1' ? 'H1' : 'FT'));
                    input.oninput = () => { item[property] = input.value; };
                    td.appendChild(input);
                    if (property === 'Line') {
                        const note = document.createElement('span'); note.className = 'block text-right text-[10px] text-gray-400 px-2'; note.textContent = original ? (original.Estimated ? 'Suy từ FT' : original.Bookmaker) : 'Có thể nhập thêm'; td.appendChild(note);
                        input.oninput = () => { item[property] = input.value; note.textContent = 'Đã chỉnh sửa'; };
                    }
                    tr.appendChild(td);
                });
                table.appendChild(tr);
            }
            function pair(type, lineLabel, first, second) { row(type, 'Line', lineLabel); row(type, 'Home', first, true); row(type, 'Away', second, true); }
            pair('2', 'Tài bàn', 'Rate tài', 'Rate xỉu');
            pair('3', 'Bàn (chủ nhà)', 'Rate chủ', 'Rate khách');
            row('4', 'Home', 'Chủ (1X2)'); row('4', 'Draw', 'Hòa (1X2)'); row('4', 'Away', 'Khách (1X2)');
            pair('0', 'Tài góc', 'Rate tài', 'Rate xỉu'); pair('1', 'Góc (chủ nhà)', 'Rate chủ', 'Rate khách');
            pair('5', 'Tài thẻ', 'Rate tài', 'Rate xỉu'); pair('6', 'Thẻ (chủ nhà)', 'Rate chủ', 'Rate khách');
            pair('7', 'Giao bóng H1', 'Rate chủ', 'Rate khách');
            section.appendChild(table); el('webMatchPreviewList').appendChild(section);
        });
    }
    async function previewMatches() {
        lock(true); previewToken = ''; el('webMatchResultsMessage').textContent = 'Đang lấy kèo để xem trước… Vui lòng chờ theo giới hạn lượt gọi API.';
        try {
            const data = await api({ action: 'preview', ids: pendingIds, snapshot });
            previewToken = data.previewToken; renderPreview(data.matches);
            el('webMatchPreviewMessage').textContent = 'Sửa trực tiếp mốc và Rate của từng trận. H1 và FT sửa độc lập; xóa mốc để bỏ kèo, xóa đủ ba giá để bỏ 1X2. Không lấy H2. Giao bóng H1 cần được giữ.';
            el('webMatchResultsMessage').textContent = ''; show('webMatchPreview');
        } catch (e) { el('webMatchResultsMessage').textContent = e.message; }
        finally { lock(false); }
    }
    el('webMatchPreviewBack').onclick = () => { if (!busy) show('webMatchResults'); };
    el('webMatchPreviewCreate').onclick = async () => { if (!busy && previewToken) await createMatches('webMatchPreviewMessage'); };
    el('webMatchCreate').onclick = async function () {
        if (busy || !selected().length) return;
        pendingIds = selected(); previewToken = '';
        if (source === 'api-football') await previewMatches();
        else await createMatches('webMatchResultsMessage');
    };
    el('webMatchTeamsCreate').onclick = async function () {
        if (busy) return;
        if (requiredTeams.some(t => !teamChoices[t.key])) { el('webMatchTeamsMessage').textContent = 'Chọn cách xử lý cho từng đội/giải trước khi tiếp tục.'; return; }
        const creating = requiredTeams.filter(t => teamChoices[t.key] === '__new__');
        const invalid = creating.find(t => !/^[A-Za-z0-9_-]{1,16}$/.test(newTeamCodes[t.key] || ''));
        if (invalid) { el('webMatchTeamsMessage').textContent = 'Nhập mã ' + (invalid.kind || 'đội') + ' cho ' + invalid.name + ': 1–16 ký tự, gồm chữ không dấu, số, dấu - hoặc _.'; return; }
        if (new Set(creating.map(t => (t.kind || 'đội') + ':' + newTeamCodes[t.key].toUpperCase())).size !== creating.length) { el('webMatchTeamsMessage').textContent = 'Mã các đội hoặc giải mới không được trùng trong cùng loại.'; return; }
        await createMatches('webMatchTeamsMessage');
    };
    el('webMatchTeamsBack').onclick = () => { if (!busy) show(source === 'api-football' ? 'webMatchPreview' : 'webMatchResults'); };
    el('webMatchSelectAll').onchange = function () { el('webMatchList').querySelectorAll('input').forEach(c => { c.checked = this.checked; }); update(); };
    el('webMatchFilterClose').onclick = el('webMatchResultsClose').onclick = () => { if (!busy) show(null); };
    el('webMatchBack').onclick = () => { if (!busy) { renderDays(); show('webMatchFilter'); } };
    document.addEventListener('keydown', function (e) {
        const dialog = dialogs.map(el).find(x => !x.classList.contains('hidden'));
        if (!dialog) return;
        if (e.key === 'Escape' && !busy) { e.preventDefault(); show(dialog.id === 'webMatchTeams' ? (source === 'api-football' ? 'webMatchPreview' : 'webMatchResults') : dialog.id === 'webMatchPreview' ? 'webMatchResults' : null); }
        if (e.key === 'Enter' && e.target.tagName !== 'BUTTON') e.preventDefault();
        if (e.key === 'Tab') {
            const focusable = Array.from(dialog.querySelectorAll('button:not(:disabled), input:not(:disabled), select:not(:disabled), summary'));
            const first = focusable[0], last = focusable[focusable.length - 1];
            if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
            else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
        }
    });
}());
