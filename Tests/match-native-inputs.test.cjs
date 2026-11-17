const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const path = require('path');
const read = name => fs.readFileSync(path.join(__dirname, '..', name), 'utf8');
const match = read('ucAddMatch.ascx'), esport = read('ucAddEsport.ascx'), champion = read('ucAddChampion.ascx');
function extract(source, name) {
 const result = source.match(new RegExp('    function ' + name + '\\([^]*?\\n    }'));
 assert(result, name + ' exists'); return result[0];
}
for (const source of [match, esport]) {
 const ctx = {}; vm.createContext(ctx); vm.runInContext(extract(source, 'formatDecimal'),ctx);
 for (const [value, expected] of [['1,75','1.75'],['0,9','0.90'],['-2,25','-2.25'],['2.15','2.15'],['','']]) {
  const input = {value}; ctx.formatDecimal(input); assert.equal(input.value,expected);
 }
 assert(!source.includes('NumericKeyboard.attachToFields'), 'Create forms do not bind custom keyboard');
}
assert(!/h2_|Hiệp 2/.test(match), 'No H2 form or collection fields');
for (const tag of match.match(/<asp:TextBox ID="(?:h1|ft)_[^>]+>/g)) {
 assert(tag.includes('data-line-picker') || tag.includes('inputmode="decimal"'), 'Football numeric fields use decimal keyboard');
}
for (const tag of esport.match(/<input type="text" id="g\d+_[^>]+>/g)) {
 if (/dragon|_(first|third|five|ten|win)_/.test(tag)) {
  assert(!tag.includes('data-line-picker') && !tag.includes('readonly'), 'Dragon/kill/win fields editable');
  assert(tag.includes('inputmode="decimal"'), 'Dragon/kill/win uses native decimal keyboard');
 }
}
const elements = new Map();
const ctx = {document:{getElementById:id=>elements.get(id)}};
vm.createContext(ctx);
vm.runInContext(esport.match(/    const GAME_FIELDS = [^]*?;/)[0] + esport.match(/    const ESPORT_DEFAULT_RATE_FIELDS = [^]*?;/)[0] + extract(esport,'collectGameData'),ctx);
elements.set('g1_first_home_win',{value:'1,85'});
elements.set('g1_dragon_ou_line',{value:'2,75'});
const collected=ctx.collectGameData(1);
assert.equal(collected.first_home_win,'1.85'); assert.equal(collected.dragon_ou_line,'2.75');
assert.equal(collected.dragon_ou_over_win,'0.9');
const champ={}; vm.createContext(champ); vm.runInContext(extract(champion,'normalizeChampionRate'),champ);
assert.equal(champ.normalizeChampionRate('3,25'),'3.25');
assert(!read('Scripts/web-match-import.js').includes('Sửa trực tiếp mốc và Rate'), 'Preview guidance removed');
for (const file of ['ucAddMatch.ascx','ucAddEsport.ascx','ucAddChampion.ascx']) {
 for (const script of read(file).matchAll(/<script(?:\s[^>]*)?>([^]*?)<\/script>/g)) {
  if (!script[0].startsWith('<script runat=')) new vm.Script(script[1],{filename:file});
 }
}
console.log('Native decimal inputs, comma handling, H1/FT-only forms, esports numeric markets and preview message checks passed.');
