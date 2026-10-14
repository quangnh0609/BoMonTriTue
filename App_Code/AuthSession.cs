using System;
using System.Configuration;
using System.Data.SqlClient;
using System.Web;
using System.Web.Security;

public static class AuthSession
{
    public static void StoreCurrentUser(SqlDataReader reader)
    {
        HttpContext context = HttpContext.Current;
        if (context == null || context.Session == null) return;

        context.Session["UserID"] = reader["id"].ToString();
        context.Session["UserName"] = reader["name"].ToString();
        context.Session["FullName"] = reader["comment"].ToString();
    }

    public static bool TryRestoreFromFormsAuth()
    {
        HttpContext context = HttpContext.Current;
        if (context == null || context.Session == null) return false;
        if (context.Session["UserName"] != null) return true;

        HttpCookie cookie = context.Request.Cookies[FormsAuthentication.FormsCookieName];
        if (cookie == null || string.IsNullOrEmpty(cookie.Value)) return false;

        FormsAuthenticationTicket ticket;
        try
        {
            ticket = FormsAuthentication.Decrypt(cookie.Value);
        }
        catch
        {
            return false;
        }

        if (ticket == null || ticket.Expired || string.IsNullOrEmpty(ticket.Name)) return false;

        try
        {
            string connStr = ConfigurationManager.ConnectionStrings["MyDbConn"].ConnectionString;
            using (SqlConnection conn = new SqlConnection(connStr))
            {
                SqlCommand cmd = Lib.SqlCommand("SELECT TOP 1 id, name, comment FROM dbo.userinfo2 WHERE name = @name", conn);
                cmd.Parameters.AddWithValue("@name", ticket.Name.Trim().ToUpper());

                conn.Open();
                using (SqlDataReader reader = cmd.ExecuteReader())
                {
                    if (!reader.Read()) return false;
                    StoreCurrentUser(reader);
                    return true;
                }
            }
        }
        catch
        {
            return false;
        }
    }
}
