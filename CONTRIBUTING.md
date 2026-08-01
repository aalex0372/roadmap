# Contributing to the DROPZONA Roadmap

This repository is the **public roadmap** for [dropzona.tv](https://dropzona.tv) — CS2 skin-giveaway automation for Twitch streamers. It tracks *what we are building and why*, not the application source. Product code lives in the private production repo; this repo holds the board, the milestone plan, and the process that keeps them honest.

> **Read this before opening or moving any item.** The taxonomy, cadence, and standing rules below are load-bearing — they keep the roadmap consistent and keep us out of trouble with the platforms and the law.

---

## Table of contents
- [Ground truth](#ground-truth)
- [The board](#the-board)
- [Taxonomy](#taxonomy)
- [How an item moves Now → Done](#how-an-item-moves-now--done)
- [Weekly cadence](#weekly-cadence)
- [Definition of Done — M1 Fundable Beta](#definition-of-done--m1-fundable-beta)
- [Standing rules (do not violate without a written decision)](#standing-rules-do-not-violate-without-a-written-decision)
- [Filing issues](#filing-issues)

---

## Ground truth

Every roadmap claim is verified against production code before it lands here. The current build baseline is **prod HEAD `61d0e5a` (2026-07-22)**. When a claim and the code disagree, the code wins and the item is corrected.

Where we stand today, in one paragraph: the **OpenSettle wallet deposit backend is shipped** (`DZ-03` Done — persisted ledger, hosted-checkout top-ups, signed + idempotent + settlement-gated webhook, ~25 money-path tests). We are **not** yet at **M1 Fundable Beta** — the top-up loop is not reachable from the UI, two confirmed money-loss bugs remain open, and every drop still persists nothing. Closing M1 is the single focus.

---

## The board

Work is tracked on a single board with five status columns. An item lives in exactly one column at a time.

| Column | Meaning |
|---|---|
| **Now** | In progress this week. Keep this column small — one P0 track at a time. |
| **Next** | Committed, starts when a `Now` slot frees up. Fully specified and unblocked. |
| **Later** | Agreed direction, not yet scheduled. May still need a decision or a dependency. |
| **Parked** | Deliberately not being built (with a reason). Revisited only on a trigger — e.g. the discovery graph is parked until 500+ weekly-active streamers. |
| **Done** | Shipped to prod and verified in code. |

---

## Taxonomy

Use these exact labels everywhere — issues, board cards, docs. Consistency is the point.

### Milestones
| Milestone | Theme |
|---|---|
| **M0 Truth & Hygiene** | Fix the live incidents and the lies in the UI: rotate the exposed credential, kill mock numbers a funded user can reach. |
| **M1 Fundable Beta** ← *current focus* | Real money in, real drop spends it, everything persisted, no money-loss bugs. See the [Definition of Done](#definition-of-done--m1-fundable-beta). |
| **M2 Proof & Public Beta** | Demo-clean app, real-data surfaces, founding clip, legal review, MyDrop comparison/SEO. |
| **M3 Retention & Moat** | Retention surfaces, role model, provider abstraction, i18n, single-instance re-architecture. |

### Priority
| Badge | Meaning |
|---|---|
| `P0` | Blocks revenue or launch, or is a live bug / active incident. Do now. |
| `P1` | Trust or feature completion. |
| `P2` | Polish or debt. |

### Effort
| Badge | Size |
|---|---|
| `S` | ≤ half a day |
| `M` | ≤ 2 days |
| `L` | ≤ 1 week |

### Area
`Backend` · `Frontend` · `Infra` · `Security` · `GTM`

### Type
`Bug` · `Feature` · `Chore` · `Epic`

### Ticket IDs
The build plan uses stable IDs **`DZ-01` … `DZ-29`** (see the dev roadmap). **Reuse the existing ID** for anything already numbered — never renumber. **Mint `DZ-30`+** for new items (quick wins, `/streamer/health`, newly-confirmed bugs). An ID means the same thing in every file; keep it identical across the board, the docs, and the issue.

---

## How an item moves Now → Done

```
  Later ──► Next ──► Now ──► Done
    │                 │
    └────► Parked ◄────┘   (with a written reason + revisit trigger)
```

1. **Later → Next.** The item is specified: it has a `DZ-` ID, priority, effort, milestone, acceptance criteria, and no unresolved decision or open dependency. Anything blocked on an owner decision stays in `Later` until the decision is logged.
2. **Next → Now.** A `Now` slot is free (we run one P0 track at a time) and the owner picks it up. Move the card and assign yourself.
3. **In `Now`.** Keep acceptance criteria in view; update the issue with findings as you go. If scope grows, split — don't let a card silently balloon.
4. **Now → Done.** Merged to prod **and** the acceptance criteria are verified *in code* (not just "the PR is open"). For money-path items, `dotnet test` must be green with coverage on the changed path. Link the PR/commit on the card before closing.
5. **→ Parked.** Anything we consciously decline gets a one-line reason and a revisit trigger, so "why isn't this built?" is always answerable in an audit.

**Splitting large items.** An `Epic` (e.g. the money epic) is a container; the shippable units under it are the ones that move across columns. Keep each moving card at `S`/`M`/`L`, never bigger.

---

## Weekly cadence

One lightweight loop keeps the board true. Full KPI/scorecard definitions live in [`docs/roadmap/process.md`](docs/roadmap/process.md).

| When | Ritual | Output |
|---|---|---|
| **Monday** | Sprint sync (30 min): confirm the `Now` column, pull from `Next`, resolve any blocking owner decision on the call. | An agreed `Now` list, decisions logged. |
| **Mid-week** | Async status on each `Now` card (blocked / on-track). | Blockers surfaced early. |
| **Friday** | Review: move finished items to `Done` (verified in code), re-slot the rest, update the milestone scorecard. | Scorecard refreshed, board reconciled with prod. |
| **Monthly** | Risk-register review — anything marked CRITICAL blocks its milestone. | Risks re-ranked. |

Decisions that unblock work (chain/token, min-max bounds, winners-count, role-switch semantics) are **resolved on the Monday call and written down** — an unlogged decision is not a decision.

---

## Definition of Done — M1 Fundable Beta

M1 is reached only when **all** of these are true and verified in code. Current status is tracked live on the scorecard; the deposit backend (item 7's money-IN half) is already Done.

- [ ] Top-up lands as **persisted, spendable balance** — reachable end-to-end **from the UI** (checkout redirect + success poll), not just via the backend.
- [ ] **Concurrent triggers cannot overspend** — atomic deduct with a `≥ 0` floor guard and row-lock/retry. *(Confirmed reachable double-spend today — `DZ-02`/`DZ-06`.)*
- [ ] **Cancelled trade refunds the ledger** — escrow ≠ delivered; poll to a terminal accepted state; refund-on-rollback. *(Confirmed money-loss today — `DZ-06b`.)*
- [ ] **`end-live` does not crash** — the state store is injected; regression test added. *(`DZ-07`.)*
- [ ] **Every drop writes a `Drops` + `DrawAudit` row** — the keystone that unblocks the real-data surfaces. *(`DZ-01`/`DZ-08`.)*
- [ ] **Fee hook configurable, shipped at 0%** — revenue is a config flip, not a release. *(`DZ-05`.)*
- [ ] **`dotnet test` green with money-path coverage** — including the orchestrator/spend and `end-live` paths.
- [ ] **No user-visible mock numbers** anywhere a funded streamer can navigate.

---

## Standing rules (do not violate without a written decision)

These are not preferences — they are survival constraints. Changing one requires a logged decision, not a PR.

1. **No casino on any surface — ever.** No co-brand, affiliate link, referral code, or sponsor readout for any skin/cash casino, on any Twitch/Steam/product surface. It is a named Twitch ToS violation (streamers suspended + OAuth revoked) and a Valve-association risk. The "walled-off cash-casino entity later" idea is a **licensing dead-end for the US/UK/EU audience** — do not reopen without gambling counsel confirming a license that legally reaches that audience.
2. **No ShadowPay (or any skin-supplier) deposit** before a **refundable/withdrawable float is confirmed in writing.** Funded balances at a failed counterparty become unsecured claims — the reason this rule exists. Cap the first float at **≤ $500**.
3. **No paid ad spend** before the **founding clip exists** and OG cards unfurl. Organic first; gate paid amplification on the best-performing organic clip, measured on cost-per-signup.
4. **No sub-gated / paid-entry / lottery mechanics** — free entry, random, equal odds only. Anything else needs lawyer + policy review first.
5. **No custody.** Dropzona never holds crypto or runs trade bots on its primary Steam key; the Steam Web API key stays **read-only**. OpenSettle moves cash; the skin-marketplace partner holds and delivers skins.
6. **Never commit secrets.** No token, key, or password in the tree — env-injected only, `.env` git-ignored. There is an **active credential-exposure incident**: rotate the exposed CI/bot credential committed to the production repo, purge it from full git history, and move it to env-injected secrets. Specifics are tracked in the **internal security note** — do not restate credential values, types, or exact locations in this public repo.

---

## Filing issues

Use the templates — they enforce the taxonomy so items are board-ready on arrival:

- **Roadmap item** → [`.github/ISSUE_TEMPLATE/roadmap-item.md`](.github/ISSUE_TEMPLATE/roadmap-item.md)
- **Bug report** → [`.github/ISSUE_TEMPLATE/bug-report.md`](.github/ISSUE_TEMPLATE/bug-report.md)

**Never** put a secret, token, key, password, or internal file-path-plus-line "treasure map" for a security issue into a public issue. For anything sensitive, file a placeholder that references the internal security note and take the details private.
