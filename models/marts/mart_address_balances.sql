{{ config(
    materialized = "table",
    cluster_by = ["address"]
) }}

with all_outputs as (

    select
        transaction.`hash` as transaction_hash,
        output.index as output_index,
        address,
        output.value

    from {{ source("bitcoin_cash", "transactions") }} as transaction,
    unnest(transaction.outputs) as output,
    unnest(output.addresses) as address

    where address is not null

),

spent_outputs as (

    select distinct
        input.spent_transaction_hash as transaction_hash,
        input.spent_output_index as output_index

    from {{ source("bitcoin_cash", "transactions") }} as transaction,
    unnest(transaction.inputs) as input

    where input.spent_transaction_hash is not null

),

coinbase_addresses as (

    select distinct
        address

    from {{ source("bitcoin_cash", "transactions") }} as transaction,
    unnest(transaction.outputs) as output,
    unnest(output.addresses) as address

    where transaction.is_coinbase = true
      and address is not null

),

unspent_outputs as (

    select
        outputs.address,
        outputs.value

    from all_outputs as outputs

    left join spent_outputs as spent
      on outputs.transaction_hash = spent.transaction_hash
     and outputs.output_index = spent.output_index

    where spent.transaction_hash is null

),

address_balances as (

    select
        address,
        sum(value) as balance_satoshis

    from unspent_outputs
    group by address

)

select
    balances.address,
    balances.balance_satoshis,
    safe_divide(balances.balance_satoshis, 100000000) as balance_bch

from address_balances as balances

left join coinbase_addresses
    using (address)

where coinbase_addresses.address is null
  and balances.balance_satoshis > 0
