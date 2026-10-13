{#
    Incremental opportunity fact. On the first run it loads every opportunity;
    on later runs it only processes rows created since the last run, using the
    created_at watermark. This is the same pattern used to load only changed
    CRM records instead of re-scanning the whole source each night.
#}
{{
    config(
        materialized='incremental',
        unique_key='opportunity_id'
    )
}}

with opportunities as (
    select * from {{ ref('stg_opportunities') }}
)

select
    opportunity_id,
    account_id,
    opportunity_name,
    stage,
    amount,
    is_closed,
    is_won,
    primary_campaign_id,
    close_date,
    created_at
from opportunities

{% if is_incremental() %}
where created_at > (select coalesce(max(created_at), cast('1900-01-01' as timestamp)) from {{ this }})
{% endif %}
