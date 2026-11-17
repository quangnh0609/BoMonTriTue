$ErrorActionPreference = 'Stop'
$programRoot = Split-Path $PSScriptRoot -Parent
$matchPage = [IO.File]::ReadAllText((Join-Path $programRoot 'SaveMatch.aspx'))
$esportPage = [IO.File]::ReadAllText((Join-Path $programRoot 'SaveEsport.aspx'))
$matchBody = [regex]::Match($matchPage, '(?s)<script runat="server">(.*?)</script>').Groups[1].Value
$esportBody = [regex]::Match($esportPage, '(?s)<script runat="server">(.*?)</script>').Groups[1].Value
$xml = [regex]::Match($matchBody, '(?s)XElement details = new XElement\("details",.*?\r?\n            \);').Value
if (!$xml) { throw 'XML details construction not found' }
$imports = 'using System; using System.Web; using System.Web.UI; using System.Data; using System.Data.SqlClient; using System.Configuration; using System.Web.Script.Serialization; using System.Collections.Generic; using System.Xml.Linq; using System.Linq; using System.Globalization;'
$harness = $imports + 'public class MatchInputHarness : Page {' + $matchBody + ' public static XElement Build(string json) { var data = new JavaScriptSerializer().Deserialize<MatchData>(json);' + $xml + ' return details; }} public class EsportInputHarness : Page {' + $esportBody + ' public object Parse(Dictionary<string, object> values, string key) { return ParseDecimal(values, key); }}' + @'
public class InputTests {
 static void Check(bool ok, string label) { if (!ok) throw new Exception(label); }
 public static void Main() {
  var details = MatchInputHarness.Build("{\"h1_euro_home\":\"1,75\",\"ft_goal_handicap\":\"-0,25\",\"h2_goal_handicap\":\"-3\",\"h2_euro_home\":\"2\"}");
  Check(details.Elements().All(x => x.Element("h2").Value == ""), "No H2 accepted even from old clients");
  Check(details.Elements().Single(x=>x.Element("col").Value=="euro_home").Element("h1").Value=="1.75", "Football comma decimal");
  Check(details.Elements().Single(x=>x.Element("col").Value=="goal_handicap").Element("ft").Value=="-0.25", "Signed football comma decimal");
  var esport = new EsportInputHarness();
  var values = new Dictionary<string,object>{{"dragon_ou_line","2,75"},{"first_home_win","1,85"},{"dragon_hc_line","-0,25"}};
  Check((decimal)esport.Parse(values,"dragon_ou_line")==2.75m,"Dragon comma decimal");
  Check((decimal)esport.Parse(values,"first_home_win")==1.85m,"Kill comma decimal");
  Check((decimal)esport.Parse(values,"dragon_hc_line")==-.25m,"Signed dragon decimal");
  Check((decimal)esport.Parse(values,"dragon_ou_over_win")==.9m,"Default pair rate");
  Console.WriteLine("7 actual ASPX backend input assertions passed.");
 }
}
'@
$source = Join-Path $env:TEMP ('MatchInput-' + [Guid]::NewGuid().ToString('N') + '.cs')
[IO.File]::WriteAllText($source, $harness)
$exe = $source + '.exe'
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:exe ('/out:' + $exe) /r:System.Web.dll /r:System.Web.Extensions.dll /r:System.Configuration.dll /r:System.Data.dll /r:System.Xml.Linq.dll $source (Join-Path $programRoot 'App_Code\CatalogState.cs')
if ($LASTEXITCODE -ne 0) { throw 'Backend compilation failed' }
& $exe
if ($LASTEXITCODE -ne 0) { throw 'Backend assertions failed' }
