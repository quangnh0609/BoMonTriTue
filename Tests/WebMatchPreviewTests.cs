using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

// Run with Run-WebMatchPreviewTests.ps1. Session, catalog lookup and DB boundary are stubbed;
// Preview/Create/SelectedFixtures/LoadSelectedMarkets are compiled from the actual ASPX source.
public static class WebMatchPreviewTests
{
    static int count;
    static void Check(bool condition, string message) { count++; if (!condition) throw new Exception(message); }
    static object Field(object value, string name) { return value.GetType().GetProperty(name).GetValue(value, null); }
    static void Call(WebMatchesPreviewHarness page, string method, Dictionary<string, object> input)
    {
        try { page.GetType().GetMethod(method, BindingFlags.NonPublic | BindingFlags.Instance).Invoke(page, new object[] { input }); }
        catch (TargetInvocationException ex) { throw ex.InnerException; }
    }
    static void Reject(WebMatchesPreviewHarness page, Dictionary<string, object> input, string message)
    {
        bool rejected = false;
        try { Call(page, "Create", input); }
        catch (InvalidOperationException ex) { rejected = ex.Message.Contains(message); }
        Check(rejected, "Expected guard: " + message);
    }
    public static void Main()
    {
        var page = new WebMatchesPreviewHarness();
        page.GetType().GetField("source", BindingFlags.NonPublic | BindingFlags.Instance).SetValue(page, "api-football");
        var fixture = new WebMatchImport.Fixture { Source = "api-football", Id = "123", LeagueId = "39", Home = "H", Away = "A", Kickoff = DateTimeOffset.UtcNow.AddDays(1) };
        fixture.Markets.Add(new WebMatchImport.Market { Code = "33", Line = .5m, Home = .9m, Away = .9m, Bookmaker = "Test" });
        fixture.Markets.Add(new WebMatchImport.Market { Code = "32", Line = 99m, Home = .9m, Away = .9m });
        var results = new Dictionary<string, WebMatchImport.Fixture> { { "123", fixture } };
        page.Session["WebMatchResults"] = results;
        page.Session["WebMatchExpires"] = DateTime.UtcNow.AddMinutes(15);
        page.Session["WebMatchSource"] = "api-football";
        page.Session["WebMatchSnapshot"] = "snapshot";
        var input = new Dictionary<string, object> { { "ids", new string[] { "123" } }, { "snapshot", "snapshot" } };
        Reject(page, input, "xem trước");
        Call(page, "Preview", input);
        Check(page.ReplyData != null, "Preview returns data without opening SQL or reloading preloaded markets");
        string token = (string)Field(page.ReplyData, "previewToken");
        Check(token.Length > 0, "Server-generated preview token");
        var matches = ((IEnumerable)Field(page.ReplyData, "matches")).Cast<object>().ToList();
        var markets = (List<WebMatchImport.Market>)Field(matches.Single(), "Markets");
        Check(markets.Any(m => m.Code == "71" && m.Line == 0 && m.Home == 1 && m.Away == 1), "Preview includes default kickoff that SQL inserts");
        Check(Object.ReferenceEquals(markets.Single(m => m.Code == "33"), fixture.Markets.Single(m => m.Code == "33")), "Preview shows the exact session market later inserted");
        Check(!fixture.Markets.Any(m => m.Code == "71"), "Preview does not duplicate kickoff in stored markets");
        Check(!markets.Any(m => m.Code.EndsWith("2")), "No H2 in preview or later creation");
        input["edits"] = new System.Web.Script.Serialization.JavaScriptSerializer().DeserializeObject(@"{'123':[
          {'Code':'33','Line':'-0.75','Home':'0.85','Away':'0.95'},
          {'Code':'31','Line':'0','Home':'0.9','Away':'0.9'},
          {'Code':'71','Line':'0','Home':'1','Away':'1'}]}".Replace('\'', '"'));
        input["previewToken"] = "wrong";
        Reject(page, input, "xem trước");
        input["previewToken"] = token;
        Reject(page, input, "DATABASE_REACHED");
        Check(fixture.Markets.Single(m => m.Code == "33").Line == -.75m && fixture.Markets.Single(m => m.Code == "33").Home == .85m, "Create uses manually edited line and rates");
        results["456"] = fixture;
        input["ids"] = new string[] { "123", "456" };
        Reject(page, input, "xem trước");
        input["ids"] = new string[] { "123" };
        page.Session["WebMatchExpires"] = DateTime.UtcNow.AddSeconds(-1);
        Reject(page, input, "hết hạn");
        page.Session["WebMatchExpires"] = DateTime.UtcNow.AddMinutes(15);
        page.Session["WebMatchSource"] = "the-odds-api";
        Reject(page, input, "Nguồn dữ liệu");
        fixture.Source = "the-odds-api";
        page.GetType().GetField("source", BindingFlags.NonPublic | BindingFlags.Instance).SetValue(page, "the-odds-api");
        input.Remove("previewToken");
        Reject(page, input, "DATABASE_REACHED");
        Console.WriteLine(count + " preview/backend guard assertions passed.");
    }
}
