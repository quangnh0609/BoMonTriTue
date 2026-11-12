using System;
using System.Linq;
using System.Web.Script.Serialization;

public static class ApiFootballImportTests
{
    static int count;
    static void Check(bool value, string message) { count++; if (!value) throw new Exception(message); }
    static object Json(string text) { return new JavaScriptSerializer().DeserializeObject(text.Replace('\'', '"')); }
    public static void Main()
    {
        var leagueRows = WebMatchImport.Rows(Json(@"[
            {'league':{'id':999,'name':'Premier League'},'country':{'name':'Egypt'}},
            {'league':{'id':39,'name':'Premier League'},'country':{'name':'England'}},
            {'league':{'id':135,'name':'Serie A'},'country':{'name':'Italy'}},
            {'league':{'id':2,'name':'UEFA Champions League'},'country':{'name':'World'}},
            {'league':{'id':45,'name':'FA Cup'},'country':{'name':'England'}},
            {'league':{'id':40,'name':'Championship'},'country':{'name':'England'}}
        ]")).ToList();
        var leagues = ApiFootballImport.FilterLeagues(leagueRows);
        Check(String.Join(",", leagues.Select(l => l.id)) == "2,39,135,40", "Only requested competitions, ordered like The Odds API");
        Check(leagues.Single(l => l.id == "39").name == WebMatchImport.GetLeagues().Single(l => l.id == "soccer_epl").name, "Same display labels");
        leagueRows.Add(leagueRows.Single(r => WebMatchImport.Str(WebMatchImport.Obj(r["league"]), "id") == "39"));
        Check(!ApiFootballImport.FilterLeagues(leagueRows).Any(l => l.id == "39"), "Do not guess between ambiguous provider catalog entries");
        string fixtureJson = @"{'fixture':{'id':123,'date':'2026-11-12T22:00:00+07:00','status':{'short':'NS'}},'league':{'id':36,'name':'Africa Cup of Nations - Qualification','season':2026},'teams':{'home':{'id':1,'name':'Home FC'},'away':{'id':2,'name':'Away FC'}}}";
        var fixture = ApiFootballImport.ParseFixture(WebMatchImport.Obj(Json(fixtureJson)));
        Check(fixture.Source == "api-football" && fixture.Id == "123" && fixture.LeagueId == "36", "Provider and IDs");
        Check(fixture.Home == "Home FC" && fixture.AwayId == "2" && fixture.Season == "2026", "Teams and season");
        Check(fixture.Time == "22:00 12/11/2026", "UTC+7 kickoff");
        foreach (string status in new[] { "TBD", "PST", "CANC", "1H", "FT" })
            Check(ApiFootballImport.ParseFixture(WebMatchImport.Obj(Json(fixtureJson.Replace("'NS'", "'" + status + "'")))) == null, "Reject unconfirmed/started fixture " + status);
        string oddsJson = @"[
          {'id':1,'name':'Book A','bets':[
            {'name':'Match Winner','values':[{'value':'Home','odd':'2.25'},{'value':'Draw','odd':'3.45'},{'value':'Away','odd':'3.15'}]},
            {'name':'Asian Handicap','values':[{'value':'Home -0.5','odd':'1.90'},{'value':'Away +0.5','odd':'1.92'},{'value':'Home -1','odd':'1.8'},{'value':'Away +1','odd':'2.1'}]},
            {'name':'Goals Over/Under','values':[{'value':'Over 2.5','odd':'1.9'},{'value':'Under 2.5','odd':'1.92'},{'value':'Over 3','odd':'1.6'},{'value':'Under 3','odd':'2.4'}]},
            {'name':'Goals Over/Under First Half','values':[{'value':'Over 1','odd':'1.8'},{'value':'Under 1','odd':'2.1'}]},
            {'name':'Corners Over Under','values':[{'value':'Over 9.5','odd':'1.9'},{'value':'Under 9.5','odd':'1.9'}]},
            {'name':'Cards Over/Under','values':[{'value':'Over 4.5','odd':'1.9'},{'value':'Under 4.5','odd':'1.9'}]},
            {'name':'Handicap Result','values':[{'value':'Home -1','odd':'1.9'},{'value':'Away +1','odd':'1.9'},{'value':'Draw -1','odd':'1.9'}]},
            {'name':'Total - Home','values':[{'value':'Over 2','odd':'1.9'},{'value':'Under 2','odd':'1.9'}]}
          ]}
        ]";
        var markets = ApiFootballImport.SelectMarkets(WebMatchImport.Rows(Json(oddsJson)), "Home FC", "Away FC");
        Check(markets.Count == 6, "Only supported markets");
        Check(markets.Single(m => m.Code == "43").Home == 2.3m && markets.Single(m => m.Code == "43").Draw == 3.5m, "1X2 rounding");
        Check(markets.Single(m => m.Code == "33").Line == -.5m, "Pair opposite handicap signs");
        Check(markets.Single(m => m.Code == "23").Line == 2.5m, "Closest price total line");
        Check(markets.Single(m => m.Code == "21").Line == 1m, "Explicit first half");
        WebMatchImport.ApplyFirstHalfRules(markets);
        Check(markets.Single(m => m.Code == "21").Line == 1m && !markets.Single(m => m.Code == "21").Estimated, "Preserve provider first half");
        Check(markets.Any(m => m.Code == "31" && m.Estimated) && markets.Any(m => m.Code == "01" && m.Estimated), "Existing H1 rules reused");
        Check(markets.Where(m => m.Line.HasValue).All(m => m.Home == .9m && m.Away == .9m), "Existing payout rules reused");
        string splitBooks = @"[{'id':1,'name':'A','bets':[{'name':'Goals Over/Under','values':[{'value':'Over 2.5','odd':'1.9'}]}]},{'id':2,'name':'B','bets':[{'name':'Goals Over/Under','values':[{'value':'Under 2.5','odd':'1.9'}]}]}]";
        Check(ApiFootballImport.SelectMarkets(WebMatchImport.Rows(Json(splitBooks)), "H", "A").Count == 0, "Never combine bookmakers");
        string wrongLines = @"[{'id':1,'name':'A','bets':[{'name':'Asian Handicap','values':[{'value':'Home -0.5','odd':'1.9'},{'value':'Away -0.5','odd':'1.9'}]},{'name':'Goals Over/Under','values':[{'value':'Over 2.5','odd':'1.9'},{'value':'Under 3','odd':'1.9'}]}]}]";
        Check(ApiFootballImport.SelectMarkets(WebMatchImport.Rows(Json(wrongLines)), "H", "A").Count == 0, "Reject mismatched lines");
        Check(ApiFootballImport.ValidateResponse(Json("{'errors':[],'response':[]}")) != null, "Empty success");
        foreach (string errorJson in new[] { "{'errors':{'plan':'restricted'},'response':[]}", "{'errors':['quota'],'response':[]}", "{'errors':[]}" })
        {
            bool rejected = false;
            try { ApiFootballImport.ValidateResponse(Json(errorJson)); } catch (InvalidOperationException) { rejected = true; }
            Check(rejected, "Reject API errors instead of reporting empty fixtures");
        }
        Console.WriteLine(count + " API-Football assertions passed.");
    }
}
