with source as (
    select * from {{ ref('raw_campaigns') }}
),

renamed as (
    select
        campaign_id,
        campaign_name,
        campaign_type,
        {{ cents_to_dollars('actual_cost_cents') }} as actual_cost,
        cast(start_date as date) as start_date,
        cast(end_date as date) as end_date,
        cast(is_active as boolean) as is_active
    from source
)

select * from renamed
