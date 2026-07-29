# Raccoon vs Alice vs Chucker

Comparison of `raccoon` (this package, 0.5.0) against the two established Flutter
HTTP inspectors: [Alice](https://github.com/jhomlala/alice) and
[chucker_flutter](https://pub.dev/packages/chucker_flutter).

**TL;DR** — Raccoon is a lighter, opinionated **Dio-only, in-memory** inspector
with a draggable overlay. Alice & Chucker are mature, **persistent**,
multi-client inspectors. Raccoon trades breadth/persistence for a few sharp
differentiators (request replay, webhook alerts, overlay UX).

## Feature grid

| Capability | **Raccoon** (0.5.0) | **Alice** | **chucker_flutter** |
|---|---|---|---|
| HTTP clients | Dio only | Dio, `http`, `HttpClient`, Chopper/generic | Dio, `http` |
| **Persistent storage** | ✗ in-memory, capped 1000, lost on restart | ✓ ObjectBox | ✓ local storage |
| Open via notification | ✗ | ✓ | ✓ in-app notif (shows status + URL) |
| Shake to open | ✗ | ✓ | ✗ |
| Draggable overlay button | ✓ | ✗ | ✗ |
| Call list + search | ✓ | ✓ | ✓ |
| Detail (headers/response/error) | ✓ | ✓ | ✓ |
| Syntax highlight (JSON/XML) | ✓ | basic | basic |
| cURL export | ✓ copy | ✓ | ✓ |
| Save/share to **file** | ✗ clipboard only | ✓ save to file | ✓ share |
| HAR export | ✓ | ✗ | likely ✓ (Chucker lineage) |
| Stats screen | ✓ rich + Markdown export | ✓ | ✗ |
| **Request replay** | ✓ | ✗ | ✗ |
| **Webhook alerts (Discord)** | ✓ slow-call | ✗ | ✗ |
| Image response preview | ✗ stub | ✓ | ✓ |
| Platform breadth | mobile + web + desktop (pure Dart, web-safe) | Flutter + Android logs | Flutter |
| Maturity / adoption | young, 0.5.0 | mature, high adoption | mature, high adoption |

> Uncertain cells for competitors (chucker_flutter HAR/image specifics) are
> inferred from Chucker's Android lineage, not verified line-by-line.

## Where Raccoon wins

- **Request replay** — resend a captured call. Neither Alice nor Chucker do this.
- **Discord webhook alerts** on slow calls — proactive; others are pull-only viewers.
- **Draggable floating button** + zero-config navigator auto-discovery — nicer
  in-app entry than shake/notification.
- **Rich stats + Markdown export** — Alice has basic stats; Chucker none.
- **Cleaner JSON/XML syntax highlighting** and **HAR export**.

## Where Raccoon is behind (the real gaps)

1. **No persistence** — biggest one. Alice (ObjectBox) and Chucker survive app
   restarts; raccoon drops all calls on restart and hard-caps at 1000. Matters
   for debugging crashes / cold-start flows.
2. **Dio-only** — Alice covers 4 client types. `http`/Chopper users can't use raccoon.
3. **No notification-to-open** — both competitors surface calls via
   system/in-app notifications; raccoon needs the overlay button on screen.
4. **Clipboard-only export** — fine for cURL, but a full HAR of 1000 calls into
   the clipboard is fragile; no file save/share means no easy handoff.
5. **Image preview is a stub**, shake-to-open absent.

## Net

Raccoon is not yet a drop-in Alice/Chucker replacement for teams needing
persistence or multi-client support — but it's a sharper tool for a Dio app that
wants replay, slow-call alerting, and a friendlier overlay UX.

---

Sources:
[jhomlala/alice](https://github.com/jhomlala/alice) ·
[chucker_flutter (pub.dev)](https://pub.dev/packages/chucker_flutter) ·
[chucker_flutter (Flutter Gems)](https://fluttergems.dev/packages/chucker_flutter/)
