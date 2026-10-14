<%@ Page Language="C#" AutoEventWireup="true" CodePage="65001" %>
<%@ Register Src="~/ucChangePass.ascx" TagPrefix="uc" TagName="ChangePass" %>
<%@ Register Src="~/ucSidebar.ascx" TagPrefix="uc" TagName="Sidebar" %>
<%@ Register Src="~/ucPageHeaderInfo.ascx" TagPrefix="uc" TagName="PageHeaderInfo" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Data.SqlClient" %>

<script runat="server">
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["UserName"] == null) 
		{
			Response.Redirect("login.aspx?ReturnUrl=" + Server.UrlEncode(Request.Url.PathAndQuery));
			return;
		}
		
        if (!IsPostBack) { BindSettingTable(); }
        
        string fixF5 = "<script>if(window.history.replaceState){window.history.replaceState(null,null,window.location.href);}</sc" + "ript>";
        ClientScript.RegisterStartupScript(this.GetType(), "FixF5", fixF5);
    }

    private void BindSettingTable() {
        try {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr)) {
                SqlCommand cmd = new SqlCommand("bet_setting", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@username", Session["UserName"].ToString());
                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable(); 
                da.Fill(dt);
                gvSettings.DataSource = dt; 
                gvSettings.DataBind();
            }
        } catch { }
    }
</script>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <title>Cài đặt hệ thống</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <style>
        body { font-family: sans-serif; overflow: hidden; background-color: #f1f5f9; font-size: 16px; }
        .main-scroll::-webkit-scrollbar { width: 6px; }
        .main-scroll::-webkit-scrollbar-thumb { background: #cbd5e1; border-radius: 10px; }
        .menu-font { font-size: 16px; font-weight: bold; }
        .menu-link { display: flex; align-items: center; padding: 12px 16px; color: #4b5563; border-radius: 10px; margin: 4px 10px; text-decoration: none; transition: 0.2s; }
        .menu-link.active { background-color: #eff6ff; color: #1d4ed8; }
        .breadcrumb-link { color: #2563eb; text-decoration: none; }
        .breadcrumb-current { color: #4b5563; cursor: default; }
        .grid-header th { position: sticky; top: 0; z-index: 10; background-color: #1d4ed8 !important; color: white !important; text-align: center !important; padding: 12px 8px; font-size: 14px; font-weight: bold; }
        .row-style td { padding: 12px 8px; font-weight: bold; font-size: 14px; border-bottom: 1px solid #eef2f6; }
        .row-white { background-color: white; }
        .row-gray { background-color: #f9fafb; }
		
        /* Xử lý không scroll ngang */
        .table-fixed-layout { table-layout: fixed; width: 100%; }
        .truncate-text { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
		
		/* Sidebar không bị lệch và icon thẳng hàng */
		.nav-item { 
			border-right: 4px solid transparent; 
			display: flex;
			align-items: center;
			padding: 0.75rem 1rem; /* px-4 py-3 */
			font-weight: bold;
			transition: all 0.2s;
		}

		.nav-item-active { 
			border-right-color: #1d4ed8; 
			background-color: #eff6ff; 
			color: #1d4ed8 !important; 
		}

		/* Cố định kích thước icon */
		.nav-item i {
			width: 20px; 
			text-align: center;
			margin-right: 12px;
		}
    </style>
</head>
<body class="h-screen flex flex-col">
    <form runat="server" class="h-full flex flex-col">
        <nav class="bg-white border-b h-16 flex-none flex items-center justify-between px-4 lg:px-6 z-50 shadow-sm">
            <uc:PageHeaderInfo runat="server" ID="ucPageHeader" PageName="settings" PageTitle="Cài đặt" />
        </nav>

        <div class="flex flex-1 overflow-hidden relative">
            <div id="overlay" onclick="toggleSidebar()" class="fixed inset-0 bg-gray-900/50 z-30 hidden lg:hidden"></div>

            <uc:Sidebar runat="server" ID="ucSidebar" ActivePage="settings" />

            <main class="flex-1 p-3 lg:p-6 overflow-hidden bg-[#f8fafc]">
                <div class="h-full bg-white rounded-xl shadow-md border flex flex-col overflow-hidden">
                    <div class="flex-1 overflow-auto main-scroll">
                        <asp:GridView ID="gvSettings" runat="server" AutoGenerateColumns="false" CssClass="table-fixed-layout" GridLines="None">
                            <HeaderStyle CssClass="grid-header" />
                            <RowStyle CssClass="row-style row-white" />
                            <AlternatingRowStyle CssClass="row-style row-gray" />
                            <Columns>
                                <asp:TemplateField HeaderText="STT">
                                    <ItemStyle CssClass="text-center w-12 lg:w-16 text-gray-400 font-normal" />
                                    <ItemTemplate><%# Container.DataItemIndex + 1 %></ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Tên đăng nhập">
                                    <ItemStyle CssClass="text-left px-2 lg:px-8 truncate-text text-blue-700" />
                                    <ItemTemplate><%# Eval("name") %></ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Tên hiển thị">
                                    <ItemStyle CssClass="text-left px-2 lg:px-8 text-gray-500 truncate-text" />
                                    <ItemTemplate><%# Eval("comment") %></ItemTemplate>
                                </asp:TemplateField>

                                <asp:TemplateField HeaderText="Sửa">
                                    <ItemStyle CssClass="text-center w-16 lg:w-32" />
                                    <ItemTemplate>
                                        <button type="button" onclick='openChangePassModal("<%# Eval("name") %>")' 
                                                class="text-orange-500 hover:text-orange-600 transition p-2">
                                            <i class="fa-solid fa-key text-xl"></i>
                                        </button>
                                    </ItemTemplate>
                                </asp:TemplateField>
                            </Columns>
                        </asp:GridView>
                    </div>
                </div>
            </main>
        </div>

        <uc:ChangePass runat="server" ID="ucChangePass" />
    </form>

    <script>
        function toggleSidebar() {
            const sidebar = document.getElementById('sidebar');
            const overlay = document.getElementById('overlay');
            if (sidebar.classList.contains('-translate-x-full')) {
                sidebar.classList.remove('-translate-x-full');
                overlay.classList.remove('hidden');
            } else {
                sidebar.classList.add('-translate-x-full');
                overlay.classList.add('hidden');
            }
        }
    </script>
</body>
</html>
