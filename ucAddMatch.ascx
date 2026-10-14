<%@ Control Language="C#" AutoEventWireup="true" %>
<%@ Register Src="~/ucNumericKeyboard.ascx" TagPrefix="uc" TagName="NumericKeyboard" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

<style>
    /* Fix cho Safari để không bị lệch text bên trong ô */
    input[type="datetime-local"] {
        appearance: none;
        -webkit-appearance: none;
        min-height: 2.25rem; /* Tương đương h-9 */
    }
    
    /* Safari datetime picker fix */
    .safari-datetime-fix {
        position: relative;
    }
    
    /* Đảm bảo picker hoạt động trên Safari */
    .safari-datetime-fix::-webkit-datetime-edit {
        padding: 0;
    }
    
    .safari-datetime-fix::-webkit-calendar-picker-indicator {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        width: 100%;
        height: 100%;
        opacity: 0;
        cursor: pointer;
        z-index: 1;
    }
    
    /* Chỉ áp dụng cho mobile để tránh ảnh hưởng desktop */
    @media screen and (max-width: 768px) {
        .safari-datetime-fix {
            font-size: 16px !important; /* Đánh lừa trình duyệt để không zoom */
        }

        /* Nếu muốn chữ nhìn vẫn nhỏ như 12px thì dùng scale */
        .safari-datetime-fix {
            display: block;
        }
        
        /* Hoặc đơn giản nhất là ép font-size lên 16px khi focus */
        input:focus {
            font-size: 16px !important;
        }
    }
    
    /* Fix lỗi không hiện picker trên Safari/iPhone */
    input[id$='time'] {
        position: relative;
        -webkit-appearance: none;
    }

    /* Kéo dãn vùng kích hoạt lịch ra toàn bộ ô input */
    input[id$='time']::-webkit-calendar-picker-indicator {
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        width: 100%;
        height: 100%;
        opacity: 0;
        cursor: pointer;
    }
    @keyframes shake {
        0%, 100% { transform: translateX(0); }
        20%       { transform: translateX(-5px); }
        40%       { transform: translateX(5px); }
        60%       { transform: translateX(-4px); }
        80%       { transform: translateX(4px); }
    }
    .msg-shake {
        animation: shake 0.4s ease;
    }

    /* Fix viewport khi bàn phím hiện trên mobile */
    @media screen and (max-width: 768px) {
        /* Ngăn zoom khi focus input */
        input, textarea, select {
            font-size: 16px !important;
        }

        /* Riêng cho trường time - giữ font size nhỏ */
        input[id$='time'] {
            font-size: 12px !important;
        }
    }
</style>

<script runat="server">
</script>

<asp:ScriptManager ID="sm1" runat="server" />

<asp:UpdatePanel ID="upnlAddMatch" runat="server">
    <ContentTemplate>
        <div id="modalAdd" class="fixed inset-0 bg-gray-900/80 z-[60] hidden flex items-center justify-center p-4 font-sans">
            <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-2xl flex flex-col overflow-hidden animate-fade-in text-[12px] max-h-[90vh]">
                
                <div class="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4 text-white flex justify-between items-center shrink-0 shadow-lg">
                    <h3 class="font-bold flex items-center text-[14px]">
                        <i class="fa-solid fa-futbol mr-3 text-lg"></i> Thêm mới trận đấu
                    </h3>
                </div>
                
                <div id="modalFormContent" class="p-5 flex-grow overflow-y-auto">
                    <input type="hidden" id="match" runat="server" />
                    <asp:HiddenField ID="editYn" runat="server" Value="false" />
                    <asp:HiddenField ID="hdnTimeValue" runat="server" />
                    <asp:HiddenField ID="hdnShouldCloseModal" runat="server" Value="false" />
                    
                    <div class="grid grid-cols-2 gap-3 mb-4 items-start">
                        <div class="relative">
                            <asp:TextBox ID="season" runat="server" 
                                onkeyup="filterData(this, 'listSeason')" 
                                onfocus="showAllData(this, 'listSeason')"
                                onblur="validateSelection(this, 'listSeason')" 
                                autocomplete="off" placeholder="Giải đấu"
                                class="w-full h-9 border border-gray-300 rounded px-3 outline-none font-bold text-[12px] focus:border-blue-500 bg-gray-50/50"></asp:TextBox>
                            <div id="listSeason" class="absolute z-[100] w-full bg-white shadow-xl border rounded mt-1 max-h-80 overflow-y-auto hidden"></div>
                            <span id="msg_season" class="text-[10px] text-red-500 absolute left-0 -bottom-4 hidden font-semibold">! Vui lòng chọn giải đấu hợp lệ</span>
                        </div>

                        <div class="relative">
                            <input type="datetime-local" id="timePickerHidden" 
                                style="position: absolute; opacity: 0; width: 100%; height: 100%; top: 0; left: 0; cursor: pointer; z-index: 2;" />
                            <asp:TextBox ID="time" runat="server" 
                                placeholder="hh:mm dd/MM/yyyy"
                                ReadOnly="true"
								onfocus="showAllData(this, '')"
                                class="w-full h-9 border border-gray-300 rounded px-3 outline-none font-bold text-[12px] bg-gray-50/50 cursor-pointer"></asp:TextBox>
                            <span id="msg_time" class="text-[10px] text-red-500 absolute left-0 -bottom-4 hidden font-semibold">! Vui lòng chọn thời gian</span>
                        </div>
                    </div>

                    <div class="grid grid-cols-2 gap-3 mb-5 items-start">
                        <div class="relative">
                            <asp:TextBox ID="home" runat="server" 
                                onkeyup="filterData(this, 'listHome')" 
                                onfocus="showAllData(this, 'listHome')"
                                onblur="validateSelection(this, 'listHome')" 
                                autocomplete="off" placeholder="Home"
                                class="w-full h-9 border-2 border-blue-100 rounded px-3 text-right font-black text-[12px] focus:border-blue-500"></asp:TextBox>
                            <div id="listHome" class="absolute z-[100] w-full bg-white shadow-xl border rounded mt-1 max-h-80 overflow-y-auto hidden text-left font-normal normal-case"></div>
                            <span id="msg_home" class="text-[10px] text-red-500 absolute right-0 -bottom-4 hidden text-right w-full font-semibold">! Chưa chọn đội chủ</span>
                        </div>

                        <div class="relative">
                            <asp:TextBox ID="way" runat="server" 
                                onkeyup="filterData(this, 'listWay')" 
                                onfocus="showAllData(this, 'listWay')"
                                onblur="validateSelection(this, 'listWay')" 
                                autocomplete="off" placeholder="Way"
                                class="w-full h-9 border-2 border-blue-100 rounded px-3 text-left font-black text-[12px] focus:border-blue-500"></asp:TextBox>
                            <div id="listWay" class="absolute z-[100] w-full bg-white shadow-xl border rounded mt-1 max-h-80 overflow-y-auto hidden text-left font-normal normal-case"></div>
                            <span id="msg_way" class="text-[10px] text-red-500 absolute left-0 -bottom-4 hidden text-left w-full font-semibold">! Chưa chọn đội khách</span>
                        </div>
                    </div>

                    <div class="border rounded-lg border-gray-200 overflow-hidden">
                        <div class="max-h-[400px] overflow-y-auto">
                            <table class="border-collapse text-[12px] w-full">
                                <thead class="sticky top-0 z-10">
                                    <tr class="bg-gray-100 text-gray-600 border-b">
                                        <th class="p-2 text-center border-r w-[40%]">
                                            <button type="button" id="btnToggleRate" onclick="toggleRateMode()" class="px-3 py-1 bg-red-500 text-white rounded text-[11px] font-bold hover:opacity-90 transition-all">
                                                Rate
                                            </button>
                                        </th>
                                        <th class="p-2 text-right border-r w-[20%]">Hiệp 1</th>
                                        <th class="p-2 text-right border-r w-[20%] bg-blue-50 text-blue-700 font-black">Cả trận</th>
                                        <th class="p-2 text-right w-[20%]">Hiệp 2</th>
                                    </tr>
                                </thead>
                            <tbody class="divide-y divide-gray-200 font-bold">
                                <tr>
                                    <td class="p-2 text-gray-500 bg-gray-50/30 border-r text-right">Tài bàn</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_goal_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_goal_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_goal_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate tài</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_goal_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_goal_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_goal_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate xỉu</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_goal_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_goal_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_goal_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr>
                                    <td class="p-2 text-gray-500 bg-gray-50/30 border-r text-right">Bàn (chủ nhà)</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_goal_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_goal_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_goal_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate chủ</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_goal_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_goal_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_goal_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate khách</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_goal_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_goal_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_goal_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
								
                                <tr class="border-t-2">
                                    <td class="p-2 text-gray-500 bg-orange-50/100 border-r text-right">Chủ</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_euro_home" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_euro_home" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_euro_home" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none" ></asp:TextBox></td>
                                </tr>
                                <tr>
                                    <td class="p-2 text-gray-500 bg-orange-50/100 border-r text-right">Hòa</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_euro_draw" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_euro_draw" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_euro_draw" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none" ></asp:TextBox></td>
                                </tr>
                                <tr>
                                    <td class="p-2 text-gray-500 bg-orange-50/100 border-r text-right">Khách</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_euro_way" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_euro_way" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_euro_way" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none" ></asp:TextBox></td>
                                </tr>
								
                                <tr class="border-t-2">
                                    <td class="p-2 text-gray-500 bg-gray-50/30 border-r text-right">Tài góc</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_conner_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_conner_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_conner_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate tài</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_conner_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_conner_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_conner_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate xỉu</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_conner_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_conner_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_conner_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr>
                                    <td class="p-2 text-gray-500 bg-gray-50/30 border-r text-right">Góc (chủ nhà)</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_conner_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_conner_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_conner_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate chủ</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_conner_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_conner_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_conner_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate khách</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_conner_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_conner_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_conner_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
								
								<tr class="border-t-2">
                                    <td class="p-2 text-gray-500 bg-gray-50/30 border-r text-right">Tài thẻ</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_card_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_card_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_card_over_under" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate tài</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_card_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_card_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_card_over_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate xỉu</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_card_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_card_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_card_under_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr>
                                    <td class="p-2 text-gray-500 bg-gray-50/30 border-r text-right">Thẻ (chủ nhà)</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_card_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_card_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_card_handicap" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate chủ</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_card_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_card_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_card_home_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                                <tr class="rate-row hidden">
                                    <td class="p-2 text-red-500 bg-gray-50/30 border-r text-right">Rate khách</td>
                                    <td class="p-1 border-r"><asp:TextBox ID="h1_card_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                    <td class="p-1 border-r bg-blue-50/20"><asp:TextBox ID="ft_card_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent text-blue-600" ></asp:TextBox></td>
                                    <td class="p-1"><asp:TextBox ID="h2_card_way_win" runat="server" onblur="formatDecimal(this)" class="w-full text-right py-1 outline-none bg-transparent" ></asp:TextBox></td>
                                </tr>
                            </tbody>
                        </table>
                        </div>
                    </div>
                </div>

                <div class="px-6 py-4 bg-gradient-to-r from-gray-50 to-gray-100 border-t flex justify-end gap-3 shrink-0">
                    <button type="button" onclick="clearAddMatchForm(); closeAddMatchModal();" 
                        class="px-6 py-2.5 rounded-lg font-bold text-gray-600 bg-white border-2 border-gray-300 hover:bg-gray-50 hover:border-gray-400 transition-all text-[12px] shadow-sm active:scale-95 flex items-center gap-2">
                        <i class="fa-solid fa-times"></i> Hủy bỏ
                    </button>
                    <button type="button" id="btnSaveMatch" onclick="saveMatchData(); return false;"
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
    // Attach numeric keyboard to decimal fields
    window.addEventListener('load', function() {
        const decimalFields = [
            'h1_conner_over_under', 'ft_conner_over_under', 'h2_conner_over_under',
            'h1_conner_handicap', 'ft_conner_handicap', 'h2_conner_handicap',
            'h1_goal_over_under', 'ft_goal_over_under', 'h2_goal_over_under',
            'h1_goal_handicap', 'ft_goal_handicap', 'h2_goal_handicap',
			'h1_card_over_under', 'ft_card_over_under', 'h2_card_over_under',
            'h1_card_handicap', 'ft_card_handicap', 'h2_card_handicap',
            'h1_euro_home', 'ft_euro_home', 'h2_euro_home',
            'h1_euro_draw', 'ft_euro_draw', 'h2_euro_draw',
            'h1_euro_way', 'ft_euro_way', 'h2_euro_way',
            'h1_conner_over_win', 'ft_conner_over_win', 'h2_conner_over_win',
            'h1_conner_under_win', 'ft_conner_under_win', 'h2_conner_under_win',
            'h1_conner_home_win', 'ft_conner_home_win', 'h2_conner_home_win',
            'h1_conner_way_win', 'ft_conner_way_win', 'h2_conner_way_win',
            'h1_goal_over_win', 'ft_goal_over_win', 'h2_goal_over_win',
            'h1_goal_under_win', 'ft_goal_under_win', 'h2_goal_under_win',
            'h1_goal_home_win', 'ft_goal_home_win', 'h2_goal_home_win',
            'h1_goal_way_win', 'ft_goal_way_win', 'h2_goal_way_win',
            'h1_card_over_win', 'ft_card_over_win', 'h2_card_over_win',
            'h1_card_under_win', 'ft_card_under_win', 'h2_card_under_win',
            'h1_card_home_win', 'ft_card_home_win', 'h2_card_home_win',
            'h1_card_way_win', 'ft_card_way_win', 'h2_card_way_win'
        ];
        
        const selectors = decimalFields.map(function(fieldId) {
            return '[id$="' + fieldId + '"]';
        });
        
        if (window.NumericKeyboard) {
            window.NumericKeyboard.attachToFields(selectors);
        }
    });
    
    // Hiển thị lỗi inline kèm animation shake
    function showError(el, text) {
        el.innerText = text;
        el.classList.remove('hidden');
        // Reset animation để chạy lại nếu đang hiển thị rồi
        el.classList.remove('msg-shake');
        void el.offsetWidth; // reflow
        el.classList.add('msg-shake');
    }

    // Kiểm tra một field có khớp đúng 1 item trong danh sách không
    function isValidSelection(inputValue, listId) {
        const val = removeAccents(inputValue.trim()).toLowerCase();
        if (val === '') return false;

        const data = listId === 'listSeason' ? dataSeason : dataTeam;
        const codeKey = listId === 'listSeason' ? 'season' : 'team';
        const nameKey = listId === 'listSeason' ? 'season_name' : 'team_name';

        const matches = data.filter(item => {
            const codeMatch = removeAccents(item[codeKey] || '').toLowerCase();
            const nameMatch = removeAccents(item[nameKey] || '').toLowerCase();
            return codeMatch.includes(val) || nameMatch.includes(val);
        });

        if (matches.length === 1) return true;
        if (matches.length > 1) {
            return matches.some(item =>
                removeAccents(item[codeKey]).toLowerCase() === val
            );
        }
        return false;
    }

    // Validate trước khi submit
    function validateBeforeSubmit() {
        let hasError = false;

        const seasonInput = document.querySelector('[id$="season"]');
        const timeInput = document.querySelector('[id$="time"]');
        const homeInput = document.querySelector('[id$="home"]');
        const wayInput = document.querySelector('[id$="way"]');

        const msgSeason = document.getElementById('msg_season');
        const msgTime = document.getElementById('msg_time');
        const msgHome = document.getElementById('msg_home');
        const msgWay = document.getElementById('msg_way');

        // Season
        if (!seasonInput.value.trim()) {
            showError(msgSeason, '! Vui lòng chọn giải đấu');
            hasError = true;
        } else if (!isValidSelection(seasonInput.value, 'listSeason')) {
            showError(msgSeason, '! Dữ liệu không tồn tại');
            hasError = true;
        } else {
            msgSeason.classList.add('hidden');
        }

        // Time
        if (!timeInput.value.trim()) {
            msgTime.classList.remove('hidden');
            msgTime.classList.remove('msg-shake');
            void msgTime.offsetWidth;
            msgTime.classList.add('msg-shake');
            hasError = true;
        } else {
            msgTime.classList.add('hidden');
        }

        // Home
        if (!homeInput.value.trim()) {
            showError(msgHome, '! Chưa chọn đội chủ');
            hasError = true;
        } else if (!isValidSelection(homeInput.value, 'listHome')) {
            showError(msgHome, '! Dữ liệu không tồn tại');
            hasError = true;
        } else {
            msgHome.classList.add('hidden');
        }

        // Way
        if (!wayInput.value.trim()) {
            showError(msgWay, '! Chưa chọn đội khách');
            hasError = true;
        } else if (!isValidSelection(wayInput.value, 'listWay')) {
            showError(msgWay, '! Dữ liệu không tồn tại');
            hasError = true;
        } else {
            msgWay.classList.add('hidden');
        }

        return !hasError;
    }
    
    function saveMatchData() {
        if (!validateBeforeSubmit()) {
            return false;
        }
        
        // Disable button để tránh double click
        const btnSave = document.getElementById('btnSaveMatch');
        btnSave.disabled = true;
        btnSave.innerText = 'Đang lưu...';
        
        // Thu thập dữ liệu từ form
        const matchData = {
            match: document.querySelector('[id$="match"]').value,
            season: document.querySelector('[id$="season"]').value,
            time: document.querySelector('[id$="hdnTimeValue"]').value,
            home: document.querySelector('[id$="home"]').value,
            way: document.querySelector('[id$="way"]').value,
            editYn: document.querySelector('[id$="editYn"]').value
        };
        
        // Thu thập tất cả các trường số
        const fields = [
            'h1_conner_over_under', 'ft_conner_over_under', 'h2_conner_over_under',
            'h1_conner_handicap', 'ft_conner_handicap', 'h2_conner_handicap',
            'h1_goal_over_under', 'ft_goal_over_under', 'h2_goal_over_under',
            'h1_goal_handicap', 'ft_goal_handicap', 'h2_goal_handicap',
            'h1_card_over_under', 'ft_card_over_under', 'h2_card_over_under',
            'h1_card_handicap', 'ft_card_handicap', 'h2_card_handicap',
            'h1_euro_home', 'ft_euro_home', 'h2_euro_home',
            'h1_euro_draw', 'ft_euro_draw', 'h2_euro_draw',
            'h1_euro_way', 'ft_euro_way', 'h2_euro_way',
            'h1_conner_over_win', 'ft_conner_over_win', 'h2_conner_over_win',
            'h1_conner_under_win', 'ft_conner_under_win', 'h2_conner_under_win',
            'h1_conner_home_win', 'ft_conner_home_win', 'h2_conner_home_win',
            'h1_conner_way_win', 'ft_conner_way_win', 'h2_conner_way_win',
            'h1_goal_over_win', 'ft_goal_over_win', 'h2_goal_over_win',
            'h1_goal_under_win', 'ft_goal_under_win', 'h2_goal_under_win',
            'h1_goal_home_win', 'ft_goal_home_win', 'h2_goal_home_win',
            'h1_goal_way_win', 'ft_goal_way_win', 'h2_goal_way_win',
            'h1_card_over_win', 'ft_card_over_win', 'h2_card_over_win',
            'h1_card_under_win', 'ft_card_under_win', 'h2_card_under_win',
            'h1_card_home_win', 'ft_card_home_win', 'h2_card_home_win',
            'h1_card_way_win', 'ft_card_way_win', 'h2_card_way_win'
        ];
        
        fields.forEach(field => {
            const element = document.querySelector('[id$="' + field + '"]');
            if (element) {
                matchData[field] = element.value;
            }
        });
        
        // Gọi SaveMatch.aspx
        fetch('SaveMatch.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(matchData)
        })
        .then(function(r) {
            return r.text().then(function(text) {
                try { return JSON.parse(text); }
                catch(e) { throw new Error('Server response: ' + text.substring(0, 200)); }
            });
        })
        .then(function(result) {
            btnSave.disabled = false;
            btnSave.innerText = '✓ Lưu lại';
            
            if (result.isSuccess == 1) {
                alert(result.msg);
                closeAddMatchModal();
                clearAddMatchForm();
                if (typeof reloadMatchesData === 'function') {
                    reloadMatchesData();
                } else {
                    location.reload();
                }
            } else {
                alert(result.msg);
            }
        })
        .catch(function(error) {
            btnSave.disabled = false;
            btnSave.innerText = '✓ Lưu lại';
            alert('Lỗi khi lưu dữ liệu: ' + error);
        });
        
        return false;
    }

    let scrollPosition = 0;
    
    function openAddMatchModal() {
        const modal = document.getElementById('modalAdd');
        if (modal) {
            // Lưu vị trí scroll hiện tại
            scrollPosition = window.pageYOffset || document.documentElement.scrollTop;
            
            // Lock body
            document.body.style.position = 'fixed';
            document.body.style.top = `-${scrollPosition}px`;
            document.body.style.width = '100%';
            document.body.style.overflow = 'hidden';
            
            modal.classList.remove('hidden');
            modal.classList.add('flex');
        }
    }

    function closeAddMatchModal() {
        const modal = document.getElementById('modalAdd');
        modal.classList.add('hidden');
        
        // Restore body
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        
        // Restore vị trí scroll
        window.scrollTo(0, scrollPosition);
        
        window.onbeforeunload = null; 
    }
    
    // Kiểm tra sau UpdatePanel postback để giữ modal mở nếu có lỗi
    function checkModalState() {
        const hdnShouldClose = document.querySelector('[id$="hdnShouldCloseModal"]');
        const modal = document.getElementById('modalAdd');
        
        if (hdnShouldClose && modal) {
            // Nếu modal đang ẩn và shouldClose = false, mở lại modal
            if (hdnShouldClose.value === 'false' && modal.classList.contains('hidden')) {
                modal.classList.remove('hidden');
                modal.classList.add('flex');
                
                // Lock body
                document.body.style.position = 'fixed';
                document.body.style.top = `-${scrollPosition}px`;
                document.body.style.width = '100%';
                document.body.style.overflow = 'hidden';
            }
        }
    }
    
    // Gọi checkModalState sau mỗi UpdatePanel postback
    var prm = Sys.WebForms.PageRequestManager.getInstance();
    if (prm) {
        prm.add_endRequest(function() {
            checkModalState();
        });
    }
    
    function fillEditForm(data, isEditMode) {
        // Đổi title popup chỉ khi ở chế độ edit
        const modalTitle = document.querySelector('#modalAdd h3');
        if (modalTitle && isEditMode) {
            modalTitle.innerHTML = '<i class="fa-solid fa-pen-to-square mr-3 text-lg"></i> Sửa trận đấu';
        } else if (modalTitle && !isEditMode) {
            modalTitle.innerHTML = '<i class="fa-solid fa-futbol mr-3 text-lg"></i> Thêm mới trận đấu';
        }

        // Fill match ID chỉ khi edit, không fill khi copy
        if (isEditMode) {
            document.querySelector('[id$="match"]').value = data.match || '';
        } else {
            document.querySelector('[id$="match"]').value = '';
        }
        
        document.querySelector('[id$="season"]').value = data.season || '';
        document.querySelector('[id$="home"]').value = data.home || '';
        document.querySelector('[id$="way"]').value = data.way || '';
        
        // Format time
        if (data.time) {
            try {
                let dt;
                
                if (typeof data.time === 'string' && data.time.startsWith('/Date(')) {
                    const timestamp = parseInt(data.time.match(/\d+/)[0]);
                    dt = new Date(timestamp);
                } else {
                    dt = new Date(data.time);
                }
                                    
                if (!isNaN(dt.getTime())) {
                    const hh = String(dt.getHours()).padStart(2, '0');
                    const mm = String(dt.getMinutes()).padStart(2, '0');
                    const dd = String(dt.getDate()).padStart(2, '0');
                    const MM = String(dt.getMonth() + 1).padStart(2, '0');
                    const yyyy = dt.getFullYear();
                    
                    const formattedTime = `${hh}:${mm} ${dd}/${MM}/${yyyy}`;
                    
                    const allInputs = document.querySelectorAll('input');
                    let timeTextBox = null;
                    allInputs.forEach(el => {
                        if (el.type === 'text' && el.id.includes('time') && !el.id.includes('Picker')) {
                            timeTextBox = el;
                        }
                    });
                    
                    if (timeTextBox) {
                        timeTextBox.value = formattedTime;
                    }
                    
                    const isoString = `${yyyy}-${MM}-${dd}T${hh}:${mm}`;
                    const timePicker = document.getElementById('timePickerHidden');
                    if (timePicker) {
                        timePicker.value = isoString;
                    }
                    
                    const hdnTimeValue = document.querySelector('[id$="hdnTimeValue"]');
                    if (hdnTimeValue) {
                        hdnTimeValue.value = isoString;
                    }
                }
            } catch (e) {
                console.error('Error parsing time:', e);
            }
        }

        // Fill các trường số
        const fields = [
            'h1_conner_over_under', 'ft_conner_over_under', 'h2_conner_over_under',
            'h1_conner_handicap', 'ft_conner_handicap', 'h2_conner_handicap',
            'h1_goal_over_under', 'ft_goal_over_under', 'h2_goal_over_under',
            'h1_goal_handicap', 'ft_goal_handicap', 'h2_goal_handicap',
			'h1_card_over_under', 'ft_card_over_under', 'h2_card_over_under',
            'h1_card_handicap', 'ft_card_handicap', 'h2_card_handicap',
            'h1_euro_home', 'ft_euro_home', 'h2_euro_home',
            'h1_euro_draw', 'ft_euro_draw', 'h2_euro_draw',
            'h1_euro_way', 'ft_euro_way', 'h2_euro_way',
            'h1_conner_over_win', 'ft_conner_over_win', 'h2_conner_over_win',
            'h1_conner_under_win', 'ft_conner_under_win', 'h2_conner_under_win',
            'h1_conner_home_win', 'ft_conner_home_win', 'h2_conner_home_win',
            'h1_conner_way_win', 'ft_conner_way_win', 'h2_conner_way_win',
            'h1_goal_over_win', 'ft_goal_over_win', 'h2_goal_over_win',
            'h1_goal_under_win', 'ft_goal_under_win', 'h2_goal_under_win',
            'h1_goal_home_win', 'ft_goal_home_win', 'h2_goal_home_win',
            'h1_goal_way_win', 'ft_goal_way_win', 'h2_goal_way_win',
            'h1_card_over_win', 'ft_card_over_win', 'h2_card_over_win',
            'h1_card_under_win', 'ft_card_under_win', 'h2_card_under_win',
            'h1_card_home_win', 'ft_card_home_win', 'h2_card_home_win',
            'h1_card_way_win', 'ft_card_way_win', 'h2_card_way_win'
        ];

        fields.forEach(field => {
            const element = document.querySelector('[id$="' + field + '"]');
            if (element && data[field] !== null && data[field] !== undefined) {
                if (data[field] === '___') {
                    element.value = '';
                } else {
                    element.value = data[field];
                    formatDecimal(element);
                }
            }
        });
    }
    
    function clearAddMatchForm() {
        const modal = document.getElementById('modalAdd');
        const inputs = modal.querySelectorAll('input[type="text"], input[type="datetime-local"], input[type="tel"], input[type="number"]');
        
        inputs.forEach(input => {
            input.value = '';
        });

        // Clear cả textbox time và hidden field
        const timeTextBox = document.querySelector('[id$="time"]');
        if (timeTextBox) timeTextBox.value = '';
        
        const hdnTimeValue = document.querySelector('[id$="hdnTimeValue"]');
        if (hdnTimeValue) hdnTimeValue.value = '';
        
        // Clear match ID (hidden field)
        const matchField = document.querySelector('[id$="match"]');
        if (matchField) matchField.value = '';
        
        // Clear edit_yn
        const editYnField = document.querySelector('[id$="editYn"]');
        if (editYnField) editYnField.value = 'false';

        // Reset title về "Thêm mới trận đấu"
        const modalTitle = document.querySelector('#modalAdd h3');
        if (modalTitle) {
            modalTitle.innerHTML = '<i class="fa-solid fa-futbol mr-3 text-lg"></i> Thêm mới trận đấu';
        }

        const errorMsgs = modal.querySelectorAll('[id^="msg_"]');
        errorMsgs.forEach(msg => msg.classList.add('hidden'));

        const lists = modal.querySelectorAll('[id^="list"]');
        lists.forEach(list => list.classList.add('hidden'));

        window.onbeforeunload = null;
    }

    window.addEventListener('beforeunload', function (e) {
        delete e['returnValue'];
    }, true);
    
    function removeAccents(str) {
        return str.normalize('NFD').replace(/[\u0300-\u036f]/g, "").toLowerCase();
    }
    
    function filterData(input, listId, forceAll = false) {
        var value = removeAccents(input.value.trim()).toLowerCase();
        var list = document.querySelector(`[id$='${listId}']`);
        if (!list) return;

        var data = [];
        if (listId.includes('Season')) data = dataSeason;
        else if (listId.includes('Home')) data = dataTeam;
        else if (listId.includes('Way')) data = dataTeam;

        // Xóa nội dung cũ và build lại bằng DOM để tránh lỗi unicode trong onclick string
        list.innerHTML = '';
        if (data && data.length > 0) {
            data.forEach(function(item) {
                var codeVal = item.season ? String(item.season) : String(item.team);
                var nameVal = item.season_name ? String(item.season_name) : String(item.team_name);
                var normalizedName = removeAccents(nameVal).toLowerCase();
                var normalizedCode = removeAccents(codeVal).toLowerCase();

                if (forceAll || value === "" || normalizedName.includes(value) || normalizedCode.includes(value)) {
                    var div = document.createElement('div');
                    div.className = 'px-3 py-2 hover:bg-blue-100 cursor-pointer border-b text-[12px]';
                    div.textContent = nameVal;
                    div.dataset.code = codeVal;
                    div.dataset.inputId = input.id;
                    div.dataset.listId = listId;
                    div.addEventListener('mousedown', function(e) {
                        e.preventDefault(); // ngăn blur chạy trước khi click xử lý xong
                        selectItem(this.dataset.code, this.dataset.inputId, this.dataset.listId);
                    });
                    list.appendChild(div);
                }
            });
        }

        list.classList.remove('hidden');
    }

    function selectItem(codeVal, inputId, listId) {
        var input = document.getElementById(inputId);

        if (input) {
            input.value = codeVal;
            // Đã là code hợp lệ, ẩn lỗi luôn không cần validate lại
            var msgEl = document.getElementById('msg_' + inputId);
            if (msgEl) msgEl.classList.add('hidden');
        } else {
            console.error("Không tìm thấy input với ID: " + inputId);
        }

        var list = document.querySelector(`[id$='${listId}']`);
        if (list) list.classList.add('hidden');
    }

    function validateSelection(input, listId) {
        setTimeout(() => {
            const val = removeAccents(input.value.trim());
            if (val === "") return;

            const data = listId === 'listSeason' ? dataSeason : dataTeam;
            const codeKey = listId === 'listSeason' ? 'season' : 'team';
            const nameKey = listId === 'listSeason' ? 'season_name' : 'team_name';

            const searchTerm = removeAccents(val).toLowerCase();
            const matches = data.filter(item => {
                const codeMatch = removeAccents(item[codeKey] || "").toLowerCase();
                const nameMatch = removeAccents(item[nameKey] || "").toLowerCase();
                
                return codeMatch.includes(searchTerm) || nameMatch.includes(searchTerm);
            });
            
            const msgElement = document.getElementById('msg_' + input.id);
            
            if (matches.length === 1) {
                input.value = matches[0][codeKey];
                if (msgElement) msgElement.classList.add('hidden');
            } else if (matches.length > 1) {
                const exactMatch = matches.find(item => 
                    removeAccents(item[codeKey]).toLowerCase() === removeAccents(val).toLowerCase()
                );

                if (exactMatch) {
                    input.value = exactMatch[codeKey];
                    if (msgElement) msgElement.classList.add('hidden');
                } else {
                    if (msgElement) {
                        msgElement.classList.remove('hidden');
                        msgElement.innerText = "Dữ liệu không tồn tại";
                    }
                }
            } else {
                if (msgElement) {
                    msgElement.classList.remove('hidden');
                    msgElement.innerText = "Dữ liệu không tồn tại";
                }
            }

            const listElement = document.getElementById(listId);
            if (listElement) listElement.classList.add('hidden');
        }, 200);
    }
    
    function showAllData(input, listId) {
        document.querySelectorAll('[id^="list"]').forEach(el => el.classList.add('hidden'));
        filterData(input, listId, true); 
        
        var list = document.querySelector(`[id$='${listId}']`);
        if (list) list.classList.remove('hidden');
    }

    // Xử lý datetime picker với format tùy chỉnh
    document.addEventListener('DOMContentLoaded', function() {
        const picker = document.getElementById('timePickerHidden');
        const textBox = document.querySelector('[id$="time"]');
        const hdnTimeValue = document.querySelector('[id$="hdnTimeValue"]');
        
        if (picker && textBox && hdnTimeValue) {
            picker.addEventListener('change', function() {
                if (this.value) {
                    const dt = new Date(this.value);
                    const hh = String(dt.getHours()).padStart(2, '0');
                    const mm = String(dt.getMinutes()).padStart(2, '0');
                    const dd = String(dt.getDate()).padStart(2, '0');
                    const MM = String(dt.getMonth() + 1).padStart(2, '0');
                    const yyyy = dt.getFullYear();
                    
                    // Hiển thị format đẹp cho user
                    textBox.value = `${hh}:${mm} ${dd}/${MM}/${yyyy}`;
                    
                    // Lưu giá trị ISO để post back
                    hdnTimeValue.value = this.value;
                }
            });

            // Khi click vào textbox, trigger picker
            textBox.addEventListener('click', function() {
                picker.click();
            });
        }
    });

    // Format số thập phân ##0.00
        // Format số thập phân ##0.00
    function formatDecimal(input) {
        let val = input.value.trim();
        if (val === '' || val === '-') return;
        
        // Loại bỏ ký tự không phải số, dấu chấm, dấu trừ
        val = val.replace(/[^\d.-]/g, '');
        
        // Parse thành số
        let num = parseFloat(val);
        
        // Nếu không phải số hợp lệ, xóa
        if (isNaN(num)) {
            input.value = '';
            return;
        }
        
        // Format thành ##0.00
        input.value = num.toFixed(2);
    }

    // Thêm auto select cho các trường text khác (season, home, way)
    window.addEventListener('load', function() {
        const textFields = ['season', 'home', 'way'];
        textFields.forEach(function(fieldId) {
            const field = document.querySelector('[id$="' + fieldId + '"]');
            if (field) {
                field.addEventListener('focus', function() {
                    this.select();
                });
                
                field.addEventListener('click', function() {
                    this.select();
                });
            }
        });
    });

    document.addEventListener('keydown', function (e) {
        if (e.keyCode === 13) {
            const active = document.activeElement;
            if (active.tagName === "INPUT" && active.type !== "submit") {
                e.preventDefault();
                
                const fieldIds = ["season", "time", "home", "way"];
                const currentId = active.id.split('_').pop();
                const nextIdx = fieldIds.indexOf(currentId) + 1;

                if (nextIdx < fieldIds.length) {
                    const nextEl = document.querySelector(`[id$='${fieldIds[nextIdx]}']`);
                    if (nextEl) {
                        nextEl.focus();
                        if(fieldIds[nextIdx] === 'time') {
                            const picker = document.getElementById('timePickerHidden');
                            if (picker) picker.click();
                        }
                    }
                } else {
                    active.blur();
                }
            }
        }
    });
    
    document.addEventListener('click', function (e) {
        var containers = document.querySelectorAll('.relative');
        var isInside = false;

        containers.forEach(function (container) {
            if (container.contains(e.target)) {
                isInside = true;
            }
        });

        if (!isInside) {
            var lists = document.querySelectorAll('[id^="list"]');
            lists.forEach(function (list) {
                list.classList.add('hidden');
            });
        }
    });

    // Fix Safari iOS viewport bug khi bàn phím ẩn và scroll input vào view
    if (window.innerWidth <= 768) {
        let lastFocusedElement = null;
        let focusTimeout = null;
        
        document.addEventListener('focus', function(e) {
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                lastFocusedElement = e.target;
                
                // Clear timeout cũ nếu có
                if (focusTimeout) {
                    clearTimeout(focusTimeout);
                }
                
                // Scroll input vào view khi bàn phím hiện lên
                focusTimeout = setTimeout(function() {
                    const modal = document.getElementById('modalAdd');
                    const modalContent = document.getElementById('modalFormContent');
                    
                    if (modal && modalContent && !modal.classList.contains('hidden')) {
                        // Tính toán vị trí của input trong modal
                        const inputRect = e.target.getBoundingClientRect();
                        const modalRect = modalContent.getBoundingClientRect();
                        
                        // Tính offset cần scroll
                        const inputTop = inputRect.top - modalRect.top + modalContent.scrollTop;
                        const targetScroll = inputTop - (modalRect.height / 3); // Đặt input ở 1/3 màn hình
                        
                        modalContent.scrollTo({
                            top: Math.max(0, targetScroll),
                            behavior: 'smooth'
                        });
                    }
                }, 300);
            }
        }, true);
        
        document.addEventListener('blur', function(e) {
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                // Clear timeout khi blur
                if (focusTimeout) {
                    clearTimeout(focusTimeout);
                    focusTimeout = null;
                }
            }
        }, true);
    }

    // Toggle Rate Mode
    let isRateMode = false;
    function toggleRateMode() {
        isRateMode = !isRateMode;
        const btn = document.getElementById('btnToggleRate');
        
        if (isRateMode) {
            btn.classList.remove('bg-red-500');
            btn.classList.add('bg-green-500');
            // Hiển thị các trường Rate
            document.querySelectorAll('.rate-row').forEach(row => row.classList.remove('hidden'));
        } else {
            btn.classList.remove('bg-green-500');
            btn.classList.add('bg-red-500');
            // Ẩn các trường Rate
            document.querySelectorAll('.rate-row').forEach(row => row.classList.add('hidden'));
        }
    }

</script>

