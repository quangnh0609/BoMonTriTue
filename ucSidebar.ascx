<%@ Control Language="C#" AutoEventWireup="true" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Configuration" %>

<script runat="server">
    private string _activePage = "";
    
    public string ActivePage 
    { 
        get { return _activePage; }
        set { _activePage = value; }
    }
    
    protected string GetNavClass(string pageName)
    {
        return ActivePage == pageName ? "nav-item nav-item-active" : "nav-item";
    }

    protected bool IsAdminUser()
    {
        if (Session["UserID"] == null) return false;

        int userId;
        if (!Int32.TryParse(Session["UserID"].ToString(), out userId)) return false;

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = new SqlCommand("SELECT COUNT(1) FROM dbo.userinfo2 WHERE id = @userID AND admin = 1", conn);
                cmd.Parameters.Add("@userID", SqlDbType.Int).Value = userId;

                conn.Open();
                return Convert.ToInt32(cmd.ExecuteScalar()) > 0;
            }
        }
        catch
        {
            return false;
        }
    }
</script>

<style>
    #sidebar {
        height: 100%;
        overflow-y: auto;
        overscroll-behavior: contain;
        -webkit-overflow-scrolling: touch;
    }

    #sidebar .sidebar-menu {
        min-height: 100%;
        padding-bottom: calc(1rem + env(safe-area-inset-bottom));
    }

    @media (max-width: 1023px) {
        #sidebar {
            position: fixed;
            top: 4rem;
            bottom: 0;
            height: auto;
            max-height: calc(100dvh - 4rem);
        }
    }
</style>

<aside id="sidebar" class="absolute lg:relative w-64 bg-white border-r flex-none shadow-sm z-40 transition-transform duration-300 transform -translate-x-full lg:translate-x-0">
    <div class="sidebar-menu py-4 flex flex-col">
        <a href="home.aspx" class="<%=GetNavClass("home")%>">
            <i class="fa-solid fa-house" style="color: black;"></i>Trang chủ
        </a>
        <a href="matches.aspx" class="<%=GetNavClass("matches")%>">
            <i class="fa-solid fa-futbol" style="color: black;"></i>Trận đấu
        </a>
        <a href="champions.aspx" class="<%=GetNavClass("champions")%>">
            <i class="fa-solid fa-trophy" style="color: black;"></i>Kèo chung cuộc
        </a>
        <a href="esports.aspx" class="<%=GetNavClass("esports")%>">
            <i class="fa-solid fa-dragon" style="color: black;"></i>Esport
        </a>
        <a href="tickets.aspx" class="<%=GetNavClass("tickets")%>">
            <i class="fa-solid fa-ticket" style="color: black;"></i>Vé cược
        </a>
        <a href="copybetting.aspx" class="<%=GetNavClass("copybetting")%>">
            <i class="fa-solid fa-copy" style="color: black;"></i>Chép bài
        </a>
		<a href="magic.aspx" class="<%=GetNavClass("magic")%>">
			<i class="fa-solid fa-wand-magic-sparkles" style="color: black;"></i>Phép thuật
		</a>
		
        <div class="mt-auto">
			<% if (IsAdminUser()) { %>
			<a href="teams.aspx" class="<%=GetNavClass("teams")%>">
				<i class="fa-solid fa-users" style="color: black;"></i>Đội
			</a>
			<a href="seasons.aspx" class="<%=GetNavClass("seasons")%>">
				<i class="fa-solid fa-calendar-days" style="color: black;"></i>Mùa giải
			</a>
			<% } %>
			<a href="settings.aspx" class="<%=GetNavClass("settings")%>">
				<i class="fa-solid fa-gear" style="color: black;"></i>Cài đặt
			</a>
		</div>
    </div>
</aside>
