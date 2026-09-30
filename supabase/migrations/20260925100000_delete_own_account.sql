-- delete_own_account: self-service account deletion, replacing the request queue.
--
-- It can only delete the caller's own auth.users row (it uses auth.uid(), never a passed-in id).
-- Deleting that row cascades to the profile and all of the user's data.
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

-- The request table is no longer needed: deletion is immediate.
drop policy if exists "Users can view own deletion requests" on public.deletion_requests;
drop policy if exists "Users can request deletion of own account" on public.deletion_requests;
drop table if exists public.deletion_requests cascade;
drop type if exists public.deletion_request_status cascade;
