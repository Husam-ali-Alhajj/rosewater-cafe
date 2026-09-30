-- Adds 'pending' to subscription_status (pending -> active -> expired/cancelled).
--
-- In its own migration because Postgres can't use a new enum value in the same transaction that
-- added it, and the next migration uses it.
alter type public.subscription_status add value if not exists 'pending' before 'active';
