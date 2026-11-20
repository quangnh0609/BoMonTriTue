const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');
const testSource = process.env.WEB_MATCH_TEST_SOURCE || 'api-football';
const testSourceSelector = testSource === 'the-odds-api';

// Exercise the create -> resolve missing teams -> explicit choice -> create flow.
class Element {
    constructor(id = '') {
        this.id = id; this.value = ''; this.children = []; this.dataset = {};
        this.classes = new Set(['hidden']);
        this.classList = { add: x => this.classes.add(x), remove: x => this.classes.delete(x), contains: x => this.classes.has(x), toggle: (x, yes) => yes ? this.classes.add(x) : this.classes.delete(x) };
    }
    setAttribute() {}
    append(...items) { this.children.push(...items); }
    appendChild(item) { this.children.push(item); }
    replaceChildren() { this.children = []; }
    focus() {}
    get options() { return this.children; }
    querySelector() { return new Element(); }
    querySelectorAll(selector) { return this.id === 'webMatchList' && selector.startsWith('input') ? selectedIds.map(value => ({value,checked:true})) : []; }
}
const elements = new Map();
const el = id => { if (!elements.has(id)) elements.set(id, new Element(id)); return elements.get(id); };
const dialogHtml = fs.readFileSync(path.join(__dirname, '../WebMatchDialogs.html'), 'utf8');
for (const id of ['webMatchSource','webMatchSourceOdds','webMatchSourceFootball','webMatchSourceClose','webMatchChangeSource','webMatchSourceNote']) assert(dialogHtml.includes('id="' + id + '"'), 'Source UI must exist: ' + id);
const requests = [];
let reloads = 0;
let matchRefreshes = 0;
const kind = process.env.WEB_MATCH_TEST_KIND || 'đội';
const context = {
    document: { getElementById: el, createElement: () => new Element(), body: { style: {} }, addEventListener() {} },
    window: { BetLinePicker: { prepare() {} }, webMatchToken: 'token', location: { reload() { reloads++; } }, reloadMatchesData() { matchRefreshes++; } },
    fetch: async (_, request) => {
        const data = JSON.parse(request.body); requests.push(data);
        return { json: async () => data.teamChoices.sourceTeam ? { ok: true, count: 1 } : {
            ok: true, needsTeams: true, requiredTeams: [{ key: 'sourceTeam', name: 'External Team', kind, candidates: [{ id: 'EXISTING', name: 'Existing Team' }], allOptions: [{ id: 'EXISTING', name: 'Existing Team' }, { id: 'DANANG', name: 'Đà Nẵng' }] }]
        } };
    }
};
vm.createContext(context);
const script = fs.readFileSync(path.join(__dirname, '../Scripts/web-match-import.js'), 'utf8');
vm.runInContext(testSourceSelector ? script.replace('const allowSourceSelection = false;', 'const allowSourceSelection = true;') : script, context);


const selectedIds = testSourceSelector ? ['fixture-one'] : ['fixture-one', 'fixture-two'];
context.fetch = async (_, request) => {
    const data = JSON.parse(request.body); requests.push(data);
    return { json: async () => {
        if (data.action === 'leagues') return {ok:true,leagues:[]};
        if (data.action === 'listResults') return {ok:true,matches:[
            {Id:'live',Name:'Home – Away',Time:'20:00 31/12/2026',Status:'Trực tiếp'},
            {Id:'pending',Name:'Blue – Red',Time:'18:00 31/12/2026',Status:'Chờ kết quả'},
            {Id:'other',Name:'Black – White',Time:'17:00 31/12/2026',Status:'Chờ kết quả'}
        ]};
        if (data.action === 'importResults') return {ok:true,outcomes:[
            {Id:'live',Updated:false,Message:'Trận chưa kết thúc.'},
            {Id:'pending',Updated:true,Message:'Đã lưu bàn cả trận 2–0.'}
        ]};
        if (data.action === 'search') return {ok:true,snapshot:'selection',matches:selectedIds.map((id,i) => ({Id:id,Time:'20:00 31/12/2026',Home:'Home'+i,Away:'Away'+i}))};
        if (data.action === 'preview') return {ok:true,previewToken:'preview-one',matches:selectedIds.map((id,i)=>({Id:id,Time:'20:00 31/12/2026',Home:'Home'+i,Away:'Away'+i,Markets:[
            {Code:'33',Line:0.5,Home:0.9,Away:0.9,Bookmaker:'Book A'},
            {Code:'31',Line:0,Home:0.9,Away:0.9,Bookmaker:'Suy từ FT',Estimated:true},
            {Code:'43',Line:null,Home:2.3,Draw:3.5,Away:3.2,Bookmaker:'Book A'},
            {Code:'32',Line:99,Home:0.9,Away:0.9,Bookmaker:'Must not appear'},
            {Code:'71',Line:0,Home:1,Away:1,Bookmaker:'Mặc định hệ thống'}
        ]}))};
        return {ok:true,count:selectedIds.length};
    }};
};
(async () => {
    context.window.webMatchOpen();
    assert(!el('webMatchMode').classList.contains('hidden'));
    assert.equal(requests.length, 0, 'The mode chooser does not call the server');
    await el('webMatchModeOdds').onclick();
    if (testSourceSelector) {
        assert.equal(requests.length, 0, 'Opening the source selector does not call either API');
        await el('webMatchSourceOdds').onclick();
    } else {
        assert(/id="webMatchChangeSource"[^>]*class="hidden\b/.test(dialogHtml));
        assert(el('webMatchSource').classList.contains('hidden'));
        assert(el('webMatchChangeSource').classList.contains('hidden'));
        assert(!el('webMatchFilter').classList.contains('hidden'));
        assert.equal(requests[0].source, 'api-football');
        assert.equal(requests[0].action, 'leagues');
    }
    el('webMatchLeague').value='soccer_epl';
    const first=el('webMatchDays').children[0].dataset.day;
    const third=el('webMatchDays').children[2].dataset.day;
    el('webMatchDays').children[2].onclick();
    await el('webMatchSearch').onclick();
    assert.deepEqual(requests[1].dates, [first,third]);
    assert.equal(requests.length,2,'Search must not request odds/create');
    assert(el('webMatchList').children[0].children[0].children[1].textContent.includes('31/12/2026'),'Show date as well as time');
    await el('webMatchCreate').onclick();
    let createIndex = 2;
    if (!testSourceSelector) {
        assert.equal(requests[2].action,'preview');
        assert.equal(reloads,0,'Preview must not create matches');
        assert.equal(el('webMatchPreview').classList.contains('hidden'),false);
        assert.equal(el('webMatchPreviewList').children.length,2,'One editable card per selected fixture');
        const firstRows=el('webMatchPreviewList').children[0].children[1].children;
        const secondRows=el('webMatchPreviewList').children[1].children[1].children;
        assert.equal(firstRows[0].children.length,3,'Only label, H1 and FT columns');
        assert.equal(firstRows[0].children[1].textContent,'Hiệp 1');
        assert.equal(firstRows[0].children[2].textContent,'Cả trận');
        assert.equal(firstRows[4].children[1].children[1].textContent,'Suy từ FT');
        assert(firstRows[2].classList.contains('hidden'),'Rate rows hidden by default');
        const rateButton=firstRows[0].children[0].children[0]; rateButton.onclick();
        assert(!firstRows[2].classList.contains('hidden'),'Rate button reveals prices');
        rateButton.onclick(); assert(firstRows[2].classList.contains('hidden'),'Rate button hides prices again');
        assert.equal(firstRows[4].children[2].children[0].inputMode,'none','Handicap uses line dropdown');
        assert.equal(firstRows[1].children[2].children[0].inputMode,'none','Totals use line dropdown');
        assert.equal(firstRows[4].children[2].children[0].readOnly,true,'Dropdown prevents typing a handicap');
        assert.equal(firstRows[7].children[2].children[0].inputMode,'decimal','1X2 remains numeric input');
        function edit(rows,row,column,value) { const input=rows[row].children[column].children[0]; input.value=value; input.oninput(); }
        edit(firstRows,4,2,'-0,75'); edit(firstRows,5,2,'0,85'); edit(firstRows,6,2,'0.95');
        edit(firstRows,1,2,'2.5'); edit(firstRows,2,2,'1.1'); edit(firstRows,3,2,'0.8');
        edit(secondRows,4,2,'-1.25');
        edit(secondRows,1,2,'3.5');
        await el('webMatchPreviewCreate').onclick();
        createIndex = 3;
        assert.equal(requests[createIndex].previewToken,'preview-one');
        const edits=requests[createIndex].edits;
        assert.deepEqual(Object.keys(edits).sort(),['fixture-one','fixture-two']);
        assert.equal(edits['fixture-one'].find(k=>k.Code==='33').Line,'-0,75');
        assert.equal(edits['fixture-one'].find(k=>k.Code==='33').Home,'0,85');
        assert.equal(edits['fixture-one'].find(k=>k.Code==='23').Home,'1.1');
        assert.equal(edits['fixture-two'].find(k=>k.Code==='33').Line,'-1.25');
        assert.equal(edits['fixture-two'].find(k=>k.Code==='23').Line,'3.5');
        assert(Object.values(edits).every(markets=>markets.every(k=>!k.Code.endsWith('2'))),'Never send H2 edits');
        assert(Object.values(edits).every(markets=>markets.some(k=>k.Code==='71')),'Include editable kickoff H1');
    }
    assert.equal(requests[createIndex].action,'create');
    assert.deepEqual(requests[createIndex].ids,selectedIds);
    assert.equal(requests[createIndex].snapshot,'selection');
    assert(requests.every(r => r.source === testSource), 'Keep the same source on every request');
    const requestCount = requests.length;
    el('webMatchBack').onclick();
    el('webMatchDays').children[0].onclick();
    el('webMatchDays').children[2].onclick();
    await el('webMatchSearch').onclick();
    assert.equal(requests.length,requestCount,'Empty day selection must not send a request');
    if (testSourceSelector) {
        el('webMatchChangeSource').onclick();
        await el('webMatchSourceFootball').onclick();
    } else {
        context.window.webMatchOpen();
        await el('webMatchModeOdds').onclick();
    }
    assert.equal(requests[requestCount].source, 'api-football');
    assert.equal(el('webMatchList').children.length,0,'Opening the filter clears old selection');
    context.window.webMatchOpen();
    await el('webMatchModeResults').onclick();
    assert(!el('webMatchScore').classList.contains('hidden'));
    assert.equal(requests.at(-1).action, 'listResults');
    assert.equal(requests.at(-1).source, 'api-football');
    assert(el('webMatchScoreImport').disabled);
    const [live, pending, other] = el('webMatchScoreList').children;
    assert(live.children[0].children[1].textContent.includes('Trực tiếp'));
    assert(pending.children[0].children[1].textContent.includes('Chờ kết quả'));
    for (const row of [live, pending]) {
        const check = row.children[0].children[0];
        check.checked = true;
        check.onchange();
    }
    assert(!el('webMatchScoreImport').disabled);
    await el('webMatchScoreImport').onclick();
    assert.equal(requests.at(-1).action, 'importResults');
    assert.deepEqual(requests.at(-1).ids, ['live', 'pending']);
    assert.equal(live.children[1].textContent, 'Trận chưa kết thúc.');
    assert.equal(pending.children[1].textContent, 'Đã lưu bàn cả trận 2–0.');
    assert(!other.children[1].textContent);
    assert.equal(matchRefreshes, 1);
    assert(el('webMatchScoreImport').disabled);
    el('webMatchScoreBack').onclick();
    assert(!el('webMatchMode').classList.contains('hidden'));
    console.log('Multiple day selection and list-first flow checks passed.');
})().catch(error => {console.error(error);process.exitCode=1;});
