# Segurança da loja

O catálogo continua hospedado no GitHub Pages. O banco permanece no Supabase.
A URL e a chave `anon` são públicas por projeto; nunca publique chaves secretas,
`service_role`, senhas ou tokens de sessão, inclusive no histórico Git.

## Controles

- `produtos`: leitura e alterações diretas apenas para o administrador autorizado por ID,
  não para qualquer pessoa autenticada. Fotos: escrita com a mesma autorização.
- A lista de administradores fica no esquema privado `loja_privada`, sem acesso aos clientes.
- `catalogo_publico()`: somente produtos ativos, campos de catálogo e tamanhos com saldo positivo.
- `validar_pedido(itens)`: consulta sem reserva/baixa. Soma linhas duplicadas, verifica
  tamanho, quantidade e produto ativo, e retorna os dados oficiais do pedido, sem estoque.
- Limites de entrada: 100 linhas e 99 unidades por produto/tamanho. Falhas de rede
  impedem novas adições e envio. O painel continua sendo o único responsável pela baixa.
- Cadastros públicos devem permanecer desabilitados em Authentication → Sign In / Providers.
- A coluna `promocao` começa desmarcada: o administrador escolhe os produtos no painel.

## Limites importantes

A validação de disponibilidade pode permitir inferir limites por tentativas repetidas;
não é promessa de sigilo absoluto sobre a disponibilidade. Ela não entrega a tabela de estoque.
Se houver abuso, acrescentar uma camada com limitação por IP/CAPTCHA e monitoramento.

O pedido é uma mensagem editável no WhatsApp, não uma compra paga/confirmada. Conferir
preços e estoque antes de aceitar pagamento; não tratar a mensagem como registro inviolável.
A conferência não reserva unidades entre clientes. Para venda automática seria necessário
implementar pedidos persistidos, reserva transacional e confirmação de pagamento.

Ativar MFA na conta Supabase/GitHub e na conta administradora é recomendável e exige
configuração pelo responsável. Manter backups e revisar acessos periodicamente.

## Instalação / manutenção

1. Em projeto novo: `supabase-setup.sql`, depois criar a única conta administradora.
2. Executar `supabase-security.sql` como postgres. Na primeira execução exige uma única
   conta; nas próximas preserva a lista de administradores existente.
3. Desabilitar cadastros públicos e publicar o frontend compatível com as RPCs.
4. Nunca restaurar políticas genéricas `authenticated using (true)`.

Testes locais: `node estoque.test.mjs`, `node pedido.test.mjs`, `node ui.test.mjs`.
Teste somente de leitura das APIs reais: `node security.test.mjs`.
Teste transacional com perfis/fixture revertidos: `security-roles.test.sql` no SQL Editor.
