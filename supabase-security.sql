-- Executar como postgres no SQL Editor. Preserva produtos, fotos e estoques.
-- Na primeira execução exige exatamente a única conta já cadastrada e aprovada.
begin;
create schema if not exists loja_privada;
revoke all on schema loja_privada from public, anon, authenticated;
create table if not exists loja_privada.administradores (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table loja_privada.administradores enable row level security;
revoke all on loja_privada.administradores from public, anon, authenticated;
do $$
begin
  if not exists (select 1 from loja_privada.administradores) then
    if (select count(*) from auth.users) <> 1 then
      raise exception 'Confirme explicitamente o administrador: deve existir uma única conta na primeira execução.';
    end if;
    insert into loja_privada.administradores select id from auth.users;
  end if;
end $$;

create or replace function public.eh_admin() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from loja_privada.administradores where user_id = auth.uid());
$$;
revoke all on function public.eh_admin() from public, anon, authenticated;
grant execute on function public.eh_admin() to authenticated;

alter table public.produtos add column if not exists promocao boolean not null default false;
alter table public.produtos enable row level security;
drop policy if exists "loja le produtos ativos" on public.produtos;
drop policy if exists "admin gerencia produtos" on public.produtos;
create policy "admin gerencia produtos" on public.produtos for all to authenticated
  using ((select public.eh_admin())) with check ((select public.eh_admin()));
revoke all on public.produtos from public, anon, authenticated;
grant select, insert, update, delete on public.produtos to authenticated;

drop policy if exists "fotos admin insert" on storage.objects;
drop policy if exists "fotos admin update" on storage.objects;
drop policy if exists "fotos admin delete" on storage.objects;
create policy "fotos admin insert" on storage.objects for insert to authenticated
  with check (bucket_id = 'produtos' and (select public.eh_admin()));
create policy "fotos admin update" on storage.objects for update to authenticated
  using (bucket_id = 'produtos' and (select public.eh_admin()))
  with check (bucket_id = 'produtos' and (select public.eh_admin()));
create policy "fotos admin delete" on storage.objects for delete to authenticated
  using (bucket_id = 'produtos' and (select public.eh_admin()));

create or replace function loja_privada.quantidade(estoque jsonb, tamanho text)
returns numeric language sql immutable set search_path = '' as $$
  select case when (estoque ->> tamanho) ~ '^[0-9]{1,15}$'
    then (estoque ->> tamanho)::numeric else 0 end;
$$;
revoke all on function loja_privada.quantidade(jsonb,text) from public, anon, authenticated;

create or replace function public.catalogo_publico()
returns table(id bigint, nome text, categoria text, preco numeric, preco_de numeric,
  imagem_url text, tamanhos text[], promocao boolean, criado_em timestamptz)
language sql stable security definer set search_path = '' as $$
  select p.id,p.nome,p.categoria,p.preco,p.preco_de,p.imagem_url,
    array(select t from unnest(p.tamanhos) t where loja_privada.quantidade(p.estoque,t)>0),
    p.promocao,p.criado_em
  from public.produtos p where p.ativo order by p.criado_em desc;
$$;
revoke all on function public.catalogo_publico() from public, anon, authenticated;
grant execute on function public.catalogo_publico() to anon, authenticated;

-- Não reserva nem altera estoque. Retorna somente validação e dados oficiais do pedido.
-- Máximo 100 linhas / 99 unidades de cada tamanho por consulta.
create or replace function public.validar_pedido(itens jsonb) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare entrada jsonb; linha record; produto public.produtos%rowtype; resultado jsonb := '[]';
begin
  if itens is null or jsonb_typeof(itens) <> 'array' then return '{"ok":false}'; end if;
  if jsonb_array_length(itens) < 1 or jsonb_array_length(itens)>100 then return '{"ok":false}'; end if;
  for entrada in select value from jsonb_array_elements(itens) loop
    if jsonb_typeof(entrada) <> 'object'
      or coalesce(entrada->>'id','') !~ '^[0-9]{1,18}$'
      or jsonb_typeof(entrada->'size') is distinct from 'string'
      or length(entrada->>'size')>30
      or jsonb_typeof(entrada->'qty') is distinct from 'number'
      or coalesce(entrada->>'qty','') !~ '^[1-9][0-9]?$'
    then return '{"ok":false}'; end if;
  end loop;
  for linha in
    select (v->>'id')::bigint as id, v->>'size' as tamanho, sum((v->>'qty')::int) as qty
    from jsonb_array_elements(itens) v group by 1,2 order by 1,2
  loop
    select * into produto from public.produtos p where p.id=linha.id and p.ativo;
    if not found or not (linha.tamanho=any(produto.tamanhos))
      or linha.qty>99 or linha.qty>loja_privada.quantidade(produto.estoque,linha.tamanho)
    then return '{"ok":false}'; end if;
    resultado := resultado || jsonb_build_array(jsonb_build_object(
      'id',produto.id::text,'size',linha.tamanho,'qty',linha.qty,
      'nome',produto.nome,'preco',produto.preco,'imagem',coalesce(produto.imagem_url,'')));
  end loop;
  return jsonb_build_object('ok',true,'itens',resultado);
end $$;
revoke all on function public.validar_pedido(jsonb) from public, anon, authenticated;
grant execute on function public.validar_pedido(jsonb) to anon, authenticated;
notify pgrst, 'reload schema';
commit;
