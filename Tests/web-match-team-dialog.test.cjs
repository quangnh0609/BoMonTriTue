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
const context = {
    document: { getElementById: el, createElement: () => new Element(), body: { style: {} }, addEventListener() {} },
    window: { webMatchToken: 'token', location: { reload() { reloads++; } } },
    fetch: async (_, request) => {
        const data = JSON.parse(request.body); requests.push(data);
        return { json: async () => data.teamChoices.sourceTeam ? { ok: true, count: 1 } : {
            ok: true, needsTeams: true, requiredTeams: [{ key: 'sourceTeam', name: 'External Team' }],
            teams: [{ id: 'EXISTING', name: 'Existing Team' }]
        } };
    }
};
vm.createContext(context);
vm.runInContext(fs.readFileSync(path.join(__dirname, '../Scripts/web-match-import.js'), 'utf8'), context);

(async () => {
    await el('webMatchCreate').onclick();
    assert.equal(reloads, 0, 'Do not close or reload while teams need resolution');
    assert.equal(el('webMatchTeams').classList.contains('hidden'), false);
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests.length, 1, 'No implicit new-team choice');
    let select = el('webMatchTeamList').children[0].children[2];
    assert.equal(select.options[1].value, '__new__');
    select.value = '__new__'; select.onchange();
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests.length, 1, 'Require a team code before creating');
    const codeInput = el('webMatchTeamList').children[0].children[3];
    assert.equal(codeInput.hidden, false);
    codeInput.value = 'NEW_FC'; codeInput.oninput();
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests[1].teamChoices.sourceTeam, '__new__');
    assert.equal(requests[1].newTeamCodes.sourceTeam, 'NEW_FC');
    assert.equal(reloads, 1);
    // Explicitly choose an existing team, rather than creating another.
    select.value = 'EXISTING'; select.onchange();
    await el('webMatchTeamsCreate').onclick();
    assert.equal(requests[2].teamChoices.sourceTeam, 'EXISTING');
    assert.equal(reloads, 2);
    console.log('Team resolution dialog regression checks passed.');
})().catch(error => { console.error(error); process.exitCode = 1; });
