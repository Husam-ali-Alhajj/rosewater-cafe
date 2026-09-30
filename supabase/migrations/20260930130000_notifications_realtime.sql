-- Notifications roadmap, step 4: the app listens for new notifications
-- live (Supabase Realtime) so it can update the bell badge and play the
-- arrival chime/vibration the moment one is created (decision #71).
--
-- Realtime only streams changes for tables in the `supabase_realtime`
-- publication. It applies the table's RLS to every event it delivers, so
-- a subscriber only ever receives its OWN notification rows (the "Users
-- can view own notifications" SELECT policy) -- no new access is granted
-- by this.
--
-- Guarded so re-running this migration (or replaying it on a project
-- where the table was already added via the dashboard) doesn't fail.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end;
$$;
