import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PAYMOB_HMAC = Deno.env.get("PAYMOB_HMAC")!;
const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SVC_ROLE_KEY = Deno.env.get("SVC_ROLE_KEY")!;

async function verifyHmac(
  payload: string,
  secret: string,
  expectedHmac: string,
): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(payload),
  );
  const calculated = Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("")
    .toUpperCase();
  return calculated === expectedHmac;
}

serve(async (req) => {
  try {
    const rawBody = await req.text();
    const body = JSON.parse(rawBody);
    const tx = body.obj;

    // Verify HMAC
    const receivedHmac = req.headers.get("hmac") || "";
    const isValid = await verifyHmac(rawBody, PAYMOB_HMAC, receivedHmac);
    if (!isValid) {
      console.error("HMAC mismatch");
      return new Response("Invalid HMAC", { status: 401 });
    }

    if (!tx.success) {
      console.log("Transaction not successful");
      return new Response("Transaction not successful", { status: 200 });
    }

    // Extract user_id and plan from merchant_order_id
    const merchantOrderId = tx.order?.merchant_order_id || "";
    const [userId, plan] = merchantOrderId.split("|");
    if (!userId || !plan) {
      console.error("Invalid merchant_order_id:", merchantOrderId);
      return new Response("Invalid merchant_order_id", { status: 400 });
    }

    // Calculate premium_until based on plan
    const now = new Date();
    let premiumUntil: Date;
    switch (plan) {
      case "monthly":
        premiumUntil = new Date(
          now.getFullYear(),
          now.getMonth() + 1,
          now.getDate(),
        );
        break;
      case "yearly":
        premiumUntil = new Date(
          now.getFullYear() + 1,
          now.getMonth(),
          now.getDate(),
        );
        break;
      case "lifetime":
        premiumUntil = new Date(
          now.getFullYear() + 100,
          now.getMonth(),
          now.getDate(),
        );
        break;
      default:
        return new Response("Unknown plan: " + plan, { status: 400 });
    }

    // Update profile in Supabase
    const supabase = createClient(SUPABASE_URL, SVC_ROLE_KEY);
    const { error } = await supabase
      .from("profiles")
      .update({
        premium_until: premiumUntil.toISOString(),
        premium_plan: plan,
      })
      .eq("id", userId);

    if (error) {
      console.error("Supabase error:", error);
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
      });
    }

    console.log(`Premium activated for user ${userId}, plan: ${plan}`);
    return new Response("OK", { status: 200 });
  } catch (e) {
    console.error("Webhook error:", e);
    return new Response(JSON.stringify({ error: e.message }), {
      status: 500,
    });
  }
});
