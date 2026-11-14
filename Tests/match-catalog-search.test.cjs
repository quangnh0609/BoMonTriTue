const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');
const source = fs.readFileSync(path.join(__dirname, '../ucAddMatch.ascx'), 'utf8');
function functionSource(name) {
    const start = source.indexOf('    function ' + name + '(');
    const end = source.indexOf('\n    }', start) + 6;
    assert(start >= 0 && end > start);
    return source.slice(start, end);
}
const elements = {};
const context = {
    dataSeason: [{season:'EURO',season_name:'Vô địch châu Âu'}, {season:'EURO_Q',season_name:'Vô địch châu Âu vòng loại'}],
    dataTeam: [{team:'DN',team_name:'Đà Nẵng',the_odds_api_name:'Danang Odds',api_football_name:'Da Nang FC'}, {team:'DNA',team_name:'Đà Nẵng trẻ'}],
    document: { getElementById: id => elements[id] },
    setTimeout: callback => callback()
};
vm.createContext(context);
vm.runInContext(['removeAccents','resolveMatchSelection','isValidSelection','matchSelectionMessage','validateSelection','selectItem'].map(functionSource).join('\n'), context);
assert.equal(context.resolveMatchSelection('Danang Odds','listHome').team,'DN');
assert.equal(context.resolveMatchSelection('Da Nang FC','listWay').team,'DN');
assert.equal(context.resolveMatchSelection('da nang','listHome').team,'DN');
assert.equal(context.resolveMatchSelection('  vo dich   chau au ','listSeason').season,'EURO');
assert.equal(context.resolveMatchSelection('EURO','listSeason').season,'EURO');
assert.equal(context.resolveMatchSelection('da','listHome'),null,'Ambiguous partial names require explicit selection');
assert.equal(context.isValidSelection('Đà Nẵng','listWay'),true);
assert.equal(context.isValidSelection('unknown','listSeason'),false);
let hidden;
elements.msg_home = {classList:{toggle: (_,value) => hidden=value}};
elements.listHome = {classList:{add(){}}};
context.validateSelection({id:'ctl_AddMatch_home',value:'da nang'},'listHome');
assert.equal(hidden,true,'Resolve message by field, regardless of ASP.NET client ID prefix');
assert(source.includes('oninput="filterData(this, \'listSeason\')"'));
assert(source.includes('oninput="filterData(this, \'listHome\')"'));
assert(source.includes('oninput="filterData(this, \'listWay\')"'));
const page=fs.readFileSync(path.join(__dirname,'../matches.aspx'),'utf8');
assert(page.includes('ScriptManager.RegisterStartupScript(this, this.GetType(), "InitData", script, true)'));
console.log('Match catalog search regression checks passed.');
