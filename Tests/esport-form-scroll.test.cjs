const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');
const { pathToFileURL } = require('url');
const assert = require('assert');
const control = fs.readFileSync(path.join(__dirname, '../ucAddEsport.ascx'), 'utf8');
const css = control.match(/<style>([^]*?)<\/style>/)[1];
const markup = control.slice(control.indexOf('<div id="modalAddEsport"'), control.indexOf('<uc:NumericKeyboard'));
const behavior = control.match(/<script type="text\/javascript">([^]*?)<\/script>/)[1];
const numbers = fs.readFileSync(path.join(__dirname, '../Scripts/native-number-inputs.js'), 'utf8');
// Only local utility rules used by the actual control; no CDN or API required.
const utilities = `*{box-sizing:border-box}body{margin:0;font:16px sans-serif;overflow:hidden}button,input{font:inherit}button{padding:8px;border:1px solid #ddd}
.hidden{display:none!important}.flex{display:flex}.flex-col{flex-direction:column}.flex-grow{flex-grow:1}.flex-1{flex:1 1 0%}.shrink-0{flex-shrink:0}.min-w-0{min-width:0}.w-full{width:100%}
.overflow-hidden{overflow:hidden}.overflow-y-auto{overflow-y:auto}.items-center{align-items:center}.justify-center{justify-content:center}.justify-between{justify-content:space-between}.justify-end{justify-content:flex-end}
.grid{display:grid}.grid-cols-2{grid-template-columns:repeat(2,minmax(0,1fr))}.grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}.grid-cols-6{grid-template-columns:repeat(6,minmax(0,1fr))}.gap-1{gap:4px}.gap-2{gap:8px}.gap-3{gap:12px}
.p-2{padding:8px}.p-4{padding:16px}.px-6{padding-left:24px;padding-right:24px}.px-4{padding-left:16px;padding-right:16px}.py-4{padding-top:16px;padding-bottom:16px}.py-3{padding-top:12px;padding-bottom:12px}.py-2{padding-top:8px;padding-bottom:8px}
.mb-1{margin-bottom:4px}.mb-3{margin-bottom:12px}.mb-4{margin-bottom:16px}.mb-5{margin-bottom:20px}.block{display:block}.relative{position:relative}.absolute{position:absolute}.sticky{position:sticky}.top-0{top:0}.bg-white{background:white}.border-b{border-bottom:1px solid #ddd}
#modalAddEsport{position:fixed;inset:0;background:#ddd}#modalAddEsport>div{width:100%;max-width:768px;background:white}#esportFormContent>.sticky{z-index:20}`;
const checks = `
window.addEventListener('load', () => setTimeout(() => { try {
 let assertions=0;
 function check(ok,label){assertions++;if(!ok)throw Error(label);}
 openAddEsportModalUI();
 const form=document.getElementById('esportFormContent');
 const inner=document.querySelector('.esport-game-scroll');
 const footer=document.getElementById('btnSaveEsport');
 for(let game=1;game<=5;game++) for(const rates of [false,true]) {
  switchGameTab(game);
  isEsportRateMode=!rates;toggleEsportRateMode();
  form.scrollTop=form.scrollHeight;
  for(const side of ['home','way']) {
   const input=document.getElementById('g'+game+'_win_'+side+'_win');
   const scrolls=[];
   for(let parent=input.parentElement;parent;parent=parent.parentElement) {
    if(/auto|scroll/.test(getComputedStyle(parent).overflowY)&&parent.scrollHeight>parent.clientHeight+1)scrolls.push(parent);
   }
   check(scrolls.length===1&&scrolls[0]===form,'One form scroll, game '+game+' rates '+rates);
   const rect=input.getBoundingClientRect(),box=form.getBoundingClientRect();
   check(rect.top>=box.top&&rect.bottom<=box.bottom,'Final win input fully visible after one form scroll');
   check(rect.bottom<=footer.parentElement.getBoundingClientRect().top,'Input above footer');
   check(document.elementFromPoint(rect.left+rect.width/2,rect.top+rect.height/2)===input,'Final input not covered');
   input.value='2.15';input.focus();input.click();input.setRangeText('1,85');
   check(collectGameData(game)['win_'+side+'_win']==='1.85','Final input editable with comma decimal');
  }
  check(inner.scrollTop===0&&inner.scrollHeight<=inner.clientHeight+1,'No nested game scrolling');
 }
 switchGameTab(6);form.scrollTop=form.scrollHeight;
 const box=footer.getBoundingClientRect();
 check(box.top>=0&&box.bottom<=innerHeight,'Save button stays in viewport');
 check(document.documentElement.scrollHeight<=innerHeight+1,'No outer page scrolling');
 document.getElementById('report').textContent='PASS '+assertions+' layout assertions';
} catch(error){document.getElementById('report').textContent='FAIL '+error.stack;} },100));`;
const folder=fs.mkdtempSync(path.join(os.tmpdir(),'esport-scroll-'));
const file=path.join(folder,'layout.html');
fs.writeFileSync(file,`<!doctype html><html><head><meta charset="utf-8"><style>${utilities}\n${css}</style></head><body>${markup}<pre id="report" style="display:none"></pre><script>${behavior}</script><script>${numbers}</script><script>${checks}</script></body></html>`);
const edge=process.env.BET_LINE_TEST_BROWSER||'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
for(const size of ['390,700','390,400','1280,800']){
 const output=execFileSync(edge,['--headless','--disable-gpu','--no-first-run','--no-default-browser-check','--user-data-dir='+path.join(folder,'profile-'+size),'--allow-file-access-from-files','--dump-dom','--window-size='+size,'--virtual-time-budget=1000',pathToFileURL(file).href],{encoding:'utf8',timeout:30000,stdio:['ignore','pipe','pipe']});
 const report=output.match(/<pre id="report"[^>]*>([^]*?)<\/pre>/)?.[1];
 assert(report?.startsWith('PASS'),size+': '+(report||'No test report'));
 console.log(size+': '+report);
}
