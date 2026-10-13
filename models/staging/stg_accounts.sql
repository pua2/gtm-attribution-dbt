with source as (
    select * from {{ ref('raw_accounts') }}
),

renamed as (
    select
        account_id,
        account_name,
        industry,
        segment,
        cast(created_date as date) as created_date
    from source
)

select * from renamed
