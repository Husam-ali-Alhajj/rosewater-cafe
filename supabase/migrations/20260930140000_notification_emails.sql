-- Emails every notification to the user, through Resend, unless they turned "Email Notifications"
-- off.
--
-- Sent from the database with pg_net: a trigger queues one request to Resend's API. It's only sent
-- after the transaction commits and runs in the background, so it never slows down or blocks
-- anything.
--
-- The Resend API key is stored in Supabase Vault as 'resend_api_key', not in the repo. Until it's
-- added, no emails are sent.
--
-- Emails are in English: the language setting lives on the device, so the server doesn't know it.

create extension if not exists pg_net with schema extensions;

-- The Resend request id for this notification's email (see net._http_response), or NULL. For
-- troubleshooting only.
alter table public.notifications
  add column email_request_id bigint;

-- The sender address. Resend's test address only delivers to the Resend account owner's email; for
-- real users, verify a domain in Resend and change this.
create or replace function public.notification_email_from()
returns text
language sql
immutable
as $$ select 'Rosewater Café <onboarding@resend.dev>' $$;

-- Some text comes from user input (like the event type), so escape it before putting it in HTML.
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
    return new;  -- email notifications are off
  end if;

  select p.email into v_email from public.profiles p where p.id = new.user_id;
  if v_email is null or v_email = '' then
    return new;
  end if;

  select ds.decrypted_secret into v_key from vault.decrypted_secrets ds where ds.name = 'resend_api_key';
  if v_key is null or v_key = '' then
    return new;  -- no API key yet: in-app only
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
  -- Email is best effort: a problem here must never stop the notification (or the payment or
  -- booking behind it).
  return new;
end;
$$;

revoke execute on function public.email_notification() from public;
revoke execute on function public.email_notification() from anon;
revoke execute on function public.email_notification() from authenticated;

-- BEFORE, so the request id is saved on the same row.
create trigger trg_notifications_email
before insert on public.notifications
for each row execute function public.email_notification();
