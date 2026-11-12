const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');

// Exercise the create -> resolve missing teams -> explicit choice -> create flow.
class Element {
    constructor(id = '') {
        this.id = id; this.value = ''; this.children = []; this.dataset = {};
        this.classes = new Set(['hidden']);
        this.classList = { contains: x => this.classes.has(x), toggle: (x, yes) => yes ? this.classes.add(x) : this.classes.delete(x) };
    }
    setAttribute() {}
    append(...items) { this.children.push(...items); }
    appendChild(item) { this.children.push(item); }
    replaceChildren() { this.children = []; }
    focus() {}
    get options() { return this.children; }
    querySelector() { return new Element(); }
    querySelectorAll(selector) { return this.id === 'webMatchList' && selector.startsWith('input') ? [{ value: 'fixture-one', checked: true }] : []; }
}
const elements = new Map();
const el = id => { if (!elements.has(id)) elements.set(id, new Element(id)); return elements.get(id); };
const dialogHtml = fs.readFileSync(path.join(__dirname, '../WebMatchDialogs.html'), 'utf8');
for (const id of ['webMatchSource','webMatchSourceOdds','webMatchSourceFootball','webMatchSourceClose','webMatchChangeSource','webMatchSourceNote']) assert(dialogHtml.includes('id="' + id + '"'), 'Source UI must exist: ' + id);
const requests = [];
let reloads = 0;
const kind = process.env.WEB_MATCH_TEST_KIND || 'đội';
const context = {
    document: { getElementById: el, createElement: () => new Element(), body: { style: {} }, addEventListener() {} },
    window: { webMatchToken: 'token', location: { reload() { reloads++; } } },
    fetch: async (_, request) => {
        const data = JSON.parse(request.body); requests.push(data);
        return { json: async () => data.teamChoices.sourceTeam ? { ok: true, count: 1 } : {
            ok: true, needsTeams: true, requiredTeams: [{ key: 'sourceTeam', name: 'External Team', kind, candidates: [{ id: 'EXISTING', name: 'Existing Team' }], allOptions: [{ id: 'EXISTING', name: 'Existing Team' }, { id: 'DANANG', name: 'Đà Nẵng' }] }]
        } };
    }
};
vm.createContext(context);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../Scripts/web-match-import.js'), 'utf8'), context);


context.fetch = async (_, request) => {
    const data = JSON.parse(request.body); requests.push(data);
    return { json: async () => data.action === 'leagues' ? { ok: true, leagues: [] } : data.action === 'search' ? {
        ok: true, snapshot: 'selection', matches: [{Id:'fixture-one',Time:'20:00 31/12/2026',Home:'Home',Away:'Away'}]
    } : {ok:true,count:1} };
};
(async () => {
    await context.window.webMatchOpen();
    assert.equal(requests.length, 0, "Opening source selector must not call either API");
    await el(process.env.WEB_MATCH_TEST_SOURCE === "api-football" ? "webMatchSourceFootball" : "webMatchSourceOdds").onclick();
    el('webMatchLeague').value='soccer_epl';
    const first=el('webMatchDays').children[0].dataset.day;
    const third=el('webMatchDays').children[2].dataset.day;
    el('webMatchDays').children[2].onclick();
    await el('webMatchSearch').onclick();
    assert.deepEqual(requests[1].dates, [first,third]);
    assert.equal(requests.length,2,'Search must not request odds/create');
    assert(el('webMatchList').children[0].children[0].children[1].textContent.includes('31/12/2026'),'Show date as well as time');
    await el('webMatchCreate').onclick();
    assert.equal(requests[2].action,'create');
    assert.deepEqual(requests[2].ids,['fixture-one']);
    assert.equal(requests[2].snapshot,'selection');
    assert(requests.every(r => r.source === (process.env.WEB_MATCH_TEST_SOURCE || 'the-odds-api')), 'Keep chosen source on every request');
    el('webMatchBack').onclick();
    el('webMatchDays').children[0].onclick();
    el('webMatchDays').children[2].onclick();
    await el('webMatchSearch').onclick();
    assert.equal(requests.length,3,'Empty day selection must not send a request');
    el('webMatchChangeSource').onclick();
    await el('webMatchSourceFootball').onclick();
    assert.equal(requests[3].source, 'api-football');
    assert.equal(el('webMatchList').children.length,0,'Switching source clears old selection');
    console.log('Multiple day selection and list-first flow checks passed.');
})().catch(error => {console.error(error);process.exitCode=1;});
