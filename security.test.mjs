import assert from 'node:assert/strict';
import fs from 'node:fs';
const config = fs.readFileSync(new URL('./supabase-config.js', import.meta.url), 'utf8');
const url = config.match(/SUPABASE_URL = "([^"]+)"/)[1];
const key = config.match(/SUPABASE_ANON_KEY = "([^"]+)"/)[1];
const headers = {apikey:key, 'Content-Type':'application/json'};
const direct = await fetch(`${url}/rest/v1/produtos?select=id,estoque&limit=1`, {headers});
assert.ok(!direct.ok || (await direct.json()).length === 0, 'Visitante não pode ler estoque diretamente');
const catalogResponse = await fetch(`${url}/rest/v1/rpc/catalogo_publico`, {method:'POST',headers,body:'{}'});
assert.equal(catalogResponse.status, 200);
const catalog = await catalogResponse.json();
assert.ok(catalog.length > 0);
for (const p of catalog) {
  assert.equal('estoque' in p, false);
  assert.ok(Array.isArray(p.tamanhos));
  assert.equal(typeof p.promocao, 'boolean');
}
for (const itens of [null,{},[],[{id:'1',size:'M',qty:-1}],[{id:'1',size:'M',qty:1.5}],[{id:'1',size:'M',qty:1000000}],[{id:'not-an-id',size:'M',qty:1}]]) {
  const r = await fetch(`${url}/rest/v1/rpc/validar_pedido`, {method:'POST',headers,body:JSON.stringify({itens})});
  assert.equal(r.status,200);
  assert.deepEqual(await r.json(),{ok:false});
}
const available = catalog.find(p=>p.tamanhos.length);
if (available) {
  const r = await fetch(`${url}/rest/v1/rpc/validar_pedido`, {method:'POST',headers,body:JSON.stringify({itens:[{id:String(available.id),size:available.tamanhos[0],qty:1,preco:0.01,nome:'forjado'}]})});
  const result = await r.json();
  assert.equal(result.ok,true);
  assert.equal(Number(result.itens[0].preco),Number(available.preco));
  assert.equal(result.itens[0].nome,available.nome);
  assert.equal('estoque' in result.itens[0],false);
}
console.log('Segurança pública: estoque privado, catálogo seguro, entradas inválidas rejeitadas e preços oficiais confirmados.');
