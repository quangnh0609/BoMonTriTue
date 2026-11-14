using System;
using System.Web;

// Short-lived receipts let a resumed browser read a completed request without replaying imports.
public static class WebMatchOperations
{
    public class Operation
    {
        public string Signature;
        public volatile string ResultJson;
    }
    static readonly object Gate = new object();
    static string Key(string scope, string id) { return "WebMatchOperation:" + WebMatchImport.CompactId("K", scope) + ":" + id; }
    public static Operation Find(string scope, string id) { return HttpRuntime.Cache[Key(scope, id)] as Operation; }
    public static Operation Begin(string scope, string id, string signature, out bool started)
    {
        if (!System.Text.RegularExpressions.Regex.IsMatch(id, "^[a-f0-9]{32}$")) throw new InvalidOperationException("Mã lượt xử lý không hợp lệ.");
        lock (Gate)
        {
            var operation = Find(scope, id);
            started = operation == null;
            if (operation == null)
            {
                operation = new Operation { Signature = signature };
                HttpRuntime.Cache.Insert(Key(scope, id), operation, null, DateTime.Now.AddHours(2), System.Web.Caching.Cache.NoSlidingExpiration);
            }
            if (operation.Signature != signature) throw new InvalidOperationException("Mã lượt xử lý đã được dùng cho dữ liệu khác.");
            return operation;
        }
    }
    public static void Complete(Operation operation, string json)
    {
        lock (Gate)
        {
            // A disconnect after successful SQL commit must never overwrite success with an error.
            if (operation.ResultJson == null) operation.ResultJson = json;
        }
    }
}
