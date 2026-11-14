const fs = require('fs');
const path = require('path');
const vm = require('vm');
const assert = require('assert/strict');
const page = fs.readFileSync(path.join(__dirname, '../matches.aspx'), 'utf8');
const endpoint = fs.readFileSync(path.join(__dirname, '../WebMatches.aspx'), 'utf8');
assert(endpoint.includes('EnableSessionState="ReadOnly"'), 'Long API request must not own exclusive login session lock');
assert(!/Session\["WebMatch\w+"\]\s*=(?!=)/.test(endpoint), 'Import state writes must not mutate ASP.NET login session');
assert(endpoint.includes('lock (importState.SyncRoot)'), 'Serialize imports separately from page navigation');
const status = endpoint.indexOf('if (action == "status")');
assert(status >= 0 && status < endpoint.indexOf('lock (importState.SyncRoot)'), 'Status polling bypasses long import lock');
assert(page.includes('scriptManager.IsInAsyncPostBack) return;'), 'Do not reload full catalogs on partial postbacks');
const start = page.indexOf('        // Load dữ liệu cho datalist');
const end = page.indexOf('        // Đóng dropdown khi click bên ngoài', start);
const nodes = new Map();
const node = id => {
    if (!nodes.has(id)) nodes.set(id, {innerHTML:'',value:'',classList:{add(){},remove(){}}});
    return nodes.get(id);
};
const onLoad = [];
const context = {
    document:{getElementById:node}, window:{addEventListener:(name,callback)=>{if(name==='load')onLoad.push(callback);}},
    dataTeam:[],dataSeason:[],dataTeamAll:[{team:'A',team_name:'Alpha'},{team:'B',team_name:'Beta'}],
    dataSeasonAll:[{season:'S',season_name:'Season'}]
};
vm.createContext(context); vm.runInContext(page.slice(start,end),context);
onLoad.forEach(callback=>callback());
assert.equal(node('teamDropdown').innerHTML,'','Initial page must not build all team option DOM');
assert.equal(node('seasonDropdown').innerHTML,'','Initial page must not build all league option DOM');
context.showTeamDropdown(); assert(node('teamDropdown').innerHTML.includes('Alpha'));
assert.equal(node('seasonDropdown').innerHTML,'','Opening teams must not build leagues');
context.showSeasonDropdown(); assert(node('seasonDropdown').innerHTML.includes('Season'));
node('filterTeamSearch').value='Beta'; context.filterTeamOptions();
assert(node('teamDropdown').innerHTML.includes('Beta') && !node('teamDropdown').innerHTML.includes('Alpha'),'Filtering must preserve the filtered lazy dropdown');
console.log('Read-only import endpoint and lazy page dropdown checks passed.');
