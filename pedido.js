async function consultarPedido(client, sacola) {
  if (!Array.isArray(sacola) || !sacola.length || sacola.length > 100 ||
    sacola.some(i => !i || !Number.isSafeInteger(i.qty) || i.qty < 1 || i.qty > 99 || typeof i.size !== 'string')) return {ok:false};
  const {data, error} = await client.rpc('validar_pedido', {
    itens: sacola.map(i => ({id:String(i.id),size:i.size,qty:i.qty}))
  });
  if (error) throw error;
  if (!data || typeof data.ok !== 'boolean' || (data.ok && !Array.isArray(data.itens))) throw new Error('Resposta inválida');
  return data;
}
if (typeof module !== 'undefined') module.exports = {consultarPedido};
