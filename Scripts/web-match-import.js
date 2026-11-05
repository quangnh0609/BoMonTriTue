(function () {
    'use strict';
    const el = id => document.getElementById(id);
    let busy = false, loaded = false, opener, snapshot = '', selectedDay = '';
    function renderDays() {
        const today = new Date(Date.now() + 7 * 3600000).toISOString().slice(0, 10);
        const dates = Array.from({ length: 7 }, (_, i) => new Date(Date.parse(today + 'T00:00:00Z') + i * 86400000).toISOString().slice(0, 10));
        if (!dates.includes(selectedDay)) selectedDay = today;
        el('webMatchDays').replaceChildren();
        dates.forEach(day => {
            const button = document.createElement('button'); button.type = 'button'; button.dataset.day = day;
            button.textContent = day.slice(8, 10) + '/' + day.slice(5, 7);
            button.setAttribute('aria-pressed', String(day === selectedDay));
            button.className = 'py-2 rounded-lg border text-xs font-semibold ' + (day === selectedDay ? 'bg-blue-600 text-white border-blue-600' : 'bg-white text-gray-700 hover:bg-blue-50');
            button.onclick = () => { if (!busy) { selectedDay = day; renderDays(); el('webMatchDays').querySelector('[data-day="' + day + '"]').focus(); } };
            el('webMatchDays').appendChild(button);
        });
    }
    function show(id) {
        ['webMatchFilter', 'webMatchResults'].forEach(x => el(x).classList.toggle('hidden', x !== id));
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
        el('webMatchCreate').textContent = busy ? 'Đang xử lý…' : 'Tạo trận đấu (' + n + ')';
        el('webMatchSelectAll').checked = n > 0 && n === checks.length;
        el('webMatchSelectAll').indeterminate = n > 0 && n < checks.length;
    }
    function lock(value) {
        busy = value;
        ['webMatchSearch', 'webMatchFilterClose', 'webMatchBack', 'webMatchResultsClose', 'webMatchSelectAll'].forEach(id => { el(id).disabled = value; });
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
        lock(true); el('webMatchFilterMessage').textContent = 'Đang lấy trận và phân tích kèo…';
        try {
            const data = await api({ action: 'search', date: selectedDay, league: el('webMatchLeague').value });
            snapshot = data.snapshot; el('webMatchList').replaceChildren();
            data.matches.forEach(m => {
                const row = document.createElement('div'); row.className = 'p-3 border-b';
                const label = document.createElement('label'); label.className = 'flex gap-3 items-start cursor-pointer';
                const check = document.createElement('input'); check.type = 'checkbox'; check.value = m.Id; check.onchange = update;
                const text = document.createElement('span'); text.textContent = m.Time + ' | ' + m.League + ' | ' + m.Home + ' – ' + m.Away;
                label.append(check, text); row.appendChild(label);
                const details = document.createElement('details'); details.className = 'text-xs text-gray-500 mt-2 ml-6';
                const summary = document.createElement('summary'); summary.textContent = 'Xem ' + m.Markets.length + ' kèo sẽ tạo'; details.appendChild(summary);
                m.Markets.forEach(k => { const p = document.createElement('p'); p.textContent = k.Name + ': ' + (k.Line === null ? [k.Home, k.Draw, k.Away].map(x => Number(x).toFixed(1)).join(' / ') : k.Line + ' (0.9 / 0.9)') + ' — ' + k.Bookmaker; details.appendChild(p); });
                row.appendChild(details); el('webMatchList').appendChild(row);
            });
            el('webMatchResultsMessage').textContent = data.matches.length ? 'Tìm thấy ' + data.matches.length + ' trận.' : 'Không có trận phù hợp trong ngày đã chọn.';
            el('webMatchFilterMessage').textContent = ''; show('webMatchResults');
        } catch (e) { el('webMatchFilterMessage').textContent = e.message; }
        finally { lock(false); }
    };
    el('webMatchCreate').onclick = async function () {
        if (busy || !selected().length) return;
        const ids = selected(); lock(true); el('webMatchResultsMessage').textContent = 'Đang tạo trận đấu…';
        try { await api({ action: 'create', ids, snapshot }); show(null); window.location.reload(); }
        catch (e) { el('webMatchResultsMessage').textContent = e.message; }
        finally { lock(false); }
    };
    el('webMatchSelectAll').onchange = function () { el('webMatchList').querySelectorAll('input').forEach(c => { c.checked = this.checked; }); update(); };
    el('webMatchFilterClose').onclick = el('webMatchResultsClose').onclick = () => { if (!busy) show(null); };
    el('webMatchBack').onclick = () => { if (!busy) { renderDays(); show('webMatchFilter'); } };
    document.addEventListener('keydown', function (e) {
        const dialog = ['webMatchFilter', 'webMatchResults'].map(el).find(x => !x.classList.contains('hidden'));
        if (!dialog) return;
        if (e.key === 'Escape' && !busy) { e.preventDefault(); show(null); }
        if (e.key === 'Enter' && e.target.tagName !== 'BUTTON') e.preventDefault();
        if (e.key === 'Tab') {
            const focusable = Array.from(dialog.querySelectorAll('button:not(:disabled), input:not(:disabled), select:not(:disabled), summary'));
            const first = focusable[0], last = focusable[focusable.length - 1];
            if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
            else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
        }
    });
}());
