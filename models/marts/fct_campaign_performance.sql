{#
    One row per campaign answering the business question:
    "Did this campaign generate money?"

    Combines campaign cost, funnel engagement (members), and weighted-attribution
    revenue into net return and ROI. LEFT JOINs from campaigns so a campaign that
    influenced nothing still shows up — those are the ones marketing needs to see.
#}
with campaigns as (
    select * from {{ ref('stg_campaigns') }}
),

influence as (
    select * from {{ ref('int_campaign_influence_weighted') }}
),

members as (
    select
        campaign_id,
        count(*) as total_members,
        sum(case when responded then 1 else 0 end) as responded_members
    from {{ ref('stg_campaign_members') }}
    group by 1
),

attribution as (
    select
        campaign_id,
        count(distinct opportunity_id) as influenced_opportunities,
        sum(attributed_won_revenue) as attributed_won_revenue,
        sum(attributed_open_pipeline) as attributed_open_pipeline
    from influence
    group by 1
)

select
    c.campaign_id,
    c.campaign_name,
    c.campaign_type,
    c.actual_cost,
    coalesce(m.total_members, 0) as total_members,
    coalesce(m.responded_members, 0) as responded_members,
    coalesce(a.influenced_opportunities, 0) as influenced_opportunities,
    coalesce(a.attributed_won_revenue, 0) as attributed_won_revenue,
    coalesce(a.attributed_open_pipeline, 0) as attributed_open_pipeline,
    coalesce(a.attributed_won_revenue, 0) - c.actual_cost as net_return,
    case
        when c.actual_cost > 0
            then round((coalesce(a.attributed_won_revenue, 0) - c.actual_cost) / c.actual_cost, 2)
        else null
    end as roi
from campaigns c
left join members m on c.campaign_id = m.campaign_id
left join attribution a on c.campaign_id = a.campaign_id
order by attributed_won_revenue desc
