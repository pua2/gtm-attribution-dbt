{#
    Convert an integer cents column to a dollar amount.
    Written once, reused across every staging model that handles money,
    so the rounding rule lives in exactly one place (DRY).
#}
{% macro cents_to_dollars(column_name, decimal_places=2) %}
    round(cast({{ column_name }} as {{ dbt.type_numeric() }}) / 100, {{ decimal_places }})
{% endmacro %}
