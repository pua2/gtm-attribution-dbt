-- Data contract: every opportunity's campaign influence weights must sum to
-- ~1.0. If they don't, attributed revenue will not reconcile to actual bookings.
-- This test FAILS (returns rows) for any opportunity that violates the rule.
select
    opportunity_id,
    sum(influence_weight) as total_weight
from {{ ref('stg_campaign_influence') }}
group by opportunity_id
having abs(sum(influence_weight) - 1.0) > 0.001
