-- Keeps profiles.email in sync with the login email after a confirmed email change.
--
-- Runs after auth.users is updated, only when the email actually changed (that table updates on
-- every sign-in). Supabase only changes the email once the confirmation link is clicked, so this
-- always sees the final value.
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
