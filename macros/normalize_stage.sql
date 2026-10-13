{#
    Salesforce stage names are free-form and inconsistent ("Closed Won",
    "closed-won", "Won"). Collapse them to a canonical set so every
    downstream model and dashboard groups deals the same way.
#}
{% macro normalize_stage(column_name) %}
    case
        when lower(trim({{ column_name }})) in ('closed won', 'closed-won', 'won') then 'Closed Won'
        when lower(trim({{ column_name }})) in ('closed lost', 'closed-lost', 'lost') then 'Closed Lost'
        when lower(trim({{ column_name }})) in ('prospecting', 'qualification', 'discovery') then 'Early Stage'
        when lower(trim({{ column_name }})) in ('proposal', 'negotiation') then 'Late Stage'
        else 'Unknown'
    end
{% endmacro %}
