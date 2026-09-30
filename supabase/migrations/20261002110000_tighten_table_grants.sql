-- Limit each table's privileges to what its security policies allow.
--
-- Supabase grants every privilege on new tables to `anon` and `authenticated`, including TRUNCATE,
-- which ignores row security. This only revokes; nothing new is granted, so the app works the same.
-- Server functions run as the table owner and aren't affected.
--
-- After this:
--
-- table               authenticated keeps            anon keeps
-- door_access_logs    SELECT                         nothing
-- event_reservations  SELECT                         nothing
-- id_documents        SELECT, INSERT                 nothing
-- membership_plans    SELECT                         nothing
-- payment_methods     SELECT, INSERT, UPDATE, DELETE nothing
-- profiles            SELECT, UPDATE                 nothing
-- subscriptions       SELECT                         nothing
-- usage_allowances    SELECT                         nothing
--
-- No table has a policy for `anon`: the app doesn't touch any table before sign-in.

revoke all on public.door_access_logs   from anon;
revoke all on public.event_reservations from anon;
revoke all on public.id_documents       from anon;
revoke all on public.membership_plans   from anon;
revoke all on public.payment_methods    from anon;
revoke all on public.profiles           from anon;
revoke all on public.subscriptions      from anon;
revoke all on public.usage_allowances   from anon;

revoke insert, update, delete, truncate, references, trigger on public.door_access_logs   from authenticated;
revoke insert, update, delete, truncate, references, trigger on public.event_reservations from authenticated;
revoke update, delete, truncate, references, trigger         on public.id_documents       from authenticated;
revoke insert, update, delete, truncate, references, trigger on public.membership_plans   from authenticated;
revoke truncate, references, trigger                          on public.payment_methods    from authenticated;
revoke insert, delete, truncate, references, trigger         on public.profiles           from authenticated;
revoke insert, update, delete, truncate, references, trigger on public.subscriptions      from authenticated;
revoke insert, update, delete, truncate, references, trigger on public.usage_allowances   from authenticated;
