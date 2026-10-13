with source as (
    select * from {{ ref('raw_opportunities') }}
),

renamed as (
    select
        opportunity_id,
        account_id,
        opportunity_name,
        {{ normalize_stage('stage') }} as stage,
        {{ cents_to_dollars('amount_cents') }} as amount,
        cast(is_closed as boolean) as is_closed,
        cast(is_won as boolean) as is_won,
        primary_campaign_id,
        cast(close_date as date) as close_date,
        cast(created_date as timestamp) as created_at
    from source
)

select * from renamed
