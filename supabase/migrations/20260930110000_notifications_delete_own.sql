-- Users can delete their own notifications (and only their own).
--
-- The policy limits which rows can be deleted; DELETE also has to be granted, since it was revoked
-- earlier.

create policy "Users can delete own notifications"
  on public.notifications for delete
  to authenticated
  using (user_id = auth.uid());

grant delete on public.notifications to authenticated;

-- Also remove the other default grants left on this table. Row security kept rows safe, but
-- TRUNCATE ignores it, so the grants should allow exactly what's needed:
--   anon:          nothing
--   authenticated: SELECT, DELETE, and UPDATE of is_read only
-- Notifications are created by server functions, which don't need a user grant.
revoke all on public.notifications from anon;
revoke insert, truncate, references, trigger on public.notifications from authenticated;
