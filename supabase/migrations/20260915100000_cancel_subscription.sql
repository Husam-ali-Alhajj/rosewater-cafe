-- cancel_subscription: lets a user back out of a pending (unpaid) subscription so they can pick
-- another plan.
--
-- Same security setup as start_subscription: SECURITY DEFINER, fixed search_path, auth.uid()
-- instead of a user id, and EXECUTE revoked from PUBLIC and anon.
--
-- Only works on pending subscriptions; it can never cancel a paid one.
create or replace function public.cancel_subscription(p_subscription_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_found_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  update public.subscriptions
  set status = 'cancelled'
  where id = p_subscription_id
    and user_id = v_user_id
    and status = 'pending'
  returning id into v_found_id;

  if v_found_id is null then
    raise exception 'subscription_not_found_or_not_pending';
  end if;
end;
$$;

revoke execute on function public.cancel_subscription(uuid) from public;
revoke execute on function public.cancel_subscription(uuid) from anon;
grant execute on function public.cancel_subscription(uuid) to authenticated;
