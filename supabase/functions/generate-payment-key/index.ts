import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PAYMOB_API_KEY = Deno.env.get("PAYMOB_API_KEY")!;
const PAYMOB_INTEGRATION_ID = Deno.env.get("PAYMOB_INTEGRATION_ID")!;
const PAYMOB_IFRAME_ID = Deno.env.get("PAYMOB_IFRAME_ID")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

serve(async (req) => {
  try {
    // Verify user is authenticated
    const authHeader = req.headers.get("Authorization") || "";
    const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { amount_cents, currency, user_id, plan } = await req.json();
    if (user.id !== user_id) {
      return new Response(JSON.stringify({ error: "User ID mismatch" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }

    // 1. Auth token
    const tokenRes = await fetch("https://accept.paymob.com/api/auth/tokens", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ api_key: PAYMOB_API_KEY }),
    });
    const tokenBody = await tokenRes.json();
    if (!tokenBody.token) {
      throw new Error(`Paymob auth failed: ${JSON.stringify(tokenBody)}`);
    }
    const token: string = tokenBody.token;

    // 2. Create order with merchant_order_id = user_id|plan
    const orderRes = await fetch("https://accept.paymob.com/api/ecommerce/orders", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        auth_token: token,
        amount_cents,
        currency: currency || "EGP",
        merchant_order_id: `${user_id}|${plan}|${Date.now()}`,
        items: [],
      }),
    });
    const orderBody = await orderRes.json();
    if (!orderBody.id) {
      throw new Error(`Paymob order failed: ${JSON.stringify(orderBody)}`);
    }

    // 3. Payment key
    const keyRes = await fetch("https://accept.paymob.com/api/acceptance/payment_keys", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        auth_token: token,
        amount_cents,
        currency: currency || "EGP",
        integration_id: parseInt(PAYMOB_INTEGRATION_ID),
        order_id: orderBody.id,
        billing_data: {
          first_name: "UniPath",
          last_name: "User",
          email: `${user_id}@unipath.app`,
          phone_number: "0000000000",
          apartment: "1",
          floor: "1",
          building: "1",
          street: "N/A",
          city: "N/A",
          country: "EG",
          state: "N/A",
        },
      }),
    });
    const keyBody = await keyRes.json();
    if (!keyBody.token) {
      throw new Error(`Paymob payment key failed: ${JSON.stringify(keyBody)}`);
    }
    const payment_token: string = keyBody.token;

    return new Response(
      JSON.stringify({ payment_token, iframe_id: PAYMOB_IFRAME_ID }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
