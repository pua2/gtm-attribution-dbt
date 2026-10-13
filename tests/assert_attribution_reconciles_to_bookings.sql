-- Data contract: total weighted-attribution won revenue must equal the actual
-- won revenue of the influenced opportunities. This proves the weighting
-- neither double-counts (the bug this project fixes) nor drops revenue.
-- FAILS (returns a row) if the two totals diverge by more than a cent.
with attributed as (
    select sum(attributed_won_revenue) as total_attributed
    from {{ ref('int_campaign_influence_weighted') }}
),

actual as (
    select sum(o.amount) as total_actual
    from {{ ref('stg_opportunities') }} o
    where o.is_won
      and o.opportunity_id in (
          select distinct opportunity_id from {{ ref('stg_campaign_influence') }}
      )
)

select
    attributed.total_attributed,
    actual.total_actual
from attributed
cross join actual
where abs(attributed.total_attributed - actual.total_actual) > 0.01
