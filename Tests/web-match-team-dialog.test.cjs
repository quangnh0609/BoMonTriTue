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
const requests = [];
let reloads = 0;
const kind = process.env.WEB_MATCH_TEST_KIND || 'đội';
const context = {
    document: { getElementById: el, createElement: () => new Element(), body: { style: {} }, addEventListener() {} },
    window: { webMatchToken: 'token', location: { reload() { reloads++; } } },
    fetch: async (_, request) => {
        const data = JSON.parse(request.body); requests.push(data);
        return { json: async () => data.teamChoices.sourceTeam ? { ok: true, count: 1 } : {
            ok: true, needsTeams: true, requiredTeams: [{ key: 'sourceTeam', name: 'External Team', kind, candidates: [{ id: 'EXISTING', name: 'Existing Team' }], allOptions: [{ id: 'EXISTING', name: 'Existing Team' }, { id: 'DANANG', name: 'Đà Nẵng', apiFootballName:'Danang API', theOddsApiName:'Danang Odds' }] }]
        } };
    }
};
vm.createContext(context);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../Scripts/web-match-import.js'), 'utf8'), context);

(async () => {
    await el('webMatchCreate').onclick();
    assert.equal(reloads, 0, 'Do not close or reload while teams need resolution');
    assert.equal(el('webMatchTeams').classList.contains('hidden'), false);
    assert(el('webMatchTeamList').children[0].children[0].textContent.startsWith(kind === 'giải' ? 'Giải đấu:' : 'Đội:'));
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests.length, 1, 'No implicit new-team choice');
    const row = el('webMatchTeamList').children[0];
    const [createMode, existingMode] = row.children[1].children;
    const codeInput = row.children[2];
    const [search, selection, results] = row.children[3].children;
    assert.equal(codeInput.hidden, true);
    assert.equal(results.children.length, 2, 'Show clickable existing records');
    for (const term of ['Danang API', 'Danang Odds', 'da nang', 'DANANG']) {
        search.value = term; search.oninput();
        assert.equal(results.children.length, 1);
        assert.equal(results.children[0].textContent, 'Đà Nẵng (DANANG)');
    }
    results.children[0].onclick();
    assert(selection.textContent.includes('DANANG'), 'Click selects the search result directly');
    search.value = 'not-found'; search.oninput();
    assert(results.children[0].textContent.includes('Không tìm thấy'));
    search.value = ''; search.oninput();
    assert.equal(results.children.length, 2);
    createMode.onclick();
    assert.equal(codeInput.hidden, false);
    assert.equal(row.children[3].hidden, true);
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests.length, 1, 'Require a code before creating');
    codeInput.value = 'NEW_FC'; codeInput.oninput();
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests[1].teamChoices.sourceTeam, '__new__');
    assert.equal(requests[1].newTeamCodes.sourceTeam, 'NEW_FC');
    assert.equal(reloads, 1);
    existingMode.onclick();
    assert.equal(codeInput.hidden, true);
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests[2].teamChoices.sourceTeam, 'DANANG', 'Switching modes preserves the selected record');
    assert.equal(reloads, 2);
    console.log('Team resolution dialog regression checks passed.');
})().catch(error => { console.error(error); process.exitCode = 1; });
