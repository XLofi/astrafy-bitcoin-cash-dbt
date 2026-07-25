{{ config(
    materialized = "table",
    partition_by = {
      "field": "block_timestamp",
      "data_type": "timestamp",
      "granularity": "day"
    }
) }}

with filtered_transactions as (

    select
        transactions.* except (`hash`),
        transactions.`hash` as transaction_hash

    from {{ source("bitcoin_cash", "transactions") }} as transactions

    where transactions.block_timestamp_month >= date("2024-03-01")
      and transactions.block_timestamp_month < date("2024-06-01")
)

select *
from filtered_transactions