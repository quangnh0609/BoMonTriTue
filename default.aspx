<%@ Page Language="C#" %>
<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        // Kiểm tra Session "UserName" mà bạn đã gán khi đăng nhập thành công
        if (Session["UserName"] != null)
        {
            // Nếu đã đăng nhập -> Chuyển đến trang Home
            Response.Redirect("home.aspx");
        }
        else
        {
            // Nếu chưa đăng nhập -> Chuyển đến trang Login
            Response.Redirect("login.aspx");
        }
    }
</script>