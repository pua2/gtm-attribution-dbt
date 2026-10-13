{#
    The bridge table: a many-to-many link between campaigns and opportunities.
    One opportunity can be influenced by several campaigns, and one campaign
    influences many opportunities. influence_weight is Salesforce Campaign
    Influence — the fraction of credit a campaign gets for a deal.
#}
with source as (
    select * from {{ ref('raw_campaign_influence') }}
),

renamed as (
    select
        influence_id,
        campaign_id,
        opportunity_id,
        cast(influence_weight as double) as influence_weight
    from source
)

select * from renamed
