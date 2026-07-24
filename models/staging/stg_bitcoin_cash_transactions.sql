{{ config(
    materialized = "table",
    partition_by = {
      "field": "block_timestamp",
      "data_type": "timestamp",
      "granularity": "day"
    }
) }}

with latest_available_month as (

    select
        max(block_timestamp_month) as latest_month

    from {{ source("bitcoin_cash", "transactions") }}
),

filtered_transactions as (

    select
        transactions.*

    from {{ source("bitcoin_cash", "transactions") }} as transactions

    cross join latest_available_month

    where transactions.block_timestamp_month >= date_sub(
        latest_available_month.latest_month,
        interval 2 month
    )

    and transactions.block_timestamp_month <=
        latest_available_month.latest_month
)

select *
from filtered_transactions