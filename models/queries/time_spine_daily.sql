{{
    config(
        materialized = 'table',
    )
}}

select cast(range as date) as date_day
from range(date '1990-01-01', date '2000-01-01', interval 1 day)
