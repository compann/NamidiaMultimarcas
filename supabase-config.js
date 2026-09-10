/* ============================================================
   🔌 CONEXÃO COM O SUPABASE
   Cole aqui a URL e a chave "anon / public" do seu projeto.
   Painel do Supabase: Project Settings → API / API Keys
   ============================================================ */
const SUPABASE_URL = "https://pllmgpaodzgjayneqkvw.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsbG1ncGFvZHpnamF5bmVxa3Z3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNzAyOTEsImV4cCI6MjEwNDY0NjI5MX0.8WZ26qKmZLQ8x4UVLDBGfsCLkYqZa_a_0PDqeZ2aYv8";

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
