-- Sprint 5 Task 2 (Edit Profile): profile photos, and locking profiles.email.
--
-- 1. `avatars` storage bucket -- same pattern as `id-documents` (see
--    initial_schema.sql, decision #18): PRIVATE, and every object path must
--    be "<user_id>/<filename>". The four policies below check that first
--    path segment against auth.uid(), so a signed-in user can only read,
--    write, replace or delete files inside their own folder -- never
--    another user's, and `anon` gets nothing at all. The bucket itself also
--    caps uploads at 5MB and to PNG/JPEG/WebP, so those limits hold even if
--    someone calls the storage API directly and skips the Flutter checks.
--
--    The photo's storage path is saved in the existing profiles.avatar_url
--    column (via the normal `auth.uid() = id` UPDATE policy -- no RPC needed,
--    this is the kind of self-owned write decision #3 always allowed). The
--    bucket is private, so the app displays it through short-lived signed
--    URLs, never a public link.
--
-- 2. profiles.email is now unchangeable from a client request. Editing an
--    auth email needs its own re-verification flow (a confirmation link to
--    the new address), which this app doesn't have yet -- and the existing
--    profiles UPDATE policy lets a client PATCH any column of its own row,
--    which would let profiles.email drift away from the login email in
--    auth.users. Same idea as generate_member_id()'s member_id lock: the
--    trigger quietly keeps the old value when the request comes from a
--    signed-in user (auth.uid() is set). A server-side process with no user
--    session -- e.g. a future trigger that syncs the email after a verified
--    change -- is not affected.

-- ------------------------------------------------------------
-- 1. avatars bucket
-- ------------------------------------------------------------
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

-- ------------------------------------------------------------
-- 2. lock profiles.email against client edits
-- ------------------------------------------------------------
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
