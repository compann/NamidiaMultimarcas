import assert from 'node:assert/strict';
import {createRequire} from 'node:module';
const require = createRequire(import.meta.url);
let lib = {};
try { lib = require('./pedido.js'); } catch(e) { if(e.code!=='MODULE_NOT_FOUND') throw e; }
assert.equal(typeof lib.consultarPedido, 'function', 'Validação remota deve existir');
let sent;
const api = {rpc: async (name,args)=>{
  assert.equal(name,'validar_pedido'); sent=args;
  return {data:{ok:true,itens:[{id:'1',size:'P',qty:2,nome:'Oficial',preco:90,imagem:''}]},error:null};
}};
const result = await lib.consultarPedido(api,[{id:'1',size:'P',qty:2,preco:1,estoque:{P:8}}]);
assert.deepEqual(sent,{itens:[{id:'1',size:'P',qty:2}]});
assert.equal(result.itens[0].preco,90);
assert.deepEqual(await lib.consultarPedido({rpc:async()=>({data:{ok:false},error:null})},[{id:'1',size:'P',qty:2}]),{ok:false});
await assert.rejects(lib.consultarPedido({rpc:async()=>({error:new Error('offline')})},[{id:'1',size:'P',qty:1}]));
await assert.rejects(lib.consultarPedido({rpc:async()=>({data:null,error:null})},[{id:'1',size:'P',qty:1}]));
assert.deepEqual(await lib.consultarPedido(api,[{id:'1',size:'P',qty:-1}]),{ok:false});
console.log('Validação da sacola: somente campos necessários, preço oficial e falha segura OK.');
