-- The sign-up trigger now also saves the phone number from sign-up data, not just the name.
--
-- Done in the trigger because with email confirmation on, sign-up returns no session yet, so a
-- follow-up update from the app would be blocked by RLS.

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
