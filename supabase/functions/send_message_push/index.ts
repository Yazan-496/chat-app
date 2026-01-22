import { serve } from 'https://deno.land/std@0.192.0/http/server.ts';
// Using Deno.fetch (built-in)
Deno.serve(async (req) => {
  try {
    const url = new URL(req.url);
    // Only accept POST
    if (req.method !== 'POST') return new Response(JSON.stringify({ error: 'Method not allowed' }), { status: 405 });

    // Auth check: require Authorization Bearer
    const auth = req.headers.get('authorization');
    if (!auth || !auth.startsWith('Bearer ')) {
      return new Response(JSON.stringify({ error: 'Unauthorized - missing Authorization Bearer' }), { status: 401 });
    }

    const body = await req.json().catch(() => null);
    if (!body) return new Response(JSON.stringify({ error: 'Invalid JSON body' }), { status: 400 });

    // Normalize payload
    const payload = {} as any;

    const data = body.data ?? {};
    if (data) payload.data = data;

    // Determine recipients
    let include_external_user_ids = null;
    if (Array.isArray(body.recipient_ids)) include_external_user_ids = body.recipient_ids;
    if (!include_external_user_ids && Array.isArray(body.user_ids)) include_external_user_ids = body.user_ids;
    if (!include_external_user_ids && Array.isArray(body.include_external_user_ids)) include_external_user_ids = body.include_external_user_ids;

    // Filters
    if (body.filters) payload.filters = body.filters;

    // Contents and headings
    if (body.contents) payload.contents = body.contents;
    if (body.headings) payload.headings = body.headings;

    // title/body fallback
    if (!payload.headings && body.title) payload.headings = { en: body.title };
    if (!payload.contents && body.body) payload.contents = { en: body.body };

    // If still no content, error
    if (!payload.contents) return new Response(JSON.stringify({ error: 'No contents provided' }), { status: 400 });
    // If no recipients and no filters, error
    if (!include_external_user_ids && !payload.filters) {
      return new Response(JSON.stringify({ error: 'No recipients specified (recipient_ids/user_ids/include_external_user_ids) or filters present' }), { status: 400 });
    }

    if (include_external_user_ids) payload.include_external_user_ids = include_external_user_ids;

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    const chatId = data?.chat_id ?? null;
    const recipientId = data?.recipient_id ?? (Array.isArray(include_external_user_ids) ? include_external_user_ids[0] : null);
    if (supabaseUrl && serviceRoleKey && chatId && recipientId) {
      try {
        const presenceRes = await fetch(
          `${supabaseUrl}/rest/v1/user_presence?select=is_online,active_chat_id&user_id=eq.${recipientId}`,
          {
            headers: {
              apikey: serviceRoleKey,
              Authorization: `Bearer ${serviceRoleKey}`,
            },
          },
        );
        if (presenceRes.ok) {
          const presenceRows = await presenceRes.json();
          const presence = Array.isArray(presenceRows) ? presenceRows[0] : null;
          if (presence?.is_online === true && presence?.active_chat_id === chatId) {
            return new Response(JSON.stringify({ skipped: true, reason: 'recipient_in_chat' }), { status: 200 });
          }
        }
      } catch (_) {}

      try {
        const unreadRes = await fetch(
          `${supabaseUrl}/rest/v1/chat_participants?select=unread_count&chat_id=eq.${chatId}&user_id=eq.${recipientId}`,
          {
            headers: {
              apikey: serviceRoleKey,
              Authorization: `Bearer ${serviceRoleKey}`,
            },
          },
        );
        if (unreadRes.ok) {
          const unreadRows = await unreadRes.json();
          const unread = Array.isArray(unreadRows) ? unreadRows[0]?.unread_count : null;
          if (typeof unread === 'number') {
            payload.data = { ...(payload.data ?? {}), unread_count: unread };
            if (unread > 1) {
              payload.android_group = `chat_${chatId}`;
              payload.android_group_message = `${unread} new messages`;
            }
          }
        }
      } catch (_) {}
    }

    // Send to OneSignal
    const ONESIGNAL_APP_ID = Deno.env.get('ONESIGNAL_APP_ID');
    const ONESIGNAL_API_KEY = Deno.env.get('ONESIGNAL_REST_API_KEY') ??
      Deno.env.get('ONESIGNAL_API_KEY');
    if (!ONESIGNAL_APP_ID || !ONESIGNAL_API_KEY) {
      return new Response(JSON.stringify({ error: 'OneSignal credentials not configured on the Edge Function environment' }), { status: 500 });
    }

    const onesignalBody = { app_id: ONESIGNAL_APP_ID, ...payload };

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 15000);
    let resText = '';
    let resStatus = 502;
    try {
      const res = await fetch('https://onesignal.com/api/v1/notifications', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json;charset=utf-8',
          Authorization: `Basic ${ONESIGNAL_API_KEY}`,
        },
        body: JSON.stringify(onesignalBody),
        signal: controller.signal,
      });
      resText = await res.text();
      resStatus = res.status;
    } catch (err) {
      if (err instanceof DOMException && err.name === 'AbortError') {
        return new Response(JSON.stringify({ error: 'OneSignal request timeout' }), { status: 504 });
      }
      throw err;
    } finally {
      clearTimeout(timeoutId);
    }

    return new Response(resText, { status: resStatus, headers: { 'Content-Type': 'application/json' } });
  } catch (err) {
    console.error('Function error:', err);
    return new Response(JSON.stringify({ error: 'Internal server error', details: String(err) }), { status: 500 });
  }
});
