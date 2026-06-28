import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

interface EmailConnection {
  id: string;
  provider: 'gmail' | 'outlook';
  email: string;
  access_token: string | null;
  refresh_token: string | null;
  token_expires_at: string | null;
  last_sync_at: string | null;
  auto_sync: boolean;
}

interface ClassifiedEmail {
  id: string;
  subject: string;
  from: string;
  snippet: string;
  detected_status: string | null;
  detected_payment: string | null;
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  { auth: { persistSession: false } },
);

serve(async (req: Request) => {
  const corsCheck = handleCors(req);
  if (corsCheck) return corsCheck;

  try {
    const url = new URL(req.url);
    const action = url.searchParams.get('action');
    const code = url.searchParams.get('code');

    // ── OAuth callback from Google/Microsoft ──
    if (code) {
      return handleOAuthCallback(url);
    }

    // ── OAuth authorize redirect ──
    if (action === 'authorize') {
      return handleOAuthAuthorize(url);
    }

    // ── POST actions (existing token-exchange + sync) ──
    if (req.method === 'POST') {
      return handlePostRequest(req);
    }

    return new Response(JSON.stringify({ error: 'Invalid request' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err instanceof Error ? err.message : 'Unknown error' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

// ── OAuth AUTHORIZE ───────────────────────────────────────────

function handleOAuthAuthorize(url: URL): Response {
  const provider = url.searchParams.get('provider');
  const userId = url.searchParams.get('user_id');
  const clientState = url.searchParams.get('client_state') || '';

  if (!provider || !userId) {
    return new Response(JSON.stringify({ error: 'Missing provider or user_id' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // req.url is an internal URL (e.g. http://localhost/email-sync).
  // Use SUPABASE_URL env var to build the public redirect URI.
  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const redirectUri = `${supabaseUrl}/functions/v1/email-sync`;

  if (provider === 'gmail') {
    const clientId = Deno.env.get('GMAIL_CLIENT_ID');
    if (!clientId) {
      return new Response(JSON.stringify({ error: 'Gmail OAuth not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: 'https://www.googleapis.com/auth/gmail.readonly email',
      access_type: 'offline',
      prompt: 'consent',
      state: `gmail:${userId}:${clientState}`,
    });
    return Response.redirect(`https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`, 302);
  }

  if (provider === 'outlook') {
    const clientId = Deno.env.get('OUTLOOK_CLIENT_ID');
    if (!clientId) {
      return new Response(JSON.stringify({ error: 'Outlook OAuth not configured' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    const params = new URLSearchParams({
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: 'code',
      scope: 'Mail.Read User.Read offline_access',
      state: `outlook:${userId}:${clientState}`,
    });
    return Response.redirect(`https://login.microsoftonline.com/common/oauth2/v2.0/authorize?${params.toString()}`, 302);
  }

  return new Response(JSON.stringify({ error: 'Unknown provider' }), {
    status: 400,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ── OAuth CALLBACK ────────────────────────────────────────────

async function handleOAuthCallback(url: URL): Promise<Response> {
  const code = url.searchParams.get('code')!;
  const state = url.searchParams.get('state') || '';
  const parts = state.split(':');
  const provider = parts[0] || 'gmail';
  const userId = parts[1];
  const clientState = parts.slice(2).join(':');

  if (!userId) {
    return new Response(JSON.stringify({ error: 'Missing user in state' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL') || '';
  const redirectUri = `${supabaseUrl}/functions/v1/email-sync`;

  let tokenEndpoint: string;
  let clientIdKey: string;
  let clientSecretKey: string;
  let userInfoUrl: string;

  if (provider === 'gmail') {
    tokenEndpoint = 'https://oauth2.googleapis.com/token';
    clientIdKey = 'GMAIL_CLIENT_ID';
    clientSecretKey = 'GMAIL_CLIENT_SECRET';
    userInfoUrl = 'https://www.googleapis.com/oauth2/v2/userinfo';
  } else if (provider === 'outlook') {
    tokenEndpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
    clientIdKey = 'OUTLOOK_CLIENT_ID';
    clientSecretKey = 'OUTLOOK_CLIENT_SECRET';
    userInfoUrl = 'https://graph.microsoft.com/v1.0/me';
  } else {
    // fallback to gmail defaults
    tokenEndpoint = 'https://oauth2.googleapis.com/token';
    clientIdKey = 'GMAIL_CLIENT_ID';
    clientSecretKey = 'GMAIL_CLIENT_SECRET';
    userInfoUrl = 'https://www.googleapis.com/oauth2/v2/userinfo';
  }

  const clientId = Deno.env.get(clientIdKey);
  const clientSecret = Deno.env.get(clientSecretKey);
  if (!clientId || !clientSecret) {
    return new Response(JSON.stringify({ error: `${provider} OAuth credentials not configured on server` }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Exchange code for tokens
  const params = new URLSearchParams({
    code,
    client_id: clientId,
    client_secret: clientSecret,
    redirect_uri: redirectUri,
    grant_type: 'authorization_code',
  });

  const tokenRes = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  });

  if (!tokenRes.ok) {
    const errText = await tokenRes.text();
    return new Response(JSON.stringify({ error: `Token exchange failed: ${errText}` }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const tokens = await tokenRes.json();
  const accessToken: string = tokens.access_token;
  const refreshToken: string | null = tokens.refresh_token ?? null;
  const expiresIn: number = tokens.expires_in ?? 3600;
  const tokenExpiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();

  // Get user email from provider
  const userInfoRes = await fetch(userInfoUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  let email = '';
  if (userInfoRes.ok) {
    const userInfo = await userInfoRes.json();
    email = userInfo.email || userInfo.userPrincipalName || '';
  }

  // Save to email_connections
  const { error: upsertError } = await supabase.from('email_connections').upsert({
    user_id: userId,
    provider,
    email,
    access_token: accessToken,
    refresh_token: refreshToken,
    token_expires_at: tokenExpiresAt,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'user_id,provider' });

  if (upsertError) {
    return new Response(JSON.stringify({ error: upsertError.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Redirect back to the app via deep link
  const appRedirectParts = [`com.unipath.app://email_callback?success=true&provider=${provider}`];
  if (clientState) appRedirectParts.push(`state=${clientState}`);
  return Response.redirect(appRedirectParts.join('&'), 302);
}

// ── POST HANDLER ──────────────────────────────────────────────

async function handlePostRequest(req: Request): Promise<Response> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Missing authorization' }), { status: 401, headers: corsHeaders });
  }

  const { data: { user }, error: authError } = await supabase.auth.getUser(authHeader.replace('Bearer ', ''));
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: corsHeaders });
  }

  const body = await req.json().catch(() => ({}));

  if (body.action === 'token-exchange') {
    return handleTokenExchange(req, user.id, body);
  }

  return handleSync(user.id);
}

// ── TOKEN EXCHANGE ──────────────────────────────────────────────

async function handleTokenExchange(
  _req: Request,
  userId: string,
  body: Record<string, unknown>,
): Promise<Response> {
  const provider = body.provider as string;
  const code = body.code as string;

  if (!provider || !code) {
    return new Response(JSON.stringify({ error: 'Missing provider or code' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let tokenEndpoint: string;
  let clientIdKey: string;
  let clientSecretKey: string;
  let userInfoUrl: string;

  if (provider === 'gmail') {
    tokenEndpoint = 'https://oauth2.googleapis.com/token';
    clientIdKey = 'GMAIL_CLIENT_ID';
    clientSecretKey = 'GMAIL_CLIENT_SECRET';
    userInfoUrl = 'https://www.googleapis.com/oauth2/v2/userinfo';
  } else if (provider === 'outlook') {
    tokenEndpoint = 'https://login.microsoftonline.com/common/oauth2/v2.0/token';
    clientIdKey = 'OUTLOOK_CLIENT_ID';
    clientSecretKey = 'OUTLOOK_CLIENT_SECRET';
    userInfoUrl = 'https://graph.microsoft.com/v1.0/me';
  } else {
    return new Response(JSON.stringify({ error: 'Unknown provider' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const clientId = Deno.env.get(clientIdKey);
  const clientSecret = Deno.env.get(clientSecretKey);
  if (!clientId || !clientSecret) {
    return new Response(JSON.stringify({ error: `${provider} OAuth credentials not configured on server` }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const redirectUri = 'http://localhost/email_callback';

  const params = new URLSearchParams({
    code,
    client_id: clientId,
    client_secret: clientSecret,
    redirect_uri: redirectUri,
    grant_type: 'authorization_code',
  });

  const tokenRes = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  });

  if (!tokenRes.ok) {
    const errText = await tokenRes.text();
    return new Response(JSON.stringify({ error: `Token exchange failed: ${errText}` }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const tokens = await tokenRes.json();
  const accessToken: string = tokens.access_token;
  const refreshToken: string | null = tokens.refresh_token ?? null;
  const expiresIn: number = tokens.expires_in ?? 3600;
  const tokenExpiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();

  const userInfoRes = await fetch(userInfoUrl, {
    headers: { Authorization: `Bearer ${accessToken}` },
  });
  let email = '';
  if (userInfoRes.ok) {
    const userInfo = await userInfoRes.json();
    email = userInfo.email || userInfo.userPrincipalName || '';
  }

  const { error: upsertError } = await supabase.from('email_connections').upsert({
    user_id: userId,
    provider,
    email,
    access_token: accessToken,
    refresh_token: refreshToken,
    token_expires_at: tokenExpiresAt,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'user_id,provider' });

  if (upsertError) {
    return new Response(JSON.stringify({ error: upsertError.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ success: true, provider, email }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ── SYNC ────────────────────────────────────────────────────────

async function handleSync(userId: string): Promise<Response> {
  const { data: connections, error: connError } = await supabase
    .from('email_connections')
    .select('*')
    .eq('user_id', userId);

  if (connError) {
    return new Response(JSON.stringify({ error: connError.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  if (!connections || connections.length === 0) {
    return new Response(JSON.stringify({ message: 'No connections found', results: [] }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { data: applications } = await supabase
    .from('my_applications')
    .select('id, name, portal_status, payment_status, auto_track')
    .eq('user_id', userId);

  const results: Array<{ provider: string; emails_fetched: number; classified: number; applied: number }> = [];

  for (const conn of connections as unknown as EmailConnection[]) {
    if (!conn.auto_sync) continue;

    const accessToken = await ensureValidToken(conn);
    if (!accessToken) {
      results.push({ provider: conn.provider, emails_fetched: 0, classified: 0, applied: 0 });
      continue;
    }

    const emails = await fetchEmails(conn.provider, accessToken);
    const classified = classifyEmails(emails);

    let appliedCount = 0;
    for (const email of classified) {
      const matchedAppId = matchApplication(email, applications as Array<Record<string, unknown>> | null);
      const { error: logError } = await supabase.from('email_status_log').insert({
        user_id: userId,
        application_id: matchedAppId,
        connection_id: conn.id,
        email_subject: email.subject,
        email_from: email.from,
        detected_status: email.detected_status,
        detected_payment: email.detected_payment,
        raw_snippet: email.snippet.slice(0, 500),
        applied: matchedAppId != null,
      });

      if (logError) {
        console.error('Failed to insert email_status_log:', logError.message);
      }

      if (matchedAppId && email.detected_status) {
        const updateData: Record<string, string> = {};
        if (email.detected_status) updateData.portal_status = email.detected_status;
        if (email.detected_payment) updateData.payment_status = email.detected_payment;

        const { error: updateError } = await supabase
          .from('my_applications')
          .update(updateData)
          .eq('id', matchedAppId);

        if (!updateError) appliedCount++;
      }
    }

    await supabase.from('email_connections').update({
      last_sync_at: new Date().toISOString(),
    }).eq('id', conn.id);

    results.push({
      provider: conn.provider,
      emails_fetched: emails.length,
      classified: classified.filter((e) => e.detected_status || e.detected_payment).length,
      applied: appliedCount,
    });
  }

  return new Response(JSON.stringify({ results }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ── TOKEN REFRESH ───────────────────────────────────────────────

async function ensureValidToken(conn: EmailConnection): Promise<string | null> {
  if (!conn.access_token) return null;

  const expiresAt = conn.token_expires_at ? new Date(conn.token_expires_at).getTime() : 0;
  const isExpired = Date.now() + 60000 > expiresAt;

  if (!isExpired) return conn.access_token;
  if (!conn.refresh_token) return null;

  const clientIdKey = conn.provider === 'gmail' ? 'GMAIL_CLIENT_ID' : 'OUTLOOK_CLIENT_ID';
  const clientSecretKey = conn.provider === 'gmail' ? 'GMAIL_CLIENT_SECRET' : 'OUTLOOK_CLIENT_SECRET';
  const tokenEndpoint = conn.provider === 'gmail'
    ? 'https://oauth2.googleapis.com/token'
    : 'https://login.microsoftonline.com/common/oauth2/v2.0/token';

  const clientId = Deno.env.get(clientIdKey);
  const clientSecret = Deno.env.get(clientSecretKey);
  if (!clientId || !clientSecret) return null;

  const params = new URLSearchParams({
    client_id: clientId,
    client_secret: clientSecret,
    refresh_token: conn.refresh_token,
    grant_type: 'refresh_token',
  });

  const res = await fetch(tokenEndpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  });

  if (!res.ok) return null;

  const data = await res.json();
  const newAccessToken: string = data.access_token;
  const expiresIn: number = data.expires_in ?? 3600;
  const tokenExpiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();

  await supabase.from('email_connections').update({
    access_token: newAccessToken,
    token_expires_at: tokenExpiresAt,
    updated_at: new Date().toISOString(),
  }).eq('id', conn.id);

  return newAccessToken;
}

// ── FETCH EMAILS ────────────────────────────────────────────────

async function fetchEmails(provider: string, accessToken: string): Promise<Array<Record<string, string>>> {
  if (provider === 'gmail') {
    return fetchGmailEmails(accessToken);
  }
  return fetchOutlookEmails(accessToken);
}

async function fetchGmailEmails(accessToken: string): Promise<Array<Record<string, string>>> {
  const listRes = await fetch(
    'https://gmail.googleapis.com/gmail/v1/users/me/messages?maxResults=10&q=university+application+status+admission',
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (!listRes.ok) return [];
  const listData = await listRes.json();
  const messages: Array<{ id: string }> = listData.messages || [];

  const emails: Array<Record<string, string>> = [];
  for (const msg of messages.slice(0, 5)) {
    const detailRes = await fetch(
      `https://gmail.googleapis.com/gmail/v1/users/me/messages/${msg.id}`,
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    if (!detailRes.ok) continue;
    const detail = await detailRes.json();

    const headers: Record<string, string> = {};
    for (const h of (detail.payload?.headers || [])) {
      headers[(h.name || '').toLowerCase()] = (h.value || '').toString();
    }

    emails.push({
      id: msg.id,
      subject: headers.subject || '',
      from: headers.from || '',
      date: headers.date || '',
      snippet: detail.snippet || '',
    });
  }
  return emails;
}

async function fetchOutlookEmails(accessToken: string): Promise<Array<Record<string, string>>> {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 86400000).toISOString();
  const res = await fetch(
    `https://graph.microsoft.com/v1.0/me/messages?$filter=receivedDateTime+ge+${thirtyDaysAgo}&$search="university application admission status"&$top=10&$select=subject,from,receivedDateTime,bodyPreview`,
    { headers: { Authorization: `Bearer ${accessToken}` } },
  );
  if (!res.ok) return [];
  const data = await res.json();
  const messages: Array<Record<string, unknown>> = data.value || [];

  return messages.map((m) => ({
    id: (m.id as string) || '',
    subject: (m.subject as string) || '',
    from: ((m.from as Record<string, unknown>)?.emailAddress as Record<string, string>)?.address || '',
    date: (m.receivedDateTime as string) || '',
    snippet: (m.bodyPreview as string) || '',
  }));
}

// ── CLASSIFIER ──────────────────────────────────────────────────

function classifyEmails(emails: Array<Record<string, string>>): ClassifiedEmail[] {
  return emails.map((email) => {
    const subject = (email.subject || '').toLowerCase();
    const snippet = (email.snippet || '').toLowerCase();
    const combined = `${subject} ${snippet}`;

    let detectedStatus: string | null = null;
    let detectedPayment: string | null = null;

    if (combined.includes('accepted') || combined.includes('congratulations') || combined.includes('admitted') || combined.includes('offer of admission')) {
      detectedStatus = 'accepted';
    } else if (combined.includes('rejected') || combined.includes('regret') || combined.includes('unfortunately') || combined.includes('declined') || combined.includes('not admitted')) {
      detectedStatus = 'rejected';
    } else if (combined.includes('acknowled') || combined.includes('received your') || combined.includes('we have received') || combined.includes('application received')) {
      detectedStatus = 'acknowledged';
    } else if (combined.includes('submitted') || combined.includes('confirmation') || combined.includes('application complete') || combined.includes('successfully submitted')) {
      detectedStatus = 'submitted';
    } else if (combined.includes('pending') || combined.includes('in review') || combined.includes('under review') || combined.includes('being processed') || combined.includes('in process')) {
      detectedStatus = 'pending';
    }

    if (combined.includes('payment') && (combined.includes('received') || combined.includes('complete') || combined.includes('paid') || combined.includes('confirmed'))) {
      detectedPayment = 'paid';
    } else if (combined.includes('payment') && (combined.includes('waive') || combined.includes('waived') || combined.includes('exempt'))) {
      detectedPayment = 'waived';
    }

    return {
      id: email.id,
      subject: email.subject,
      from: email.from,
      snippet: email.snippet,
      detected_status: detectedStatus,
      detected_payment: detectedPayment,
    };
  });
}

// ── APPLICATION MATCHER ─────────────────────────────────────────

function matchApplication(
  email: ClassifiedEmail,
  applications: Array<Record<string, unknown>> | null,
): string | null {
  if (!applications || applications.length === 0) return null;

  const subjectLower = (email.subject || '').toLowerCase();
  const fromLower = (email.from || '').toLowerCase();

  for (const app of applications) {
    if (app.auto_track === false) continue;
    const appName = (app.name as string || '').toLowerCase();
    if (appName && (subjectLower.includes(appName) || fromLower.includes(appName))) {
      return app.id as string;
    }
  }
  return null;
}
