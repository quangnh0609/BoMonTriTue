<%@ Control Language="C#" AutoEventWireup="true" %>
<%@ Register Src="~/ucNumericKeyboard.ascx" TagPrefix="uc" TagName="NumericKeyboard" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<style>
    input[type="datetime-local"] { appearance: none; -webkit-appearance: none; min-height: 2.25rem; }
    .safari-datetime-fix { position: relative; }
    .safari-datetime-fix::-webkit-calendar-picker-indicator { position: absolute; top:0; left:0; right:0; bottom:0; width:100%; height:100%; opacity:0; cursor:pointer; z-index:1; }
    @media screen and (max-width: 768px) {
        input, select, textarea, .keo-input { font-size: 16px !important; }
    }
    .game-tab { cursor: pointer; width: 100%; min-width: 0; height: 38px; display: flex; align-items: center; justify-content: center; white-space: nowrap; padding: 0 4px; border-radius: 8px 8px 0 0; font-weight: 700; font-size: 14px; line-height: 1; border: 1px solid #e5e7eb; border-bottom: none; background: #f3f4f6; color: #6b7280; transition: all 0.2s; }
    .game-tab.active { background: #7c3aed; color: #fff; border-color: #7c3aed; }
    .game-panel { display: none; }
    .game-panel.active { display: block; }
    .keo-label { font-size: 11px; font-weight: bold; color: #374151; }
    .keo-input { width: 100%; border: 1px solid #d1d5db; border-radius: 6px; padding: 4px 8px; font-size: 12px; font-weight: bold; outline: none; background: #fafafa; }
    .keo-input:focus { border-color: #7c3aed; background: white; }
    .section-title { font-size: 11px; font-weight: 900; color: #7c3aed; text-transform: uppercase; letter-spacing: 0.05em; padding: 4px 0; border-bottom: 2px solid #ede9fe; margin-bottom: 8px; }
    .esport-game-shell { border: 1px solid #e5e7eb; border-radius: 0 0 10px 10px; border-top: none; background: rgba(249,250,251,0.3); display: flex; flex-direction: column; }
    .esport-game-scroll { max-height: min(52vh, 520px); overflow-y: auto; padding: 12px; }
</style>

<script runat="server">
    public event EventHandler MatchAdded;
    protected void OnMatchAdded() { if (MatchAdded != null) MatchAdded(this, EventArgs.Empty); }
</script>

<asp:ScriptManager ID="sm1" runat="server" />

<div id="modalAddEsport" class="fixed inset-0 bg-gray-900/80 z-[60] hidden items-center justify-center p-2 font-sans">
    <div class="bg-white rounded-xl shadow-2xl border border-gray-200 w-full max-w-3xl min-w-0 flex flex-col overflow-hidden max-h-[95vh]">
        
        <!-- Header -->
        <div class="bg-gradient-to-r from-purple-600 to-purple-700 px-6 py-4 text-white flex justify-between items-center shrink-0">
            <h3 id="esportModalTitle" class="font-bold flex items-center text-[14px]">
                <i class="fa-solid fa-gamepad mr-3 text-lg"></i> Thêm mới trận Esports
            </h3>
            <button type="button" onclick="closeAddEsportModal()" class="text-white/80 hover:text-white text-xl">
                <i class="fa-solid fa-xmark"></i>
            </button>
        </div>

        <!-- Form content -->
        <div id="esportFormContent" class="p-4 flex-grow overflow-y-auto">
            <input type="hidden" id="esport_match_id" value="" />
            <input type="hidden" id="esport_edit_yn" value="false" />
            <input type="hidden" id="esportHdnTimeValue" value="" />

            <!-- Thông tin chung -->
            <div class="grid grid-cols-2 gap-3 mb-4">
                <div class="relative">
                    <label class="keo-label block mb-1">Giải đấu</label>
                    <input type="text" id="esport_season" autocomplete="off" placeholder="Giải đấu"
                        class="keo-input" onkeyup="esportFilterData(this,'esportListSeason')" onfocus="esportShowAll(this,'esportListSeason')" onblur="esportValidate(this,'esportListSeason')" />
                    <div id="esportListSeason" class="absolute z-[100] w-full bg-white shadow-xl border rounded mt-1 max-h-60 overflow-y-auto hidden text-[12px]"></div>
                    <span id="msg_esport_season" class="text-[10px] text-red-500 hidden">! Vui lòng chọn giải đấu hợp lệ</span>
                </div>
                <div class="relative">
                    <label class="keo-label block mb-1">Thời gian</label>
                    <input type="datetime-local" id="esportTimePicker" style="position:absolute;opacity:0;width:100%;height:100%;top:0;left:0;cursor:pointer;z-index:2;" onchange="esportTimePickerChange()" />
                    <input type="text" id="esport_time_display" placeholder="hh:mm dd/MM/yyyy" readonly class="keo-input cursor-pointer" onclick="document.getElementById('esportTimePicker').click()" />
                    <span id="msg_esport_time" class="text-[10px] text-red-500 hidden">! Vui lòng chọn thời gian</span>
                </div>
            </div>
            <div class="grid grid-cols-2 gap-3 mb-5">
                <div class="relative">
                    <label class="keo-label block mb-1">Đội 1</label>
                    <input type="text" id="esport_home" autocomplete="off" placeholder="Đội 1"
                        class="keo-input text-right font-black text-blue-700" onkeyup="esportFilterData(this,'esportListHome')" onfocus="esportShowAll(this,'esportListHome')" onblur="esportValidate(this,'esportListHome')" />
                    <div id="esportListHome" class="absolute z-[100] w-full bg-white shadow-xl border rounded mt-1 max-h-60 overflow-y-auto hidden text-[12px]"></div>
                    <span id="msg_esport_home" class="text-[10px] text-red-500 hidden">! Chưa chọn đội 1</span>
                </div>
                <div class="relative">
                    <label class="keo-label block mb-1">Đội 2</label>
                    <input type="text" id="esport_way" autocomplete="off" placeholder="Đội 2"
                        class="keo-input text-left font-black text-red-700" onkeyup="esportFilterData(this,'esportListWay')" onfocus="esportShowAll(this,'esportListWay')" onblur="esportValidate(this,'esportListWay')" />
                    <div id="esportListWay" class="absolute z-[100] w-full bg-white shadow-xl border rounded mt-1 max-h-60 overflow-y-auto hidden text-[12px]"></div>
                    <span id="msg_esport_way" class="text-[10px] text-red-500 hidden">! Chưa chọn đội 2</span>
                </div>
            </div>

            <!-- Tabs game -->
            <div class="mb-0 sticky top-0 z-20 bg-white">
                <div class="flex items-center justify-between gap-2 border-b border-gray-200">
                    <div class="grid grid-cols-6 gap-1 flex-1 min-w-0">
                        <div class="w-1/6 game-tab active" id="tab_g6" onclick="switchGameTab(6)">BO x</div>
                        <div class="w-1/6 game-tab" id="tab_g1" onclick="switchGameTab(1)">Game 1</div>
                        <div class="w-1/6 game-tab" id="tab_g2" onclick="switchGameTab(2)">Game 2</div>
                        <div class="w-1/6 game-tab" id="tab_g3" onclick="switchGameTab(3)">Game 3</div>
                        <div class="w-1/6 game-tab" id="tab_g4" onclick="switchGameTab(4)">Game 4</div>
                        <div class="w-1/6 game-tab" id="tab_g5" onclick="switchGameTab(5)">Game 5</div>
                    </div>
                </div>
            </div>
			
            <div class="flex items-center gap-2 py-2">
                <button type="button" id="btnToggleEsportRate" onclick="toggleEsportRateMode()" class="px-3 py-1 bg-red-500 text-white rounded text-[11px] font-bold hover:opacity-90 transition-all">Rate</button>
                <button type="button" id="btnCopyEsportGame1" onclick="copyEsportGame1ToActiveGame()" class="hidden px-3 py-1 bg-blue-600 text-white rounded text-[11px] font-bold hover:bg-blue-700 transition-all">
                    <i class="fa-solid fa-copy mr-1"></i>Copy Game 1
                </button>
            </div>

            <!-- Game panels -->
            <div class="esport-game-shell">
                <div class="esport-game-scroll">

                <!-- Game 1 -->
                <div class="game-panel" id="panel_g1">
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài Kill</label><input type="text" id="g1_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g1_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g1_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Kill đội 1</label><input type="text" id="g1_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g1_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g1_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài phút</label><input type="text" id="g1_minute_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g1_minute_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g1_minute_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài rồng</label><input type="text" id="g1_dragon_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g1_dragon_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g1_dragon_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đội 1</label><input type="text" id="g1_dragon_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g1_dragon_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g1_dragon_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 1</label><input type="text" id="g1_first_dragon_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 2</label><input type="text" id="g1_first_dragon_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 1</label><input type="text" id="g1_first_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 2</label><input type="text" id="g1_first_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 1</label><input type="text" id="g1_third_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 2</label><input type="text" id="g1_third_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 1</label><input type="text" id="g1_five_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 2</label><input type="text" id="g1_five_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 1</label><input type="text" id="g1_ten_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 2</label><input type="text" id="g1_ten_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                        <div><label class="keo-label block mb-1">Đội 1 Win</label><input type="text" id="g1_win_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Đội 2 Win</label><input type="text" id="g1_win_way_win" class="keo-input" /></div>
                    </div>
                </div>

                <!-- Game 2 -->
                <div class="game-panel" id="panel_g2">
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài Kill</label><input type="text" id="g2_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g2_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g2_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Kill đội 1</label><input type="text" id="g2_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g2_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g2_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài phút</label><input type="text" id="g2_minute_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g2_minute_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g2_minute_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài rồng</label><input type="text" id="g2_dragon_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g2_dragon_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g2_dragon_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đội 1</label><input type="text" id="g2_dragon_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g2_dragon_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g2_dragon_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 1</label><input type="text" id="g2_first_dragon_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 2</label><input type="text" id="g2_first_dragon_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 1</label><input type="text" id="g2_first_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 2</label><input type="text" id="g2_first_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 1</label><input type="text" id="g2_third_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 2</label><input type="text" id="g2_third_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 1</label><input type="text" id="g2_five_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 2</label><input type="text" id="g2_five_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 1</label><input type="text" id="g2_ten_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 2</label><input type="text" id="g2_ten_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                        <div><label class="keo-label block mb-1">Đội 1 Win</label><input type="text" id="g2_win_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Đội 2 Win</label><input type="text" id="g2_win_way_win" class="keo-input" /></div>
                    </div>
                </div>

                <!-- Game 3 -->
                <div class="game-panel" id="panel_g3">
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài Kill</label><input type="text" id="g3_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g3_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g3_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Kill đội 1</label><input type="text" id="g3_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g3_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g3_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài phút</label><input type="text" id="g3_minute_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g3_minute_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g3_minute_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài rồng</label><input type="text" id="g3_dragon_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g3_dragon_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g3_dragon_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đội 1</label><input type="text" id="g3_dragon_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g3_dragon_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g3_dragon_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 1</label><input type="text" id="g3_first_dragon_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 2</label><input type="text" id="g3_first_dragon_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 1</label><input type="text" id="g3_first_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 2</label><input type="text" id="g3_first_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 1</label><input type="text" id="g3_third_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 2</label><input type="text" id="g3_third_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 1</label><input type="text" id="g3_five_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 2</label><input type="text" id="g3_five_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 1</label><input type="text" id="g3_ten_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 2</label><input type="text" id="g3_ten_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                        <div><label class="keo-label block mb-1">Đội 1 Win</label><input type="text" id="g3_win_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Đội 2 Win</label><input type="text" id="g3_win_way_win" class="keo-input" /></div>
                    </div>
                </div>

                <!-- Game 4 -->
                <div class="game-panel" id="panel_g4">
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài Kill</label><input type="text" id="g4_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g4_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g4_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Kill đội 1</label><input type="text" id="g4_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g4_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g4_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài phút</label><input type="text" id="g4_minute_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g4_minute_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g4_minute_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài rồng</label><input type="text" id="g4_dragon_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g4_dragon_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g4_dragon_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đội 1</label><input type="text" id="g4_dragon_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g4_dragon_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g4_dragon_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 1</label><input type="text" id="g4_first_dragon_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 2</label><input type="text" id="g4_first_dragon_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 1</label><input type="text" id="g4_first_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 2</label><input type="text" id="g4_first_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 1</label><input type="text" id="g4_third_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 2</label><input type="text" id="g4_third_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 1</label><input type="text" id="g4_five_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 2</label><input type="text" id="g4_five_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 1</label><input type="text" id="g4_ten_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 2</label><input type="text" id="g4_ten_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                        <div><label class="keo-label block mb-1">Đội 1 Win</label><input type="text" id="g4_win_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Đội 2 Win</label><input type="text" id="g4_win_way_win" class="keo-input" /></div>
                    </div>
                </div>
                <!-- Game 5 -->
                <div class="game-panel" id="panel_g5">
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài Kill</label><input type="text" id="g5_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g5_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g5_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Kill đội 1</label><input type="text" id="g5_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g5_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g5_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài phút</label><input type="text" id="g5_minute_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g5_minute_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g5_minute_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài rồng</label><input type="text" id="g5_dragon_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g5_dragon_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g5_dragon_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đội 1</label><input type="text" id="g5_dragon_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g5_dragon_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g5_dragon_hc_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 1</label><input type="text" id="g5_first_dragon_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Rồng đầu - Đội 2</label><input type="text" id="g5_first_dragon_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 1</label><input type="text" id="g5_first_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Mạng đầu - Đội 2</label><input type="text" id="g5_first_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 1</label><input type="text" id="g5_third_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">3 mạng đầu - Đội 2</label><input type="text" id="g5_third_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 1</label><input type="text" id="g5_five_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">5 mạng đầu - Đội 2</label><input type="text" id="g5_five_way_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 1</label><input type="text" id="g5_ten_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">10 mạng đầu - Đội 2</label><input type="text" id="g5_ten_way_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-2 gap-2">
                        <div><label class="keo-label block mb-1">Đội 1 Win</label><input type="text" id="g5_win_home_win" class="keo-input" /></div>
                        <div><label class="keo-label block mb-1">Đội 2 Win</label><input type="text" id="g5_win_way_win" class="keo-input" /></div>
                    </div>
                </div>
                <!-- BO x -->
                <div class="game-panel active" id="panel_g6">
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Tài game</label><input type="text" id="g6_ou_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Tài</label><input type="text" id="g6_ou_over_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Xỉu</label><input type="text" id="g6_ou_under_win" class="keo-input" /></div>
                    </div>
                    <div class="grid grid-cols-3 gap-2 mb-3">
                        <div><label class="keo-label block mb-1">Game đội 1</label><input type="text" id="g6_hc_line" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 1</label><input type="text" id="g6_hc_home_win" class="keo-input" /></div>
                        <div class="esport-rate-field hidden"><label class="keo-label block mb-1">Rate Đội 2</label><input type="text" id="g6_hc_way_win" class="keo-input" /></div>
                    </div>
                </div>
            </div><!-- end game panels -->
                </div>
            </div><!-- end form content -->

        <!-- Footer -->
        <div class="px-4 py-3 bg-gray-50 border-t flex justify-end gap-3 shrink-0">
            <button type="button" onclick="closeAddEsportModal()" class="px-5 py-2 rounded-lg border border-gray-300 text-gray-700 font-bold text-sm hover:bg-gray-100 transition-all">
                <i class="fa-solid fa-xmark mr-1"></i>Hủy
            </button>
            <button type="button" id="btnSaveEsport" onclick="saveEsportMatch()" class="px-6 py-2 rounded-lg bg-purple-600 hover:bg-purple-700 text-white font-bold text-sm transition-all active:scale-95">
                <i class="fa-solid fa-floppy-disk mr-1"></i>Lưu lại
            </button>
        </div>
    </div>
</div>

<uc:NumericKeyboard runat="server" ID="ucNumericKeyboardEsport" />

<script type="text/javascript">
    // ===== Tab switching =====
    let activeEsportGameTab = 6;
    function switchGameTab(n) {
        for (let i = 1; i <= 6; i++) {
            document.getElementById('tab_g' + i).classList.remove('active');
            document.getElementById('panel_g' + i).classList.remove('active');
        }
        document.getElementById('tab_g' + n).classList.add('active');
        document.getElementById('panel_g' + n).classList.add('active');
        activeEsportGameTab = n;

        const copyBtn = document.getElementById('btnCopyEsportGame1');
        if (copyBtn) copyBtn.classList.toggle('hidden', n < 2 || n > 5);
    }

    // ===== Modal open/close =====
    let esportScrollPos = 0;
    function openAddEsportModalUI() {
        esportScrollPos = window.pageYOffset || document.documentElement.scrollTop;
        document.body.style.position = 'fixed';
        document.body.style.top = '-' + esportScrollPos + 'px';
        document.body.style.width = '100%';
        document.body.style.overflow = 'hidden';
        const modal = document.getElementById('modalAddEsport');
        modal.classList.remove('hidden');
        modal.classList.add('flex');
    }
    function closeAddEsportModal() {
        const modal = document.getElementById('modalAddEsport');
        modal.classList.add('hidden');
        modal.classList.remove('flex');
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        document.body.style.overflow = '';
        window.scrollTo(0, esportScrollPos);
    }

    // ===== Time picker =====
    function esportTimePickerChange() {
        const picker = document.getElementById('esportTimePicker');
        const display = document.getElementById('esport_time_display');
        const hdn = document.getElementById('esportHdnTimeValue');
        if (picker.value) {
            const dt = new Date(picker.value);
            const hh = String(dt.getHours()).padStart(2,'0');
            const mm = String(dt.getMinutes()).padStart(2,'0');
            const dd = String(dt.getDate()).padStart(2,'0');
            const MM = String(dt.getMonth()+1).padStart(2,'0');
            const yyyy = dt.getFullYear();
            display.value = `${hh}:${mm} ${dd}/${MM}/${yyyy}`;
            hdn.value = picker.value;
        }
    }

    // ===== Dropdown helpers =====
    function removeAccentsE(str) { return str.normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase(); }

    function esportFilterData(input, listId) {
        const val = removeAccentsE(input.value.trim());
        const list = document.getElementById(listId);
        if (!list) return;
        let data = [];
        if (listId === 'esportListSeason') data = (typeof dataSeason !== 'undefined') ? dataSeason : [];
        else data = (typeof dataTeam !== 'undefined') ? dataTeam : [];
        list.innerHTML = '';
        data.forEach(function(item) {
            const code = item.season ? String(item.season) : String(item.team);
            const name = item.season_name ? String(item.season_name) : String(item.team_name);
            if (val === '' || removeAccentsE(name).includes(val) || removeAccentsE(code).includes(val)) {
                const div = document.createElement('div');
                div.className = 'px-3 py-2 hover:bg-purple-50 cursor-pointer border-b text-[12px] font-bold';
                div.textContent = name;
                div.addEventListener('mousedown', function(e) {
                    e.preventDefault();
                    input.value = code;
                    list.classList.add('hidden');
                    const msgEl = document.getElementById('msg_' + input.id);
                    if (msgEl) msgEl.classList.add('hidden');
                });
                list.appendChild(div);
            }
        });
        list.classList.remove('hidden');
    }
    function esportShowAll(input, listId) {
        document.querySelectorAll('[id^="esportList"]').forEach(el => el.classList.add('hidden'));
        esportFilterData(input, listId);
    }
    function esportValidate(input, listId) {
        setTimeout(function() {
            const val = input.value.trim();
            if (!val) return;
            const data = listId === 'esportListSeason' ? (typeof dataSeason !== 'undefined' ? dataSeason : []) : (typeof dataTeam !== 'undefined' ? dataTeam : []);
            const codeKey = listId === 'esportListSeason' ? 'season' : 'team';
            const nameKey = listId === 'esportListSeason' ? 'season_name' : 'team_name';
            const search = removeAccentsE(val);
            const matches = data.filter(i => removeAccentsE(i[codeKey]||'').includes(search) || removeAccentsE(i[nameKey]||'').includes(search));
            const msgEl = document.getElementById('msg_' + input.id);
            if (matches.length === 1) { input.value = matches[0][codeKey]; if (msgEl) msgEl.classList.add('hidden'); }
            else if (matches.length > 1) {
                const exact = matches.find(i => removeAccentsE(i[codeKey]).toLowerCase() === search);
                if (exact) { input.value = exact[codeKey]; if (msgEl) msgEl.classList.add('hidden'); }
                else if (msgEl) { msgEl.classList.remove('hidden'); msgEl.textContent = 'Dữ liệu không tồn tại'; }
            } else if (msgEl) { msgEl.classList.remove('hidden'); msgEl.textContent = 'Dữ liệu không tồn tại'; }
            document.getElementById(listId).classList.add('hidden');
        }, 200);
    }
    document.addEventListener('click', function(e) {
        if (!e.target.closest('.relative')) {
            document.querySelectorAll('[id^="esportList"]').forEach(el => el.classList.add('hidden'));
        }
    });

    // ===== Collect game data =====
    const GAME_FIELDS = ['ou_line','ou_over_win','ou_under_win','hc_line','hc_home_win','hc_way_win','minute_line','minute_over_win','minute_under_win',
        'dragon_ou_line','dragon_ou_over_win','dragon_ou_under_win','dragon_hc_line','dragon_hc_home_win','dragon_hc_way_win',
        'first_dragon_home_win','first_dragon_way_win',
        'first_dragon_tech_win','first_dragon_chemtech_win','first_dragon_wind_win','first_dragon_water_win','first_dragon_fire_win','first_dragon_earth_win',
        'first_home_win','first_way_win','third_home_win','third_way_win',
        'five_home_win','five_way_win','ten_home_win','ten_way_win',
        'win_home_win','win_way_win'];
    const ESPORT_DEFAULT_RATE_FIELDS = ['ou_over_win','ou_under_win','hc_home_win','hc_way_win','minute_over_win','minute_under_win',
        'dragon_ou_over_win','dragon_ou_under_win','dragon_hc_home_win','dragon_hc_way_win'];

    let isEsportRateMode = false;
    const DRAGON_TYPE_FIELDS = [
        { field: 'first_dragon_tech_win', label: 'Rồng đầu công nghệ' },
        { field: 'first_dragon_chemtech_win', label: 'Rồng đầu hóa kỹ' },
        { field: 'first_dragon_wind_win', label: 'Rồng đầu gió' },
        { field: 'first_dragon_water_win', label: 'Rồng đầu nước' },
        { field: 'first_dragon_fire_win', label: 'Rồng đầu lửa' },
        { field: 'first_dragon_earth_win', label: 'Rồng đầu đất' }
    ];

    function ensureDragonTypeFields() {
        for (let gameNo = 1; gameNo <= 5; gameNo++) {
            if (document.getElementById('g' + gameNo + '_first_dragon_tech_win')) continue;
            const anchor = document.getElementById('g' + gameNo + '_first_dragon_way_win');
            if (!anchor || !anchor.closest('.grid')) continue;

            const row = document.createElement('div');
            row.className = 'grid grid-cols-2 gap-2 mb-3';
            row.innerHTML = DRAGON_TYPE_FIELDS.map(function(item) {
                return '<div><label class="keo-label block mb-1">' + item.label + '</label><input type="text" id="g' + gameNo + '_' + item.field + '" class="keo-input" /></div>';
            }).join('');
            anchor.closest('.grid').insertAdjacentElement('afterend', row);
        }
    }

    function toggleEsportRateMode() {
        isEsportRateMode = !isEsportRateMode;
        const btn = document.getElementById('btnToggleEsportRate');
        if (btn) {
            btn.classList.toggle('bg-green-500', isEsportRateMode);
            btn.classList.toggle('bg-red-500', !isEsportRateMode);
        }
        document.querySelectorAll('.esport-rate-field').forEach(function(el) {
            el.classList.toggle('hidden', !isEsportRateMode);
        });
    }

    function formatDecimal(input) {
        let val = (input && input.value ? input.value : '').trim();
        if (val === '' || val === '-') return;
        val = val.replace(/[^\d.-]/g, '');
        const num = parseFloat(val);
        input.value = isNaN(num) ? '' : num.toFixed(2);
    }

    function bindEsportNumericFields() {
        const selectors = [];
        for (let i = 1; i <= 6; i++) {
            GAME_FIELDS.forEach(function(f) {
                const id = 'g' + i + '_' + f;
                const el = document.getElementById(id);
                if (!el) return;
                selectors.push('#' + id);
                el.addEventListener('blur', function() { formatDecimal(el); });
            });
        }
        if (window.NumericKeyboard) {
            window.NumericKeyboard.attachToFields(selectors);
        }
    }

    function collectGameData(gameNum) {
        const g = {};
        GAME_FIELDS.forEach(function(f) {
            const el = document.getElementById('g' + gameNum + '_' + f);
            g[f] = el ? el.value.trim() : '';
        });
        return g;
    }

    function copyEsportGame1ToActiveGame() {
        if (activeEsportGameTab < 2 || activeEsportGameTab > 5) return;

        GAME_FIELDS.forEach(function(f) {
            const source = document.getElementById('g1_' + f);
            const target = document.getElementById('g' + activeEsportGameTab + '_' + f);
            if (!source || !target) return;
            target.value = source.value;
            target.dispatchEvent(new Event('input', { bubbles: true }));
            target.dispatchEvent(new Event('change', { bubbles: true }));
        });
    }

    function isGameEmpty(gameData) {
        return GAME_FIELDS.every(function(f) {
            if (ESPORT_DEFAULT_RATE_FIELDS.includes(f) && parseFloat(gameData[f]) === 0.9) return true;
            return !gameData[f];
        });
    }

    // ===== Save =====
    function saveEsportMatch() {
        // Validate
        const season = document.getElementById('esport_season').value.trim();
        const home = document.getElementById('esport_home').value.trim();
        const way = document.getElementById('esport_way').value.trim();
        const timeVal = document.getElementById('esportHdnTimeValue').value.trim();

        let valid = true;
        function showMsg(id, show) {
            const el = document.getElementById(id);
            if (el) { if (show) el.classList.remove('hidden'); else el.classList.add('hidden'); }
        }
        if (!season) { showMsg('msg_esport_season', true); valid = false; } else showMsg('msg_esport_season', false);
        if (!timeVal) { showMsg('msg_esport_time', true); valid = false; } else showMsg('msg_esport_time', false);
        if (!home) { showMsg('msg_esport_home', true); valid = false; } else showMsg('msg_esport_home', false);
        if (!way) { showMsg('msg_esport_way', true); valid = false; } else showMsg('msg_esport_way', false);
        if (!valid) return;

        const games = [];
        for (let i = 1; i <= 6; i++) {
            const gd = collectGameData(i);
            if (!isGameEmpty(gd)) {
                gd.game_no = i;
                games.push(gd);
            }
        }
        if (games.length === 0) { alert('Vui lòng nhập kèo cho ít nhất 1 game.'); return; }

        const payload = {
            match_id: document.getElementById('esport_match_id').value.trim(),
            edit_yn: document.getElementById('esport_edit_yn').value,
            season: season,
            home: home,
            way: way,
            match_time: timeVal,
            games: games
        };

        const btn = document.getElementById('btnSaveEsport');
        btn.disabled = true;
        btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin mr-1"></i>Đang lưu...';

        fetch('SaveEsport.aspx', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        })
        .then(function(r) { return r.text().then(function(t) { try { return JSON.parse(t); } catch(e) { throw new Error('Server: ' + t.substring(0,200)); } }); })
        .then(function(result) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-floppy-disk mr-1"></i>Lưu lại';
            if (result.isSuccess == 1) {
                if (typeof clearEsportGameDetailsCache === 'function') {
                    clearEsportGameDetailsCache(document.getElementById('esport_match_id').value || '');
                }
                alert(result.msg);
                closeAddEsportModal();
                clearEsportForm();
                if (typeof reloadMatchesData === 'function') reloadMatchesData();
                else location.reload();
            } else {
                alert(result.msg);
            }
        })
        .catch(function(err) {
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-floppy-disk mr-1"></i>Lưu lại';
            alert('Lỗi khi lưu: ' + err);
        });
    }

    // ===== Clear form =====
    function clearEsportForm() {
        document.getElementById('esport_match_id').value = '';
        document.getElementById('esport_edit_yn').value = 'false';
        document.getElementById('esportHdnTimeValue').value = '';
        document.getElementById('esport_season').value = '';
        document.getElementById('esport_home').value = '';
        document.getElementById('esport_way').value = '';
        document.getElementById('esport_time_display').value = '';
        document.getElementById('esportTimePicker').value = '';
        for (let i = 1; i <= 6; i++) {
            GAME_FIELDS.forEach(function(f) {
                const el = document.getElementById('g' + i + '_' + f);
                if (el) el.value = '';
            });
        }
        switchGameTab(6);
        if (isEsportRateMode) toggleEsportRateMode();
        const title = document.getElementById('esportModalTitle');
        if (title) title.innerHTML = '<i class="fa-solid fa-gamepad mr-3 text-lg"></i> Thêm mới trận Esports';
    }

    function prepareNewEsportForm() {
        clearEsportForm();
        for (let i = 1; i <= 6; i++) {
            ESPORT_DEFAULT_RATE_FIELDS.forEach(function(f) {
                const el = document.getElementById('g' + i + '_' + f);
                if (el) el.value = '0.9';
            });
        }
    }

    // ===== Fill edit form =====
    function fillEsportEditForm(data) {
        clearEsportForm();
        document.getElementById('esport_match_id').value = data.match_id || '';
        document.getElementById('esport_edit_yn').value = 'true';
        document.getElementById('esport_season').value = data.season || '';
        document.getElementById('esport_home').value = data.home || '';
        document.getElementById('esport_way').value = data.way || '';
        if (data.match_time) {
            try {
                let dt;
                if (typeof data.match_time === 'string' && data.match_time.startsWith('/Date(')) {
                    dt = new Date(parseInt(data.match_time.match(/\d+/)[0]));
                } else { dt = new Date(data.match_time); }
                if (!isNaN(dt.getTime())) {
                    const hh = String(dt.getHours()).padStart(2,'0');
                    const mm = String(dt.getMinutes()).padStart(2,'0');
                    const dd = String(dt.getDate()).padStart(2,'0');
                    const MM = String(dt.getMonth()+1).padStart(2,'0');
                    const yyyy = dt.getFullYear();
                    document.getElementById('esport_time_display').value = `${hh}:${mm} ${dd}/${MM}/${yyyy}`;
                    document.getElementById('esportHdnTimeValue').value = `${yyyy}-${MM}-${dd}T${hh}:${mm}`;
                    document.getElementById('esportTimePicker').value = `${yyyy}-${MM}-${dd}T${hh}:${mm}`;
                }
            } catch(e) {}
        }
        // Fill game data
        if (data.games && Array.isArray(data.games)) {
            data.games.forEach(function(g) {
                const n = g.game_no;
                if (n >= 1 && n <= 6) {
                    GAME_FIELDS.forEach(function(f) {
                        const el = document.getElementById('g' + n + '_' + f);
                        if (el && g[f] !== null && g[f] !== undefined) el.value = g[f];
                    });
                }
            });
        }
        const title = document.getElementById('esportModalTitle');
        if (title) title.innerHTML = '<i class="fa-solid fa-pen-to-square mr-3 text-lg"></i> Sửa trận Esports';
    }

    document.addEventListener('DOMContentLoaded', function() {
        ensureDragonTypeFields();
        bindEsportNumericFields();
    });
</script>





