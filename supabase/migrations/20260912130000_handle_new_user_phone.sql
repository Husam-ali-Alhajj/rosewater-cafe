-- Extends the signup trigger to also capture phone number from auth
-- metadata, alongside full_name. This lets the client pass both values
-- directly in supabase.auth.signUp(data: {...}) so profile creation is
-- atomic with signup itself — no follow-up client-side UPDATE is needed.
--
-- Why this matters: a follow-up `.update()` on `profiles` right after
-- signUp() would run under RLS as whatever session exists at that moment.
-- If the project has email confirmation enabled (the default), signUp()
-- does NOT return an active session — auth.uid() is null until the user
-- clicks the confirmation link — so that update would silently fail RLS
-- and leave the profile with an empty name/phone. Populating both fields
-- via this SECURITY DEFINER trigger instead sidesteps that entirely: it
-- runs on auth.users insert, before any confirmation step, regardless of
-- session state.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.email,
    new.raw_user_meta_data ->> 'phone'
  );
  return new;
end;
$$;
