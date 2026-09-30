-- Profile photos, and protecting profiles.email.
--
-- 1. A private `avatars` bucket. Files live at "<user_id>/<filename>", and the policies only let
-- users reach their own folder; `anon` gets nothing. The bucket itself limits uploads to 5MB and
-- PNG/JPEG/WebP. The app shows photos through short-lived signed links.
--
-- 2. Users can't change profiles.email directly (it must match the login email). A trigger keeps
-- the old value when a signed-in user tries; server processes without a user session aren't
-- affected.

-- 1. avatars bucket
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', false, 5242880, array['image/png', 'image/jpeg', 'image/webp'])
on conflict (id) do nothing;

drop policy if exists "Users can read own avatars in storage" on storage.objects;
create policy "Users can read own avatars in storage"
on storage.objects for select
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can write own avatars in storage" on storage.objects;
create policy "Users can write own avatars in storage"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can update own avatars in storage" on storage.objects;
create policy "Users can update own avatars in storage"
on storage.objects for update
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete own avatars in storage" on storage.objects;
create policy "Users can delete own avatars in storage"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- 2. Protect profiles.email from edits by users
create or replace function public.lock_profile_email()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if auth.uid() is not null and new.email is distinct from old.email then
    new.email := old.email;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_profiles_lock_email on public.profiles;
create trigger trg_profiles_lock_email
before update on public.profiles
for each row execute function public.lock_profile_email();
