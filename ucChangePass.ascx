<%@ Control Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    protected void btnUpdate_Click(object sender, EventArgs e)
    {
        // 1. Lấy thông tin (Sửa lỗi ?. bằng cách kiểm tra null truyền thống cho .NET 4.0)
        string currentUser = (Session["UserName"] != null) ? Session["UserName"].ToString() : "";
        string targetUser = hdnTargetUser.Value;
        
        // 2. Mã hóa MD5 (Khai báo biến đầy đủ để tránh lỗi CS0103)
        string currentPassMD5 = Lib.ToMD5(txtCurrentPass.Value.Trim());
        string newPassMD5 = Lib.ToMD5(txtNewPass.Value.Trim());

        // 3. Thực thi SQL
        string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
        using (SqlConnection conn = new SqlConnection(connStr))
        {
            SqlCommand cmd = new SqlCommand("bet_ucChangePass", conn);
            cmd.CommandType = CommandType.StoredProcedure;
            cmd.Parameters.AddWithValue("@currentUser", currentUser);
            cmd.Parameters.AddWithValue("@currentPass", currentPassMD5);
            cmd.Parameters.AddWithValue("@targetUser", targetUser);
            cmd.Parameters.AddWithValue("@newPass", newPassMD5);

            try {
                conn.Open();
                SqlDataReader dr = cmd.ExecuteReader();
                if (dr.Read())
                {
                    string success = dr["success"].ToString();
                    string message = dr["msg"].ToString().Replace("'", "\\'");

                    // Gọi hàm JavaScript hiển thị popup thông báo đè lên mà không làm mất dữ liệu
                    string script = string.Format("showResultModal('{0}', {1});", message, success);
                    ScriptManager.RegisterStartupScript(upnlChangePass, upnlChangePass.GetType(), "ShowResult", script, true);
                }
            }
            catch (Exception ex) {
                string errorMsg = ex.Message.Replace("'", "\\'");
                ScriptManager.RegisterStartupScript(upnlChangePass, upnlChangePass.GetType(), "Error", "showResultModal('Lỗi hệ thống: " + errorMsg + "', 0);", true);
            }
        }
    }
</script>

<asp:ScriptManager ID="sm1" runat="server" />

<asp:UpdatePanel ID="upnlChangePass" runat="server">
    <ContentTemplate>
        <div id="changePassModal" class="hidden fixed inset-0 z-40 bg-black/60 flex items-center justify-center p-4">
            <div class="bg-white w-full max-w-md rounded-2xl shadow-2xl border border-gray-100 overflow-hidden">
                <div class="p-5 bg-blue-700 text-white flex justify-between items-center">
                    <span class="font-bold uppercase text-sm">Đổi mật khẩu: <span id="displayTargetUser" class="underline"></span></span>
                    <button type="button" onclick="closeModal()" class="text-white text-2xl">&times;</button>
                </div>

                <div class="p-6 space-y-4">
                    <asp:HiddenField ID="hdnTargetUser" runat="server" />
                    
                    <div>
                        <label class="block text-xs font-bold text-gray-400 mb-1 uppercase">Mật khẩu hiện tại</label>
                        <input type="password" id="txtCurrentPass" runat="server" class="w-full px-4 py-2 bg-gray-50 border rounded-lg outline-none text-sm" />
                    </div>

                    <div class="grid grid-cols-1 gap-4 pt-2 border-t border-gray-100">
                        <input type="password" id="txtNewPass" runat="server" class="w-full px-4 py-2 bg-gray-50 border rounded-lg outline-none text-sm" placeholder="Mật khẩu mới" />
                        <input type="password" id="txtConfirmPass" runat="server" class="w-full px-4 py-2 bg-gray-50 border rounded-lg outline-none text-sm" placeholder="Xác nhận lại mật khẩu" />
                    </div>

                    <div class="flex gap-2 pt-4">
                        <button type="button" onclick="closeModal()" class="flex-1 py-2 bg-gray-100 text-gray-600 font-bold rounded-lg text-xs uppercase">Hủy</button>
                        <asp:Button ID="btnUpdate" runat="server" Text="CẬP NHẬT" 
                            OnClientClick="return validateForm();" 
                            OnClick="btnUpdate_Click" 
                            class="flex-[2] py-2 bg-blue-600 text-white font-bold rounded-lg text-xs hover:bg-blue-700 shadow-md transition cursor-pointer uppercase" />
                    </div>
                </div>
            </div>
        </div>

        <div id="resultModal" class="hidden fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/20">
            <div class="bg-white w-full max-w-xs rounded-xl shadow-2xl border border-gray-200 p-6 text-center">
                <div id="resultIcon" class="text-4xl mb-3"></div>
                <p id="resultMsg" class="text-sm font-medium text-gray-700 mb-5"></p>
                <button type="button" onclick="closeResultModal()" class="w-full py-2 bg-gray-800 text-white font-bold rounded-lg text-xs uppercase">Đóng</button>
            </div>
        </div>
    </ContentTemplate>
</asp:UpdatePanel>

<script>
    var isSuccess = 0;

    function validateForm() {
        var p1 = document.getElementById('<%= txtNewPass.ClientID %>').value.trim();
        var p2 = document.getElementById('<%= txtConfirmPass.ClientID %>').value.trim();
        var cur = document.getElementById('<%= txtCurrentPass.ClientID %>').value.trim();

        if (cur === "" || p1 === "" || p2 === "") {
            showResultModal("Vui lòng nhập đủ thông tin!", 0);
            return false;
        }
        if (p1 !== p2) {
            showResultModal("Mật khẩu mới không khớp nhau!", 0);
            document.getElementById('<%= txtConfirmPass.ClientID %>').focus();
            return false;
        }
        return true;
    }

    function showResultModal(msg, status) {
        isSuccess = status;
        document.getElementById("resultMsg").innerText = msg;
        document.getElementById("resultIcon").innerText = (status == 1) ? "✅" : "❌";
        document.getElementById("resultModal").classList.remove("hidden");
        // Đảm bảo popup đổi pass vẫn hiện ở dưới
        document.getElementById("changePassModal").classList.remove("hidden");
    }

    function closeResultModal() {
        document.getElementById("resultModal").classList.add("hidden");
        if (isSuccess == 1) {
            closeModal();
            location.href = 'settings.aspx';
        } else {
            document.getElementById('<%= txtCurrentPass.ClientID %>').focus();
        }
    }

    function openChangePassModal(username) {
        document.getElementById("displayTargetUser").innerText = username;
        document.getElementById('<%= hdnTargetUser.ClientID %>').value = username;
        document.getElementById("changePassModal").classList.remove("hidden");
        document.getElementById('<%= txtCurrentPass.ClientID %>').focus();
    }

    function closeModal() {
        document.getElementById("changePassModal").classList.add("hidden");
        document.body.style.overflow = 'auto';
    }
</script>