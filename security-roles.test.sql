-- Executar no SQL Editor como postgres APÓS supabase-security.sql.
-- Todos os dados de teste são revertidos; não altera produtos reais.
begin;
insert into public.produtos(id,nome,categoria,preco,tamanhos,estoque,promocao,ativo)
overriding system value values (900000000000000001,'TESTE TRANSACIONAL','Teste',90,array['P','M','G'],'{"P":2,"M":0,"G":4}',true,true);
do $$ declare c record; r jsonb; begin
  select * into c from public.catalogo_publico() where id=900000000000000001;
  assert c.tamanhos = array['P','G'], 'Tamanhos zerados não devem ser públicos';
  assert c.promocao, 'Promoção precisa refletir seleção do administrador';
  assert not (to_jsonb(c) ? 'estoque'), 'Catálogo não pode expor estoque';
  r := public.validar_pedido('[{"id":"900000000000000001","size":"P","qty":2,"preco":1}]');
  assert (r->>'ok')::boolean and (r->'itens'->0->>'preco')::numeric=90, 'Validar quantidade e preço oficial';
  assert public.validar_pedido('[{"id":"900000000000000001","size":"P","qty":2},{"id":"900000000000000001","size":"P","qty":1}]')='{"ok":false}', 'Duplicatas não podem ultrapassar estoque';
  assert public.validar_pedido('[{"id":"900000000000000001","size":"M","qty":1}]')='{"ok":false}', 'Tamanho zerado deve ser rejeitado';
  assert public.validar_pedido('[{"id":"900000000000000001","size":"P","qty":0}]')='{"ok":false}';
  assert public.validar_pedido('[{"id":"900000000000000001","size":"P","qty":1.5}]')='{"ok":false}';
  assert public.validar_pedido('[{"id":"900000000000000001","size":"P","qty":"1"}]')='{"ok":false}';
  assert public.validar_pedido('[null]')='{"ok":false}';
  assert public.validar_pedido('{}')='{"ok":false}';
  assert public.validar_pedido('[]')='{"ok":false}';
end $$;
update public.produtos set ativo=false where id=900000000000000001;
do $$ begin
  assert not exists(select from public.catalogo_publico() where id=900000000000000001);
  assert public.validar_pedido('[{"id":"900000000000000001","size":"P","qty":1}]')='{"ok":false}';
end $$;
select set_config('request.jwt.claim.sub',(select user_id::text from loja_privada.administradores limit 1),true);
set local role authenticated;
do $$ begin
  assert public.eh_admin(), 'Conta autorizada deve ter acesso';
  assert exists(select from public.produtos where id=900000000000000001), 'Admin pode ler estoque';
  update public.produtos set promocao=false where id=900000000000000001;
  assert found, 'Admin pode editar';
end $$;
reset role;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000000',true);
set local role authenticated;
do $$ begin
  assert not public.eh_admin();
  assert not exists(select from public.produtos), 'Outra conta não pode ler estoque';
  update public.produtos set nome='NEGADO' where id=900000000000000001;
  assert not found, 'Outra conta não pode editar';
  assert not has_table_privilege(current_user,'public.produtos','TRUNCATE');
end $$;
reset role;
set local role anon;
do $$ begin
  assert not has_table_privilege(current_user,'public.produtos','SELECT');
  assert not has_table_privilege(current_user,'public.produtos','INSERT');
  assert not has_table_privilege(current_user,'public.produtos','UPDATE');
  assert not has_table_privilege(current_user,'public.produtos','DELETE');
  assert not has_function_privilege(current_user,'public.eh_admin()','EXECUTE');
  assert exists(select from public.catalogo_publico()), 'Catálogo público deve continuar funcionando';
end $$;
reset role;
rollback;
select 'OK: catálogo, estoque, duplicatas, preços, promoção e isolamento de permissões' as resultado;
