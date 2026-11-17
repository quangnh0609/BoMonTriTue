const fs=require('fs'),path=require('path'),os=require('os'),assert=require('assert');
const {execFileSync}=require('child_process');
const {pathToFileURL}=require('url');
const page=fs.readFileSync(path.join(__dirname,'../esports.aspx'),'utf8');
function extract(name){const start=page.indexOf('        function '+name+'(');assert(start>=0);const end=page.indexOf('\n        function ',start+1);return page.slice(start,end);}
const native=fs.readFileSync(path.join(__dirname,'../Scripts/native-number-inputs.js'),'utf8');
const html=`<!doctype html><html><head><meta charset="utf-8"><style>.hidden{display:none}input{display:block;margin:10px;font-size:16px}</style></head><body>
<div id="modalEsportResult"><div id="erMatchLabel"></div><div id="erBody"></div><input id="erEndGame" type="checkbox"></div><pre id="report"></pre>
<script>${native}</script><script>
let assertions=0,payload,alerts=[];
function check(ok,label){assertions++;if(!ok)throw Error(label);}
window.NumericKeyboard={attachToFields(){throw Error('Custom keyboard must never attach');}};
window.alert=value=>alerts.push(value);
window.fetch=(url,request)=>{
 if(url.endsWith('GetResultData'))return Promise.resolve({json:async()=>({d:JSON.stringify({home:'H',way:'A',games:[{game_no:1,result_fields:{kill:true,minute:true,dragon:true},result_kill_home:1,result_kill_way:2,result_dragon_home:3,result_dragon_way:4,result_minute:30.5}]})})});
 payload=JSON.parse(JSON.parse(request.body).resultData);return new Promise(()=>{});
};
${extract('openEsportResult')}
${extract('saveEsportResultData')}
window.addEventListener('load',()=>setTimeout(async()=>{try{
 openEsportResult('test-match');await new Promise(resolve=>setTimeout(resolve,10));
 check(!alerts.length,'Result modal opens');
 document.querySelector('[data-result-game-body]').classList.remove('hidden');
 const numbers=Array.from(document.querySelectorAll('#erBody [data-number-input]'));
 check(numbers.length===4,'Kill and dragon numeric inputs rendered');
 for(const input of numbers){
  check(input.inputMode==='decimal'&&!input.readOnly&&!input.hasAttribute('data-numeric-keyboard'),'Native decimal keyboard');
  input.focus();input.setSelectionRange(1,1);input.click();
  check(input.selectionStart===0&&input.selectionEnd===input.value.length,'Click selects all result number');
 }
 const kill=numbers[0];kill.focus();kill.click();kill.setRangeText('1,75');kill.dispatchEvent(new Event('input',{bubbles:true}));
 const minute=document.querySelector('[data-minute-mask]');
 check(minute.inputMode==='numeric'&&!minute.readOnly,'Time uses native numeric keyboard');
 minute.focus();minute.click();check(minute.selectionStart===0&&minute.selectionEnd===minute.value.length,'Time selects all');
 minute.setRangeText('3045');minute.dispatchEvent(new Event('input',{bubbles:true}));
 check(minute.value==='30:45','Time mask preserved');
 saveEsportResultData();
 check(payload.games[0].result_kill_home==='1.75','Comma decimal normalized in saved results');
 check(payload.games[0].result_minute==='30:45','Time value saved in mm:ss');
 check(!('result_kill_way' in payload.games[0]),'Unchanged results omitted');
 payload=null;minute.value='30:65';saveEsportResultData();check(!payload&&alerts.length===1,'Invalid seconds still rejected');
 document.getElementById('report').textContent='PASS '+assertions+' esports result input assertions';
}catch(error){document.getElementById('report').textContent='FAIL '+error.stack;}},100));
</script></body></html>`;
const folder=fs.mkdtempSync(path.join(os.tmpdir(),'esport-result-input-')),file=path.join(folder,'test.html');fs.writeFileSync(file,html);
const edge=process.env.BET_LINE_TEST_BROWSER||'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const out=execFileSync(edge,['--headless','--disable-gpu','--no-first-run','--no-default-browser-check','--user-data-dir='+path.join(folder,'profile'),'--allow-file-access-from-files','--dump-dom','--window-size=600,800','--virtual-time-budget=1000',pathToFileURL(file).href],{encoding:'utf8',timeout:30000,stdio:['ignore','pipe','pipe']});
const report=out.match(/<pre id="report">([^]*?)<\/pre>/)?.[1];assert(report?.startsWith('PASS'),report||'No browser report');console.log(report);
