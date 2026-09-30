-- Adds each plan's extra perks from the design (for example "Priority seating", "24/7 access"),
-- stored in the database so they can be edited without an app update.
--
-- VIP doesn't list "Member discounts" because the design's footer already says all plans include
-- it.
alter table public.membership_plans
  add column features text[] not null default '{}';

update public.membership_plans
set features = array['Standard seating', 'Member discounts']
where name = 'Basic';

update public.membership_plans
set features = array['Priority seating', 'Weekend access', 'Member discounts']
where name = 'Premium';

update public.membership_plans
set features = array['Private booth', '24/7 access', 'Event priority', 'Exclusive menu']
where name = 'VIP';
