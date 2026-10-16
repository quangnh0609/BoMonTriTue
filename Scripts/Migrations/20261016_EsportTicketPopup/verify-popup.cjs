// Local regression checks only: no server or database access.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../../..');
const read = file => fs.readFileSync(path.join(root, file), 'utf8');
const shared = read('ucTicketMatch.ascx').match(/<script>([\s\S]*?)<\/script>/)[1];
const football = read('matches.aspx').match(/function openTicketMatchModal\(matchId, matchLabel\) \{[\s\S]*?(?=\s*function openResultMatchModal)/)[0];
const calls = [];
const handlers = {};
const elements = new Map();
const context = {
    document: {
        getElementById(id) {
            if (!elements.has(id)) elements.set(id, {
                style: {}, classList: { add() {}, remove() {} }, innerHTML: ''
            });
            return elements.get(id);
        },
        documentElement: { scrollTop: 0 }, body: { style: {} },
        addEventListener(event, handler) { handlers[event] = handler; }
    },
    window: { pageYOffset: 0, scrollTo() {} },
    confirm: () => true,
    fetch(url, options) {
        calls.push({ url, body: JSON.parse(options.body) });
        return Promise.resolve({ json: () => Promise.resolve({ d: [], isSuccess: 1 }) });
    }
};
vm.createContext(context);
vm.runInContext(shared, context);

async function run() {
    context.openTicketMatchModal('E550', 'Esports', 'esport');
    assert.equal(calls.at(-1).body.ticketType, 'esport');
    context.loadTicketMatchTable();
    assert.equal(calls.at(-1).body.ticketType, 'esport');

    // matches.aspx overrides the shared opener after the control script loads.
    vm.runInContext(football, context);
    context.openTicketMatchModal('123', 'Football');
    assert.equal(calls.at(-1).url, 'GetTicketList.aspx');
    assert.equal(calls.at(-1).body.ticketType, 'football');
    assert.equal(calls.at(-1).body.match, '123');
    for (const action of ['delete', 'clear']) {
        const button = { dataset: { match: '123', userid: '7', code: '21', ticket: 'O' } };
        handlers.click({ target: { closest: selector => selector === `.tm-btn-${action}` ? button : null } });
        await new Promise(resolve => setImmediate(resolve));
        assert.equal(calls.at(-1).url, 'GetTicketList.aspx');
        assert.equal(calls.at(-1).body.ticketType, 'football');
        assert.equal(calls.at(-1).body.match, '123');
    }

    vm.runInContext(shared.slice(shared.indexOf('function openTicketMatchModal'), shared.indexOf('function closeTicketMatchModal')), context);
    context.openTicketMatchModal('CHAMP|S1|20261016', 'Champion');
    assert.equal(calls.at(-1).url, 'GetChampionTicketList.aspx');
    assert.equal(calls.at(-1).body.ticketType, undefined);
    context.openTicketMatchModal('123', 'Legacy caller');
    assert.equal(calls.at(-1).body.ticketType, '');

    const baseline = read('docs/performance/bet-ticket-result-current.sql');
    const sql = fs.readFileSync(path.join(__dirname, 'bet_ticket_result.sql'), 'utf8');
    const settlement = source => source.slice(source.indexOf('\t-- result')).trim().replace(/\s+GO$/, '');
    assert.equal(settlement(sql), settlement(baseline));
    console.log('PASS: Esports, football override, delete/clear reloads, champion routing, legacy mode and unchanged settlement/output SQL.');
}
run().catch(error => { console.error(error); process.exitCode = 1; });
