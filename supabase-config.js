/* ============================================================
   🔌 CONEXÃO COM O SUPABASE
   Cole aqui a URL e a chave "anon public" do seu projeto.
   Painel do Supabase: Project Settings → API
   ============================================================ */
const SUPABASE_URL = "https://yzlllpohloembwrdroyc.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6bGxscG9obG9lbWJ3cmRyb3ljIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MDcwMjIsImV4cCI6MjA5ODM4MzAyMn0.gnnAN_inr2mpuJbeXWzjtfYqKJZmnbjcpDmuocDFAHg";

const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
