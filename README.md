# GTM Campaign Attribution (dbt)

A production-shaped dbt project that answers one go-to-market question:

> **For each marketing campaign, did we generate money?**

It models Salesforce-style CRM data (accounts, campaigns, campaign members,
opportunities, and a campaign-influence bridge) into a campaign-performance mart
with cost, weighted-attribution revenue, net return, and ROI — and it solves the
double-counting trap that a naive many-to-many join falls into.

Runs locally on DuckDB with zero infrastructure. The SQL stays portable to
Snowflake (see [Portability](#portability)).

---

## The data model

```
accounts ──< opportunities >──┐
                              │ (bridge: campaign_influence)
campaigns ──< campaign_members│
        └─────────────────────< campaign_influence >── opportunities
```

- **accounts** — customers.
- **campaigns** — marketing efforts, each with a cost.
- **campaign_members** — people engaged by a campaign (the funnel layer).
- **opportunities** — deals, each with an amount and a stage; money is booked when the stage is Closed Won.
- **campaign_influence** — the many-to-many bridge crediting campaigns for the deals they influenced, with an influence weight per link.

## The core problem: don't double-count revenue

The bridge is many-to-many: one deal can be influenced by several campaigns.
If you sum `opportunity.amount` per campaign, a **$100k deal influenced by three
campaigns reports as $300k** of campaign revenue. Multiply that across a pipeline
and marketing's numbers no longer tie to finance's bookings.

The fix lives in [`int_campaign_influence_weighted`](models/intermediate/int_campaign_influence_weighted.sql):
split each deal's amount across its campaigns by influence weight, so **every
dollar is credited exactly once**. Weights are re-normalized to sum to 1.0 per
deal so the result always reconciles.

Two [singular tests](tests/) enforce this as a data contract:
- `assert_influence_weights_sum_to_one` — every deal's weights sum to 1.0.
- `assert_attribution_reconciles_to_bookings` — total attributed won revenue equals actual won bookings (no double-count, no dropped revenue).

## Results (from the seed data)

Total won bookings across influenced deals = **$740k**, and attribution
reconciles to it exactly:

| campaign | cost | attributed won rev | net return | ROI |
|---|---:|---:|---:|---:|
| Partner Referral Program | $3,000 | $126,000 | $123,000 | **41.0x** |
| Google Search - Brand | $25,000 | $184,000 | $159,000 | 6.4x |
| 2025 Security Summit | $50,000 | $200,000 | $150,000 | 3.0x |
| Zero Trust Whitepaper | $8,000 | $110,000 | $102,000 | 12.8x |
| Q1 Webinar Series | $12,000 | $120,000 | $108,000 | 9.0x |
| Cold Outbound - SDR | $15,000 | $0 | -$15,000 | -1.0x |

The insight the model surfaces: the **$3k referral program returned 41x**, while
the **$15k cold-outbound campaign influenced nothing** and lost its whole budget.

## What this project demonstrates

- **Layered modeling** — `staging` (clean/rename) → `intermediate` (attribution logic) → `marts` (business-facing fact).
- **Macros for DRY** — `cents_to_dollars` and `normalize_stage` keep money and stage logic in one place.
- **Incremental model** — `fct_opportunities` loads only rows newer than the last run via a `created_at` watermark.
- **Testing** — schema tests (unique, not_null, relationships, accepted_values) plus two singular data-contract tests.
- **CI** — GitHub Actions runs `dbt build` on every push and PR; a failing test blocks merge.

## Run it

```bash
python -m venv .venv && source .venv/bin/activate
pip install "dbt-duckdb==1.9.*"
dbt build --profiles-dir .        # seeds, models, and tests in dependency order
```

Then inspect the answer:

```bash
duckdb gtm_attribution.duckdb "select campaign_name, actual_cost, attributed_won_revenue, roi from fct_campaign_performance order by roi desc nulls last"
```

## Portability

DuckDB is used so the project runs anywhere with no account or credentials. The
SQL avoids engine-specific syntax; to point it at Snowflake, swap the adapter
(`pip install dbt-snowflake`) and replace the `profiles.yml` output with Snowflake
credentials. The models, tests, and macros are unchanged.

## Note on my background

My production transformation framework day-to-day is **SQLMesh**, which is
dbt-equivalent — the same model/audit/contract concepts. This repo is dbt Core,
built to show those concepts in dbt's own idiom (models, `ref`, tests, macros,
incremental materialization, and slim CI).
