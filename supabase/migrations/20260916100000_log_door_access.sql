-- log_door_access: records a door entry (arrival and guest count). The only way to add a
-- door_access_logs row.
--
-- Same security setup as the other functions: SECURITY DEFINER, fixed search_path, auth.uid()
-- instead of a user id, and EXECUTE revoked from PUBLIC and anon.
--
-- It checks on the server that:
-- 1. the membership is active and hasn't ended, and
-- 2. the guest count is between 0 and the plan's max_guests (the app's counter is only a
-- convenience).
--
-- It doesn't change usage_allowances: the app can't know what a member actually uses once inside.
create or replace function public.log_door_access(p_guest_count integer)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_max_guests integer;
  v_log_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_guest_count is null then
    raise exception 'guest_count_required';
  end if;

  select p.max_guests into v_max_guests
  from public.subscriptions s
  join public.membership_plans p on p.id = s.plan_id
  where s.user_id = v_user_id
    and s.status = 'active'
    and s.valid_until > now()
  limit 1;

  if not found then
    raise exception 'no_active_subscription';
  end if;

  if p_guest_count < 0 or p_guest_count > v_max_guests then
    raise exception 'guest_count_exceeds_plan_limit'
      using detail = json_build_object(
        'max_guests', v_max_guests,
        'requested', p_guest_count
      )::text;
  end if;

  insert into public.door_access_logs (user_id, guest_count)
  values (v_user_id, p_guest_count)
  returning id into v_log_id;

  return v_log_id;
end;
$$;

revoke execute on function public.log_door_access(integer) from public;
revoke execute on function public.log_door_access(integer) from anon;
grant execute on function public.log_door_access(integer) to authenticated;
