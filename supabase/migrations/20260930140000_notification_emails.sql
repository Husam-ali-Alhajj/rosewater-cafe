-- Notifications roadmap, step 5: the "Email Notifications" toggle now
-- sends real email (decision #74). Every notification row -- payment,
-- reservation, reminder, allowance alert, and later promotions -- is also
-- emailed to the user's account address, via Resend, unless they switched
-- "Email Notifications" off (`notification_preferences.email`, #67).
--
-- Sent from inside the database with pg_net (Supabase's asynchronous HTTP
-- extension), so there's no separate server code to deploy: a BEFORE
-- INSERT trigger on notifications queues one POST to Resend's API. pg_net
-- only sends queued requests after the transaction COMMITs, so a rolled
-- back insert never emails anyone, and the request runs in the background
-- -- it never slows down or blocks the insert.
--
-- The Resend API key is NOT in this file or the repo. It lives in Supabase
-- Vault (encrypted), under the name 'resend_api_key', added by the
-- project owner. Until it exists, the trigger simply sends nothing and
-- in-app notifications work exactly as before.
--
-- Emails are in English (the notification's stored title/body): the app's
-- language choice lives on the device, so the server doesn't know it.

create extension if not exists pg_net with schema extensions;

-- The Resend request queued for this notification's email (pg_net request
-- id -> net._http_response has the outcome), or NULL if none was sent.
-- For troubleshooting; nothing in the app reads it.
alter table public.notifications
  add column email_request_id bigint;

-- The sender. Resend's shared test address works with no setup, but only
-- delivers to the email the Resend account was created with. For real
-- users, verify a domain in Resend and change this (one place) -- e.g.
-- 'Rosewater Café <notifications@your-domain.com>'.
create or replace function public.notification_email_from()
returns text
language sql
immutable
as $$ select 'Rosewater Café <onboarding@resend.dev>' $$;

-- Some notification text includes user-typed input (e.g. a free-text
-- event type), so it's escaped before going into HTML.
create or replace function public.html_escape(p text)
returns text
language sql
immutable
as $$
  select replace(replace(replace(replace(replace(coalesce(p, ''),
    '&', '&amp;'), '<', '&lt;'), '>', '&gt;'), '"', '&quot;'), '''', '&#39;')
$$;

create or replace function public.email_notification()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
  v_key text;
begin
  if not coalesce(
    (select np.email from public.notification_preferences np where np.user_id = new.user_id),
    true
  ) then
    return new; -- "Email Notifications" switched off
  end if;

  select p.email into v_email from public.profiles p where p.id = new.user_id;
  if v_email is null or v_email = '' then
    return new;
  end if;

  select ds.decrypted_secret into v_key from vault.decrypted_secrets ds where ds.name = 'resend_api_key';
  if v_key is null or v_key = '' then
    return new; -- email not set up yet: in-app only
  end if;

  new.email_request_id := net.http_post(
    url := 'https://api.resend.com/emails',
    headers := jsonb_build_object('Authorization', 'Bearer ' || v_key, 'Content-Type', 'application/json'),
    body := jsonb_build_object(
      'from', public.notification_email_from(),
      'to', jsonb_build_array(v_email),
      'subject', new.title,
      'text', new.title || E'\n\n' || coalesce(new.body, '') || E'\n\n-- Rosewater Café',
      'html',
        '<div style="font-family:Arial,Helvetica,sans-serif;max-width:480px;margin:0 auto;padding:24px;color:#1E2939">'
        || '<div style="font-size:14px;color:#EC003F;font-weight:bold;margin-bottom:16px">Rosewater Café</div>'
        || '<div style="border:1px solid #E5E7EB;border-radius:14px;padding:20px">'
        || '<div style="font-size:18px;font-weight:bold;margin-bottom:8px">' || public.html_escape(new.title) || '</div>'
        || '<div style="font-size:14px;line-height:20px;color:#4A5565">' || public.html_escape(new.body) || '</div>'
        || '</div>'
        || '<div style="font-size:12px;color:#6A7282;margin-top:16px">You can turn these emails off in the app: '
        || 'Profile &rarr; Notifications &rarr; Email Notifications.</div>'
        || '</div>'
    )
  );
  return new;
exception when others then
  -- Email is best-effort: a problem here must never stop the
  -- notification itself (or the payment/reservation that created it).
  return new;
end;
$$;

revoke execute on function public.email_notification() from public;
revoke execute on function public.email_notification() from anon;
revoke execute on function public.email_notification() from authenticated;

-- BEFORE, so the request id is stored on the same row write.
create trigger trg_notifications_email
before insert on public.notifications
for each row execute function public.email_notification();
