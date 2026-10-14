<%@ Control Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<script runat="server">
    public event EventHandler ResultSaved;
</script>

<asp:UpdatePanel ID="upnlResultMatch" runat="server">
    <ContentTemplate>
        <div id="modalResult" class="fixed inset-0 bg-gray-900/80 z-[60] hidden flex items-center justify-center p-4 font-sans">
            <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-2xl flex flex-col overflow-hidden animate-fade-in text-[12px]">
                
                <div class="bg-gradient-to-r from-green-600 to-green-700 px-6 py-4 text-white flex justify-between items-center shrink-0 shadow-lg">
                    <h3 class="font-bold flex items-center text-[14px]">
                        <i class="fa-solid fa-soccer-ball mr-3 text-lg"></i> Kết quả trận đấu
                    </h3>
                </div>
                
                <div class="p-5 flex-grow overflow-hidden">
                    <input type="hidden" id="match" runat="server" />
                    <asp:HiddenField ID="hdnHome" runat="server" />
                    <asp:HiddenField ID="hdnWay" runat="server" />
                    
                    <div class="border rounded-lg border-gray-200 overflow-hidden">
                        <table class="border-collapse text-[13px] w-full">
                            <thead>
                                <tr class="bg-gradient-to-r from-gray-100 to-gray-50 text-gray-700 border-b-2 border-gray-300">
                                    <th class="p-3 text-center border-r border-gray-300 w-[34%] font-bold"></th>
                                    <th class="p-3 text-center border-r border-gray-300 w-[33%] font-bold pr-4">
                                        <asp:Label ID="lblHome" runat="server" Text="Chủ"></asp:Label>
                                    </th>
                                    <th class="p-3 text-center w-[33%] font-bold pr-4">
                                        <asp:Label ID="lblWay" runat="server" Text="Khách"></asp:Label>
                                    </th>
                                </tr>
                            </thead>
                            <tbody class="font-bold">
                                <tr data-result-field="h1_conner" class="hover:bg-orange-50/40 transition-colors bg-orange-50/20">
                                    <td class="p-3 text-gray-600 bg-gray-50/50 border-r border-gray-300 text-right font-semibold">Góc h1</td>
                                    <td class="p-2 border-r border-gray-200">
                                        <asp:TextBox ID="h1_conner_home" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                    <td class="p-2">
                                        <asp:TextBox ID="h1_conner_way" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                </tr>
                                <tr data-result-field="h1_goal" class="hover:bg-orange-50/40 transition-colors bg-orange-50/20">
                                    <td class="p-3 text-gray-600 bg-gray-50/50 border-r border-gray-300 text-right font-semibold">Bàn h1</td>
                                    <td class="p-2 border-r border-gray-200">
                                        <asp:TextBox ID="h1_goal_home" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                    <td class="p-2">
                                        <asp:TextBox ID="h1_goal_way" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                </tr>
								<tr data-result-field="h1_card" class="hover:bg-orange-50/40 transition-colors bg-orange-50/20">
                                    <td class="p-3 text-gray-600 bg-gray-50/50 border-r border-gray-300 text-right font-semibold">Thẻ h1</td>
                                    <td class="p-2 border-r border-gray-200">
                                        <asp:TextBox ID="h1_card_home" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                    <td class="p-2">
                                        <asp:TextBox ID="h1_card_way" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                </tr>
                                <tr data-result-field="ft_conner" class="hover:bg-orange-50/40 transition-colors bg-orange-50/20">
                                    <td class="p-3 text-gray-600 bg-gray-50/50 border-r border-gray-300 text-right font-semibold">Góc trận</td>
                                    <td class="p-2 border-r border-gray-200">
                                        <asp:TextBox ID="ft_conner_home" runat="server"
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                    <td class="p-2">
                                        <asp:TextBox ID="ft_conner_way" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                </tr>
                                <tr data-result-field="ft_goal" class="hover:bg-orange-50/40 transition-colors bg-orange-50/20">
                                    <td class="p-3 text-gray-600 bg-gray-50/50 border-r border-gray-300 text-right font-semibold">Bàn trận</td>
                                    <td class="p-2 border-r border-gray-200">
                                        <asp:TextBox ID="ft_goal_home" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                    <td class="p-2">
                                        <asp:TextBox ID="ft_goal_way" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                </tr>
								<tr data-result-field="ft_card" class="hover:bg-orange-50/40 transition-colors bg-orange-50/20">
                                    <td class="p-3 text-gray-600 bg-gray-50/50 border-r border-gray-300 text-right font-semibold">Thẻ trận</td>
                                    <td class="p-2 border-r border-gray-200">
                                        <asp:TextBox ID="ft_card_home" runat="server"
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                    <td class="p-2">
                                        <asp:TextBox ID="ft_card_way" runat="server" 
                                            class="w-full text-right py-2 px-3 outline-none bg-white border-2 border-gray-300 rounded font-bold focus:border-gray-400 focus:ring-2 focus:ring-gray-100 transition-all" 
                                            inputmode="numeric"></asp:TextBox>
                                    </td>
                                </tr>
                                <tr data-result-field="serve" class="hover:bg-orange-50/40 transition-colors bg-orange-50/20">
                                    <td class="p-3 text-gray-600 bg-gray-50/50 border-r border-gray-300 text-right font-semibold">Giao bóng</td>
                                    <td class="p-2 border-r border-gray-200 text-center">
                                        <label class="inline-flex items-center justify-center gap-2 cursor-pointer">
                                            <input type="radio" name="serve_result" value="H" class="w-4 h-4 accent-green-600" />
                                            <span>Chủ</span>
                                        </label>
                                    </td>
                                    <td class="p-2 text-center">
                                        <label class="inline-flex items-center justify-center gap-2 cursor-pointer">
                                            <input type="radio" name="serve_result" value="W" class="w-4 h-4 accent-green-600" />
                                            <span>Khách</span>
                                        </label>
                                    </td>
                                </tr>
                                <tr id="resultNoTicketFields" class="hidden">
                                    <td colspan="3" class="p-4 text-center text-gray-500 font-semibold">
                                        Chưa có vé cược cần cập nhật kết quả cho trận này.
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>

                <div class="px-6 py-4 bg-gradient-to-r from-gray-50 to-gray-100 border-t flex justify-between items-center shrink-0">
                    <button type="button" id="btnDeleteResult" onclick="deleteResultData(); return false;"
                        class="px-4 py-2 rounded-lg font-bold text-white bg-gradient-to-r from-red-500 to-red-600 hover:from-red-600 hover:to-red-700 transition-all text-[11px] shadow-lg active:scale-95 flex items-center gap-1.5 whitespace-nowrap">
                        <i class="fa-solid fa-trash text-[10px]"></i>Xóa kết quả
                    </button>
                    <div class="flex gap-2">
                        <button type="button" onclick="clearResultForm(); closeResultModal();" 
                            class="px-4 py-2 rounded-lg font-bold text-gray-700 bg-white border-2 border-gray-300 hover:bg-gray-100 hover:border-gray-400 transition-all text-[11px] shadow-md active:scale-95 flex items-center gap-1.5 whitespace-nowrap">
                            <i class="fa-solid fa-times text-[10px]"></i>Hủy bỏ
                        </button>
                        <button type="button" id="btnSaveResult" onclick="saveResultData(); return false;"
                            class="px-5 py-2 bg-gradient-to-r from-green-600 to-green-700 text-white rounded-lg font-bold hover:from-green-700 hover:to-green-800 shadow-lg active:scale-95 text-[11px] cursor-pointer transition-all flex items-center gap-1.5 whitespace-nowrap">
                            <i class="fa-solid fa-check text-[10px]"></i>Lưu lại
                        </button>
                    </div>
                </div>
            </div>
        </div>
    </ContentTemplate>
</asp:UpdatePanel>

<script>
    let scrollPositionResult = 0;
    
    function openResultModal() {
        const modal = document.getElementById('modalResult');
        if (modal) {
            scrollPositionResult = window.pageYOffset || document.documentElement.scrollTop;
            
            document.body.style.position = 'fixed';
            document.body.style.top = `-${scrollPositionResult}px`;
            document.body.style.width = '100%';
            document.body.style.overflow = 'hidden';
            
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        }
    }

    function closeResultModal() {
        const modal = document.getElementById('modalResult');
        modal.classList.add('hidden');
        
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        
        window.scrollTo(0, scrollPositionResult);
    }
    
    function clearResultForm() {
        const modal = document.getElementById('modalResult');
        const inputs = modal.querySelectorAll('input[type="text"]');
        
        inputs.forEach(input => {
            input.value = '';
        });

        modal.querySelectorAll('input[name="serve_result"]').forEach(input => {
            input.checked = false;
        });
    }

    function getServeResultValue() {
        const selected = document.querySelector('[id*="modalResult"] input[name="serve_result"]:checked');
        return selected ? selected.value : '';
    }
    
    function fillResultForm(data) {
        document.querySelector('[id*="modalResult"] [id$="match"]').value = data.match || '';
        clearResultForm();
        
        // Fill tên đội vào header
        const lblHome = document.querySelector('[id$="lblHome"]');
        const lblWay = document.querySelector('[id$="lblWay"]');
        
        if (lblHome && data.home) {
            lblHome.textContent = data.home;
        }
        
        if (lblWay && data.way) {
            lblWay.textContent = data.way;
        }
        
        const visibleFields = data.result_fields || {};
        const rows = document.querySelectorAll('[id*="modalResult"] [data-result-field]');
        let visibleRowCount = 0;
        rows.forEach(row => {
            const key = row.getAttribute('data-result-field');
            const visible = !!visibleFields[key];
            row.classList.toggle('hidden', !visible);
            if (visible) visibleRowCount++;
        });

        const emptyRow = document.getElementById('resultNoTicketFields');
        if (emptyRow) emptyRow.classList.toggle('hidden', visibleRowCount > 0);

        const btnSave = document.getElementById('btnSaveResult');
        if (btnSave) btnSave.disabled = visibleRowCount === 0;

        // Fill các trường kết quả
        const fields = ['h1_conner_home', 'h1_conner_way'
						, 'ft_conner_home', 'ft_conner_way'
						, 'h1_goal_home', 'h1_goal_way'
						, 'ft_goal_home', 'ft_goal_way'
						, 'h1_card_home', 'h1_card_way'
						, 'ft_card_home', 'ft_card_way'];
        
        fields.forEach(field => {
            const element = document.querySelector('[id$="' + field + '"]');
            if (element && data[field] !== null && data[field] !== undefined) {
                element.value = data[field];
            }
        });

        const serveValue = data.serve_result || '';
        document.querySelectorAll('[id*="modalResult"] input[name="serve_result"]').forEach(input => {
            input.checked = input.value === serveValue;
        });
    }
    
    function saveResultData() {
        const btnSave = document.getElementById('btnSaveResult');
        btnSave.disabled = true;
        btnSave.innerHTML = '<i class="fa-solid fa-spinner fa-spin text-[10px]"></i>Đang lưu...';
        
        const resultData = {
            match: document.querySelector('[id*="modalResult"] [id$="match"]').value,
            h1_conner_home: document.querySelector('[id$="h1_conner_home"]').value,
            h1_conner_way: document.querySelector('[id$="h1_conner_way"]').value,
            ft_conner_home: document.querySelector('[id$="ft_conner_home"]').value,
            ft_conner_way: document.querySelector('[id$="ft_conner_way"]').value,
            h1_goal_home: document.querySelector('[id$="h1_goal_home"]').value,
            h1_goal_way: document.querySelector('[id$="h1_goal_way"]').value,
            ft_goal_home: document.querySelector('[id$="ft_goal_home"]').value,
            ft_goal_way: document.querySelector('[id$="ft_goal_way"]').value,
			h1_card_home: document.querySelector('[id$="h1_card_home"]').value,
            h1_card_way: document.querySelector('[id$="h1_card_way"]').value,
            ft_card_home: document.querySelector('[id$="ft_card_home"]').value,
            ft_card_way: document.querySelector('[id$="ft_card_way"]').value,
            serve_result: getServeResultValue()
        };
        
        fetch('matches.aspx/SaveResultData', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ resultData: JSON.stringify(resultData) })
        })
        .then(response => response.json())
        .then(data => {
            btnSave.disabled = false;
            btnSave.innerHTML = '<i class="fa-solid fa-check text-[10px]"></i>Lưu lại';
            
            if (data.d) {
                const result = JSON.parse(data.d);
                alert(result.msg);
                
                // Chỉ đóng popup nếu thành công (isSuccess = 1)
                if (result.isSuccess == 1) {
                    closeResultModal();
                    clearResultForm();
                }
            }
        })
        .catch(error => {
            btnSave.disabled = false;
            btnSave.innerHTML = '<i class="fa-solid fa-check text-[10px]"></i>Lưu lại';
            console.error('Error:', error);
            alert('Lỗi khi lưu dữ liệu');
        });
        
        return false;
    }
    
    function deleteResultData() {
        if (!confirm('Bạn có chắc chắn muốn xóa kết quả này?')) {
            return false;
        }
        
        const btnDelete = document.getElementById('btnDeleteResult');
        btnDelete.disabled = true;
        btnDelete.innerHTML = '<i class="fa-solid fa-spinner fa-spin text-[10px]"></i>Đang xóa...';
        
        const resultData = {
            match: document.querySelector('[id*="modalResult"] [id$="match"]').value,
            h1_conner_home: document.querySelector('[id$="h1_conner_home"]').value,
            h1_conner_way: document.querySelector('[id$="h1_conner_way"]').value,
            ft_conner_home: document.querySelector('[id$="ft_conner_home"]').value,
            ft_conner_way: document.querySelector('[id$="ft_conner_way"]').value,
            h1_goal_home: document.querySelector('[id$="h1_goal_home"]').value,
            h1_goal_way: document.querySelector('[id$="h1_goal_way"]').value,
            ft_goal_home: document.querySelector('[id$="ft_goal_home"]').value,
            ft_goal_way: document.querySelector('[id$="ft_goal_way"]').value,
            h1_card_home: document.querySelector('[id$="h1_card_home"]').value,
            h1_card_way: document.querySelector('[id$="h1_card_way"]').value,
            ft_card_home: document.querySelector('[id$="ft_card_home"]').value,
            ft_card_way: document.querySelector('[id$="ft_card_way"]').value,
            serve_result: getServeResultValue()
        };
        
        fetch('matches.aspx/DeleteResultData', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ resultData: JSON.stringify(resultData) })
        })
        .then(response => response.json())
        .then(data => {
            btnDelete.disabled = false;
            btnDelete.innerHTML = '<i class="fa-solid fa-trash text-[10px]"></i>Xóa kết quả';
            
            if (data.d) {
                const result = JSON.parse(data.d);
                alert(result.msg);
                
                // Chỉ đóng popup và reload data nếu thành công (isSuccess = 1)
                if (result.isSuccess == 1) {
                    closeResultModal();
                    clearResultForm();
                }
            }
        })
        .catch(error => {
            btnDelete.disabled = false;
            btnDelete.innerHTML = '<i class="fa-solid fa-trash text-[10px]"></i>Xóa kết quả';
            console.error('Error:', error);
            alert('Lỗi khi xóa dữ liệu');
        });
        
        return false;
    }
</script>
