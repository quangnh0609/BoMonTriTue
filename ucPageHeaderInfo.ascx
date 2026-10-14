<%@ Control Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="System.Web.Security" %>

<script runat="server">
    private string _pageName = "";
    private string _pageTitle = "";
    
    public string PageName 
    { 
        get { return _pageName; }
        set { _pageName = value; }
    }
    
    public string PageTitle 
    { 
        get { return _pageTitle; }
        set { _pageTitle = value; }
    }
    
    protected void btnLogout_Click(object sender, EventArgs e)
    {
        FormsAuthentication.SignOut();
        Session.Abandon();
        Response.Redirect("login.aspx");
    }
    
    protected string GetBreadcrumb()
    {
        if (PageName == "home")
        {
            return "<span class='breadcrumb-current'>Trang chủ</span>";
        }
        else
        {
            return "<a href='home.aspx' class='breadcrumb-link flex items-center'>" +
                   "<i class='fa-solid fa-house-chimney mr-2 text-[14px]'></i><span class='hidden sm:inline'>Trang chủ</span>" +
                   "</a>" +
                   "<span class='mx-2 lg:mx-3 text-gray-300 font-light'>/</span>" +
                   "<span class='breadcrumb-current'>" + PageTitle + "</span>";
        }
    }
</script>

<div class="flex items-center">
    <button type="button" onclick="toggleSidebar()" class="lg:hidden p-2 mr-2 text-gray-700 hover:text-gray-900 transition-colors">
        <i class="fa-solid fa-bars text-xl"></i>
    </button>
    <div class="flex items-center font-bold text-[16px]">
        <%= GetBreadcrumb() %>
    </div>
</div>
<div class="flex items-center gap-2 lg:gap-4">
    <span class="text-gray-400 italic text-xs lg:text-sm whitespace-nowrap">Chào, <b><%= Session["UserName"] %></b></span>
    <asp:LinkButton ID="btnLogout" runat="server" OnClick="btnLogout_Click" class="bg-red-500 hover:bg-red-600 text-white px-3 lg:px-4 py-2 rounded font-bold uppercase text-[10px] lg:text-[11px] transition shadow-sm">Thoát</asp:LinkButton>
</div>
