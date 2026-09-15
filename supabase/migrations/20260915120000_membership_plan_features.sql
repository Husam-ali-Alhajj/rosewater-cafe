-- Adds the plan-specific perk bullets the Figma design shows beyond the
-- numeric ones (hookah/drinks/guests) already derivable from existing
-- columns -- e.g. "Priority seating", "24/7 access", "Exclusive menu".
--
-- Kept as a real column rather than hardcoded copy in the Flutter widget:
-- the whole point of Task 2 was that Choose Membership renders from real
-- database rows, not hardcoded plan data -- adding these as literal
-- strings in the app would quietly reintroduce that for exactly the
-- content most likely to need editing later (marketing copy).
--
-- Text pulled verbatim from the Figma file (node 1213:1030, "Choose Your
-- Membership") via its API, not retyped from a screenshot. Note VIP's own
-- bullet list in the design does NOT repeat "Member discounts" the way
-- Basic and Premium's do -- the footer note ("All plans include member
-- discounts") already covers it for VIP, so this mirrors that asymmetry
-- exactly rather than "fixing" it.
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
