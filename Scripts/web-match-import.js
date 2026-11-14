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
    function operationId() {
        const bytes = new Uint8Array(16);
        if (window.crypto && window.crypto.getRandomValues) window.crypto.getRandomValues(bytes);
        else for (let i = 0; i < bytes.length; i++) bytes[i] = Math.floor(Math.random() * 256);
        return Array.from(bytes, value => value.toString(16).padStart(2, '0')).join('');
    }
    function activePage() { return document.hidden !== true && !(typeof navigator !== 'undefined' && navigator.onLine === false); }
    function waitForActivePage() {
        if (activePage()) return Promise.resolve();
        return new Promise(resolve => {
            const resume = () => {
                if (!activePage()) return;
                if (document.removeEventListener) document.removeEventListener('visibilitychange', resume);
                if (window.removeEventListener) { window.removeEventListener('online', resume); window.removeEventListener('pageshow', resume); }
                resolve();
            };
            document.addEventListener('visibilitychange', resume);
            if (window.addEventListener) { window.addEventListener('online', resume); window.addEventListener('pageshow', resume); }
        });
    }
    async function requestJson(payload, url = 'WebMatches.aspx') {
        const controller = typeof AbortController !== 'undefined' ? new AbortController() : null;
        let slept = document.hidden === true;
        const resume = () => { if (document.hidden === true) slept = true; else if (slept && controller) controller.abort(); };
        document.addEventListener('visibilitychange', resume);
        try {
            const options = payload ? { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(payload) } : { credentials: 'same-origin', cache: 'no-store' };
            if (controller) options.signal = controller.signal;
            const response = await fetch(url, options);
            const result = await response.json();
            if (!result || typeof result !== 'object') throw new Error('Phản hồi không hợp lệ.');
            return result;
        } finally { if (document.removeEventListener) document.removeEventListener('visibilitychange', resume); }
    }
    async function recoverOperation(payload) {
        let retriedRead = false;
        const deadline = Date.now() + 35 * 60 * 1000;
        for (let attempt = 0; attempt < 12 && Date.now() < deadline; attempt++) {
            await waitForActivePage();
            const message = 'Đang khôi phục kết nối và kiểm tra kết quả lượt xử lý…';
            const notices = payload.action === 'create' ? ['webMatchPreviewMessage', 'webMatchTeamsMessage', 'webMatchResultsMessage'] : [payload.action === 'preview' ? 'webMatchResultsMessage' : 'webMatchFilterMessage'];
            notices.forEach(id => { el(id).textContent = message; });
            let result;
            try { result = await requestJson({ action: 'status', token: window.webMatchToken, source: payload.source, operationId: payload.operationId }); }
            catch (_) { if (attempt === 11) break; await new Promise(resolve => setTimeout(resolve, 3000)); continue; }
            if (result.code === 'WEB_MATCH_OPERATION_MISSING') {
                // A lost create response is ambiguous. Never submit the import again automatically.
                if (payload.action === 'create') throw new Error('Kết nối bị gián đoạn, chưa xác định được kết quả tạo trận. Kiểm tra danh sách Trận đấu trước khi thử lại. Các ô đã sửa vẫn được giữ.');
                if (retriedRead) throw new Error(result.message || 'Không thể khôi phục lượt tải. Vui lòng thử lại.');
                retriedRead = true;
                try { result = await requestJson(payload); } catch (_) { continue; }
            }
            if (!result.operationPending) return result;
            attempt = -1; // A healthy pending response is not a failed reconnect.
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
        throw new Error('Chưa khôi phục được kết nối. Các ô đã sửa vẫn được giữ; nếu đang tạo trận, hãy kiểm tra danh sách trước khi thử lại.');
    }
    async function api(data, tokenRetried = false, requestId = operationId()) {
        const payload = Object.assign({ token: window.webMatchToken, source, operationId: requestId }, data);
        let result;
        try { result = await requestJson(payload); }
        catch (_) { result = await recoverOperation(payload); }
        if (result.operationPending) result = await recoverOperation(payload);
        if (!result.ok && result.code === 'WEB_MATCH_TOKEN_CHANGED' && !tokenRetried) {
            const session = await requestJson(null, 'WebMatches.aspx?action=token');
            if (!session.ok || !session.token) throw new Error(session.message || 'Vui lòng đăng nhập lại.');
            window.webMatchToken = session.token;
            // Retry only an explicitly rejected token, never a timeout or an ambiguous create response.
            return api(data, true, requestId);
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
        el('webMatchTeamList').querySelectorAll('select,input,button').forEach(x => { x.disabled = value; });
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
            const all = team.allOptions || team.candidates || [];
            const row = document.createElement('div');
            const label = document.createElement('h4'); label.className = 'font-semibold text-sm mb-2';
            label.textContent = (kind === 'giải' ? 'Giải đấu: ' : 'Đội: ') + team.name;
            const modes = document.createElement('div'); modes.className = 'flex rounded-lg bg-gray-100 p-1 mb-3 gap-1';
            modes.setAttribute('role', 'group'); modes.setAttribute('aria-label', 'Chế độ đối chiếu ' + team.name);
            const createMode = document.createElement('button'), existingMode = document.createElement('button');
            createMode.type = existingMode.type = 'button';
            createMode.textContent = 'Tạo mới'; existingMode.textContent = 'Chọn ' + kind + ' đang có';
            modes.append(createMode, existingMode);
            const codeInput = document.createElement('input'); codeInput.type = 'text'; codeInput.maxLength = 16;
            codeInput.placeholder = 'Mã ' + kind + ' mới (tối đa 16 ký tự)'; codeInput.value = newTeamCodes[team.key] || '';
            codeInput.className = 'w-full border rounded-lg p-2 text-sm'; codeInput.setAttribute('aria-label', 'Mã ' + kind + ' mới cho ' + team.name);
            const existing = document.createElement('div');
            const search = document.createElement('input'); search.type = 'search'; search.placeholder = 'Tìm ' + kind + ' theo mã hoặc tên'; search.className = 'w-full border rounded-lg p-2 mb-2 text-sm'; search.setAttribute('aria-label', 'Tìm ' + kind + ' cho ' + team.name);
            const selection = document.createElement('p'); selection.className = 'text-sm text-blue-700 mb-2'; selection.setAttribute('aria-live', 'polite');
            const results = document.createElement('div'); results.className = 'max-h-48 overflow-auto border rounded-lg';
            const note = document.createElement('p'); note.className = 'text-xs text-gray-500 mt-2'; note.textContent = 'Lựa chọn được lưu khi tạo trận thành công để tự nhận diện ở lần lấy tiếp theo.';
            existing.append(search, selection, results, note);
            const normalize = text => String(text).normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/Đ/g, 'D').toLowerCase();
            let mode = teamChoices[team.key] === '__new__' ? 'new' : 'existing';
            let selectedId = mode === 'existing' ? teamChoices[team.key] || '' : '';
            const renderOptions = () => {
                const term = normalize(search.value.trim());
                const filtered = all.filter(t => normalize([t.name, t.id, t.theOddsApiName || '', t.apiFootballName || ''].join(' ')).includes(term));
                results.replaceChildren();
                const chosen = all.find(t => t.id === selectedId);
                selection.textContent = chosen ? 'Đã chọn: ' + chosen.name + ' (' + chosen.id + ')' : 'Bấm vào kết quả để chọn ' + kind + '.';
                filtered.forEach(t => {
                    const option = document.createElement('button'); option.type = 'button';
                    option.className = 'block w-full text-left p-2 border-b text-sm ' + (selectedId === t.id ? 'bg-blue-100 text-blue-700' : 'hover:bg-blue-50');
                    option.textContent = t.name + ' (' + t.id + ')'; option.setAttribute('aria-pressed', String(selectedId === t.id));
                    option.onclick = () => { if (busy) return; selectedId = t.id; teamChoices[team.key] = t.id; renderOptions(); };
                    results.appendChild(option);
                });
                if (!filtered.length) { const empty = document.createElement('p'); empty.className = 'p-2 text-sm text-gray-500'; empty.textContent = 'Không tìm thấy ' + kind + ' phù hợp.'; results.appendChild(empty); }
            };
            const setMode = value => {
                mode = value;
                teamChoices[team.key] = mode === 'new' ? '__new__' : selectedId;
                codeInput.hidden = mode !== 'new'; existing.hidden = mode !== 'existing';
                [createMode, existingMode].forEach((button, i) => {
                    const active = (i === 0) === (mode === 'new');
                    button.className = 'flex-1 rounded-md px-3 py-2 text-sm font-semibold ' + (active ? 'bg-white shadow text-blue-700' : 'text-gray-600');
                    button.setAttribute('aria-pressed', String(active));
                });
            };
            codeInput.oninput = () => { newTeamCodes[team.key] = codeInput.value.trim(); };
            createMode.onclick = () => { if (busy) return; setMode('new'); codeInput.focus(); };
            existingMode.onclick = () => { if (busy) return; setMode('existing'); search.focus(); };
            search.oninput = renderOptions;
            setMode(mode); renderOptions();
            row.append(label, modes, codeInput, existing); el('webMatchTeamList').appendChild(row);
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
            let showRates = false;
            rateButton.setAttribute('aria-expanded', 'false');
            rateButton.onclick = () => { if (busy) return; showRates = !showRates; rateButton.setAttribute('aria-expanded', String(showRates)); rateRows.forEach(row => row.classList.toggle('hidden', !showRates)); };
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
                const tr = document.createElement('tr'); if (rate) { rateRows.push(tr); tr.classList.add('hidden'); }
                const labelCell = document.createElement('td'); labelCell.className = 'p-2 border text-right ' + (rate ? 'text-red-500' : 'bg-gray-50 font-bold'); labelCell.textContent = label; tr.appendChild(labelCell);
                ['1', '3'].forEach(period => {
                    const td = document.createElement('td'); td.className = 'p-1 border ' + (period === '3' ? 'bg-blue-50/30 text-blue-700' : '');
                    if (type === '7' && period === '3') { td.textContent = '—'; tr.appendChild(td); return; }
                    const item = market(type, period), original = originals[item.Code];
                    const input = document.createElement('input'); input.type = 'text'; input.inputMode = property === 'Line' && ['1', '3', '6', '7'].includes(type) ? 'text' : 'decimal'; input.autocomplete = 'off'; input.maxLength = 24;
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
