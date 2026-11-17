(function () {
    'use strict';
    if (window.BetLinePicker) return;
    const style = document.createElement('style');
    style.textContent = 'input[data-line-picker]{cursor:pointer;padding-right:24px!important;background-image:url("data:image/svg+xml,%3Csvg xmlns=\'http://www.w3.org/2000/svg\' width=\'16\' height=\'16\' viewBox=\'0 0 16 16\'%3E%3Cpath d=\'m4 6 4 4 4-4\' fill=\'none\' stroke=\'%2364748b\' stroke-width=\'2\'/%3E%3C/svg%3E");background-repeat:no-repeat;background-position:right 4px center}';
    document.head.appendChild(style);
    const ROW = 32, MIN = -400, MAX = 400;
    let popup, list, active, cursor = 0, restoring = false;
    const format = tick => String(tick / 4);
    function close(restore) {
        if (!active) return;
        const field = active;
        field.setAttribute('aria-expanded', 'false');
        field.removeAttribute('aria-activedescendant');
        popup.remove(); popup = list = active = null;
        if (restore && field.isConnected) {
            restoring = true; field.focus({ preventScroll: true }); restoring = false;
        }
    }
    function choose(value) {
        if (!active || active.disabled) return;
        active.value = value;
        active.dispatchEvent(new Event('input', { bubbles: true }));
        active.dispatchEvent(new Event('change', { bubbles: true }));
        close(true);
    }
    function highlight() {
        Array.from(list.children).forEach((option, i) => {
            const selected = i + MIN === cursor;
            option.setAttribute('aria-selected', String(selected));
            option.style.background = selected ? '#dbeafe' : '';
            option.style.color = selected ? '#1d4ed8' : '';
        });
        active.setAttribute('aria-activedescendant', 'bet-line-option-' + cursor);
        list.scrollTop = (cursor - MIN) * ROW;
    }
    function open(field) {
        if (field.disabled || restoring) return;
        if (active === field) return;
        close(false); active = field;
        const value = Number(field.value.trim().replace(',', '.'));
        cursor = Math.max(MIN, Math.min(MAX, Math.round((Number.isFinite(value) ? value : 0) * 4)));
        popup = document.createElement('div');
        popup.style.cssText = 'position:fixed;z-index:10000;background:white;border:1px solid #cbd5e1;border-radius:10px;box-shadow:0 8px 28px #0003;overflow:hidden;color:#1f2937;font:16px sans-serif;';
        popup.setAttribute('data-bet-line-popup', '');
        const clear = document.createElement('button');
        clear.type = 'button'; clear.textContent = 'Bỏ kèo (để trống)';
        clear.style.cssText = 'display:block;width:100%;height:36px;border:0;border-bottom:1px solid #e2e8f0;background:#f8fafc;cursor:pointer;';
        clear.onclick = () => choose(''); popup.appendChild(clear);
        list = document.createElement('div'); list.id = 'bet-line-options'; list.setAttribute('role', 'listbox');
        list.setAttribute('aria-label', field.getAttribute('aria-label') || 'Mốc kèo');
        list.style.cssText = 'height:224px;overflow-y:auto;overscroll-behavior:contain;padding:96px 0;box-sizing:border-box;touch-action:pan-y;';
        for (let tick = MIN; tick <= MAX; tick++) {
            const option = document.createElement('div');
            option.id = 'bet-line-option-' + tick; option.setAttribute('role', 'option');
            option.textContent = format(tick);
            option.style.cssText = 'height:32px;line-height:32px;text-align:center;cursor:pointer;font-weight:600;';
            option.onclick = () => choose(format(tick)); list.appendChild(option);
        }
        popup.appendChild(list); document.body.appendChild(popup);
        const rect = field.getBoundingClientRect();
        const width = Math.min(Math.max(rect.width, 160), window.innerWidth - 16);
        popup.style.width = width + 'px';
        popup.style.left = Math.max(8, Math.min(rect.left, window.innerWidth - width - 8)) + 'px';
        const height = 262;
        const top = rect.bottom + height + 12 <= window.innerHeight ? rect.bottom + 4 : rect.top - height - 4;
        popup.style.top = Math.max(8, Math.min(top, window.innerHeight - height - 8)) + 'px';
        field.setAttribute('aria-expanded', 'true'); highlight();
    }
    function isField(target) { return target && target.matches && target.matches('input[data-line-picker]'); }
    function prepare(field) {
        field.readOnly = true; field.inputMode = 'none';
        field.setAttribute('role', 'combobox'); field.setAttribute('aria-haspopup', 'listbox');
        field.setAttribute('aria-controls', 'bet-line-options');
        field.setAttribute('aria-expanded', 'false');
        field.style.cursor = 'pointer';
    }
    document.addEventListener('focus', e => {
        if (!isField(e.target)) return;
        prepare(e.target); open(e.target); e.stopImmediatePropagation();
    }, true);
    document.addEventListener('click', e => {
        if (!isField(e.target)) return;
        open(e.target); e.stopImmediatePropagation();
    }, true);
    document.addEventListener('pointerdown', e => {
        if (active && e.target !== active && !popup.contains(e.target)) close(false);
    }, true);
    document.addEventListener('focusin', e => {
        if (active && e.target !== active && !popup.contains(e.target)) close(false);
    });
    document.addEventListener('keydown', e => {
        if (!isField(e.target)) return;
        if (e.key === 'Tab') { close(false); return; }
        if (e.key === 'Escape') { close(true); e.preventDefault(); e.stopImmediatePropagation(); return; }
        if (!['ArrowDown', 'ArrowUp', 'PageDown', 'PageUp', 'Home', 'End', 'Enter', ' '].includes(e.key)) return;
        e.preventDefault(); e.stopImmediatePropagation();
        if (!active) { open(e.target); return; }
        if (e.key === 'Enter' || e.key === ' ') { choose(format(cursor)); return; }
        if (e.key === 'Home') cursor = MIN;
        else if (e.key === 'End') cursor = MAX;
        else cursor = Math.max(MIN, Math.min(MAX, cursor + ({ ArrowDown: 1, ArrowUp: -1, PageDown: 7, PageUp: -7 }[e.key])));
        highlight();
    }, true);
    window.addEventListener('resize', () => close(false));
    document.addEventListener('scroll', e => { if (active && e.target !== list && !popup.contains(e.target)) close(false); }, true);
    window.BetLinePicker = { prepare, close: () => close(false) };
})();
