using System;
using System.Threading;
using System.Threading.Tasks;

public static class WebMatchStateTests
{
    static int count;
    static void Check(bool value, string message) { count++; if (!value) throw new Exception(message); }
    public static void Main()
    {
        string scope = Guid.NewGuid().ToString("N");
        var state = WebMatchState.Get(scope, "initial-token");
        state.Values["WebMatchSnapshot"] = "one";
        Check(Object.ReferenceEquals(state, WebMatchState.Get(scope, "other-token")), "Same login scope retains import state");
        Check(state.Token == "initial-token", "Existing import token stays stable across page navigation");
        var other = WebMatchState.Get(scope + "other", "other-token");
        Check(other.Values["WebMatchSnapshot"] == null, "Separate login scope cannot see snapshots");
        using (var locked = new ManualResetEvent(false))
        using (var release = new ManualResetEvent(false))
        {
            var loading = Task.Factory.StartNew(() => {
                lock (state.SyncRoot) { locked.Set(); release.WaitOne(); }
            });
            Check(locked.WaitOne(1000), "Simulate long provider load holding importer-only lock");
            try
            {
                var unrelated = Task.Factory.StartNew(() => WebMatchState.Get(scope, "ignored"));
                Check(unrelated.Wait(1000), "Looking up state does not wait for ongoing provider work");
                var receipt = Task.Factory.StartNew(() => WebMatchOperations.Find(scope, Guid.NewGuid().ToString("N")));
                Check(receipt.Wait(1000), "Status polling is independent of importer mutation lock");
                var otherUser = Task.Factory.StartNew(() => { lock (other.SyncRoot) { return true; } });
                Check(otherUser.Wait(1000), "Other scopes are never held by this import");
            }
            finally { release.Set(); loading.Wait(); }
        }
        Console.WriteLine(count + " independent import state assertions passed.");
    }
}
