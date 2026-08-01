# Roadmap Process — Cadence & Scorecard

How the DROPZONA roadmap is run week to week, and how we measure whether each milestone is actually reached. This complements [`CONTRIBUTING.md`](../../CONTRIBUTING.md) (board rules, taxonomy, standing rules) with the **rhythm** and the **numbers**.

Build baseline: **prod HEAD `61d0e5a` (2026-07-22)**. Milestones and priority/effort/area labels are defined in `CONTRIBUTING.md`; this doc does not redefine them.

---

## Cadence

A single weekly loop keeps the board reconciled with prod, plus a monthly risk pass.

| Ritual | Frequency | Who | Purpose | Output |
|---|---|---|---|---|
| **Sprint sync** | Weekly (Mon) | Andrey · Bohdan · Eugen | Confirm the `Now` column, pull from `Next`, resolve blocking owner decisions on the call | Agreed `Now` list + decision log entries |
| **Async status** | Mid-week | Item owners | Flag blocked vs on-track per `Now` card | Blockers surfaced early |
| **Review + scorecard** | Weekly (Fri) | All | Move verified items to `Done`, re-slot the rest, update the scorecard below | Refreshed KPIs, board = prod |
| **Risk review** | Monthly | Andrey | Re-rank the risk register; CRITICAL blocks its milestone | Updated risk ranking |
| **Milestone gate** | On milestone exit | All | Check the DoD/scorecard for the milestone before declaring it reached | Milestone marked reached (or not) |

**Decision discipline.** Blocking decisions (chain/token + min-max top-up bounds, winners-count, role-switch semantics, kill/park calls) are resolved on the Monday sync and **written into the decision log**. Un-logged = un-decided.

**Scope freeze during M1.** No new features and no casino side-quests until M1 closes. New ideas go to `Later`/`Parked`, not `Now`.

---

## Scorecard — KPIs per milestone

Each milestone has a small set of metrics that define "reached." We report the four north-star numbers every Friday and gate the milestone on its targets. `—` means the metric is not yet meaningful at that stage (report `n/a`, don't fabricate it).

### North-star metrics (tracked every week)

| Metric | Definition | Source |
|---|---|---|
| **Activated streamers** | Streamers who connected Steam + GSI, funded a balance, and ran ≥ 1 real drop | Backend (post-`DZ-08` persistence) |
| **Drops delivered** | Giveaways that reached a **confirmed-delivered** terminal state (escrow rollbacks excluded) | `Drops` / `DrawAudit` |
| **GMV** | Total prize spend routed through drops (fee-inclusive once the fee is on) | Ledger + `Drops` |
| **Retention** | Share of activated streamers who run a drop in two consecutive weeks (W-over-W) | `Drops` by streamer |

> Until `Drops` + `DrawAudit` persistence (`DZ-08`/`DZ-01`) lands, most of these have **no data source** — the keystone that unblocks the scorecard is itself on the M1 money track.

### Targets by milestone

| KPI | **M0 Truth & Hygiene** | **M1 Fundable Beta** | **M2 Proof & Public Beta** | **M3 Retention & Moat** |
|---|---|---|---|---|
| **Activated streamers** | — | First self-funded alpha (1–3, white-glove) | **25+** activated | 100+ activated |
| **Drops delivered** | — | ≥ 1 real, audited, confirmed-delivered drop end-to-end | Steady weekly drops across the alpha cohort | Sustained weekly volume |
| **GMV** | — | ≥ $1 real deposit becomes spendable **and** is spent | Alpha float in use, capped ≤ $500, fee **OFF** | Fee **ON** (~10%); positive fee-on signal |
| **Retention (W-over-W)** | — | — (single-cohort, too early) | Baseline established | **≥ target** (moat metric) |
| **Founding clip** | — | Captured in white-glove alpha (manually-funded prize) | Cut into 9:16 variants, driving short-form | Anchors public launch |
| **Gate also requires** | Credential rotated + purged; no mock numbers a funded user can reach | Full [M1 DoD](../../CONTRIBUTING.md#definition-of-done--m1-fundable-beta) met | Legal review done; MyDrop comparison/SEO live | Pricing published; provider abstraction shipped |

### Health / guardrail metrics (watch, don't game)

| Metric | Why we watch it | Guardrail |
|---|---|---|
| **Overspend / negative-balance events** | Confirmed money-loss risk (`DZ-02`/`DZ-06`) | **0** — any occurrence is a P0 stop-ship |
| **Escrow-rollback losses** | Escrow ≠ delivered (`DZ-06b`) | **0** unrefunded rollbacks |
| **Money-path test coverage** | Regression safety on funds | Green `dotnet test` on every spend-path change |
| **Cost-per-signup** | The number paid amplification is judged on (never raw views) | Trends down before scaling spend |
| **Skin-supplier float exposure** | Counterparty risk (R1/R2) | ≤ $500, and **$0** until refundable terms are in writing |

---

## Reporting format

Each Friday, append one row to the running scorecard log:

```
| Week | Activated | Drops delivered | GMV | Retention W/W | Overspend events | Notes |
|------|-----------|-----------------|-----|---------------|------------------|-------|
```

Keep it honest: a metric with no real data source is `n/a`, never a mock number. The whole point of the `Drops`/`DrawAudit` keystone is that these figures become real instead of placeholder.
