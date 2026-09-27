-- Notifications roadmap, step 2: the Notifications feed (Figma App-23)
-- has a delete (trash) button on every card, so a user may now delete
-- their OWN notifications -- and only those.
--
-- Two layers, same as every other client write in this project:
--  * RLS policy: which ROWS a DELETE may touch (own rows only -- another
--    user's rows are silently filtered out, 0 rows deleted).
--  * Table grant: 20260928100000 revoked Supabase's blanket grants and
--    handed back only what was needed then (SELECT, and UPDATE of is_read
--    alone). DELETE was never granted back, so it's added explicitly here.
-- Nothing else changes: still no client INSERT, and UPDATE is still
-- limited to the is_read column.

create policy "Users can delete own notifications"
  on public.notifications for delete
  to authenticated
  using (user_id = auth.uid());

grant delete on public.notifications to authenticated;

-- Found while verifying the above on the real project: 20260928100000
-- only revoked UPDATE, so both roles still held the rest of Supabase's
-- default table grants -- anon: SELECT, INSERT, DELETE, TRUNCATE,
-- REFERENCES, TRIGGER; authenticated: the same plus the is_read UPDATE.
-- RLS kept every row safe through the API (anon's DELETE matched 0 rows),
-- but TRUNCATE ignores RLS entirely, so the grants themselves should say
-- exactly what a client may do, not rely on the REST API happening not to
-- expose TRUNCATE. After this, the table-level grants are:
--   anon:          nothing
--   authenticated: SELECT, DELETE (+ UPDATE of is_read only, column grant)
-- INSERT stays revoked for clients -- every row is written by the
-- SECURITY DEFINER functions, which run as the table owner and don't need
-- a client grant.
revoke all on public.notifications from anon;
revoke insert, truncate, references, trigger on public.notifications from authenticated;
