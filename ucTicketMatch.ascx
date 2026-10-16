<%@ Control Language="C#" AutoEventWireup="true" %>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<div id="modalTicketMatch" class="fixed inset-0 bg-gray-900/80 z-[60] hidden items-center justify-center p-4 font-sans">
    <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-2xl flex flex-col overflow-hidden text-[12px]" style="max-height: 90vh;">
        
        <div class="bg-gradient-to-r from-yellow-500 to-yellow-600 px-6 py-4 text-white flex justify-between items-center shrink-0 shadow-lg">
            <h3 class="font-bold flex items-center text-[14px]">
                <i class="fa-solid fa-ticket mr-3 text-lg"></i>
                Vé cược - <span id="tmMatchLabel" class="ml-2"></span>
            </h3>
        </div>
        
        <div class="flex-1 overflow-auto" style="display: flex; flex-direction: column;">
            <table class="w-full table-fixed text-[12px]" style="border-collapse: collapse;">
                <thead style="position: sticky; top: 0; z-index: 10;">
					<tr style="background-color: #1d4ed8; color: white;">
                        <th style="width: 12%; padding: 8px; text-align: center;"></th>
                        <th style="width: 44%; padding: 8px; text-align: left;">Vé cược</th>
                        <th style="width: 22%; padding: 8px; text-align: right;">Tiền</th>
                        <th style="width: 22%; padding: 8px; text-align: right;">Lãi/Lỗ</th>
                    </tr>
                    <tr style="background-color: #F5F5F5; font-weight:bold; border-top: 2px solid #F5F5F5;">
                        <th style="width: 12%; padding: 8px; text-align: center;"></th>
						<td id="tmTotalHost" style="padding:8px; text-align:left;">Cái</td>
                        <td id="tmTotalMoney" style="padding:8px; text-align:right;">0</td>
                        <td id="tmTotalWin" style="padding:8px; text-align:right;">0</td>
                    </tr>
                </thead>
                <tbody id="ticketMatchBody">
                    <tr>
                        <td colspan="4" class="text-center py-4 text-gray-400">Đang tải...</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div class="px-6 py-3 bg-gray-50 border-t flex justify-end shrink-0">
            <button type="button" onclick="closeTicketMatchModal()"
                class="px-4 py-2 rounded-lg font-bold text-gray-700 bg-white border-2 border-gray-300 hover:bg-gray-100 transition-all text-[11px] shadow-md active:scale-95 flex items-center gap-1.5">
                <i class="fa-solid fa-times text-[10px]"></i>Đóng
            </button>
        </div>
    </div>
</div>

<script>
    let tmScrollPosition = 0;
    let tmCurrentMatch = '';
    let tmCurrentTicketType = '';

    function openTicketMatchModal(matchId, matchLabel, ticketType) {
        tmCurrentTicketType = ticketType || '';
        tmCurrentMatch = matchId;
        const modal = document.getElementById('modalTicketMatch');
        const label = document.getElementById('tmMatchLabel');
        if (label) label.textContent = matchLabel || matchId;

        tmScrollPosition = window.pageYOffset || document.documentElement.scrollTop;
        document.body.style.position = 'fixed';
        document.body.style.top = `-${tmScrollPosition}px`;
        document.body.style.width = '100%';
        document.body.style.overflow = 'hidden';

        modal.classList.remove('hidden');
        modal.classList.add('flex');

        loadTicketMatchTable(matchId);
    }

    function closeTicketMatchModal() {
        const modal = document.getElementById('modalTicketMatch');
        modal.classList.add('hidden');
        modal.classList.remove('flex');

        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        window.scrollTo(0, tmScrollPosition);
    }

    function loadTicketMatchTable(matchId) {
        matchId = matchId || tmCurrentMatch || '';
        tmCurrentMatch = matchId;
        const tbody = document.getElementById('ticketMatchBody');
        tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-gray-400">Đang tải...</td></tr>';
        const champTicket = parseChampionTicketMatch(matchId);

        fetch(champTicket ? 'GetChampionTicketList.aspx' : 'GetTicketList.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(champTicket || {
                userId: '-2',
                match: matchId,
                ticketType: tmCurrentTicketType,
                type: '0',
                clear: '2',
                result: '2',
                dateFrom: '',
                dateTo: ''
            })
        })
        .then(r => r.json())
        .then(data => {
            if (data.d && data.d.length > 0) {
                renderTicketMatchTable(data.d);
            } else {
                const foot = document.getElementById('ticketMatchFoot');
                if (foot) foot.style.display = 'none';
                tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-gray-400">Không có vé cược</td></tr>';
            }
        })
        .catch(() => {
            const foot = document.getElementById('ticketMatchFoot');
            if (foot) foot.style.display = 'none';
            tbody.innerHTML = '<tr><td colspan="4" class="text-center py-4 text-red-400">Lỗi tải dữ liệu</td></tr>';
        });
    }

    function parseChampionTicketMatch(matchId) {
        if (!matchId || !matchId.startsWith('CHAMP|')) return null;
        const parts = matchId.split('|');
        return {
            season: decodeURIComponent(parts[1] || ''),
            time: decodeURIComponent(parts[2] || '')
        };
    }

    function renderTicketMatchTable(tickets) {
        const tbody = document.getElementById('ticketMatchBody');
        const tfoot = document.getElementById('ticketMatchFoot');
        let html = '';
        let totalMoney = 0;
        let totalWin = 0;

        tickets.forEach((item, index) => {
            const bgDefault = index % 2 === 0 ? 'white' : '#f9fafb';
            const bg = item.rowColor || bgDefault;
            const color = item.textColor || '';
            const fw = (item.rowBold === '1' || item.rowBold === 'true') ? 'bold' : 'normal';

            totalMoney += parseFloat(item.money) || 0;
            totalWin -= parseFloat(item.money_win) || 0;

            html += `<tr style="background-color:${bg};color:${color};font-weight:${fw};border-bottom:1px solid #eef2f6;">`;

            html += `<td style="text-align:center;padding:5px 4px;">
                <div style="display:flex;gap:3px;justify-content:center;">
                    <button type="button" class="tm-btn-delete" style="padding:2px 6px;border-radius:4px;font-size:11px;cursor:pointer;border:none;background:transparent;"
                        data-match="${item.match||''}" data-userid="${item.user_id||0}" data-code="${item.code||''}" data-ticket="${item.ticket||''}">
                        <i class="fa-solid fa-trash"></i>
                    </button>
                    <button type="button" class="tm-btn-clear" style="padding:2px 6px;border-radius:4px;font-size:11px;cursor:pointer;border:none;background:transparent;"
                        data-match="${item.match||''}" data-userid="${item.user_id||0}" data-code="${item.code||''}" data-ticket="${item.ticket||''}">
                        <i class="fa-solid fa-eraser"></i>
                    </button>
                </div>
            </td>`;
            html += `<td style="text-align:left;padding:5px 8px;">${item.ticket_name||''}</td>`;
            html += `<td style="text-align:right;padding:5px 8px;">${tmFormatNumber(item.money)}</td>`;
            html += `<td style="text-align:right;padding:5px 8px;">${tmFormatNumber(item.money_win)}</td>`;
            html += '</tr>';
        });

        tbody.innerHTML = html;

        // Cập nhật tổng
        const winCell1 = document.getElementById('tmTotalHost');
        winCell1.style.color = totalWin > 0 ? 'green' : totalWin < 0 ? 'red' : 'Fuchsia';
		
        const winCell2 = document.getElementById('tmTotalMoney');
        winCell2.textContent = tmFormatNumber(totalMoney / 2);
        winCell2.style.color = totalWin > 0 ? 'green' : totalWin < 0 ? 'red' : 'Fuchsia';
		
        const winCell3 = document.getElementById('tmTotalWin');
        winCell3.textContent = tmFormatNumber(totalWin / 2);
        winCell3.style.color = totalWin > 0 ? 'green' : totalWin < 0 ? 'red' : 'Fuchsia';
    }

    function tmFormatNumber(value) {
        if (value === null || value === undefined || value === '') return '0';
        const num = parseFloat(value);
        if (isNaN(num)) return '0';
        return Math.round(num).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
    }

    // Event delegation cho delete/clear
    document.addEventListener('click', function(e) {
        const delBtn = e.target.closest('.tm-btn-delete');
        if (delBtn) {
            if (!confirm('Bạn có chắc chắn muốn xóa vé cược này?')) return;
            const matchId = delBtn.dataset.match || tmCurrentMatch;
            fetch('DeleteTicket.aspx', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ match: matchId, user_id: parseInt(delBtn.dataset.userid), code: delBtn.dataset.code, ticket: delBtn.dataset.ticket })
            })
            .then(r => r.json())
            .then(data => {
                if (data.msg) alert(data.msg);
                if (data.isSuccess === 1) loadTicketMatchTable(tmCurrentMatch);
            });
        }

        const clearBtn = e.target.closest('.tm-btn-clear');
        if (clearBtn) {
            const matchId = clearBtn.dataset.match || tmCurrentMatch;
            fetch('ClearTicket.aspx', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ match: matchId, user_id: parseInt(clearBtn.dataset.userid), code: clearBtn.dataset.code, ticket: clearBtn.dataset.ticket })
            })
            .then(r => r.json())
            .then(data => {
                if (data.msg) alert(data.msg);
                if (data.isSuccess === 1) loadTicketMatchTable(tmCurrentMatch);
            });
        }
    });
</script>
