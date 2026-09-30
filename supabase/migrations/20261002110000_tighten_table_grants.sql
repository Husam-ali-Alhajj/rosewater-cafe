-- Tighten table privileges to match RLS policies exactly (decision #81).
--
-- Supabase grants every new table ALL privileges to `anon` and
-- `authenticated` by default. An audit of the live dev project found 8 of
-- the 10 public tables still carrying the full set -- SELECT, INSERT,
-- UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER -- to both roles, when
-- their RLS policies only ever allow a subset, and only to
-- `authenticated`. (notifications and notification_preferences were
-- already tightened, 20260930110000 / 20260930100000.)
--
-- Row-level security already denied every request those extra privileges
-- could make through the API -- except TRUNCATE, which bypasses RLS
-- entirely (the REST API can't issue it, so this was never exploitable
-- from the app, but grants shouldn't depend on that).
--
-- REVOKE ONLY -- nothing is granted here, so no existing access (incl. any
-- column-level grant) can be widened, and app behaviour is unchanged:
-- every revoked privilege is one no policy allows. SECURITY DEFINER
-- functions (payments, upgrades, reservations, account deletion, ...) run
-- as the table owner and are unaffected. After this, each table's grants
-- equal its policies:
--
--   table               authenticated keeps            anon keeps
--   door_access_logs    SELECT                         nothing
--   event_reservations  SELECT                         nothing
--   id_documents        SELECT, INSERT                 nothing
--   membership_plans    SELECT                         nothing
--   payment_methods     SELECT, INSERT, UPDATE, DELETE nothing
--   profiles            SELECT, UPDATE                 nothing
--   subscriptions       SELECT                         nothing
--   usage_allowances    SELECT                         nothing
--
-- No table has any policy for `anon`: nothing in the app reads or writes
-- a table before sign-in.

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
