-- cancel_subscription: lets a user back out of a pending (unpaid)
-- subscription they started, so Choose Membership has a real way to let
-- them pick a different plan instead of being stuck resuming the same one
-- forever (see docs/decisions.md #19).
--
-- Same security pattern as start_subscription/confirm_subscription_payment
-- (20260914090100_subscription_two_rpc_pattern.sql): SECURITY DEFINER with
-- search_path pinned, auth.uid() read internally rather than trusting a
-- caller-supplied user_id, and EXECUTE revoked from PUBLIC *and* explicitly
-- from anon (revoking from PUBLIC alone is not enough on Supabase -- see
-- decision #16 for why).
--
-- Deliberately restricted to `status = 'pending'` only -- this must never
-- be usable to cancel an already-active paid subscription; that's a
-- separate feature (with separate implications, e.g. refunds) this project
-- hasn't built.
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
