using System;
using System.Collections.Generic;
using System.Collections;
using System.Configuration;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Web.Script.Serialization;

// The Odds API v4 decimal odds. Never combine outcomes from different bookmakers.
public static class WebMatchImport
{
    public static string LikeLiteral(string name)
    {
        return name.Replace("~", "~~").Replace("%", "~%").Replace("_", "~_").Replace("[", "~[");
    }
    public class Quota
    {
        public long Remaining, Total;
    }
    private static string QuotaCacheKey { get { return "OddsQuota:" + CompactId("K", ConfigurationManager.AppSettings["TheOddsApiKey"] ?? ""); } }
    public static Quota CurrentQuota { get { return System.Web.HttpRuntime.Cache[QuotaCacheKey] as Quota; } }
    public static Quota ParseQuota(string remainingText, string usedText)
    {
        long remaining, used;
        if (!Int64.TryParse(remainingText, NumberStyles.Integer, CultureInfo.InvariantCulture, out remaining) ||
            !Int64.TryParse(usedText, NumberStyles.Integer, CultureInfo.InvariantCulture, out used) || remaining < 0 || used < 0 || remaining > Int64.MaxValue - used) return null;
        return new Quota { Remaining = remaining, Total = remaining + used };
    }
    private static void CaptureQuota(WebHeaderCollection headers)
    {
        var quota = ParseQuota(headers["x-requests-remaining"], headers["x-requests-used"]);
        if (quota != null) System.Web.HttpRuntime.Cache.Insert(QuotaCacheKey, quota, null, DateTime.Now.AddHours(1), System.Web.Caching.Cache.NoSlidingExpiration);
    }
    public class LeagueOption
    {
        public string id, name;
    }
    // Keep display order aligned with the requested competitions; use exact provider keys.
    public static List<LeagueOption> GetLeagues()
    {
        return new List<LeagueOption> {
            new LeagueOption { id = "soccer_uefa_champs_league", name = "Cúp C1 châu Âu (Champions League)" },
            new LeagueOption { id = "soccer_uefa_europa_league", name = "Cúp C2 châu Âu (Europa League)" },
            new LeagueOption { id = "soccer_uefa_europa_conference_league", name = "Cúp C3 châu Âu (Conference League)" },
            new LeagueOption { id = "soccer_epl", name = "Ngoại hạng Anh" },
            new LeagueOption { id = "soccer_spain_la_liga", name = "La Liga (Tây Ban Nha)" },
            new LeagueOption { id = "soccer_italy_serie_a", name = "Serie A (Ý)" },
            new LeagueOption { id = "soccer_germany_bundesliga", name = "Bundesliga (Đức)" },
            new LeagueOption { id = "soccer_efl_champ", name = "Championship (Anh)" },
            new LeagueOption { id = "soccer_england_efl_cup", name = "Cúp EFL (Anh)" },
            new LeagueOption { id = "soccer_spain_copa_del_rey", name = "Cúp Nhà vua Tây Ban Nha (Copa del Rey)" },
            new LeagueOption { id = "soccer_uefa_nations_league", name = "UEFA Nations League" },
            new LeagueOption { id = "soccer_uefa_european_championship", name = "Euro (UEFA European Championship)" },
            new LeagueOption { id = "soccer_fifa_world_cup", name = "World Cup (FIFA)" },
            new LeagueOption { id = "soccer_africa_cup_of_nations", name = "Cúp bóng đá châu Phi (AFCON)" }
        };
    }
    public static bool IsAllowedLeague(string key)
    {
        return GetLeagues().Any(l => String.Equals(l.id, key, StringComparison.Ordinal));
    }
    public static List<string> SelectedIds(Dictionary<string, object> input)
    {
        object value;
        // Deserialize<Dictionary<string, object>> produces ArrayList for JSON arrays.
        var items = input.TryGetValue("ids", out value) ? value as IList : null;
        if (items == null || items.Count == 0 || items.Count > 100 ||
            items.Cast<object>().Any(id => !(id is string) || String.IsNullOrWhiteSpace((string)id)))
            throw new InvalidOperationException("Chọn từ 1 đến 100 trận trong danh sách.");
        return items.Cast<string>().Distinct(StringComparer.Ordinal).ToList();
    }
    public static List<DateTime> SelectedDates(Dictionary<string, object> input, DateTime today)
    {
        object value;
        var items = input.TryGetValue("dates", out value) ? value as IList : null;
        if (items == null || items.Count == 0 || items.Count > 7)
            throw new InvalidOperationException("Chọn ít nhất một ngày trong 7 ngày tính từ hôm nay.");
        var dates = new List<DateTime>();
        foreach (object item in items)
        {
            DateTime date;
            if (!(item is string) || !DateTime.TryParseExact((string)item, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out date) || date < today.Date || date > today.Date.AddDays(6))
                throw new InvalidOperationException("Chọn ngày trong 7 ngày tính từ hôm nay.");
            dates.Add(date);
        }
        return dates.Distinct().OrderBy(date => date).ToList();
    }
    public class Market
    {
        public string Code, Name, Bookmaker;
        public decimal? Line;
        public decimal Home, Away, Draw;
        public decimal Difference;
        public bool IsAlternate, Estimated;
    }
    public static decimal FirstHalfLine(decimal fullTime)
    {
        decimal half = Math.Abs(fullTime) / 2m;
        decimal fraction = half - Decimal.Truncate(half);
        decimal deduction = fraction == .125m || fraction == .625m ? .375m
            : fraction == .375m || fraction == .875m ? .125m : .25m;
        decimal result = Math.Max(0m, half - deduction);
        return fullTime < 0 ? -result : result;
    }
    public static void ApplyFirstHalfRules(List<Market> markets)
    {
        foreach (var source in markets.Where(m => m.Code.EndsWith("3") && m.Line.HasValue).ToList())
        {
            string code = source.Code.Substring(0, 1) + "1";
            if (markets.Any(m => m.Code == code) || source.Line.Value % .25m != 0) continue;
            markets.Add(new Market { Code = code, Name = (source.Name ?? "").Replace("cả trận", "hiệp 1"), Line = FirstHalfLine(source.Line.Value), Home = .9m, Away = .9m, Bookmaker = "Suy từ FT", Estimated = true });
        }
        markets.Sort((a, b) => StringComparer.Ordinal.Compare(a.Code, b.Code));
    }
    public class Fixture
    {
        public string Id, League, LeagueId, Season, Home, Away, HomeId, AwayId;
        public DateTimeOffset Kickoff;
        public string Time { get { return Kickoff.ToOffset(TimeSpan.FromHours(7)).ToString("HH:mm dd/MM/yyyy"); } }
        public List<Market> Markets = new List<Market>();
    }
    public static Dictionary<string, object> Obj(object value) { return (Dictionary<string, object>)value; }
    public static string Str(Dictionary<string, object> value, string key) { return value.ContainsKey(key) ? Convert.ToString(value[key], CultureInfo.InvariantCulture) : ""; }
    public static IEnumerable<Dictionary<string, object>> Rows(object value)
    {
        return ((IEnumerable)value).Cast<object>().Select(Obj);
    }
    public static string CompactId(string kind, string source)
    {
        using (var hash = System.Security.Cryptography.SHA256.Create())
            return kind + String.Concat(hash.ComputeHash(System.Text.Encoding.UTF8.GetBytes(source)).Take(7).Select(b => b.ToString("x2")));
    }
    public static object Get(string path)
    {
        string key = ConfigurationManager.AppSettings["TheOddsApiKey"];
        if (String.IsNullOrWhiteSpace(key)) throw new InvalidOperationException("Chưa cấu hình API key lấy trận từ web trên máy chủ.");
        ServicePointManager.SecurityProtocol |= (SecurityProtocolType)3072;
        var request = (HttpWebRequest)WebRequest.Create("https://api.the-odds-api.com/v4/" + path + (path.Contains("?") ? "&" : "?") + "apiKey=" + Uri.EscapeDataString(key));
        request.Timeout = 20000;
        try
        {
            using (var response = request.GetResponse())
            using (var reader = new System.IO.StreamReader(response.GetResponseStream()))
            {
                CaptureQuota(response.Headers);
                return new JavaScriptSerializer { MaxJsonLength = 10000000 }.DeserializeObject(reader.ReadToEnd());
            }
        }
        catch (WebException ex)
        {
            using (var response = ex.Response as HttpWebResponse)
            {
                if (response != null) CaptureQuota(response.Headers);
                if (response != null && (response.StatusCode == HttpStatusCode.Unauthorized || response.StatusCode == HttpStatusCode.Forbidden))
                    throw new InvalidOperationException("API key không hợp lệ, hết credits hoặc không có quyền truy cập dữ liệu. Kiểm tra tài khoản The Odds API.");
                if (response != null && (int)response.StatusCode == 429)
                    throw new InvalidOperationException("Nguồn dữ liệu đang giới hạn lượt gọi. Vui lòng chờ rồi thử lại.");
            }
            throw new InvalidOperationException("Không kết nối được The Odds API. Vui lòng kiểm tra API key, hạn mức và thử lại.");
        }
    }
    public static object CachedGet(string path, int seconds)
    {
        string cacheKey = "TheOddsApi:" + CompactId("K", ConfigurationManager.AppSettings["TheOddsApiKey"] ?? "") + ":" + path;
        lock (CacheLock)
        {
            object value = System.Web.HttpRuntime.Cache[cacheKey];
            if (value != null) return value;
            value = Get(path);
            System.Web.HttpRuntime.Cache.Insert(cacheKey, value, null, DateTime.Now.AddSeconds(seconds), System.Web.Caching.Cache.NoSlidingExpiration);
            return value;
        }
    }
    private static readonly object CacheLock = new object();
    public static List<Market> SelectMarkets(IEnumerable<Dictionary<string, object>> bookmakers, string homeTeam, string awayTeam)
    {
        var best = new Dictionary<string, Market>();
        foreach (var book in bookmakers.OrderBy(b => Str(b, "key"), StringComparer.Ordinal))
        foreach (var bet in Rows(book["markets"]))
        {
            string name = Str(bet, "key").ToLowerInvariant();
            // Explicit market allowlist: exclude team totals, European handicap, cards points, etc.
            string period = "3", baseName = name;
            if (name.EndsWith("_h1")) { period = "1"; baseName = name.Substring(0, name.Length - 3); }
            else if (name.EndsWith("_h2")) { period = "2"; baseName = name.Substring(0, name.Length - 3); }
            string code = null;
            bool total = false, euro = false;
            switch (baseName)
            {
                case "totals": case "alternate_totals": code = "2" + period; total = true; break;
                case "alternate_totals_corners": code = "0" + period; total = true; break;
                case "alternate_totals_cards": code = "5" + period; total = true; break;
                case "spreads": case "alternate_spreads": code = "3" + period; break;
                case "alternate_spreads_corners": code = "1" + period; break;
                case "alternate_spreads_cards": code = "6" + period; break;
                case "h2h": case "h2h_3_way": code = "4" + period; euro = true; break;
            }
            if (code == null) continue;
            var values = Rows(bet["outcomes"]).ToList();
            if (euro)
            {
                decimal home, away, draw;
                if (!Price(values, homeTeam, out home) || !Price(values, awayTeam, out away) || !Price(values, "Draw", out draw)) continue;
                if (!best.ContainsKey(code)) best[code] = new Market { Code = code, Name = "1X2" + (period == "3" ? " cả trận" : " hiệp " + period), Bookmaker = Str(book, "title"), Home = Math.Round(home, 1, MidpointRounding.AwayFromZero), Away = Math.Round(away, 1, MidpointRounding.AwayFromZero), Draw = Math.Round(draw, 1, MidpointRounding.AwayFromZero) };
                continue;
            }
            foreach (var value in values)
            {
                decimal line, first, second;
                if (Str(value, "name") != (total ? "Over" : homeTeam) || !Decimal.TryParse(Str(value, "point"), NumberStyles.Float, CultureInfo.InvariantCulture, out line)) continue;
                if (total && line < 0) continue;
                // Pair handicap Home -x with Away +x; total Over x with Under x.
                var other = values.FirstOrDefault(v => {
                    decimal n;
                    return Str(v, "name") == (total ? "Under" : awayTeam) && Decimal.TryParse(Str(v, "point"), NumberStyles.Float, CultureInfo.InvariantCulture, out n) && n == (total ? line : -line);
                });
                if (other == null || !Odd(value, out first) || !Odd(other, out second)) continue;
                decimal diff = Math.Abs(first - second);
                bool alternate = baseName.StartsWith("alternate_");
                if (!best.ContainsKey(code) || (best[code].IsAlternate && !alternate) || (best[code].IsAlternate == alternate && diff < best[code].Difference))
                    best[code] = new Market { Code = code, Name = (total ? "Tài xỉu " : "Chấp ") + (code[0] == '0' || code[0] == '1' ? "góc" : code[0] == '5' || code[0] == '6' ? "thẻ" : "bàn thắng") + (period == "3" ? " cả trận" : " hiệp " + period), Bookmaker = Str(book, "title"), Line = line, Home = .9m, Away = .9m, Difference = diff, IsAlternate = alternate };
            }
        }
        return best.Values.OrderBy(m => m.Code).ToList();
    }
    private static bool Odd(Dictionary<string, object> value, out decimal price)
    { return Decimal.TryParse(Str(value, "price"), NumberStyles.Float, CultureInfo.InvariantCulture, out price) && price > 1; }
    private static bool Price(List<Dictionary<string, object>> values, string label, out decimal price)
    {
        var value = values.FirstOrDefault(v => Str(v, "name") == label); price = 0;
        return value != null && Odd(value, out price);
    }
}
