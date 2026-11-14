using System;
public static class WebMatchOperationsTests
{
    static int count;
    static void Check(bool value, string message) { count++; if (!value) throw new Exception(message); }
    public static void Main()
    {
        string scope = Guid.NewGuid().ToString("N"), id = Guid.NewGuid().ToString("N");
        bool started;
        var first = WebMatchOperations.Begin(scope, id, "payload", out started);
        Check(started && first.ResultJson == null, "First request starts exactly once");
        var duplicate = WebMatchOperations.Begin(scope, id, "payload", out started);
        Check(!started && Object.ReferenceEquals(first, duplicate), "Duplicate while pending does not start another import");
        WebMatchOperations.Complete(first, "{\"ok\":true,\"count\":2}");
        Check(WebMatchOperations.Find(scope, id).ResultJson.Contains("true"), "Read success after disconnect");
        WebMatchOperations.Complete(first, "{\"ok\":false}");
        Check(WebMatchOperations.Find(scope, id).ResultJson.Contains("true"), "Disconnect after commit cannot overwrite success");
        WebMatchOperations.Begin(scope, id, "payload", out started);
        Check(!started, "Completed import cannot run twice");
        bool rejected = false;
        try { WebMatchOperations.Begin(scope, id, "different payload", out started); } catch (InvalidOperationException) { rejected = true; }
        Check(rejected, "Reject reused request ID with changed edits");
        Check(WebMatchOperations.Find("other session", id) == null, "Results isolated by user/session scope");
        WebMatchOperations.Begin("other session", id, "payload", out started);
        Check(started, "Separate session scope");
        rejected = false;
        try { WebMatchOperations.Begin(scope, "invalid-id", "payload", out started); } catch (InvalidOperationException) { rejected = true; }
        Check(rejected, "Reject malformed operation ID");
        Console.WriteLine(count + " resumable operation assertions passed.");
    }
}
