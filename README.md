# Bitcoin Cash Analytics — dbt

This repository contains the dbt implementation for the Astrafy Data Engineer take-home challenge.

It reads Bitcoin Cash blockchain data from the public BigQuery dataset:

```text
bigquery-public-data.crypto_bitcoin_cash.transactions
```

The project creates:

- A staging table containing the latest three available months of transactions
- A data mart containing the current balance by address
- A GitHub Actions workflow that runs dbt on pull requests

## Architecture

```text
BigQuery public dataset
        ↓
dbt staging model
        ↓
staging.stg_bitcoin_cash_transactions
        ↓
dbt data mart
        ↓
data_mart.mart_address_balances
```

The Google Cloud project, datasets, service account, and permissions are provisioned separately with Terraform.

## Project structure

```text
.
├── .github/
│   └── workflows/
│       └── dbt-ci.yml
├── macros/
│   └── generate_schema_name.sql
├── models/
│   ├── sources.yml
│   ├── staging/
│   │   ├── stg_bitcoin_cash_transactions.sql
│   │   └── staging.yml
│   └── marts/
│       ├── mart_address_balances.sql
│       └── marts.yml
├── dbt_project.yml
├── profiles.yml
├── requirements.txt
└── README.md
```

## Models

### Staging

```text
staging.stg_bitcoin_cash_transactions
```

This model selects the three latest calendar months available in the public source:

- March 2024
- April 2024
- May 2024

The source currently contains data up to May 13, 2024.

Fixed partition boundaries are used so BigQuery can prune unrelated partitions and reduce the amount of data processed.

The source column `hash` is renamed to `transaction_hash` because `HASH` is a reserved BigQuery keyword and caused generic dbt tests to fail.

### Data mart

```text
data_mart.mart_address_balances
```

Bitcoin Cash uses the UTXO, or Unspent Transaction Output, model.

The balance is calculated by:

1. Reading all transaction outputs
2. Identifying outputs referenced by transaction inputs
3. Keeping only outputs that have not been spent
4. Summing the remaining output values by address
5. Excluding addresses linked to at least one coinbase transaction

In this project, **coinbase transaction** means a blockchain mining-reward transaction, not the Coinbase exchange.

The mart exposes balances in both satoshis and Bitcoin Cash.

## Important modelling assumption

The staging model is limited to three months, as required by the challenge.

However, calculating the true current balance of every address requires the complete blockchain transaction history. An address may still own an unspent output created several years ago.

The data mart therefore reads full historical transaction input and output data rather than relying only on the three-month staging table.

## Prerequisites

- Python 3.12
- Google Cloud CLI
- dbt Core
- dbt-bigquery
- Access to the Google Cloud project

Google Cloud project:

```text
astrafy-bch-xlofi-2026
```

BigQuery datasets:

```text
staging
data_mart
```

## Installation

Create and activate a virtual environment:

```bash
python3 -m venv ~/.venvs/astrafy-dbt
source ~/.venvs/astrafy-dbt/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Authenticate with Google Cloud for local development:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project astrafy-bch-xlofi-2026
```

## Local dbt profile

Create or update:

```text
~/.dbt/profiles.yml
```

Example:

```yaml
bitcoin_cash_analytics:
  target: dev

  outputs:
    dev:
      type: bigquery
      method: oauth
      project: astrafy-bch-xlofi-2026
      dataset: staging
      location: US
      threads: 4
      priority: interactive
```

Test the connection:

```bash
dbt debug --profiles-dir ~/.dbt --target dev
```

## Run the project

Run all models:

```bash
dbt run --profiles-dir ~/.dbt --target dev
```

Run the staging model:

```bash
dbt run \
  --profiles-dir ~/.dbt \
  --target dev \
  --select stg_bitcoin_cash_transactions
```

Run the data mart:

```bash
dbt run \
  --profiles-dir ~/.dbt \
  --target dev \
  --select mart_address_balances
```

Run the tests:

```bash
dbt test --profiles-dir ~/.dbt --target dev
```

The project currently contains:

- 2 dbt models
- 8 data-quality tests
- 1 BigQuery source

## Continuous integration

GitHub Actions runs when:

- A pull request is opened
- A pull request is reopened
- A new commit is pushed to an existing pull request

The workflow:

1. Checks out the repository
2. Authenticates with Google Cloud
3. Installs Python and dbt
4. Validates the dbt configuration
5. Runs `dbt run`
6. Runs `dbt test`

Required GitHub secrets:

```text
GCP_PROJECT_ID
GCP_SERVICE_ACCOUNT_KEY
```

Credentials are never committed to the repository.

The CI service account and its permissions are provisioned through Terraform. In production, Workload Identity Federation would be preferred over a long-lived service-account key.

## Validation

The staging model currently materializes:

```text
5,136,399 transactions
3 monthly partitions
2024-03-01 to 2024-05-13
```

The final dbt test run passes all eight tests.

## Author

Julio Germade  
Astrafy Data Engineer Take-Home Challenge
