-- "Delete Account" made real self-service, replacing the request-queue from
-- decision #45. The user explicitly asked for immediate deletion rather
-- than staff processing, after being shown the real tradeoff decision #45
-- weighed (docs/decisions.md #52): a SECURITY DEFINER function with DELETE
-- power over auth.users is real risk if it's ever wrong -- but the risk is
-- fully contained here, the same way every other RPC in this project
-- contains its own: it reads auth.uid() itself (never a caller-supplied
-- id) and can only ever delete exactly that one row.
--
-- Deleting the auth.users row cascades automatically through the FK chain
-- already in place: profiles.id references auth.users(id) on delete
-- cascade, and every one of the user's own rows (subscriptions,
-- payment_methods, usage_allowances, door_access_logs, event_reservations,
-- notifications, id_documents, deletion_requests) cascades from profiles
-- the same way. Nothing is left behind by construction, not by a follow-up
-- cleanup step.
create or replace function public.delete_own_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  delete from auth.users where id = v_user_id;
end;
$$;

revoke execute on function public.delete_own_account() from public;
revoke execute on function public.delete_own_account() from anon;
grant execute on function public.delete_own_account() to authenticated;

-- The request-queue table this replaces (decision #45) has no further
-- purpose: deletion is now immediate, and the user explicitly chose not to
-- keep any record after the fact (docs/decisions.md #52) -- a lasting log
-- would need a separate, non-cascading table anyway, since this one
-- disappears along with everything else the moment its owning profile does.
drop policy if exists "Users can view own deletion requests" on public.deletion_requests;
drop policy if exists "Users can request deletion of own account" on public.deletion_requests;
drop table if exists public.deletion_requests cascade;
drop type if exists public.deletion_request_status cascade;
