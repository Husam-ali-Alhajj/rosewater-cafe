-- Add 'pending' to subscription_status, ordered before 'active' in the
-- state machine: pending -> active -> expired/cancelled.
--
-- This is deliberately its own migration file/transaction. Postgres
-- forbids using a newly-added enum value (e.g. in an index predicate or
-- a DML statement) within the same transaction that added it. The next
-- migration references 'pending' in a partial unique index and in
-- function bodies, so this value must already be committed first.
alter type public.subscription_status add value if not exists 'pending' before 'active';
