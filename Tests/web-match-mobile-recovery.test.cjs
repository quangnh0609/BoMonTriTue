const fs = require('fs');
const vm = require('vm');
const path = require('path');
const assert = require('assert/strict');
const documentListeners = new Map(), windowListeners = new Map(), elements = new Map();
const add = (map, name, callback) => { if (!map.has(name)) map.set(name, new Set()); map.get(name).add(callback); };
const remove = (map, name, callback) => map.get(name)?.delete(callback);
const emit = (map, name) => [...(map.get(name) || [])].forEach(callback => callback());
const context = {
    AbortController,
    navigator: { onLine: true },
    setTimeout: callback => queueMicrotask(callback),
    document: {
        hidden: false,
        getElementById(id) { if (!elements.has(id)) elements.set(id, {}); return elements.get(id); },
        addEventListener: (name, callback) => add(documentListeners, name, callback),
        removeEventListener: (name, callback) => remove(documentListeners, name, callback)
    },
    window: {
        webMatchToken: 'token',
        addEventListener: (name, callback) => add(windowListeners, name, callback),
        removeEventListener: (name, callback) => remove(windowListeners, name, callback)
    }
};
const source = fs.readFileSync(path.join(__dirname, '../Scripts/web-match-import.js'), 'utf8');
vm.createContext(context);
vm.runInContext(source.replace('    function selected()', '    window.testApi = api;\n    function selected()'), context);
let calls;
function responses(items) {
    calls = [];
    context.fetch = async (url, options) => {
        const payload = options.body && JSON.parse(options.body); calls.push({url,payload});
        assert(items.length, 'Unexpected extra request');
        const next = items.shift();
        if (next instanceof Error) throw next;
        if (typeof next === 'function') return next(options);
        return {json:async () => next};
    };
}
async function rejected(promise) { try { await promise; } catch (error) { return error; } throw new Error('Expected rejection'); }
const flush = () => new Promise(resolve => setImmediate(resolve));
(async () => {
    responses([new Error('network lost'), {ok:true,previewToken:'saved',matches:[]}]);
    let result = await context.window.testApi({action:'preview',ids:['one'],snapshot:'snapshot'});
    assert.equal(result.previewToken,'saved');
    assert.deepEqual(calls.map(call=>call.payload.action),['preview','status']);
    assert.match(calls[0].payload.operationId,/^[a-f0-9]{32}$/);
    assert.equal(calls[0].payload.operationId,calls[1].payload.operationId);

    responses([new Error('screen off'), {ok:true,operationPending:true}, {ok:true,count:2}]);
    result = await context.window.testApi({action:'create',ids:['one','two'],edits:{one:[],two:[]}});
    assert.equal(result.count,2);
    assert.deepEqual(calls.map(call=>call.payload.action),['create','status','status'],'Never replay an uncertain import');

    responses([new Error('network'), {ok:false,code:'WEB_MATCH_OPERATION_MISSING'}]);
    assert((await rejected(context.window.testApi({action:'create'}))).message.includes('Kiểm tra danh sách'));
    assert.equal(calls.filter(call=>call.payload.action==='create').length,1);

    responses([new Error('not received'), {ok:false,code:'WEB_MATCH_OPERATION_MISSING'}, {ok:true,snapshot:'new'}]);
    result = await context.window.testApi({action:'search',dates:['2026-11-14']});
    assert.equal(result.snapshot,'new');
    assert.deepEqual(calls.map(call=>call.payload.action),['search','status','search']);
    assert.equal(calls[0].payload.operationId,calls[2].payload.operationId,'Safe read retry uses same receipt key');

    context.document.hidden = true;
    responses([new Error('sleep'), {ok:true,matches:[],previewToken:'awake'}]);
    const sleeping = context.window.testApi({action:'preview'});
    await flush();
    assert.equal(calls.length,1,'Wait until visible before reconnecting');
    context.document.hidden = false; emit(documentListeners,'visibilitychange');
    assert.equal((await sleeping).previewToken,'awake');

    context.navigator.onLine = false;
    responses([new Error('offline'), {ok:true,leagues:[]}]);
    const offline = context.window.testApi({action:'leagues'});
    await flush(); assert.equal(calls.length,1,'Wait for online');
    context.navigator.onLine = true; emit(windowListeners,'online');
    assert.deepEqual((await offline).leagues,[]);

    responses([options => new Promise((resolve,reject)=>options.signal.addEventListener('abort',()=>reject(new Error('stale connection')))), {ok:true,count:1}]);
    const stale = context.window.testApi({action:'create'});
    context.document.hidden = true; emit(documentListeners,'visibilitychange');
    context.document.hidden = false; emit(documentListeners,'visibilitychange');
    assert.equal((await stale).count,1,'Wake interrupts stale socket and reads saved result');
    assert.deepEqual(calls.map(call=>call.payload.action),['create','status']);

    responses([new Error('sleep'), ...Array.from({length:15},()=>({ok:true,operationPending:true})), {ok:true,count:4}]);
    assert.equal((await context.window.testApi({action:'create'})).count,4,'Long pending imports keep polling without resubmitting');
    assert.equal(calls.filter(call=>call.payload.action==='create').length,1);

    responses([{ok:false,message:'API quota exhausted'}]);
    assert.equal((await rejected(context.window.testApi({action:'preview'}))).message,'API quota exhausted');
    assert.equal(calls.length,1,'Do not retry real API errors');
    responses([{ok:true,operationPending:true},{ok:true,count:3}]);
    assert.equal((await context.window.testApi({action:'create'})).count,3,'Pending duplicate reads receipt');
    console.log('Mobile sleep/wake, offline recovery and no-duplicate-create checks passed.');
})().catch(error => { console.error(error); process.exitCode=1; });
