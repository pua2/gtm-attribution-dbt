with source as (
    select * from {{ ref('raw_campaign_members') }}
),

renamed as (
    select
        campaign_member_id,
        campaign_id,
        contact_name,
        member_status,
        cast(responded as boolean) as responded,
        cast(created_date as date) as created_date
    from source
)

select * from renamed
