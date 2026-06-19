# Sakshi Development Roadmap

> **Current: v2.4.0** (pin: cyrius 6.2.1). Linux x86_64 / aarch64 / AGNOS / macOS and **Windows PE** all build from one portable source — as of v2.2.10 even `src/clock.cyr` has no `#ifdef CYRIUS_TARGET_WIN` branch (PE now shares the calibrated-rdtsc timestamp path). The `build-windows` (wine) and `build-aarch64` (qemu) CI lanes both run the smoke and assert output reaches stderr. Compile-time log-level elimination (`#define SAKSHI_LEVEL <0..5>`) shipped. v2.3.0 adds the lock-free multi-producer `SK_OUT_ATOMIC_RING` target (interim unblock of item #4). v2.2.0 public API is stable.
>
> Shipped history lives in [`CHANGELOG.md`](../../CHANGELOG.md). This file tracks only what's ahead.

---

## Next minor — unscheduled

- **Env-driven log level (`sakshi_init_from_env`).** Read a level name
  (`trace`/`debug`/`info`/`warn`/`error`/`off`) from an env var (e.g.
  `SAKSHI_LOG`) and call `sakshi_set_level`. Folded-from-agnosys context:
  agnosys `logging.cyr` had `log_init_from_env` reading `AGNOSYS_LOG` by
  hand-parsing `/proc/self/environ` — **Linux-eccentric** (that path doesn't
  exist on agnos/macOS/Windows). The sakshi version should go through cyrius's
  cross-target `getenv` instead, so it's portable. **Deferred:** no consumer
  needs it yet (the agnosys→agnodrm fold dropped `logging.cyr`'s only caller,
  `audit`, into kavach). Pick up when a consumer wants env-driven verbosity.

The single key=value emit (`sakshi_log_kv`) **landed** (folded from agnosys
`logging.cyr` `log_msg_kv`) — composes `msg key=value` into one event routed
through every output target (the lightweight cousin of upstream-blocked item
#6, which needs generics for *typed* fields). The atomic ring buffer (the prior
v2.3.0 lane) **shipped in v2.3.0** — `SK_OUT_ATOMIC_RING`,
`fetch_add`-reservation MPSC writer, `sakshi_aring_*` single-reader API, benched
at 1.0× the plain ring cost (no contention). See
[`CHANGELOG.md`](../../CHANGELOG.md). Full per-CPU partitioning is still
upstream-blocked (item #4 below).

---

## Upstream-blocked — no firm version

These items need cyrius compiler/stdlib work. Each will move into a minor lane once the upstream feature lands. Detailed status, severity, and workarounds: [`docs/development/issues/2026-04-30-cyrius-lang-blockers.md`](issues/2026-04-30-cyrius-lang-blockers.md).

| # | Item | Cyrius feature needed | Best-effort estimate |
|---|------|-----------------------|----------------------|
| 2 | Deferred formatting (defmt-style) | String interning / `#strid` | No estimate |
| 3 | Per-module log levels | `__FILE__` / `__MODULE__` / `#module` | No estimate |
| 4 | Per-CPU ring buffers (full) — _MPSC atomic ring interim shipped in v2.3.0_ | `sched_getcpu` / `getcpu` syscall wrappers | No estimate |
| 6 | Structured typed fields | Generics / templates / comptime layout | No estimate |

Item #1 (compile-time log-level elimination) **shipped in v2.2.8** via the `#if SAKSHI_LEVEL >= n` threshold — cleared from this list. #4's MPSC atomic-ring interim **shipped in v2.3.0** (`SK_OUT_ATOMIC_RING`); only full per-CPU partitioning remains blocked on `sched_getcpu`. #6 (hook escape hatch from v2.1.0) has a functional sakshi-side workaround; #2 is buildable on cyrius's `defmt`/interning but is a larger lift. Full unblock of the rest is upstream's call.

---

## Cleanup / hardening — no firm version

_None open._ The clock-path items (timespec sizing in v2.2.9; Windows
busy-spin + `GetTickCount64` removal in v2.2.10) are shipped — see
[`CHANGELOG.md`](../../CHANGELOG.md).
