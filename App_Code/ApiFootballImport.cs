using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Web.Script.Serialization;

// Direct API-Sports subscription (x-apisports-key), not the RapidAPI gateway.
public static class ApiFootballImport
{
    private static readonly object CacheLock = new object();
    private static string Key { get { return ConfigurationManager.AppSettings["ApiFootballKey"] ?? ""; } }
    private static string Scope { get { return WebMatchImport.CompactId("K", Key); } }
    public static WebMatchImport.Quota CurrentQuota { get { return System.Web.HttpRuntime.Cache["ApiFootballQuota:" + Scope] as WebMatchImport.Quota; } }
    private static void CaptureQuota(WebHeaderCollection headers)
    {
        long remaining, total;
        if (Int64.TryParse(headers["x-ratelimit-requests-remaining"], out remaining) &&
            Int64.TryParse(headers["x-ratelimit-requests-limit"], out total) && remaining >= 0 && total >= remaining)
            System.Web.HttpRuntime.Cache.Insert("ApiFootballQuota:" + Scope, new WebMatchImport.Quota { Remaining = remaining, Total = total }, null, DateTime.Now.AddHours(1), System.Web.Caching.Cache.NoSlidingExpiration);
    }
    public static Dictionary<string, object> ValidateResponse(object response)
    {
        var data = WebMatchImport.Obj(response);
        object errors;
        if (data.TryGetValue("errors", out errors) && errors is ICollection && ((ICollection)errors).Count > 0)
            throw new InvalidOperationException("API-Football từ chối yêu cầu. Kiểm tra API key, hạn mức và quyền truy cập mùa giải/gói dịch vụ trong dashboard API-Football.");
        if (!data.ContainsKey("response") || !(data["response"] is IList))
            throw new InvalidOperationException("API-Football trả dữ liệu không hợp lệ. Vui lòng thử lại.");
        return data;
    }
    public static Dictionary<string, object> Get(string path, int seconds)
    {
        if (String.IsNullOrWhiteSpace(Key)) throw new InvalidOperationException("Chưa cấu hình ApiFootballKey trên máy chủ (API key trực tiếp từ dashboard API-Football). ");
        string cacheKey = "ApiFootball:" + Scope + ":" + path;
        lock (CacheLock)
        {
            var cached = System.Web.HttpRuntime.Cache[cacheKey] as Dictionary<string, object>;
            if (cached != null) return cached;
            ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072;
            var request = (HttpWebRequest)WebRequest.Create("https://v3.football.api-sports.io/" + path);
            request.Headers["x-apisports-key"] = Key;
            request.Timeout = 20000;
            // Space uncached requests for the free plan (10/minute); adapt to the provider header.
            string pacingKey = "ApiFootballPacing:" + Scope;
            var next = System.Web.HttpRuntime.Cache[pacingKey];
            if (next is DateTime)
            {
                double wait = ((DateTime)next - DateTime.UtcNow).TotalMilliseconds;
                if (wait > 0) System.Threading.Thread.Sleep((int)Math.Min(wait + 1, 61000));
            }
            int requestsPerMinute = 10;
            try
            {
                using (var response = request.GetResponse())
                using (var reader = new System.IO.StreamReader(response.GetResponseStream()))
                {
                    CaptureQuota(response.Headers);
                    int providerLimit;
                    if (Int32.TryParse(response.Headers["X-RateLimit-Limit"], out providerLimit) && providerLimit > 0)
                        requestsPerMinute = Math.Min(providerLimit, 900);
                    cached = ValidateResponse(new JavaScriptSerializer { MaxJsonLength = 10000000 }.DeserializeObject(reader.ReadToEnd()));
                }
            }
            catch (WebException ex)
            {
                using (var response = ex.Response as HttpWebResponse)
                {
                    if (response != null) CaptureQuota(response.Headers);
                    if (response != null && (int)response.StatusCode == 429)
                        throw new InvalidOperationException("API-Football đã chạm giới hạn lượt gọi. Vui lòng chờ hoặc kiểm tra hạn mức ngày.");
                }
                throw new InvalidOperationException("Không truy cập được API-Football. Kiểm tra kết nối, API key trực tiếp và gói dịch vụ.");
            }
            finally
            {
                System.Web.HttpRuntime.Cache.Insert(pacingKey, DateTime.UtcNow.AddMilliseconds(60000.0 / requestsPerMinute + 100), null, DateTime.Now.AddMinutes(2), System.Web.Caching.Cache.NoSlidingExpiration);
            }
            System.Web.HttpRuntime.Cache.Insert(cacheKey, cached, null, DateTime.Now.AddSeconds(seconds), System.Web.Caching.Cache.NoSlidingExpiration);
            return cached;
        }
    }
    public static List<WebMatchImport.LeagueOption> GetLeagues()
    {
        return FilterLeagues(WebMatchImport.Rows(Get("leagues", 21600)["response"]));
    }
    public static List<WebMatchImport.LeagueOption> FilterLeagues(IEnumerable<Dictionary<string, object>> rows)
    {
        // Resolve real provider IDs, but expose the same competitions, labels and order as The Odds API.
        var names = new Dictionary<string, string> {
            { "soccer_uefa_champs_league", "World|UEFA Champions League" },
            { "soccer_uefa_europa_league", "World|UEFA Europa League" },
            { "soccer_uefa_europa_conference_league", "World|UEFA Europa Conference League" },
            { "soccer_epl", "England|Premier League" },
            { "soccer_spain_la_liga", "Spain|La Liga" },
            { "soccer_italy_serie_a", "Italy|Serie A" },
            { "soccer_germany_bundesliga", "Germany|Bundesliga" },
            { "soccer_efl_champ", "England|Championship" },
            { "soccer_england_efl_cup", "England|League Cup" },
            { "soccer_spain_copa_del_rey", "Spain|Copa del Rey" },
            { "soccer_uefa_nations_league", "World|UEFA Nations League" },
            { "soccer_uefa_european_championship", "World|Euro Championship" },
            { "soccer_fifa_world_cup", "World|World Cup" },
            { "soccer_africa_cup_of_nations", "World|Africa Cup of Nations" }
        };
        var catalog = rows.Select(row => new {
            league = WebMatchImport.Obj(row["league"]), country = WebMatchImport.Obj(row["country"])
        }).ToList();
        var result = new List<WebMatchImport.LeagueOption>();
        foreach (var option in WebMatchImport.GetLeagues())
        {
            string target;
            if (!names.TryGetValue(option.id, out target)) continue;
            var found = catalog.Where(row => WebMatchImport.Str(row.country, "name") + "|" + WebMatchImport.Str(row.league, "name") == target).ToList();
            if (found.Count == 1) result.Add(new WebMatchImport.LeagueOption { id = WebMatchImport.Str(found[0].league, "id"), name = option.name });
        }
        return result;
    }
    public static WebMatchImport.Fixture ParseFixture(Dictionary<string, object> row)
    {
        var fixture = WebMatchImport.Obj(row["fixture"]);
        var status = WebMatchImport.Obj(fixture["status"]);
        if (WebMatchImport.Str(status, "short") != "NS") return null;
        var league = WebMatchImport.Obj(row["league"]);
        var teams = WebMatchImport.Obj(row["teams"]);
        var home = WebMatchImport.Obj(teams["home"]); var away = WebMatchImport.Obj(teams["away"]);
        return new WebMatchImport.Fixture {
            Source = "api-football", Id = WebMatchImport.Str(fixture, "id"), LeagueId = WebMatchImport.Str(league, "id"),
            League = WebMatchImport.Str(league, "name"), Season = WebMatchImport.Str(league, "season"),
            Home = WebMatchImport.Str(home, "name"), Away = WebMatchImport.Str(away, "name"),
            HomeId = WebMatchImport.Str(home, "id"), AwayId = WebMatchImport.Str(away, "id"),
            Kickoff = DateTimeOffset.Parse(WebMatchImport.Str(fixture, "date"), CultureInfo.InvariantCulture)
        };
    }
    public static Dictionary<string, WebMatchImport.Fixture> Search(List<DateTime> dates, string league)
    {
        var result = new Dictionary<string, WebMatchImport.Fixture>();
        foreach (DateTime date in dates)
        foreach (var row in WebMatchImport.Rows(Get("fixtures?date=" + date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture) + "&timezone=Asia%2FBangkok", 120)["response"]))
        {
            var f = ParseFixture(row);
            if (f != null && f.LeagueId == league && dates.Contains(f.Kickoff.ToOffset(TimeSpan.FromHours(7)).Date) && f.Kickoff > DateTimeOffset.UtcNow) result[f.Id] = f;
        }
        return result;
    }
    public static List<WebMatchImport.Market> LoadMarkets(WebMatchImport.Fixture fixture)
    {
        var books = new List<Dictionary<string, object>>();
        int page = 1, total = 1;
        do
        {
            var data = Get("odds?fixture=" + Uri.EscapeDataString(fixture.Id) + "&page=" + page, 120);
            total = Convert.ToInt32(WebMatchImport.Obj(data["paging"])["total"], CultureInfo.InvariantCulture);
            if (total > 100) throw new InvalidOperationException("API-Football trả quá nhiều trang kèo. Vui lòng thử lại.");
            foreach (var row in WebMatchImport.Rows(data["response"]))
            {
                var rawFixture = WebMatchImport.Obj(row["fixture"]);
                if (WebMatchImport.Str(rawFixture, "id") != fixture.Id) throw new InvalidOperationException("API-Football trả sai mã trận.");
                fixture.Kickoff = DateTimeOffset.Parse(WebMatchImport.Str(rawFixture, "date"), CultureInfo.InvariantCulture);
                books.AddRange(WebMatchImport.Rows(row["bookmakers"]));
            }
            page++;
        } while (page <= total);
        return SelectMarkets(books, fixture.Home, fixture.Away);
    }
    public static List<WebMatchImport.Market> SelectMarkets(IEnumerable<Dictionary<string, object>> bookmakers, string home, string away)
    {
        var converted = new List<Dictionary<string, object>>();
        foreach (var book in bookmakers)
        {
            var markets = new List<Dictionary<string, object>>();
            foreach (var bet in WebMatchImport.Rows(book["bets"]))
            {
                string key = MarketKey(WebMatchImport.Str(bet, "name"));
                if (key == null) continue;
                var outcomes = new List<Dictionary<string, object>>();
                foreach (var value in WebMatchImport.Rows(bet["values"]))
                {
                    string text = WebMatchImport.Str(value, "value"), name = null;
                    decimal line;
                    var outcome = new Dictionary<string, object> { { "price", WebMatchImport.Str(value, "odd") } };
                    if (key.StartsWith("h2h")) name = text == "Home" ? home : text == "Away" ? away : text == "Draw" ? "Draw" : null;
                    else
                    {
                        int space = text.IndexOf(' ');
                        if (space < 0 || !Decimal.TryParse(text.Substring(space + 1), NumberStyles.Float, CultureInfo.InvariantCulture, out line) || line % .25m != 0) continue;
                        string side = text.Substring(0, space);
                        bool total = key.Contains("totals");
                        name = total ? (side == "Over" || side == "Under" ? side : null) : side == "Home" ? home : side == "Away" ? away : null;
                        outcome["point"] = line;
                    }
                    if (name == null) continue;
                    outcome["name"] = name; outcomes.Add(outcome);
                }
                markets.Add(new Dictionary<string, object> { { "key", key }, { "outcomes", outcomes } });
            }
            converted.Add(new Dictionary<string, object> { { "key", WebMatchImport.Str(book, "id") }, { "title", WebMatchImport.Str(book, "name") }, { "markets", markets } });
        }
        return WebMatchImport.SelectMarkets(converted, home, away);
    }
    private static string MarketKey(string name)
    {
        // Exact allowlist: team totals, European handicaps and booking points are not interchangeable.
        switch (name)
        {
            case "Match Winner": return "h2h";
            case "First Half Winner": return "h2h_h1";
            case "Second Half Winner": return "h2h_h2";
            case "Asian Handicap": return "spreads";
            case "Asian Handicap First Half": return "spreads_h1";
            case "Asian Handicap Second Half": return "spreads_h2";
            case "Goals Over/Under": return "totals";
            case "Goals Over/Under First Half": return "totals_h1";
            case "Goals Over/Under Second Half": return "totals_h2";
            case "Corners Over Under": return "alternate_totals_corners";
            case "Corners Over Under First Half": return "alternate_totals_corners_h1";
            case "Corners Over Under Second Half": return "alternate_totals_corners_h2";
            case "Corners Asian Handicap": return "alternate_spreads_corners";
            case "Cards Over/Under": return "alternate_totals_cards";
            default: return null;
        }
    }
}
