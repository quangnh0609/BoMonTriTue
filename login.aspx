<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Security.Cryptography" %>
<%@ Import Namespace="System.Text" %>
<%@ Import Namespace="System.Web.Security" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        AuthSession.TryRestoreFromFormsAuth();

        if (Session["UserName"] != null)
		{
			RedirectAfterLogin();
            return;
		}

		Response.ContentEncoding = System.Text.Encoding.UTF8;
        
        if (Request.QueryString["error"] == "1")
        {
            lblError.Text = "Tên đăng nhập hoặc mật khẩu không đúng!";
            if (Request.QueryString["u"] != null)
            {
                txtUser.Value = Request.QueryString["u"].ToUpper();
            }
        }
    }

    protected void btnLogin_Click(object sender, EventArgs e)
    {
        string user = txtUser.Value.Trim().ToUpper();
        string pass = txtPass.Value.Trim();
        string hashedPass = Lib.ToMD5(pass);
        bool rememberLogin = chkRememberLogin.Checked;

        string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;

        try
        {
            using (SqlConnection conn = new SqlConnection(connStr))
			{
				string sql = "exec bet_login @u, @p";
				SqlCommand cmd = new SqlCommand(sql, conn);
				cmd.Parameters.AddWithValue("@u", user);
				cmd.Parameters.AddWithValue("@p", hashedPass);

				conn.Open();

				// Khai báo 'reader' ở đây
				using (SqlDataReader reader = cmd.ExecuteReader())
				{
					if (reader.Read()) 
					{
						AuthSession.StoreCurrentUser(reader);
                        FormsAuthentication.SetAuthCookie(user, rememberLogin);

						RedirectAfterLogin();
                        return;
					}
				}
			}

            lblError.Text = "Tên đăng nhập hoặc mật khẩu không đúng!";
        }
        catch (Exception ex)
        {
            lblError.Text = "Lỗi hệ thống: " + ex.Message;
        }
    }

    private void RedirectAfterLogin()
    {
        string returnUrl = Request.QueryString["ReturnUrl"];
        string targetUrl = !string.IsNullOrEmpty(returnUrl) ? returnUrl : "home.aspx";
        Response.Redirect(targetUrl, false);
        Context.ApplicationInstance.CompleteRequest();
    }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Đăng nhập</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <script src="https://cdn.tailwindcss.com"></script>
    <style>
        /* Ngăn chặn việc zoom vào input khi focus trên mobile */
        input[type="text"], input[type="password"] {
            font-size: 16px !important;
        }
    </style>
</head>
<body class="bg-slate-100 flex min-h-screen items-center justify-center p-4">
    <div class="bg-white p-6 md:p-10 rounded-xl shadow-2xl w-full max-w-md">
        <h2 class="text-xl md:text-2xl font-bold mb-6 md:mb-8 text-gray-800 text-center border-b pb-4">ĐĂNG NHẬP</h2>
        
        <form id="form1" runat="server" class="space-y-5" autocomplete="on">
            <div>
                <label class="block text-sm font-semibold text-gray-600 mb-2">Tên đăng nhập</label>
                <input type="text" id="txtUser" runat="server" placeholder="USERNAME" required
                    autocomplete="username"
                    oninput="this.value = this.value.toUpperCase()"
                    class="w-full p-3 border border-gray-300 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 transition-all uppercase font-medium">
            </div>
            
            <div>
                <label class="block text-sm font-semibold text-gray-600 mb-2">Mật khẩu</label>
                <input type="password" id="txtPass" runat="server" placeholder="••••••••" required
                    autocomplete="current-password"
                    class="w-full p-3 border border-gray-300 rounded-lg outline-none focus:ring-2 focus:ring-blue-500 transition-all">
            </div>

            <div class="space-y-2">
                <div class="flex items-center gap-2">
                    <input type="checkbox" id="chkRememberLogin" runat="server" class="w-4 h-4 accent-blue-600 cursor-pointer">
                    <label for="<%= chkRememberLogin.ClientID %>" class="text-sm text-gray-600 cursor-pointer select-none">Ghi nhớ đăng nhập</label>
                </div>
                <div class="flex items-center gap-2">
                    <input type="checkbox" id="chkRemember" class="w-4 h-4 accent-blue-600 cursor-pointer">
                    <label for="chkRemember" class="text-sm text-gray-600 cursor-pointer select-none">Lưu mật khẩu</label>
                </div>
            </div>

            <asp:Button ID="btnLogin" runat="server" Text="ĐĂNG NHẬP" OnClick="btnLogin_Click" 
                class="w-full bg-blue-600 text-white py-3 rounded-lg hover:bg-blue-700 active:scale-95 transition-all font-bold shadow-md cursor-pointer" />
            
            <div class="text-center mt-2">
                <asp:Label ID="lblError" runat="server" ForeColor="Red" Font-Bold="true" Font-Size="Small"></asp:Label>
            </div>
        </form>
    </div>

    <script>
        var KEY_USER = 'login_saved_user';
        var KEY_PASS = 'login_saved_pass';

        window.onload = function() {
            var txtUser = document.getElementById('<%= txtUser.ClientID %>');
            var txtPass = document.getElementById('<%= txtPass.ClientID %>');
            var chk = document.getElementById('chkRemember');

            // Điền lại nếu đã lưu
            var savedUser = localStorage.getItem(KEY_USER);
            var savedPass = localStorage.getItem(KEY_PASS);
            if (savedUser && savedPass) {
                txtUser.value = savedUser;
                txtPass.value = savedPass;
                chk.checked = true;
                txtPass.focus();
            } else if (txtUser.value.trim() === "") {
                txtUser.focus();
            } else {
                txtPass.focus();
            }

            // Lưu hoặc xóa trước khi submit
            var form = document.getElementById('form1');
            form.addEventListener('submit', function() {
                if (chk.checked) {
                    localStorage.setItem(KEY_USER, txtUser.value.trim());
                    localStorage.setItem(KEY_PASS, txtPass.value);
                } else {
                    localStorage.removeItem(KEY_USER);
                    localStorage.removeItem(KEY_PASS);
                }
            });
        };
    </script>
</body>
</html>
