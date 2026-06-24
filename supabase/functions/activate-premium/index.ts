import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;
const SVC_ROLE_KEY = Deno.env.get("SVC_ROLE_KEY")!;

serve(async (req) => {
  try {
    const authHeader = req.headers.get("Authorization") || "";
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }

    const { plan } = await req.json();
    if (!["monthly", "yearly", "lifetime"].includes(plan)) {
      return new Response(JSON.stringify({ error: "Invalid plan" }), { status: 400 });
    }

    const now = new Date();
    let premiumUntil: Date;
    switch (plan) {
      case "monthly":
        premiumUntil = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
        break;
      case "yearly":
        premiumUntil = new Date(now.getFullYear() + 1, now.getMonth(), now.getDate());
        break;
      case "lifetime":
        premiumUntil = new Date(now.getFullYear() + 100, now.getMonth(), now.getDate());
        break;
    }

    const admin = createClient(SUPABASE_URL, SVC_ROLE_KEY);
    const { error } = await admin
      .from("profiles")
      .update({
        premium_until: premiumUntil.toISOString(),
        premium_plan: plan,
      })
      .eq("id", user.id);

    if (error) {
      console.error("Supabase error:", error);
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }

    return new Response(JSON.stringify({ success: true, premium_until: premiumUntil.toISOString() }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 });
  }
});