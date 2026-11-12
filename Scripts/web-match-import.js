(function () {
    'use strict';
    const el = id => document.getElementById(id);
    let busy = false, loaded = false, opener, snapshot = '', selectedDays = new Set();
    const dialogs = ['webMatchFilter', 'webMatchResults', 'webMatchTeams'];
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
    async function api(data) {
        const response = await fetch('WebMatches.aspx', { method: 'POST', credentials: 'same-origin', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(Object.assign({ token: window.webMatchToken }, data)) });
        let result;
        try { result = await response.json(); } catch (_) { throw new Error('Không nhận được dữ liệu. Vui lòng kiểm tra kết nối hoặc đăng nhập lại.'); }
        const quota = result.quota;
        const quotaText = (quota ? 'Credits còn lại: ' + Number(quota.Remaining).toLocaleString('vi-VN') + ' / ' + Number(quota.Total).toLocaleString('vi-VN') : 'Credits còn lại: — / —') + ' · Reset: ' + (result.quotaResetDate || '—');
        ['webMatchFilterQuota', 'webMatchResultsQuota'].forEach(id => { el(id).textContent = quotaText; });
        if (!result.ok) throw new Error(result.message || 'Không thể xử lý yêu cầu.');
        return result;
    }
    function selected() { return Array.from(el('webMatchList').querySelectorAll('input:checked')).map(x => x.value); }
    function update() {
        const checks = Array.from(el('webMatchList').querySelectorAll('input'));
        const n = selected().length;
        el('webMatchCreate').disabled = busy || n === 0;
        el('webMatchCreate').textContent = busy ? 'Đang xử lý…' : 'Lấy kèo và tạo (' + n + ')';
        el('webMatchSelectAll').checked = n > 0 && n === checks.length;
        el('webMatchSelectAll').indeterminate = n > 0 && n < checks.length;
    }
    function lock(value) {
        busy = value;
        ['webMatchSearch', 'webMatchFilterClose', 'webMatchBack', 'webMatchResultsClose', 'webMatchSelectAll', 'webMatchTeamsBack', 'webMatchTeamsCreate'].forEach(id => { el(id).disabled = value; });
        el('webMatchTeamList').querySelectorAll('select,input').forEach(x => { x.disabled = value; });
        el('webMatchList').querySelectorAll('input').forEach(x => { x.disabled = value; });
        el('webMatchDays').querySelectorAll('button').forEach(x => { x.disabled = value; });
        el('webMatchLeague').disabled = value;
        update();
    }
    window.webMatchOpen = async function () {
        if (busy) return;
        opener = document.activeElement;
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
    el('webMatchSearch').onclick = async function () {
        if (busy) return;
        if (!el('webMatchLeague').value) { el('webMatchFilterMessage').textContent = 'Vui lòng chọn một giải đấu.'; el('webMatchLeague').focus(); return; }
        if (!selectedDays.size) { el('webMatchFilterMessage').textContent = 'Vui lòng chọn ít nhất một ngày.'; return; }
        lock(true); el('webMatchFilterMessage').textContent = 'Đang lấy danh sách trận…';
        try {
            const data = await api({ action: 'search', dates: Array.from(selectedDays).sort(), league: el('webMatchLeague').value });
            snapshot = data.snapshot; teamChoices = {}; newTeamCodes = {}; pendingIds = []; el('webMatchList').replaceChildren();
            data.matches.forEach(m => {
                const row = document.createElement('div'); row.className = 'p-3 border-b';
                const label = document.createElement('label'); label.className = 'flex gap-3 items-start cursor-pointer';
                const check = document.createElement('input'); check.type = 'checkbox'; check.value = m.Id; check.onchange = update;
                const text = document.createElement('span'); text.className = 'font-semibold'; text.textContent = m.Time + ' | ' + m.Home + ' – ' + m.Away;
                label.append(check, text); row.appendChild(label);
                el('webMatchList').appendChild(row);
            });
            el('webMatchResultsMessage').textContent = data.matches.length ? 'Tìm thấy ' + data.matches.length + ' trận. Chọn trận để lấy kèo và tạo; chỉ các trận được chọn mới dùng credits lấy kèo.' : 'Không có trận phù hợp trong các ngày đã chọn.';
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
                const filtered = pool.filter(t => normalize(t.name + ' ' + t.id).includes(term));
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
        lock(true); el(messageId).textContent = 'Đang lấy kèo cho trận đã chọn và tạo trận đấu…';
        try {
            const data = await api({ action: 'create', ids: pendingIds, snapshot, teamChoices, newTeamCodes });
            if (data.needsTeams) { el(messageId).textContent = ''; renderTeamChoices(data); return; }
            show(null); window.location.reload();
        }
        catch (e) { el(messageId).textContent = e.message; }
        finally { lock(false); }
    }
    el('webMatchCreate').onclick = async function () {
        if (busy || !selected().length) return;
        pendingIds = selected(); await createMatches('webMatchResultsMessage');
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
    el('webMatchTeamsBack').onclick = () => { if (!busy) show('webMatchResults'); };
    el('webMatchSelectAll').onchange = function () { el('webMatchList').querySelectorAll('input').forEach(c => { c.checked = this.checked; }); update(); };
    el('webMatchFilterClose').onclick = el('webMatchResultsClose').onclick = () => { if (!busy) show(null); };
    el('webMatchBack').onclick = () => { if (!busy) { renderDays(); show('webMatchFilter'); } };
    document.addEventListener('keydown', function (e) {
        const dialog = dialogs.map(el).find(x => !x.classList.contains('hidden'));
        if (!dialog) return;
        if (e.key === 'Escape' && !busy) { e.preventDefault(); show(dialog.id === 'webMatchTeams' ? 'webMatchResults' : null); }
        if (e.key === 'Enter' && e.target.tagName !== 'BUTTON') e.preventDefault();
        if (e.key === 'Tab') {
            const focusable = Array.from(dialog.querySelectorAll('button:not(:disabled), input:not(:disabled), select:not(:disabled), summary'));
            const first = focusable[0], last = focusable[focusable.length - 1];
            if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
            else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
        }
    });
}());
