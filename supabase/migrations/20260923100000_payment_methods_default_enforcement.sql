-- Sprint 5 Task 3 (Payment Methods): make "one default card per user" a real
-- database guarantee, and make deleting the default card safe.
--
-- What this table stores: only card brand, last 4 digits, expiry and the
-- default flag -- never a full card number or CVV (there is no column for
-- them). The app derives brand/last4 from the typed number purely for
-- display; there is still no payment processor (same accepted simplification
-- as confirm_subscription_payment, decisions #4/#16).
--
-- RLS already covers self-owned rows on this table (select / insert / update /
-- delete own, see initial_schema.sql), so -- like Edit Profile -- no RPC is
-- needed: these are exactly the self-owned writes decision #3 always allowed.
-- What RLS does NOT cover is the *relationship between rows* (only one
-- default), and that is what this migration adds:
--
--   1. A partial unique index -- the hard guarantee. Postgres itself refuses a
--      second is_default = true row for the same user, whatever the client
--      does and however requests interleave.
--   2. A BEFORE trigger that makes "set this card as default" a single atomic
--      step: it clears the user's other default first, then lets the write
--      through (so the client never has to uncheck the old default itself).
--      It also makes a user's FIRST card the default automatically. The old
--      trigger was AFTER + convenience only, with no constraint behind it;
--      under two concurrent requests both could end up default.
--   3. An AFTER DELETE trigger: deleting the default card promotes the most
--      recently added remaining card, so a user who has cards always has a
--      default.
--   4. The old CHECK (exp_year >= extract(year from now())) is replaced. It is
--      re-evaluated on EVERY update of a row, so once a saved card's year had
--      passed, ANY update of it failed -- including the trigger above clearing
--      an old default, which would have made "set a new default" fail whenever
--      the old default card had expired. "Not already expired" is now checked
--      once, on INSERT only (year AND month).

-- ------------------------------------------------------------
-- 4. replace the now()-based CHECK
-- ------------------------------------------------------------
alter table public.payment_methods
  drop constraint if exists payment_methods_exp_year_check;

alter table public.payment_methods
  drop constraint if exists payment_methods_exp_year_range;
alter table public.payment_methods
  add constraint payment_methods_exp_year_range check (exp_year between 2000 and 2200);

-- ------------------------------------------------------------
-- 1. the hard guarantee: at most one default per user
-- ------------------------------------------------------------
-- Any pre-existing duplicate defaults must be resolved first or the index
-- can't be built: keep each user's most recently updated default.
update public.payment_methods pm
set is_default = false
where pm.is_default
  and pm.id <> (
    select p2.id
    from public.payment_methods p2
    where p2.user_id = pm.user_id and p2.is_default
    order by p2.updated_at desc, p2.id
    limit 1
  );

create unique index if not exists uq_payment_methods_one_default_per_user
  on public.payment_methods (user_id)
  where (is_default);

-- ------------------------------------------------------------
-- 2. atomic swap + first card is default + reject already-expired cards
-- ------------------------------------------------------------
create or replace function public.enforce_single_default_payment_method()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    -- Not already expired (year and month). Checked on insert only; see 4.
    if (new.exp_year, new.exp_month) <
       (extract(year from current_date)::int, extract(month from current_date)::int) then
      raise exception 'card_expired';
    end if;

    -- A user's first card is always their default.
    if not exists (select 1 from public.payment_methods where user_id = new.user_id) then
      new.is_default := true;
    end if;
  end if;

  -- Making this card the default clears the user's other default first, so
  -- the partial unique index above is satisfied and the swap is one step.
  if new.is_default then
    update public.payment_methods
    set is_default = false
    where user_id = new.user_id
      and id <> new.id
      and is_default;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_payment_methods_single_default on public.payment_methods;
create trigger trg_payment_methods_single_default
before insert or update of is_default on public.payment_methods
for each row execute function public.enforce_single_default_payment_method();

-- ------------------------------------------------------------
-- 3. deleting the default promotes another card
-- ------------------------------------------------------------
create or replace function public.promote_default_payment_method()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if old.is_default then
    update public.payment_methods
    set is_default = true
    where id = (
      select id
      from public.payment_methods
      where user_id = old.user_id
      order by created_at desc, id
      limit 1
    );
  end if;
  return null;
end;
$$;

drop trigger if exists trg_payment_methods_promote_default on public.payment_methods;
create trigger trg_payment_methods_promote_default
after delete on public.payment_methods
for each row execute function public.promote_default_payment_method();
