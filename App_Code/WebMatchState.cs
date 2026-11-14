using System;
using System.Collections;
using System.Web;

// Import-only state: a long provider request must not own the ASP.NET login session lock.
public class WebMatchState
{
    public readonly object SyncRoot = new object();
    public readonly Hashtable Values = new Hashtable();
    public readonly string Token;
    static readonly object Gate = new object();
    public WebMatchState(string token) { Token = String.IsNullOrEmpty(token) ? Guid.NewGuid().ToString("N") : token; }
    public static WebMatchState Get(string scope, string initialToken)
    {
        string key = "WebMatchState:" + WebMatchImport.CompactId("K", scope);
        lock (Gate)
        {
            var state = HttpRuntime.Cache[key] as WebMatchState;
            if (state == null)
            {
                state = new WebMatchState(initialToken);
                HttpRuntime.Cache.Insert(key, state, null, DateTime.Now.AddHours(2), System.Web.Caching.Cache.NoSlidingExpiration);
            }
            return state;
        }
    }
}
