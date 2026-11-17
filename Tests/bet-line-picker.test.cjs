const fs = require('fs');
const os = require('os');
const path = require('path');
const {execFileSync} = require('child_process');
const assert = require('assert');
const script = fs.readFileSync(path.join(__dirname, '../Scripts/bet-line-picker.js'), 'utf8');
const nativeScript = fs.readFileSync(path.join(__dirname, '../Scripts/native-number-inputs.js'), 'utf8');
const folder = fs.mkdtempSync(path.join(os.tmpdir(), 'bet-line-picker-'));
const html = `<!doctype html><html><head><meta charset="utf-8"></head><body>
<input id="line" data-line-picker readonly value="2.5" aria-label="Tài bàn FT" style="margin:30px;width:150px">
<input id="rate" inputmode="decimal" value="2.3"><pre id="report"></pre>
<script>${script}</script><script>${nativeScript}</script><script>
let assertions = 0;
function check(value, name) { assertions++; if (!value) throw Error(name); }
function key(field, value) { field.dispatchEvent(new KeyboardEvent('keydown', {key:value,bubbles:true})); }
window.addEventListener('load', () => setTimeout(async () => { try {
 const field = document.getElementById('line');
 let events = []; field.addEventListener('input', () => events.push('input')); field.addEventListener('change', () => events.push('change'));
 field.focus();
 let list = document.querySelector('[role=listbox]');
 check(!!list, 'Focus opens picker');
 check(list.children.length === 801, '801 quarter-step options');
 check(list.children[0].textContent === '-100' && list.children[800].textContent === '100', 'Inclusive bounds');
 check(list.clientHeight === 224, 'Exactly seven rows');
 function centered(value) {
  const option = Array.from(list.children).find(x=>x.textContent === value);
  const box = option.getBoundingClientRect(), viewport = list.getBoundingClientRect();
  check(Math.abs(box.top - viewport.top - 96) < 1, 'Selected value centered: ' + value);
 }
 centered('2.5');
 const visible = Array.from(list.children).filter(x => { const r=x.getBoundingClientRect(), p=list.getBoundingClientRect(); return r.top >= p.top && r.bottom <= p.bottom; }).map(x=>x.textContent);
 check(visible.join(',') === '1.75,2,2.25,2.5,2.75,3,3.25', 'Three options above and below');
 key(field,'ArrowDown'); key(field,'Enter');
 check(field.value === '2.75' && events.join(',') === 'input,change', 'Select quarter step and notify save handlers');
 check(!document.querySelector('[role=listbox]'), 'Selection closes picker');
 field.click(); list = document.querySelector('[role=listbox]'); centered('2.75');
 key(field,'Home'); centered('-100'); key(field,'ArrowUp'); key(field,'Enter'); check(field.value === '-100', 'Lower bound clamped');
 field.click(); list = document.querySelector('[role=listbox]'); key(field,'End'); centered('100'); key(field,'ArrowDown'); key(field,'Enter'); check(field.value === '100', 'Upper bound clamped');
 field.click(); document.querySelector('[data-bet-line-popup] button').click(); check(field.value === '', 'Clear removes optional market');
 field.click(); list = document.querySelector('[role=listbox]'); centered('0'); key(field,'Escape'); check(!document.querySelector('[role=listbox]'), 'Escape closes');
 field.click(); document.getElementById('rate').focus(); check(!document.querySelector('[role=listbox]'), 'Moving to numeric rate closes');
 check(!document.getElementById('rate').readOnly, 'Numeric rates remain editable');
 const rate = document.getElementById('rate');
 check(rate.selectionStart === 0 && rate.selectionEnd === rate.value.length, 'Focus selects entire numeric rate');
 rate.setSelectionRange(1,1); rate.click();
 check(rate.selectionStart === 0 && rate.selectionEnd === rate.value.length, 'Click reselects whole value');
 await new Promise(resolve => setTimeout(resolve, 10));
 check(rate.selectionEnd === rate.value.length, 'Selection survives tap caret handling');
 rate.setRangeText('1,85'); check(rate.value === '1,85', 'Can immediately replace whole value with comma decimal');
 const newRate = document.createElement('input'); newRate.inputMode = 'decimal'; newRate.value = '3.25'; document.body.appendChild(newRate); newRate.focus();
 check(newRate.selectionStart === 0 && newRate.selectionEnd === 4, 'Dynamic preview numeric inputs select all');
 const dynamic = document.createElement('input'); dynamic.setAttribute('data-line-picker',''); dynamic.value='-0.75'; document.body.appendChild(dynamic); dynamic.focus();
 list = document.querySelector('[role=listbox]'); centered('-0.75'); check(dynamic.readOnly && dynamic.inputMode === 'none','Dynamic fields supported');
 key(dynamic,'Tab'); check(!document.querySelector('[role=listbox]'), 'Tab closes');
 document.getElementById('report').textContent = 'PASS ' + assertions + ' browser assertions';
 // Leave the centered dropdown open for visual inspection.
 field.value = '2.5'; setTimeout(() => { field.focus(); field.click(); }, 300);
} catch (error) { document.getElementById('report').textContent = 'FAIL ' + error.stack; } }, 100));
</script></body></html>`;
const fixture = path.join(folder, 'test.html'); fs.writeFileSync(fixture, html);
const edge = process.env.BET_LINE_TEST_BROWSER || 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const args = ['--headless','--disable-gpu','--no-first-run','--no-default-browser-check','--user-data-dir='+path.join(folder,'profile'),'--allow-file-access-from-files','--dump-dom','--window-size=600,600','--virtual-time-budget=1000'];
if (process.env.BET_LINE_SCREENSHOT) args.push('--screenshot='+process.env.BET_LINE_SCREENSHOT);
const output = execFileSync(edge,[...args,require('url').pathToFileURL(fixture).href],{encoding:'utf8',timeout:30000,stdio:['ignore','pipe','pipe']});
const report = output.match(/<pre id="report">([\s\S]*?)<\/pre>/)?.[1];
assert(report && report.startsWith('PASS'), report || 'No browser test report');
console.log(report);
const manual = fs.readFileSync(path.join(__dirname,'../ucAddMatch.ascx'),'utf8');
assert.equal((manual.match(/data-line-picker="true"/g)||[]).length,12,'All football H1/FT total and handicap lines');
assert(!manual.includes('ID="h2_') && !manual.includes('Hiệp 2'), 'No H2 creation fields');
const esport = fs.readFileSync(path.join(__dirname,'../ucAddEsport.ascx'),'utf8');
assert.equal((esport.match(/data-line-picker="true"/g)||[]).length,17,'Kill, minute and series lines use dropdowns; dragons use numbers');
for (const file of ['ucAddMatch.ascx','ucAddEsport.ascx','ucAddChampion.ascx']) assert(fs.readFileSync(path.join(__dirname,'..',file),'utf8').includes('Scripts/bet-line-picker.js'),'Shared picker loaded: '+file);
console.log('Manual football, esports and champion integration checks passed.');
