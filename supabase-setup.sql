-- ============================================================
--  NA MÍDIA MULTIMARCAS — estrutura do banco (Supabase)
--  Cole tudo no SQL Editor do Supabase e clique em RUN.
--  Pode rodar mais de uma vez sem problema (é idempotente).
--
--  Depois de rodar, ainda falta 1 passo MANUAL no painel:
--  Authentication -> Users -> Add user -> (e-mail + senha + Auto Confirm)
--  Esse e-mail/senha é o login do admin.html.
-- ============================================================

-- 1. TABELA DE PRODUTOS ---------------------------------------------------
create table if not exists public.produtos (
  id         bigint generated always as identity primary key,
  nome       text        not null,
  categoria  text        not null default 'Geral',
  preco      numeric     not null,
  preco_de   numeric,                       -- preço "De" (riscado). Vazio = sem desconto
  tamanhos   text[]      not null default '{}',
  imagem_url text,
  ativo      boolean     not null default true,
  criado_em  timestamptz not null default now()
);

-- garante a coluna de desconto mesmo se a tabela já existir de antes
alter table public.produtos add column if not exists preco_de numeric;

-- 2. SEGURANÇA (RLS) DA TABELA -----------------------------------------
alter table public.produtos enable row level security;

drop policy if exists "loja le produtos ativos" on public.produtos;
create policy "loja le produtos ativos"
  on public.produtos for select
  to anon, authenticated
  using (ativo = true);

drop policy if exists "admin gerencia produtos" on public.produtos;
create policy "admin gerencia produtos"
  on public.produtos for all
  to authenticated
  using (true) with check (true);

-- 3. BUCKET DAS FOTOS --------------------------------------------------
insert into storage.buckets (id, name, public)
values ('produtos', 'produtos', true)
on conflict (id) do update set public = true;

-- 4. SEGURANÇA DAS FOTOS ---------------------------------------------
drop policy if exists "fotos leitura publica" on storage.objects;
create policy "fotos leitura publica"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'produtos');

drop policy if exists "fotos admin insert" on storage.objects;
create policy "fotos admin insert"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'produtos');

drop policy if exists "fotos admin update" on storage.objects;
create policy "fotos admin update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'produtos');

drop policy if exists "fotos admin delete" on storage.objects;
create policy "fotos admin delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'produtos');
