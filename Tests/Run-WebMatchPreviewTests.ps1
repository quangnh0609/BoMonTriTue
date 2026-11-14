$ErrorActionPreference = 'Stop'
$programRoot = Split-Path $PSScriptRoot -Parent
$pageText = [IO.File]::ReadAllText((Join-Path $programRoot 'WebMatches.aspx'))
$body = [regex]::Match($pageText, '(?s)<script runat="server">(.*?)</script>').Groups[1].Value
$body = [regex]::Replace($body, '(?s)    void Reply\(object value\).*?(?=    protected void Page_Load)', '    void Reply(object value) { ReplyData = value; }' + "`n")
$body = [regex]::Replace($body, '(?m)^    bool AllowedLeague.*$', '    bool AllowedLeague(string league) { return league == "39"; }')
$body = [regex]::Replace($body, '(?m)^    string OperationScope.*$', '    string OperationScope { get { return "test-scope"; } }')
$body = [regex]::Replace($body, '(?m)^    string Connection.*$', '    string Connection { get { throw new InvalidOperationException("DATABASE_REACHED"); } }')
$harness = 'using System; using System.Web; using System.Data; using System.Data.SqlClient; using System.Configuration; using System.Collections.Generic; using System.Linq; using System.Globalization; public class WebMatchesPreviewHarness : System.Web.UI.Page { public new System.Collections.Hashtable Session = new System.Collections.Hashtable(); public object ReplyData;' + $body + '}'
$sourcePath = Join-Path $env:TEMP ('WebMatchPreview-' + [Guid]::NewGuid().ToString('N') + '.cs')
[IO.File]::WriteAllText($sourcePath, $harness)
$exePath = $sourcePath + '.exe'
$outputArgument = '/out:' + $exePath
& "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:exe $outputArgument /r:System.Web.dll /r:System.Web.Extensions.dll /r:System.Configuration.dll /r:System.Data.dll $sourcePath (Join-Path $programRoot 'App_Code\WebMatchImport.cs') (Join-Path $programRoot 'App_Code\ApiFootballImport.cs') (Join-Path $programRoot 'App_Code\CatalogState.cs') (Join-Path $programRoot 'App_Code\WebMatchEdits.cs') (Join-Path $programRoot 'App_Code\WebMatchOperations.cs') (Join-Path $programRoot 'App_Code\WebMatchState.cs') (Join-Path $PSScriptRoot 'WebMatchPreviewTests.cs')
if ($LASTEXITCODE -ne 0) { throw 'Preview test compilation failed.' }
& $exePath
if ($LASTEXITCODE -ne 0) { throw 'Preview tests failed.' }
