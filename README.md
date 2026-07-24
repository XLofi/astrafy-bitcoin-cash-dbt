# Bitcoin Cash Analytics — dbt

This repository contains the dbt part of the Astrafy Data Engineer take-home challenge.

It reads Bitcoin Cash blockchain data from the public BigQuery dataset:

```text
bigquery-public-data.crypto_bitcoin_cash.transactions
````

The project creates:

* A staging table containing the latest three months of available transactions
* A data mart containing the current balance by address
* A GitHub Actions workflow that runs dbt on pull requests

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
├── models/
│   ├── sources.yml
│   ├── staging/
│   │   ├── stg_bitcoin_cash_transactions.sql
│   │   └── staging.yml
│   └── marts/
│       ├── mart_address_balances.sql
│       └── marts.yml
├── dbt_project.yml
├── requirements.txt
└── README.md
```

## Models

### Staging

```text
staging.stg_bitcoin_cash_transactions
```

This model selects the three latest calendar months available in the source table.

The source dataset is not necessarily updated up to the current date, so the model uses the latest available month instead of `CURRENT_DATE()`.

### Data mart

```text
data_mart.mart_address_balances
```

Bitcoin Cash uses the UTXO model.

The balance is calculated by:

1. Reading transaction outputs
2. Identifying outputs that were spent
3. Keeping only unspent outputs
4. Summing their values by address
5. Excluding addresses linked to at least one coinbase transaction

In this project, **coinbase transaction** means a blockchain mining-reward transaction, not the Coinbase exchange.

## Prerequisites

* Python 3.12
* Google Cloud CLI
* dbt Core
* dbt-bigquery
* Access to the Google Cloud project

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

Authenticate with Google Cloud:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project astrafy-bch-xlofi-2026
```

## dbt profile

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
dbt debug
```

## Run the project

Run all models:

```bash
dbt run
```

Run the staging model:

```bash
dbt run --select stg_bitcoin_cash_transactions
```

Run the data mart:

```bash
dbt run --select mart_address_balances
```

Run the tests:

```bash
dbt test
```

## Continuous integration

GitHub Actions runs when:

* A pull request is opened
* A pull request is reopened
* A new commit is pushed to a pull request

The workflow:

1. Installs Python
2. Installs dbt
3. Authenticates with Google Cloud
4. Runs `dbt run`

Required GitHub secrets:

```text
GCP_PROJECT_ID
GCP_SERVICE_ACCOUNT_KEY
```

Credentials must never be committed to the repository.

## Important assumption

The staging model is limited to three months.

However, calculating the true current balance of every address requires the complete blockchain transaction history. The data mart therefore needs full historical input and output data.

## Author

Julio Germade
Astrafy Data Engineer Take-Home Challenge

```
```
