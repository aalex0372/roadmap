# Dropzona — Product Roadmap

> The public roadmap for **[Dropzona](https://dropzona.tv)** — CS2 skin-giveaway automation for Twitch streamers.

![milestone](https://img.shields.io/badge/focus-M1%20Fundable%20Beta-blue) ![status](https://img.shields.io/badge/beta-not%20reached-orange) ![p0](https://img.shields.io/badge/open%20P0-10-red) ![prod](https://img.shields.io/badge/prod%20HEAD-61d0e5a-lightgrey)

This repository is where we plan Dropzona in the open: the **board** ([`ROADMAP.md`](ROADMAP.md)), the **track-level detail** ([`docs/roadmap/`](docs/roadmap/)), and the **GitHub Project + Issues** that track day-to-day work. Everything here is grounded in a code-verified audit of the production repo, not aspirational slideware.

---

## What is Dropzona?

Dropzona lets a Twitch streamer run **automated, free-to-enter CS2 skin giveaways** live on stream: a Steam GSI event (an ace, a clutch, a round win) triggers a random draw from eligible chat, and the winning viewer is delivered a real skin — sourced and shipped through a non-gambling merchant marketplace. **Viewers never pay to enter**; streamers fund a wallet balance that covers prize spend. The model is a free tool during beta, moving to a ~10% service fee on prize spend after launch.

---

## Current focus

> ### 🎯 M1 — Fundable Beta · ~1.5–2 focused sprints
>
> The money-**IN** stack shipped and is real (persisted balance ledger + OpenSettle top-ups + a signed, idempotent, `fullySettled`-gated webhook — `DZ-03` ✅ **Done**). We are **not at M1 yet**: **8 of 9** Definition-of-Done items are still open, and every one is an **S** or **M** ticket. These are the M1-critical-path P0s (the board carries **10 open P0s** in total); the critical path is short and specific:
>
> - 🔴 **`P0` Overspend guard** (`DZ-02` / `DZ-06`) — the balance deduction is not yet atomic, so concurrent draws can drive a streamer's balance below zero: a real-money double-spend. **Fix:** fold the balance check and the debit into one transaction with a non-negative floor and per-streamer concurrency control. **Acceptance:** a concurrent-spend test proves the balance can never go negative. Ship-blocker before any funded stream.
> - 🔴 **`P0` Escrow-rollback money-loss** (`DZ-06b`) — a Steam trade sitting in escrow is counted as *delivered* and debited, but escrow can roll back days later, leaving the streamer debited for a prize the winner never received: permanent loss. **Fix:** only count delivery on a terminal accepted/confirmed signal, and refund the ledger on rollback. **Acceptance:** a rolled-back trade always leaves the streamer made whole.
> - 🔑 **`P0` Drops + DrawAudit persistence** (`DZ-01` / `DZ-08`) — the **keystone**: today every draw persists *nothing*. This one write-path unblocks most placeholder surfaces (dashboard, history, profile, viewer my-drops) and is our dispute/"was it fair?" defense.
> - 🔴 **`P0` `end-live` NRE crash** (`DZ-07`) — an un-injected dependency throws on every `end-live` call, so streamers cannot cleanly end a session.
>
> Plus one **`Security` `P0`** (`DZ-30`): rotate an exposed CI/bot credential committed to the production repo, purge it from git history, and move to env-injected secrets (see [Security note](#security)).

Full Definition-of-Done scorecard lives in [`docs/roadmap/backend-money-track.md`](docs/roadmap/backend-money-track.md).

---

## How this roadmap is organized

| Where | What it holds |
|---|---|
| **[`ROADMAP.md`](ROADMAP.md)** | The **board** — every ticket in the `Now / Next / Later / Parked / Done` columns, with priority, effort, area and type. Start here. |
| **[`docs/roadmap/`](docs/roadmap/)** | **Track-level detail** — one doc per track: the [backend money track](docs/roadmap/backend-money-track.md), the [frontend placeholder track](docs/roadmap/frontend-placeholders.md), [GTM & budget](docs/roadmap/gtm-and-budget.md), and [process](docs/roadmap/process.md). Acceptance criteria, dependency spine, decisions. |
| **[`CONTRIBUTING.md`](CONTRIBUTING.md)** | How to file, label and move a ticket; the conventions the setup script enforces. |
| **GitHub Project board** | The live kanban mirroring `ROADMAP.md`. Provisioned by `scripts/setup-github.sh`. |
| **Milestones** | `M0 → M3` (below). Each ticket is filed under exactly one milestone. |
| **Issues + Labels** | One issue per `DZ-##` ticket, labelled by `priority` · `effort` · `area` · `type` · `status`. Labels and milestones are created by the setup script so they stay consistent. |

Ticket IDs (`DZ-01`…`DZ-45`, with no `DZ-44`) are **stable and identical across every file** — cite them directly in issues, commits and PRs.

---

## Status legend

**Board status**

| Column | Meaning |
|---|---|
| 🟢 **Now** | In progress this sprint |
| 🔵 **Next** | Queued — next up when a `Now` slot frees |
| ⚪ **Later** | Committed, not yet scheduled |
| ⚫ **Parked** | Deliberately deferred (usually to M3, or a non-goal until scale) |
| ✅ **Done** | Shipped and verified in prod |

**Priority**

| | Meaning |
|---|---|
| `P0` | Blocks revenue/launch, or a live bug (money-loss, crash, security) |
| `P1` | Trust / feature completion |
| `P2` | Polish / debt |

**Effort**

| | Meaning |
|---|---|
| `S` | ≤ ½ day |
| `M` | ≤ 2 days |
| `L` | ≤ 1 week |

**Area** — `backend` · `frontend` · `infra` · `security` · `gtm`  
**Type** — `bug` · `feature` · `chore` · `epic`

Labels are slash-delimited on GitHub — `priority/P0`, `effort/S`, `area/backend`, `type/bug`, `status/now` — one namespace per axis.

---

## Milestones at a glance

| Milestone | Goal | Primary KPI |
|---|---|---|
| **M0 · Truth & Hygiene** | No live secrets in the repo, no user-visible lies (fake numbers, dead buttons, stale metadata), tests runnable | Zero exposed credentials; zero mock numbers on a funded-streamer path |
| **M1 · Fundable Beta** ⬅️ *current* | A streamer can top up real funds and run a real drop that spends them — atomically, auditably, without crashing | Real USD in → persisted, spendable balance → drop delivered → `Drops` + `DrawAudit` row written; 0 open money-loss `P0`s |
| **M2 · Proof & Public Beta** | A demo-clean app + the founding clip; real-data surfaces (dashboard, history, my-drops) live | ≥ 25 activated streamers; founding "ace → winner → trade sent" clip captured |
| **M3 · Retention & Moat** | Retention surfaces, anti-farming enforcement, multi-supplier abstraction, i18n/discovery when scale warrants | Weekly-active streamers; prize-delivery reliability; supplier redundancy |

Track detail: [`backend-money-track.md`](docs/roadmap/backend-money-track.md) · [`frontend-placeholders.md`](docs/roadmap/frontend-placeholders.md) · [`gtm-and-budget.md`](docs/roadmap/gtm-and-budget.md) · [`process.md`](docs/roadmap/process.md)

---

## Quick start for maintainers

Provision labels, milestones, issues and the Project board from the ticket definitions in this repo:

```bash
gh auth login          # authenticate the GitHub CLI (one-time)
./scripts/setup-github.sh
```

<details>
<summary>What the script does</summary>

- Creates the label set: `priority/P0`…`priority/P2`, `effort/S`,`effort/M`,`effort/L`, `area/*`, `type/*`, and one `status/*` per board column.
- Creates milestones `M0`–`M3`.
- Opens one issue per `DZ-##` ticket, labelled and assigned to its milestone.
- Creates (or updates) the **Dropzona Roadmap** Project board with the `Now / Next / Later / Parked / Done` columns and files each issue into its column.

Re-running is safe: existing labels/milestones/issues are updated in place, not duplicated.
</details>

> **Requires** `gh` ≥ 2.0 with `repo` and `project` scopes. Run from the repository root.

---

## Security

<a id="security"></a>

One `P0` `security` item is tracked as `DZ-30`: **rotate an exposed CI/bot credential that was committed to the production repository, purge it from git history, and move it to env-injected secrets.** Exact locations and the credential's identity are kept in an **internal security note**, not in this public repo — do not paste secret values, file paths, or credential types into issues or PRs here. Treat the credential as compromised until rotation is confirmed.

Longer-term hardening debt (GSI token rotation + rate-limiting, tokens encrypted at rest) is tracked separately as `DZ-29`.

---

## North star

> **Paid prize GMV delivered** — the dollar value of real skins actually delivered to real winners. Everything on this roadmap ladders up to making that number real, safe, and repeatable.