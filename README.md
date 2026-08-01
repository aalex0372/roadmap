# Dropzona — Frontend Gap & Placeholder Roadmap

> The developer roadmap for **[Dropzona](https://dropzona.tv)** — CS2 skin-giveaway automation for Twitch. This repo is the shared work queue for **two frontend / full-stack devs**: fix the existing broken UI and turn the app's "Coming soon" placeholders into real, data-backed product across **8 routes**.

![focus](https://img.shields.io/badge/focus-fill%20the%20placeholders-blue) ![keystone](https://img.shields.io/badge/keystone-Drops%20persistence-purple) ![tickets](https://img.shields.io/badge/tickets-16-lightgrey) ![prod](https://img.shields.io/badge/prod%20HEAD-61d0e5a-lightgrey)

The app today is littered with `COMING SOON` panels, `<ComingSoon/>` layouts, mock data, and a few live UI bugs. This repo tracks converting all of that into real product — sequenced so the cheapest wins ship first and the one dependency that unblocks everything else lands in the middle.

---

## Scope — what this repo is (and isn't)

**In scope:** fixing existing UI bugs and filling placeholder surfaces across the 8 app routes below — the frontend gap work, plus the thin backend read-layer those surfaces need to show real data.

**Deliberately out of scope** (tracked separately, not here):

- **The money path** — wallet, top-up, balance, overspend guard, escrow, fees, pricing.
- **GTM** — outreach, the founding clip, waitlist, channel plans, budget.
- **Casino / gambling** monetization of any kind.
- **Core infra & platform** — runtime crashes, auth attributes, test-suite work, framework/.NET bumps, multi-instance.

If a ticket touches any of the above, it doesn't belong here. Keep this board focused on the placeholders and the UI.

> One clarification on the keystone below: `Drops` + `DrawAudit` persistence appears here framed strictly as the **data layer** that the placeholder surfaces read from — record-keeping for who won what, when. It is not the money path.

---

## The one insight that orders everything: **Drops persistence is the keystone**

Today the giveaway orchestrator draws a winner, hands off the prize, and then **persists nothing** — the result is only *logged*. There is **no `Drops` table, no `DrawAudit` table, no entity, no migration.**

That single missing write-path is the root cause behind **most** of the placeholders. The dashboard stat cards, the dashboard event feed, `/streamer/history`, the viewer `my-drops` win-proof surface, and the profile Statistics / My Prizes panels are all `<ComingSoon/>` for the same reason: **there is no data to show.**

The frontends already exist — most panels are fully built and sitting commented out behind `<ComingSoon/>`. Once Drops persistence lands, wiring each surface is a cheap swap (S/M), not a rebuild. The move: ship the zero-dependency quick wins now, land the Drops keystone next, then light up the real-data surfaces the moment it lands. Park the discovery graph.

---

## The 8 routes → current state → what's needed

1. `/streamer/dashboard` — 4 stat cards COMING SOON + a fake "Live" event feed + Triggers-summary COMING SOON → wire Triggers-summary now (DZ-31); stat cards + feed on Drops data (DZ-13).
2. `/streamer/triggers` — Game-Triggers list WORKS; Drop Logic + Viewer Requirements COMING SOON (forms, no save) → new rule fields + enforcement + save (DZ-21); reconcile typo first (DZ-34).
3. `/streamer/health` — placeholder; UI commented → new GET /streamer/health + wire (DZ-32).
4. `/streamer/history` — placeholder; RewardsTable commented → streamer-scoped Drops read + uncomment (DZ-14).
5. `/profile` — "Member since" shows today (bug), ShareOption hooks crash, Statistics + My Prizes COMING SOON → DZ-33 + DZ-11 now; DZ-17 after keystone.
6. `/viewer/my-drops` — placeholder; UI commented → viewer-scoped Drops read + uncomment (DZ-15).
7. `/viewer/live-streams` — placeholder directory (empty pre-scale) → decide park vs minimal (DZ-20, parked).
8. `/viewer/followings` — placeholder; no markup; needs net-new follow system → decide park vs build (DZ-46, parked).

Cross-cutting: DZ-16 wires the dead coming-soon widget buttons; DZ-34 reconciles the maxDropsPerWiewer typo before DZ-21.

---

## The 5-sprint sequence

Sprint A · Quick wins (Now): DZ-31, DZ-32, DZ-33, DZ-11, DZ-16, DZ-34.
Sprint B · Drops keystone (Next): DZ-01, DZ-08, DZ-42 (epic).
Sprint C · Real-data surfaces (Later): DZ-13, DZ-14, DZ-15, DZ-17.
Sprint D · New features (Later): DZ-21.
Sprint E · Parked (Parked): DZ-20, DZ-46.

---

## Legend

Board stage: Now / Next / Later / Parked / Done.
Priority: P0 blocks the other surfaces (keystone) · P1 trust/feature · P2 polish/debt/decision.
Effort: S <= half day · M <= 2 days · L <= 1 week.
Area: frontend, backend. Type: bug, feature, chore, epic.
Labels (slash-delimited): priority/P0..P2, effort/S,M,L, area/frontend,backend, type/bug,feature,chore,epic, status/now,next,later,parked,done.

---

## Quick start for maintainers

```bash
gh auth login
./scripts/setup-github.sh
```

The script creates the label set, the five milestones (Sprint A · Quick wins, Sprint B · Drops keystone, Sprint C · Real-data surfaces, Sprint D · New features, Sprint E · Parked), one issue per DZ-## ticket, and the Now/Next/Later/Parked/Done Project board. Re-running is safe.

---

## Where things live

- ROADMAP.md — the board (all 16 tickets by stage).
- docs/roadmap/frontend-placeholders.md — the placeholder-fill epic in full.
- docs/roadmap/process.md — how tickets move.
- CONTRIBUTING.md — filing/labelling conventions.

<sub>Grounded in a code-verified placeholder audit at HEAD 61d0e5a. Money-path, GTM, casino, and core-infra work is tracked elsewhere and excluded here.</sub>
