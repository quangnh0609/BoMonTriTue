using System;
using System.Linq;
using System.Web.Script.Serialization;
public static class WebMatchImportTests
{
    static void Check(bool value, string message) { if (!value) throw new Exception(message); }
    public static void Main()
    {
        string json = @"[
          {'key':'a','title':'A','markets':[
            {'key':'alternate_totals','outcomes':[
              {'name':'Over','point':2.5,'price':1.7},{'name':'Under','point':2.5,'price':2.1},
              {'name':'Over','point':2.75,'price':1.91},{'name':'Under','point':2.75,'price':1.93},
              {'name':'Over','point':3.5,'price':1.90}]},
            {'key':'alternate_spreads','outcomes':[
              {'name':'Home FC','point':-0.5,'price':1.91},{'name':'Away FC','point':0.5,'price':1.92},
              {'name':'Home FC','point':-1,'price':1.9},{'name':'Away FC','point':-1,'price':1.9}]},
            {'key':'alternate_totals_corners','outcomes':[{'name':'Over','point':9.5,'price':1.9},{'name':'Under','point':9.5,'price':1.9}]},
            {'key':'alternate_spreads_corners','outcomes':[{'name':'Home FC','point':-1.5,'price':1.9},{'name':'Away FC','point':1.5,'price':1.9}]},
            {'key':'alternate_spreads_cards','outcomes':[{'name':'Home FC','point':0,'price':1.9},{'name':'Away FC','point':0,'price':1.9}]},
            {'key':'alternate_totals_cards','outcomes':[{'name':'Over','point':3.5,'price':1.9},{'name':'Under','point':3.5,'price':1.9}]},
            {'key':'h2h','outcomes':[{'name':'Away FC','price':3.15},{'name':'Draw','price':3.44},{'name':'Home FC','price':2.25}]},
            {'key':'team_totals','outcomes':[{'name':'Over','point':1.5,'price':1.9},{'name':'Under','point':1.5,'price':1.9}]},
            {'key':'h2h_h1','outcomes':[{'name':'Home FC','price':2.1},{'name':'Away FC','price':3.1}]}
          ]},
          {'key':'b','title':'B','markets':[
            {'key':'alternate_totals','outcomes':[{'name':'Under','point':3.5,'price':1.90}]}
          ]}
        ]".Replace('\'', '"');
        var markets = WebMatchImport.SelectMarkets(WebMatchImport.Rows(new JavaScriptSerializer().DeserializeObject(json)), "Home FC", "Away FC");
        Check(markets.Count == 7, "Recognized complete markets only; exclude team totals and two-way 1X2");
        Check(markets.Single(m => m.Code == "23").Line == 2.75m, "Closest pair without mixing bookmakers or lines");
        Check(markets.Single(m => m.Code == "33").Line == -.5m, "Opposite handicap signs");
        Check(markets.Single(m => m.Code == "63").Line == 0, "Zero handicap");
        Check(markets.Any(m => m.Code == "03") && markets.Any(m => m.Code == "13") && markets.Any(m => m.Code == "53"), "Corners and cards mapped");
        Check(markets.Where(m => m.Line.HasValue).All(m => m.Home == .9m && m.Away == .9m), "Fixed payout");
        var euro = markets.Single(m => m.Code == "43");
        Check(euro.Home == 2.3m && euro.Draw == 3.4m && euro.Away == 3.2m, "Round correct named teams, midpoint away from zero");
        string id = "bda33adca828c09dc3cac3a856aef176";
        Check(WebMatchImport.CompactId("OM", id).Length == 16, "Fits SQL varchar(16)");
        Check(WebMatchImport.CompactId("OM", id) == WebMatchImport.CompactId("OM", id), "Stable import id");
        Check(WebMatchImport.CompactId("OT", "Home FC") != WebMatchImport.CompactId("OL", "Home FC"), "Separate entity namespaces");
        var request = new JavaScriptSerializer().Deserialize<System.Collections.Generic.Dictionary<string, object>>("{\"action\":\"create\",\"ids\":[\"first\",\"second\"]}");
        Check(request["ids"] is System.Collections.ArrayList, "Reproduce actual ASP.NET request array type");
        Check(WebMatchImport.SelectedIds(request).SequenceEqual(new[] { "first", "second" }), "Create two matches from deserialized request");
        request["ids"] = new object[] { "first", "first", "second" };
        Check(WebMatchImport.SelectedIds(request).Count == 2, "Handle object arrays and deduplicate selections");
        foreach (object invalid in new object[] { "first", new object[0], new object[] { null }, new object[] { 12 }, new string[101] })
        {
            request["ids"] = invalid; bool rejected = false;
            try { WebMatchImport.SelectedIds(request); } catch (InvalidOperationException) { rejected = true; }
            Check(rejected, "Reject malformed selections");
        }
        request.Remove("ids"); bool missingRejected = false;
        try { WebMatchImport.SelectedIds(request); } catch (InvalidOperationException) { missingRejected = true; }
        Check(missingRejected, "Reject missing selections");
        decimal[] fullLines = { 10m, 10.5m, 9.5m, 8.5m, 2.5m };
        decimal[] halfLines = { 4.75m, 5m, 4.5m, 4m, 1m };
        for (int i = 0; i < fullLines.Length; i++)
        {
            var sample = new System.Collections.Generic.List<WebMatchImport.Market> { new WebMatchImport.Market { Code = "03", Name = "Tài xỉu góc cả trận", Line = fullLines[i] } };
            WebMatchImport.ApplyFirstHalfRules(sample);
            var half = sample.Single(m => m.Code == "01");
            Check(half.Line == halfLines[i] && half.Home == .9m && half.Away == .9m && half.Estimated, "Configured FT to H1 example");
        }
        var existing = new System.Collections.Generic.List<WebMatchImport.Market> {
            new WebMatchImport.Market { Code = "23", Line = 2.5m },
            new WebMatchImport.Market { Code = "21", Line = 1.25m },
            new WebMatchImport.Market { Code = "33", Line = -.5m },
            new WebMatchImport.Market { Code = "63", Line = 0m },
            new WebMatchImport.Market { Code = "53", Line = 3.5m },
            new WebMatchImport.Market { Code = "43", Home = 2.3m, Away = 3.2m, Draw = 3.4m }
        };
        WebMatchImport.ApplyFirstHalfRules(existing);
        Check(existing.Single(m => m.Code == "21").Line == 1.25m && !existing.Single(m => m.Code == "21").Estimated, "Keep provider H1");
        Check(existing.Single(m => m.Code == "31").Line == 0m && existing.Single(m => m.Code == "61").Line == 0, "Preserve signed and zero handicap");
        Check(existing.Single(m => m.Code == "51").Line == 1.5m && !existing.Any(m => m.Code == "41"), "Default ratio and no synthetic 1X2");
        decimal[] expected = { .75m,.75m,1m,1.25m,1.25m,1.25m,1.5m,1.75m,1.75m,1.75m,2m,2.25m,2.25m,2.25m,2.5m,2.75m,2.75m,2.75m,3m,3.25m,3.25m,3.25m,3.5m,3.75m,3.75m,3.75m,4m,4.25m,4.25m,4.25m,4.5m,4.75m,4.75m,4.75m,5m,5.25m,5.25m,5.25m,5.5m };
        for (int i = 0; i < expected.Length; i++)
        {
            decimal ft = 2m + i * .25m;
            Check(WebMatchImport.FirstHalfLine(ft) == expected[i], "FT to H1 at " + ft);
            Check(WebMatchImport.FirstHalfLine(-ft) == -expected[i], "Negative handicap at " + ft);
        }
        Check(WebMatchImport.FirstHalfLine(0) == 0 && WebMatchImport.FirstHalfLine(.25m) == 0, "Clamp small lines to zero");
        string priorityJson = @"[{'key':'a','title':'A','markets':[{'key':'alternate_spreads','outcomes':[{'name':'Home FC','point':-1.5,'price':1.9},{'name':'Away FC','point':1.5,'price':1.9}]},{'key':'spreads','outcomes':[{'name':'Home FC','point':-0.5,'price':1.8},{'name':'Away FC','point':0.5,'price':2.0}]}]}]".Replace('\'', '"');
        Check(WebMatchImport.SelectMarkets(WebMatchImport.Rows(new JavaScriptSerializer().DeserializeObject(priorityJson)), "Home FC", "Away FC").Single().Line == -.5m, "Prefer main handicap over closer-priced alternate");
        Check(WebMatchImport.LikeLiteral("A_%[~B") == "A~_~%~[~~B", "Escape literal SQL LIKE wildcard characters");
        Console.WriteLine("108 assertions passed.");
    }
}
