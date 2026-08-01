# Backend & Money-Layer Track

> **Epic A — Money** and **Epic B — Stability of the "working" core** (both roll up to `DZ-41` Epic: M1 Fundable Beta). These are the tickets that stand between DROPZONA and a **fundable beta (M1)**: a real dollar goes in, a real drop spends it, and every event is persisted and auditable.

**Verified against:** production `prod` @ HEAD `61d0e5a` (2026-07-22) via a full ticket-by-ticket code audit.
**Milestones:** `M0 → M1 → M2 → M3` (milestone concepts, tracked on the board — there are no per-milestone doc files).
**Labels (GitHub, slash-delimited):** `priority/{P0,P1,P2}` · `effort/{S,M,L}` · `area/{backend,frontend,infra,security,gtm}` · `type/{bug,feature,chore,epic}` · `status/{now,next,later,parked,done}`.

Since the last strategy snapshot, the devs **shipped the entire money-IN stack** (persisted balance ledger + OpenSettle top-ups + a signed, idempotent, settlement-gated webhook). That flips the old "money layer is fake" status: the plumbing is real. What remains is (1) the **spend side is not yet safe** — two confirmed money-loss defects — and (2) drops **persist nothing**, so most of the product still shows mock data. This track closes both.

---

## 🔴 Read this first — the two confirmed money-loss defects

Two P0 defects on the **spend side** can lose a streamer's real money. Both are confirmed in the code audit, not theoretical, and neither may ship on a funded stream. They are described here at a **risk + fix** level by policy; internal reproduction detail lives in the private audit note, not in this public tracker.

### 1. Overspend on the balance deduction · `DZ-02` (+ `DZ-06` atomicity)
**Risk.** The balance deduction is not concurrency-safe, so under concurrent draws a streamer can be charged past their balance and the balance can go **negative**.
**Fix.** Make the deduction a single atomic operation with a non-negative floor guard and per-streamer serialization (row-lock or optimistic-retry), so a debit can never be applied against a stale decision or drive the balance below zero.

### 2. Escrow counted as delivered · `DZ-06b`
**Risk.** Steam **escrow / "hold"** state is currently treated as a completed delivery and the streamer is irreversibly debited — but escrow is not a delivery guarantee, and Steam can roll it back (up to ~15 days later), leaving the winner with nothing while the streamer stays debited. There is no refund path today.
**Fix.** Only a terminal, confirmed-delivered state may debit; a rolled-back trade must refund the streamer's ledger and mark the drop failed.

> Both are tracked below with full acceptance criteria. **Fixing them is the ship-gate for M1** — see the Definition of Done.

---

## ✅ M1 "Fundable Beta" — Definition of Done

M1 is **not yet reached** — **8 of 9 items open** (only `DZ-03`, money-IN, is done). Scorecard against the current HEAD:

- [x] **Money-IN backend is real** — persisted ledger, hosted-checkout top-ups, signed + idempotent + settlement-gated webhook, ~25 money-path tests · `DZ-03` **Done**
- [ ] **Top-up lands as spendable balance end-to-end** — backend is real; the frontend never completes the redirect · `DZ-04` (frontend track — [frontend-placeholders.md](frontend-placeholders.md))
- [ ] **Concurrent draws cannot overspend** — 🔴 confirmed reachable · `DZ-02` + `DZ-06` (atomicity)
- [ ] **Cancelled / rolled-back trade refunds the ledger** — 🔴 confirmed money-loss · `DZ-06b`
- [ ] **`end-live` doesn't crash** — 🔴 NRE on every call · `DZ-07`
- [ ] **Every drop has a `Drops` + `DrawAudit` row** — 🔴 no table, orchestrator persists nothing · `DZ-01` (drops half) + `DZ-08`
- [ ] **Fee hook configurable, shipped at 0%** — 🔴 no fee logic exists yet · `DZ-05`
- [ ] **`dotnet test` green with money-path coverage** — 🟡 money-IN covered; **zero** spend / orchestrator / end-live coverage · `DZ-10`
- [ ] **No user-visible mock numbers where a funded streamer navigates** — 🔴 dashboard/history/my-drops/profile still mock (Epic C · `DZ-42`, unblocked by `DZ-08`)

**Realistic close:** ~1.5–2 focused sprints — every open item is `S` or `M`. The dependency spine:

```
DZ-07 ─▶ DZ-02(finish) ─▶ DZ-06 / DZ-06b ─▶ DZ-05 ─▶ DZ-01(drops) ─▶ DZ-08 ─▶ (unblocks Epic C real-data wiring)
```

---

## 🔐 Security gate (P0, runs today, parallel to everything)

### `DZ-30` — Rotate exposed CI/bot credential in the production repo
`priority/P0` · `effort/S` · `status/now` · `area/security` · `type/chore`

**Description.** An internal security note flags a shared CI/bot credential that was committed to the production repository and pushed to a public remote. Because it is reachable in git history, treat it as compromised regardless of whether it is currently active.

**Why it matters.** A live credential in a public tree is a realized breach, not a backlog item. It must be neutralized before any funded operation, and it undermines the no-custody / minimal-trust posture the whole money layer depends on.

**Acceptance criteria** *(exact specifics — files, commit, value — are kept only in the internal security note; not restated here):*
- [ ] Rotate the exposed credential at its issuer and revoke the old value.
- [ ] Purge it from full git history and force-update the remote.
- [ ] Move the value to env-injected secrets; ensure no secret-bearing file is tracked.
- [ ] Sweep the repo for any other committed secrets and rotate anything found.

**Dependencies.** None — do this immediately, independent of the build spine.

---

# Epic A — Money

*One dependency chain. The money-IN half (`DZ-03`) is shipped; the spend + persistence half is the open work.*

---

### `DZ-07` — `end-live` crashes on every call
`priority/P0` · `effort/S` · `status/now` · `area/backend` · `type/bug`

**Description.** The stream-session manager references a state store that is never constructor-injected, so `POST twitchStreaming/end-live` throws a NullReferenceException **every time** a streamer ends a stream.

**Why it matters.** This is the exit door of the core loop. Day-1, cheapest possible fix, and it blocks clean session teardown that later persistence relies on. Sequenced first in the sprint.

**Acceptance criteria:**
- [ ] Inject the state store into the manager's constructor and assign it.
- [ ] `end-live` completes without an NRE across the full start → end lifecycle.
- [ ] Regression test covers the end-live path so it can't silently break again.

**Dependencies.** None. Do first.

---

### `DZ-02` — Overspend guard on the balance deduction
`priority/P0` · `effort/M` · `status/now` · `area/backend` · `type/bug`

**Status:** core **Done** (the stub is gone; balance is persisted and survives restart via the ledger tables). The **overspend-safety finish is open** and is the single most dangerous unresolved defect.

**Description.** The persisted ledger exists, but the deduction is not concurrency-safe: under concurrent draws it can overspend and drive the balance negative. Add an **atomic delta** update with a **non-negative floor guard** and **per-streamer serialization** (row-lock or optimistic-retry) so a deduction can never be applied against a stale decision or push the balance below zero. (Risk + fix only — internal reproduction detail is in the private audit note.)

**Why it matters.** This is the ship-gate item — no streamer funds a wallet until a draw provably cannot overspend it.

**Acceptance criteria:**
- [ ] Deduction is a single atomic update with a non-negative floor guard — a below-zero deduction is rejected, not applied.
- [ ] Per-streamer row-lock or optimistic-concurrency + retry serializes concurrent deductions.
- [ ] Two concurrent draws near depletion **cannot** both spend; balance can never go negative.
- [ ] Balance survives a restart (already true — keep covered by a test).

**Dependencies.** Fold the atomic-deduct into the same transaction as `DZ-06` (atomic check + deduct). Any lock added here holds **only within one process** — see the single-instance constraint below; keep to **one backend instance**.

---

### `DZ-03` — Wallet backend: OpenSettle top-ups ✅
`priority/P0` · `effort/L` · `status/done` · `area/backend` · `type/feature`

**Description.** `GET /wallet` + `POST /wallet/top-up` (returns a hosted-checkout URL) + a **webhook receiver** that credits the ledger asynchronously. Built to the current **amount-only** spec: the user submits only a USD amount; the backend pins chain + token and makes one checkout call (no customer/invoice object). Inbound only — no withdrawals.

**Why it matters.** This is the money-IN half of the business. It is shipped and real, not theater — and it is the backend contract the frontend completion loop (`DZ-04`) consumes.

**Delivered (verified in code):**
- [x] `GET /wallet` (real persisted balance + ledger rows), `POST /wallet/top-up → hostedUrl`, and the webhook receiver — the old hardcoded mock arrays are gone on both sides.
- [x] Webhook is **signature-verified**, **idempotent**, and gated on the real settlement-complete signal.
- [x] Statuses map to Completed / Pending Review / Rejected; an ops notifier fires on Pending-Review / reversal / unknown-checkout.
- [x] ~25 money-path tests on a Testcontainers Postgres fixture.
- [x] Public webhook route wired through the deploy path (Caddy + compose + DI).

**Open follow-ups (config / ops, not plumbing):**
- [ ] Confirm the live settlement rail: the code pins one chain/token pair, the amount-only spec names a different pair — **confirm the workspace's verified settlement wallet with OpenSettle before checkouts can succeed.** (Owner decision `DZ-D1`.)
- [ ] Fix the min-amount config value that sits below the provider's floor (would reject a live checkout).
- [ ] Provision the live OpenSettle credentials via injected env on the host, and register the webhook per the provider's setup.

**Dependencies.** Blocked only on the `DZ-D1` owner confirms (rail + bounds) and live-credential provisioning. The **frontend completion** (`DZ-04`) is the reason DoD item 2 is still open.

---

### `DZ-04` — Wallet frontend: finish the top-up completion loop *(frontend track)*
`priority/P0` · `effort/M` · `status/now` · `area/frontend` · `type/feature`

**Cross-track reference.** `DZ-04` is a **frontend** ticket — tracked in [frontend-placeholders.md](frontend-placeholders.md). It appears here only because it closes DoD item 2 and depends on the backend read contract this track already shipped.

**Backend dependency — delivered under `DZ-03`.** The wallet read contract the UI consumes is real: `GET /wallet` returns the persisted balance plus the transaction ledger rows, each with a status the frontend can render and poll after a top-up returns. The mock arrays are gone; the UI reads the ledger.

**Open (frontend):**
- [ ] Consume the checkout `hostedUrl` (full-page redirect on Top-Up).
- [ ] Handle `?topup=success` → "crediting…" + poll balance; handle `?topup=cancelled` → dismissible notice.
- [ ] Land the top-up as spendable balance end-to-end.

**Backend-adjacent follow-up:** ensure the transaction status a client polls after `?topup=success` transitions correctly once the webhook credits, so the frontend's poll resolves.

**Dependencies.** Backend contract shipped with `DZ-03`; end-to-end completion is the open frontend work.

---

### `DZ-05` — Platform fee hook (dormant, ship at 0%)
`priority/P0` · `effort/S` · `status/now` · `area/backend` · `type/feature`

**Description.** Add a `PlatformFeePct` config applied at the deduction point (today the orchestrator deducts exactly the purchase price — there is **no** fee logic anywhere in the codebase). Ship it wired but set to **0%**.

**Why it matters.** It makes turning revenue on later a **config change, not a release.** The business model is a free beta → ~10% service fee on prize spend; this is the switch that enables it without redeploying.

**Acceptance criteria:**
- [ ] `PlatformFeePct` config exists and is applied at the deduction site.
- [ ] Shipped at **0%** — behavior identical to today until changed.
- [ ] Fee amount is recorded on the drop's audit row (see `DZ-08`) so revenue is reconstructable.
- [ ] Covered by a money-path test (0% and a nonzero value).

**Dependencies.** Lands cleanly alongside `DZ-06` and `DZ-08` so the fee is computed and persisted in the same debit + audit transaction.

---

### `DZ-06` — Orchestrator money-flow hardening
`priority/P0` · `effort/M` · `status/now` · `area/backend` · `type/bug`

Two spend-path defects beyond the `DZ-02` floor guard. **`(b)` is split out as `DZ-06b`** (escrow) because it is an independent confirmed money-loss defect with its own refund requirement.

**Description.**
- **(a) Atomic check + deduct.** The balance check and the debit are not performed atomically. Move check + deduct into **one transaction** (shared with `DZ-02`) so a debit cannot be applied against a stale decision.
- **(c) Delivery idempotency.** A delivery timeout can fall through to a retry, which risks delivering two skins for one deduction. Add idempotency keyed on the purchase's id so a timeout/retry path cannot double-buy.

**Why it matters.** `(a)` is half of the overspend defect; `(c)` is a silent way to pay once and ship twice. Both bleed real money on the spend side.

**Acceptance criteria:**
- [ ] Balance check and deduction execute in a single transaction (no window between decision and debit).
- [ ] A purchase carries an idempotency key; a timeout-then-retry **cannot** result in two deliveries for one deduction.
- [ ] The timeout → retry path is covered by a test proving single-delivery.

**Dependencies.** Shares the deduct transaction with `DZ-02`. Records outcome on the audit row from `DZ-01`/`DZ-08`.

---

### `DZ-06b` — Escrow ≠ delivered + refund-on-rollback
`priority/P0` · `effort/M` · `status/now` · `area/backend` · `type/bug`

**Description.** The delivery path counts Steam **escrow / "hold"** state as a completed delivery and irreversibly debits the streamer — but escrow can **roll back** (up to ~15 days later), returning items to the supplier while the winner gets nothing. There is no refund path today. Fix by counting only a **terminal, confirmed-delivered** state as complete (or writing a pending-delivery row that settles on a confirmed-delivered signal), **plus a refund path** that credits the streamer's ledger and marks the drop failed on a rollback.

**Why it matters.** This is a permanent, unrecoverable loss of a streamer's real money on any rolled-back trade — the single worst first-night failure mode. It is also the delivery-side money-loss risk called out in the ShadowPay working doc as a must-fix **before real float flows.**

**Acceptance criteria:**
- [ ] Only a **terminal delivered** state counts as complete — escrow/hold and unresolved trade-offer states never debit.
- [ ] A rolled-back trade produces a **refund ledger row** and marks the drop **failed**.
- [ ] The drop's audit row reflects the final delivery state, not the interim escrow state.
- [ ] Tests cover: escrow-that-succeeds, escrow-that-rolls-back (→ refund), and unresolved-offer-state (→ no premature debit).

**Dependencies.** Refund rows depend on the ledger (`DZ-02`, shipped) and the drop/audit tables (`DZ-01`). Real trades depend on the ShadowPay supply relationship (external, CEO track) — but the code fix does not.

---

### `DZ-01` — DB schema: Drops + DrawAudit (drops half)
`priority/P0` · `effort/M` · `status/next` · `area/backend` · `type/chore`

**Status:** the **money half is Done** — the balance ledger tables shipped with the wallet work. The **drops half is open**; there is **no `Drops` or `DrawAudit` table, entity, or migration** today.

**Description.** Add the append-only history entities the audit trail needs, in one migration:
- **`Drops`** — streamer, trigger, rule, skin, price, winner, supplier op id, delivery status, timestamps.
- **`DrawAudit`** — entrants snapshot / count, winner, seed, timestamp.

(The balance ledger half already exists and is not rebuilt.)

**Why it matters.** This is the **keystone.** The orchestrator currently draws, buys, delivers, debits — and **persists nothing** (results are only logged). That single missing write-path is the root cause behind most placeholder pages (dashboard, history, profile stats, viewer my-drops all have no data to show). It is also the dispute-defense: without a draw audit trail, "was it rigged?" is unanswerable.

**Acceptance criteria:**
- [ ] Migration applies clean; `Drops` and `DrawAudit` DbSets exist.
- [ ] Every money/drop event can be written as a row (schema covers the fields `DZ-08` needs).
- [ ] Append-only in practice — history rows are never mutated after settlement.

**Dependencies.** None to create the schema. It **unblocks** `DZ-08` (the write-path) and all of Epic C's (`DZ-42`) real-data wiring.

---

### `DZ-08` — Persist every drop + auditable draw — KEYSTONE
`priority/P0` · `effort/M` · `status/next` · `area/backend` · `type/feature`

**Description.** Make the orchestrator write a `Drops` + `DrawAudit` row per giveaway. Replace the non-deterministic `new Random()` winner pick with a **seeded / crypto draw**, and record the **entrant count** at draw time. Resolve `WinnersCount` (stored but currently ignored — always draws 1) per owner decision **`DZ-D3`** (recommendation: for M1, always draw 1 and hide the input; revisit multi-winner post-beta).

**Why it matters.** This turns "every drop is auditable" from aspiration into fact, clears the DoD "no mock numbers" item by giving Epic C real data, and makes fairness demonstrable — the win-proof surface GTM depends on.

**Acceptance criteria:**
- [ ] Every giveaway writes one `Drops` row and one `DrawAudit` row (skin, price, winner, delivery state, fee from `DZ-05`, entrant count, timestamps).
- [ ] Winner selection is seeded/crypto, not `new Random()`; the seed/basis is recorded so the draw is reconstructable.
- [ ] `WinnersCount` is either honored or hidden per `DZ-D3` — no path silently ignores a stored value the UI accepted.
- [ ] Streamer-scoped and viewer-scoped paginated read endpoints expose the drops (feeds Epic C).

**Dependencies.** `DZ-01` (drops half) for the tables. Lands in the same sprint as `DZ-05`/`DZ-06b` so fee and final delivery state land in the same audit row. Unblocks `DZ-13`/`DZ-14`/`DZ-15`/`DZ-17` (Epic C · `DZ-42`).

---

# Epic B — Stability of the "working" core

*The core loop is real, but less bulletproof than the demo implies.*

---

### `DZ-09` — Restore auth attributes on streaming endpoints
`priority/P0` · `effort/S` · `status/next` · `area/security` · `type/chore`

**Description.** Class-level authorization attributes are commented out on the streaming controller (a leftover marker sits next to them); actions carry the authenticate attribute but skip the user-id requirement. Restore both at the class level. While here, delete the commented test-scaffold endpoint and a dead `getuser` endpoint.

**Why it matters.** Streaming endpoints drive the live loop and touch streamer state; leaving them under-guarded is a straightforward auth gap. Cheap to close.

**Acceptance criteria:**
- [ ] All streaming endpoints enforce **both** the authenticate and require-user-id attributes at the class level.
- [ ] Commented test-scaffold endpoint and the dead `getuser` endpoint are removed.
- [ ] A test confirms an unauthenticated / user-id-less request is rejected.

**Dependencies.** None. Pairs naturally with `DZ-07` as day-1 hygiene.

---

### `DZ-10` — Revive and enforce the test suite
`priority/P0` · `effort/M` · `status/now` *(partial)* · `area/backend` · `type/chore`

**Status:** partial. The **money-IN** paths are covered (~25 tests on the wallet ledger + webhook). The **spend side, orchestrator, and end-live have zero coverage.** The pre-existing unit + integration test files are still fully commented; the Testcontainers Postgres fixture exists.

**Description.** Revive the commented unit + integration tests and add coverage for the money-spend paths, making tests **mandatory** for `DZ-02`, `DZ-05`, `DZ-06`/`DZ-06b`, `DZ-07`, and `DZ-08`.

**Why it matters.** The dangerous open defects are all on the spend side, which currently has **no** automated coverage. Green money-path tests in CI are the DoD gate that keeps the overspend/escrow/double-delivery fixes from regressing.

**Acceptance criteria:**
- [ ] `dotnet test` runs green in CI with a nonzero test count.
- [ ] Overspend guard (`DZ-02`), escrow-rollback refund (`DZ-06b`), delivery idempotency (`DZ-06`), fee hook (`DZ-05`), end-live (`DZ-07`), and draw audit (`DZ-08`) each have covering tests.
- [ ] Previously-commented unit + integration tests are restored or replaced.

**Dependencies.** Grows alongside each money-path ticket it covers.

---

## ⚠️ Standing constraint — single backend instance

All runtime state (session cache, viewer cache, streamer state store) lives in **in-memory singletons**. Any lock added for `DZ-02` holds **only within one process**, so a second instance breaks the overspend guarantee and loses sessions/entrants on restart. **Keep to one backend instance** through M1. Moving this state to a shared store (DB/Redis) is parked for **M3** (`DZ-12`) — do not start it inside the money sprint.

---

## Ticket index

| ID | Title | Pri | Effort | Area | Status |
|---|---|:--:|:--:|---|---|
| `DZ-30` | Rotate exposed CI/bot credential + purge history | P0 | S | Security | Now |
| `DZ-07` | `end-live` NRE crash | P0 | S | Backend | Now |
| `DZ-02` | Overspend guard on the balance deduction | P0 | M | Backend | Now (core Done) |
| `DZ-03` | Wallet backend: OpenSettle top-ups | P0 | L | Backend | **Done** ✅ |
| `DZ-04` | Wallet frontend: finish top-up completion loop | P0 | M | Frontend | Now *(frontend track)* |
| `DZ-05` | Platform fee hook (0%) | P0 | S | Backend | Now |
| `DZ-06` | Orchestrator money-flow hardening (atomicity + double-delivery) | P0 | M | Backend | Now |
| `DZ-06b` | Escrow ≠ delivered + refund-on-rollback | P0 | M | Backend | Now |
| `DZ-01` | DB schema: Drops + DrawAudit (money half Done) | P0 | M | Backend | Next |
| `DZ-08` | Persist every drop + auditable draw (KEYSTONE) | P0 | M | Backend | Next |
| `DZ-09` | Restore auth attributes | P0 | S | Security | Next |
| `DZ-10` | Revive + enforce test suite (spend coverage) | P0 | M | Backend | Now (partial) |

---

<sub>Sourced from the internal DROPZONA strategy pack (06 dev roadmap · 07 build status · 08 forward roadmap · 09 placeholder roadmap · 05 risk register) and the ShadowPay working doc, verified against production HEAD `61d0e5a` (2026-07-22). Sibling tracks: [frontend-placeholders.md](frontend-placeholders.md) · [gtm-and-budget.md](gtm-and-budget.md) · [process.md](process.md). No secrets, tokens, or credential specifics appear in this document by policy — credential-exposure specifics live in the internal security note.</sub>
