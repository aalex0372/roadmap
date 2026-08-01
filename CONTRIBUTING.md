# Contributing to the Dropzona Gap Roadmap

This repo is the **developer-facing gap board** for [Dropzona](https://dropzona.tv): fix what's broken in the app UI and replace the "Coming soon" placeholders with real logic across 8 routes.

## Scope

**In scope:** the 8 placeholder/gap routes (`/streamer/dashboard`, `/streamer/triggers`, `/streamer/history`, `/streamer/health`, `/streamer/profile`, `/viewer/my-drops`, `/viewer/followings`, `/viewer/live-streams`), the bugs living on those pages, and the **drop-history data layer** (`DZ-01`/`DZ-08`) required to fill them.

**Out of scope (tracked privately — do not add here):** the money path (wallet, top-ups, overspend/escrow, fees), pricing/budget, GTM/marketing, casino decisions, and core-infra tickets (end-live crash, auth attributes, tests, .NET bump).

## The board

Work is a **GitHub Project** with a single-select **Stage** field mirrored by `status/*` labels:

| Stage | Meaning |
|---|---|
| **Now** | In progress this sprint |
| **Next** | Queued for the next sprint |
| **Later** | Scheduled, not yet queued |
| **Parked** | Deliberately not being built (decision recorded) |
| **Done** | Shipped & verified in code |

An item moves **Now → Done** as it's built; update both the Stage field and the matching `status/*` label so the board and issue list agree.

## Labels & milestones

- **priority/** `P0` (blocks the keystone / live bug) · `P1` (trust/feature) · `P2` (polish or a park decision)
- **effort/** `S` (≤ ½ day) · `M` (≤ 2 days) · `L` (≤ 1 week)
- **area/** `frontend` · `backend` (full-stack tickets carry both)
- **type/** `bug` · `feature` · `chore` · `epic`
- **status/** one per Stage column

Milestones are the five sprints: **Sprint A · Quick wins → Sprint E · Parked**. Every ticket sits in exactly one.

## Definition of Done — "a placeholder is filled"

- [ ] Real data from a real endpoint (no mock arrays, no hardcoded numbers, no fake "Live" feed)
- [ ] `<ComingSoon/>` removed for that surface
- [ ] No dead buttons — every control has a handler (see `DZ-16`)
- [ ] Loading, empty, and error states handled
- [ ] Labels honest (e.g. "Viewers" → "Eligible viewers" where the data is join-scoped)
- [ ] Any in-surface bug fixed (`DZ-33` member-since, `DZ-11` hooks, `DZ-34` typo)
- [ ] Built clean + verified with an in-app screenshot

> `DZ-21` (Drop Logic + Viewer Requirements) is a real feature — it needs new rule fields, orchestrator enforcement, **and** the missing save mutation, not just an uncomment.

## Filing an issue

1. Scope-check it against the list above — if it's money/GTM/infra, it belongs in the private tracker, not here.
2. Use the **Roadmap item** or **Bug** template.
3. Add `priority/`, `effort/`, `area/`, `type/`, `status/` labels + a milestone.
4. Reference the `DZ-##` id in branches, commits, and PRs.

See [`ROADMAP.md`](ROADMAP.md) for the board and [`docs/roadmap/`](docs/roadmap/) for the per-track detail.
