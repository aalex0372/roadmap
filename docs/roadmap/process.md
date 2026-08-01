# Process — cadence & sprint sequence

Success here = **placeholders filled to the Definition of Done + the in-surface bugs fixed.** No KPI/GMV/GTM tracking lives in this repo.

## Sprint sequence

The order follows from one fact: **Drops persistence (`DZ-01`/`DZ-08`) is the keystone** — most real-data surfaces have nothing to show until it lands.

| Sprint | Milestone | Stage | Goal |
|---|---|---|---|
| **A** | Sprint A · Quick wins | Now | Delete 3 "Coming soon" panels + fix live UI bugs — no Drops needed |
| **B** | Sprint B · Drops keystone | Next | Persist every drop + read endpoints (the data layer) |
| **C** | Sprint C · Real-data surfaces | Later | Wire dashboard / history / my-drops / profile once Drops lands |
| **D** | Sprint D · New features | Later | Drop Logic + Viewer Requirements (new backend, off critical path) |
| **E** | Sprint E · Parked | Parked | Discovery graph — decide, don't build pre-scale |

**A and B can run in parallel** (A is frontend-only over existing data; B is backend). C cannot start until `DZ-08` is Done.

## Cadence (two devs, lightweight)

- **Mon** — sprint sync: confirm what's in `Now`, unblock.
- **Mid-week** — async status on the board (move cards, update `status/*`).
- **Fri** — review: demo each `Now` card against the DoD; move to `Done` only when verified in-app.
- **One `Now` track at a time.** Don't pull a Sprint C card into `Now` while `DZ-08` is open.

## Per-sprint notes

- **A** — 6 independent tickets; do `DZ-34` (typo reconcile) before `DZ-21` so the field name is settled.
- **B** — the deliverable is the data layer + endpoints, not a screen. Nothing in C is "done" until this is.
- **C** — value order: `DZ-15` (viewer win-proof) → `DZ-14` → `DZ-13` → `DZ-17`.
- **D** — `DZ-21` needs the save mutation + orchestrator enforcement, not just an uncomment.
- **E** — no build. Each parked ticket records the reason + a revisit trigger (≈ 500+ weekly-active streamers).
