-- Sprint 7 Task 3 (Change Login Email, decision #57): keeps public.profiles.email
-- following auth.users.email once a real, confirmed email change actually happens.
--
-- Without this, profiles.email would go stale forever after any successful
-- email change: handle_new_user() (initial_schema.sql) only fires on INSERT,
-- so nothing currently updates profiles.email after signup at all. That's
-- exactly the gap decision #9's original lock-trigger comment already
-- anticipated: "A server-side process with no user session -- e.g. a future
-- trigger that syncs the email after a verified change -- is not affected."
-- This is that trigger.
--
-- Fires AFTER UPDATE on auth.users, only when the email actually changed
-- (the WHEN clause -- auth.users rows update constantly, e.g. every sign-in
-- touches last_sign_in_at, and this must not fire on any of that). By the
-- time this runs, the change is already real and confirmed: Supabase's own
-- /verify endpoint updates auth.users.email server-side when the
-- confirmation link is clicked, before ever redirecting the browser back to
-- the app -- so there's no "pending" state to worry about reflecting here,
-- only the final, confirmed value.
--
-- SECURITY DEFINER + search_path pinned, the same pattern every other
-- trigger/RPC in this project follows for a cross-schema or elevated write.
create or replace function public.sync_profile_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles set email = new.email where id = new.id;
  return new;
end;
$$;

drop trigger if exists trg_sync_profile_email on auth.users;
create trigger trg_sync_profile_email
after update on auth.users
for each row
when (new.email is distinct from old.email)
execute function public.sync_profile_email();
