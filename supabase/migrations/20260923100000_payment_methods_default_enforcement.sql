-- Makes "one default card per user" a real database rule, and makes deleting the default card safe.
--
-- The table only stores card brand, last 4 digits, expiry and the default flag, never the full
-- number or CVV. Users already manage their own rows through RLS; this adds the rules between rows:
--
-- 1. A partial unique index: at most one default card per user, even with requests at the same
-- moment.
-- 2. A trigger that unsets the old default when a new one is chosen (one step), and makes the first
-- card the default.
-- 3. A trigger that makes the newest remaining card the default when the default is deleted.
-- 4. The old expiry CHECK is replaced: it ran on every update, so once a card's year had passed,
-- even unsetting it as default failed. Now "not expired" is only checked when a card is added.

-- 4. Replace the expiry CHECK
alter table public.payment_methods
  drop constraint if exists payment_methods_exp_year_check;

alter table public.payment_methods
  drop constraint if exists payment_methods_exp_year_range;
alter table public.payment_methods
  add constraint payment_methods_exp_year_range check (exp_year between 2000 and 2200);

-- 1. At most one default per user. Existing duplicates are cleaned up first (the most recently
-- updated one stays default).
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

-- 2. One-step default swap, first card is default, reject expired cards
create or replace function public.enforce_single_default_payment_method()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    -- Not already expired (year and month). Only checked on insert.
    if (new.exp_year, new.exp_month) <
       (extract(year from current_date)::int, extract(month from current_date)::int) then
      raise exception 'card_expired';
    end if;

    -- A user's first card is always the default.
    if not exists (select 1 from public.payment_methods where user_id = new.user_id) then
      new.is_default := true;
    end if;
  end if;

  -- Unset the user's other default first, so the unique index is satisfied.
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

-- 3. Deleting the default picks another card
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
