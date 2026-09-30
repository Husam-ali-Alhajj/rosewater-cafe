-- Removes the "update own reservations" policy: it let users change their reservation's price after
-- booking (tested: 450.00 -> 0.01 worked). The price should only ever be set by
-- create_event_reservation.
--
-- The app never updates reservations. A future "cancel reservation" feature should be its own
-- function that only changes the status.
drop policy if exists "Users can update own reservations" on public.event_reservations;
