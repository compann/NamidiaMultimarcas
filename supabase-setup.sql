-- ============================================================
--  NA MÍDIA MULTIMARCAS — estrutura do banco (Supabase)
--  Cole tudo no SQL Editor do Supabase e clique em RUN.
--  Pode rodar mais de uma vez sem problema (é idempotente).
--
--  Depois de rodar, cadastre a única conta de administrador:
--  Authentication -> Users -> Add user -> (e-mail + senha + Auto Confirm)
--  Esse e-mail/senha é o login do admin.html.
--  Em seguida execute supabase-security.sql para autorizar essa conta
--  e criar as consultas públicas seguras. Não habilite cadastro público.
-- ============================================================

-- 1. TABELA DE PRODUTOS ---------------------------------------------------
create table if not exists public.produtos (
  id         bigint generated always as identity primary key,
  nome       text        not null,
  categoria  text        not null default 'Geral',
  preco      numeric     not null,
  preco_de   numeric,                       -- preço "De" (riscado). Vazio = sem desconto
  tamanhos   text[]      not null default '{}',
  estoque    jsonb       not null default '{}'::jsonb,
  imagem_url text,
  ativo      boolean     not null default true,
  criado_em  timestamptz not null default now()
);

-- garante a coluna de desconto mesmo se a tabela já existir de antes
alter table public.produtos add column if not exists preco_de numeric;
alter table public.produtos add column if not exists estoque jsonb not null default '{}'::jsonb;

-- 2. SEGURANÇA (RLS) DA TABELA -----------------------------------------
alter table public.produtos enable row level security;

-- Não recriar políticas públicas na tabela. O acesso ao catálogo ocorre
-- por catalogo_publico(), e ao painel apenas por eh_admin().
-- As políticas são geridas exclusivamente por supabase-security.sql.

-- 3. BUCKET DAS FOTOS --------------------------------------------------
insert into storage.buckets (id, name, public)
values ('produtos', 'produtos', true)
on conflict (id) do update set public = true;

-- 4. LEITURA PÚBLICA DAS FOTOS DO CATÁLOGO -----------------------------
drop policy if exists "fotos leitura publica" on storage.objects;
create policy "fotos leitura publica"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'produtos');

-- Escrita das fotos: somente o administrador em supabase-security.sql.
