using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Script.Serialization;

public static class WebMatchEditsTests
{
    static int count;
    static void Check(bool value, string message) { count++; if (!value) throw new Exception(message); }
    static object Json(string value) { return new JavaScriptSerializer().DeserializeObject(value.Replace('\'', '"')); }
    public static void Main()
    {
        var first = new WebMatchImport.Fixture { Id = "one", Home = "Kosovo", Away = "Israel" };
        first.Markets.Add(new WebMatchImport.Market { Code = "33", Line = -.5m, Home = .9m, Away = .9m, Bookmaker = "API" });
        var second = new WebMatchImport.Fixture { Id = "two", Home = "Home2", Away = "Away2" };
        var fixtures = new Dictionary<string, WebMatchImport.Fixture> { { "one", first }, { "two", second } };
        var ids = new List<string> { "one", "two" };
        string payload = @"{'one':[
          {'Code':'33','Line':'-0,75','Home':'0,85','Away':'0.95'},
          {'Code':'23','Line':'2.5','Home':'1.1','Away':'0.8'},
          {'Code':'43','Home':'2.1','Draw':'3.2','Away':'4.3'},
          {'Code':'71','Line':'0','Home':'1','Away':'1'}],
        'two':[{'Code':'33','Line':'1.25','Home':'0.8','Away':'1.0'},{'Code':'71','Line':'0','Home':'1','Away':'1'}]}";
        var parsed = WebMatchEdits.ParseBatch(Json(payload), fixtures, ids);
        Check(parsed["one"].Single(m => m.Code == "33").Line == -.75m, "Accept manual Kosovo -0.75 with decimal comma");
        Check(parsed["one"].Single(m => m.Code == "33").Home == .85m && parsed["one"].Single(m => m.Code == "33").Away == .95m, "Keep edited side prices");
        Check(parsed["one"].Single(m => m.Code == "23").Home == 1.1m && parsed["one"].Single(m => m.Code == "23").Away == .8m, "Keep edited over/under prices");
        Check(parsed["two"].Single(m => m.Code == "33").Line == 1.25m, "Each selected fixture has independent edits");
        Check(parsed["one"].Single(m => m.Code == "43").Draw == 3.2m, "Accept all three 1X2 prices");
        Check(first.Markets.Single().Line == -.5m && second.Markets.Count == 0, "Parse all rows before mutating snapshots or writing SQL");
        foreach (string invalid in new[] {
            payload.Replace("'Line':'-0,75'", "'Line':'-0.3'"),
            payload.Replace("'Line':'2.5'", "'Line':'-2.5'"),
            payload.Replace("'Code':'33'", "'Code':'32'"),
            payload.Replace("'Home':'0,85'", "'Home':'0'"),
            payload.Replace("'Draw':'3.2'", "'Draw':''"),
            payload.Replace("'Draw':'3.2'", "'Draw':'0.9'"),
            payload.Replace("'Code':'71'", "'Code':'33'"),
            payload.Replace("'Home':'0,85'", "'Home':'1.00001'"),
            payload.Replace("'Home':'0,85'", "'Home':'1000000000000000'"),
            payload.Replace("'Home':'0,85'", "'Home':'NaN'"),
            payload.Replace("'Line':'-0,75'", "'Line':'-1,000.75'"),
            payload.Replace("'Away':'1.0'", "'Away':'broken'"),
            payload.Replace("'two':", "'foreign':")
        })
        {
            bool rejected = false;
            try { WebMatchEdits.ParseBatch(Json(invalid), fixtures, ids); }
            catch (InvalidOperationException) { rejected = true; }
            Check(rejected, "Reject malformed, foreign, H2 or incomplete edits");
            Check(first.Markets.Single().Line == -.5m && second.Markets.Count == 0, "Invalid batch leaves all fixtures unchanged");
        }
        Console.WriteLine(count + " multi-fixture edit assertions passed.");
    }
}
