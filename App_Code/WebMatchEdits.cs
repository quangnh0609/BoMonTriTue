using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;

public static class WebMatchEdits
{
    static decimal Number(Dictionary<string, object> row, string key)
    {
        string text = WebMatchImport.Str(row, key).Trim();
        decimal value;
        if ((text.Contains(",") && text.Contains(".")) || !Decimal.TryParse(text.Replace(',', '.'), NumberStyles.AllowLeadingSign | NumberStyles.AllowDecimalPoint, CultureInfo.InvariantCulture, out value) ||
            (value <= -1000000000000000m || value >= 1000000000000000m) || Decimal.Round(value, 4) != value)
            throw new InvalidOperationException("Giá trị " + key + " phải là số hợp lệ, tối đa 4 chữ số thập phân.");
        return value;
    }
    public static Dictionary<string, List<WebMatchImport.Market>> ParseBatch(object raw, Dictionary<string, WebMatchImport.Fixture> fixtures, List<string> ids)
    {
        var edits = raw as Dictionary<string, object>;
        if (edits == null || edits.Count != ids.Count || edits.Keys.Any(id => !ids.Contains(id)))
            throw new InvalidOperationException("Dữ liệu chỉnh sửa phải khớp toàn bộ các trận đã chọn.");
        var result = new Dictionary<string, List<WebMatchImport.Market>>();
        foreach (string id in ids)
        {
            var rows = edits[id] as IList;
            if (rows == null || rows.Count == 0 || rows.Count > 15) throw new InvalidOperationException("Danh sách kèo chỉnh sửa không hợp lệ.");
            var markets = new List<WebMatchImport.Market>();
            var codes = new HashSet<string>();
            foreach (object item in rows)
            {
                var row = item as Dictionary<string, object>;
                if (row == null) throw new InvalidOperationException("Dữ liệu kèo không hợp lệ.");
                string code = WebMatchImport.Str(row, "Code");
                if (!(code == "71" || (code.Length == 2 && code[0] >= '0' && code[0] <= '6' && (code[1] == '1' || code[1] == '3'))) || !codes.Add(code))
                    throw new InvalidOperationException("Mã kèo không hợp lệ, bị trùng hoặc là H2.");
                try
                {
                    decimal home = Number(row, "Home"), away = Number(row, "Away"), draw = code[0] == '4' ? Number(row, "Draw") : 0m;
                    if (home <= 0 || away <= 0 || (code[0] == '4' && (home < 1 || away < 1 || draw < 1)))
                        throw new InvalidOperationException("Giá hai cửa phải lớn hơn 0; giá 1X2 phải từ 1 trở lên và đủ ba cửa.");
                    decimal? line = code[0] == '4' ? (decimal?)null : Number(row, "Line");
                    if (line.HasValue && (line.Value % .25m != 0 || ((code[0] == '0' || code[0] == '2' || code[0] == '5') && line.Value < 0)))
                        throw new InvalidOperationException("Mốc phải là bội số 0,25; mốc tài/xỉu không được âm.");
                    var original = fixtures[id].Markets.FirstOrDefault(m => m.Code == code);
                    bool changed = original == null || original.Line != line || original.Home != home || original.Away != away || original.Draw != draw;
                    markets.Add(new WebMatchImport.Market { Code = code, Name = original == null ? "Kèo nhập tay " + code : original.Name,
                        Line = line, Home = home, Away = away, Draw = draw,
                        Bookmaker = changed ? "Chỉnh sửa thủ công" : original.Bookmaker, Estimated = !changed && original.Estimated });
                }
                catch (InvalidOperationException ex) { throw new InvalidOperationException(fixtures[id].Home + " – " + fixtures[id].Away + " (" + code + "): " + ex.Message); }
            }
            if (!codes.Contains("71")) throw new InvalidOperationException("Thiếu kèo giao bóng hiệp 1 của trận " + fixtures[id].Home + " – " + fixtures[id].Away + ".");
            result[id] = markets.OrderBy(m => m.Code).ToList();
        }
        return result;
    }
}
