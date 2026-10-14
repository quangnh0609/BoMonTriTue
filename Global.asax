<%@ Application Language="C#" %>
<%@ Import Namespace="System.Web.SessionState" %>

<script runat="server">
    void Application_AcquireRequestState(object sender, EventArgs e)
    {
        if (Context == null) return;

        object handler = Context.CurrentHandler;
        if (handler is IRequiresSessionState || handler is IReadOnlySessionState)
        {
            AuthSession.TryRestoreFromFormsAuth();
        }
    }
</script>
