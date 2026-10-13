{#
    The core of the project.

    Because the campaign<->opportunity bridge is many-to-many, naively summing
    opportunity.amount per campaign DOUBLE-COUNTS revenue: a $100k deal
    influenced by three campaigns would report as $300k of "campaign revenue".

    Fix: split each deal's amount across its campaigns by influence weight, so
    every dollar of a deal is credited exactly once across all campaigns. The
    weights are re-normalized defensively so they always sum to 1.0 per deal,
    even if the source CRM weights drift.
#}
with influence as (
    select * from {{ ref('stg_campaign_influence') }}
),

opportunities as (
    select * from {{ ref('stg_opportunities') }}
),

weight_totals as (
    select
        opportunity_id,
        sum(influence_weight) as total_weight
    from influence
    group by 1
),

normalized as (
    select
        i.campaign_id,
        i.opportunity_id,
        i.influence_weight / nullif(wt.total_weight, 0) as normalized_weight
    from influence i
    inner join weight_totals wt
        on i.opportunity_id = wt.opportunity_id
)

select
    n.campaign_id,
    n.opportunity_id,
    n.normalized_weight,
    o.amount,
    o.is_won,
    o.is_closed,
    o.amount * n.normalized_weight as attributed_amount,
    case when o.is_won then o.amount * n.normalized_weight else 0 end as attributed_won_revenue,
    case when not o.is_closed then o.amount * n.normalized_weight else 0 end as attributed_open_pipeline
from normalized n
inner join opportunities o
    on n.opportunity_id = o.opportunity_id
