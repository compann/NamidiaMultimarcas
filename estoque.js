function normalizarEstoque(valor, tamanhos = []) {
  const origem = valor && typeof valor === 'object' ? valor : {};
  return Object.fromEntries(tamanhos.map(t => {
    const q = Number(origem[t]);
    return [t, Number.isSafeInteger(q) && q > 0 ? q : 0];
  }));
}
function disponivel(estoque, tamanho) { return Number(estoque?.[tamanho]) > 0; }
function restanteEstoque(produto, tamanho, sacola) {
  if (!produto || !produto.tamanhos.includes(tamanho)) return 0;
  const limite = normalizarEstoque(produto.estoque, produto.tamanhos)[tamanho];
  const usado = sacola.filter(i => String(i.id) === String(produto.id) && i.size === tamanho)
    .reduce((n, i) => n + (Number.isSafeInteger(i.qty) && i.qty > 0 ? i.qty : limite), 0);
  return Math.max(0, limite - usado);
}
function validarSacola(sacola, produtos) {
  const validos = [];
  for (const item of sacola) {
    const p = produtos.find(p => String(p.id) === String(item.id));
    const restante = restanteEstoque(p, item.size, validos);
    const qty = Number.isSafeInteger(item.qty) && item.qty > 0 ? Math.min(item.qty, restante) : 0;
    if (qty) validos.push({...item, qty});
  }
  return validos;
}
if (typeof module !== 'undefined') module.exports = {normalizarEstoque, disponivel, restanteEstoque, validarSacola};
