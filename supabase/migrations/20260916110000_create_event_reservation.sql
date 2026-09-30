-- create_event_reservation: the only way to create a reservation. The price is calculated here;
-- it's not a parameter, so a user can't set their own price.
--
-- It also removes the old "insert own rows" policy, which let the app insert a reservation with any
-- price.
--
-- Same security setup as the other functions: SECURITY DEFINER, fixed search_path, auth.uid()
-- instead of a user id, and EXECUTE revoked from PUBLIC and anon.
--
-- It checks that the guest count is 5-100 and the date isn't in the past. Reservations are created
-- as 'confirmed', since there's no approval step in the app.
create or replace function public.create_event_reservation(
  p_event_type text,
  p_event_date date,
  p_start_time time,
  p_duration_hours numeric,
  p_guest_count integer
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  -- Placeholder price until the company gives real numbers. Change it here only (the app uses the
  -- same value for its estimate).
  c_price_per_hour constant numeric := 150.00;
  v_total_price numeric;
  v_reservation_id uuid;
begin
  if v_user_id is null then
    raise exception 'not_authenticated';
  end if;

  if p_guest_count is null or p_guest_count < 5 or p_guest_count > 100 then
    raise exception 'guest_count_out_of_range'
      using detail = json_build_object(
        'min', 5,
        'max', 100,
        'requested', p_guest_count
      )::text;
  end if;

  if p_event_date is null or p_event_date < current_date then
    raise exception 'event_date_in_past';
  end if;

  v_total_price := p_duration_hours * c_price_per_hour;

  insert into public.event_reservations (
    user_id, event_type, event_date, start_time, duration_hours, guest_count, status, total_price
  )
  values (
    v_user_id, p_event_type, p_event_date, p_start_time, p_duration_hours, p_guest_count, 'confirmed', v_total_price
  )
  returning id into v_reservation_id;

  return v_reservation_id;
end;
$$;

revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from public;
revoke execute on function public.create_event_reservation(text, date, time, numeric, integer) from anon;
grant execute on function public.create_event_reservation(text, date, time, numeric, integer) to authenticated;

-- Remove the direct-insert policy described above.
drop policy if exists "Users can create own reservations" on public.event_reservations;
