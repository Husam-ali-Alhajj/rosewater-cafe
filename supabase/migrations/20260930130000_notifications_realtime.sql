-- Lets the app hear about new notifications live (Supabase Realtime), to update the bell badge and
-- play the arrival sound.
--
-- Realtime respects row security, so users only receive their own notifications. Safe to re-run.
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
