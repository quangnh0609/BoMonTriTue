const fs = require('fs');
const vm = require('vm');
const path = require('path');
const assert = require('assert/strict');
const script = fs.readFileSync(path.join(__dirname, '../Scripts/web-match-import.js'), 'utf8');
const elements = new Map();
const context = {
    document: { getElementById(id) { if (!elements.has(id)) elements.set(id, {}); return elements.get(id); }, addEventListener() {} },
    window: { webMatchToken: 'old' }
};
vm.createContext(context);
vm.runInContext(script.replace('    function selected()', '    window.testApi = api;\n    function selected()'), context);
const changed = { ok: false, code: 'WEB_MATCH_TOKEN_CHANGED' };
async function run(responses) {
    const calls = [];
    context.fetch = async (url, options) => {
        calls.push({ url, options });
        const result = responses.shift();
        if (result instanceof Error) throw result;
        assert(result, 'Unexpected extra retry');
        return { json: async () => result };
    };
    let error;
    try { await context.window.testApi({ action: 'create', ids: ['one'], snapshot: 'saved' }); } catch (e) { error = e; }
    return { calls, error };
}
(async () => {
    let result = await run([changed, { ok: true, token: 'new' }, { ok: true, count: 1 }]);
    assert.equal(result.error, undefined);
    assert.equal(result.calls.length, 3);
    assert.equal(result.calls[1].url, 'WebMatches.aspx?action=token');
    assert.equal(result.calls[1].options.cache, 'no-store');
    const first = JSON.parse(result.calls[0].options.body), retry = JSON.parse(result.calls[2].options.body);
    assert.equal(first.token, 'old');
    assert.deepEqual(retry, { ...first, token: 'new' });
    result = await run([changed, { ok: true, token: 'newer' }, changed]);
    assert(result.error);
    assert.equal(result.calls.length, 3, 'Repeated mismatch must stop');
    result = await run([new Error('timeout'), {ok:false,code:'WEB_MATCH_OPERATION_MISSING'}]);
    assert(result.error);
    assert.equal(result.calls.length, 2, 'Only check status for an uncertain create');
    assert.equal(JSON.parse(result.calls[1].options.body).action, 'status', 'Never replay an uncertain create');
    result = await run([changed, { ok: false, message: 'Login required' }]);
    assert.equal(result.error.message, 'Login required');
    assert.equal(result.calls.length, 2);
    result = await run([changed, { ok: true, token: 'fresh' }, { ok: false, message: 'Snapshot expired' }]);
    assert.equal(result.error.message, 'Snapshot expired');
    assert.equal(result.calls.length, 3);
    console.log('Session recovery, bounded retry, login and snapshot expiry checks passed.');
})().catch(error => { console.error(error); process.exitCode = 1; });
