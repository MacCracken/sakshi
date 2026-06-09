# Sakshi Development Roadmap

> **Current: v2.2.8** (pin: cyrius 6.1.16). Linux x86_64 / aarch64 / AGNOS / macOS and **Windows PE** all build from one portable source; the `build-windows` (wine) and `build-aarch64` (qemu) CI lanes both run the smoke and assert output reaches stderr. Compile-time log-level elimination (`#define SAKSHI_LEVEL <0..5>`) shipped. v2.2.0 public API is stable.
>
> Shipped history lives in [`CHANGELOG.md`](../../CHANGELOG.md). This file tracks only what's ahead.

---

## Next minor — v2.3.0

**Single-producer atomic ring buffer.** Interim partial unblock of the per-CPU ring (upstream-blocked item #4) — Cyrius 5.7.x shipped `lib/atomic.cyr` (`atomic_load/store/cas/fetch_add/fence` on x86_64 + aarch64), so a thread-safe global ring is buildable now even though `sched_getcpu` / per-CPU partitioning is still upstream-blocked.

Scope:
- New `SK_OUT_ATOMIC_RING = 5` output target. CAS-based writer (multi-producer), single-reader.
- Public API: `sakshi_set_output(SK_OUT_ATOMIC_RING)` + thread-safe `sakshi_ring_*` reader variants.
- Bench target: ≤2× the current single-threaded `SK_OUT_RING` cost under no contention; document the cache-line-bouncing curve under contention.
- Doc: explicit trade-off note vs. the future per-CPU ring (which lands when sched-affinity wrappers do).

Why minor (not patch): adds a new public output target and ring-reader API surface.

---

## Upstream-blocked — no firm version

These items need cyrius compiler/stdlib work. Each will move into a minor lane once the upstream feature lands. Detailed status, severity, and workarounds: [`docs/development/issues/2026-04-30-cyrius-lang-blockers.md`](issues/2026-04-30-cyrius-lang-blockers.md).

| # | Item | Cyrius feature needed | Best-effort estimate |
|---|------|-----------------------|----------------------|
| 2 | Deferred formatting (defmt-style) | String interning / `#strid` | No estimate |
| 3 | Per-module log levels | `__FILE__` / `__MODULE__` / `#module` | No estimate |
| 4 | Per-CPU ring buffers (full) | `sched_getcpu` / `getcpu` syscall wrappers | No estimate |
| 6 | Structured typed fields | Generics / templates / comptime layout | No estimate |

Item #1 (compile-time log-level elimination) **shipped in v2.2.8** via the `#if SAKSHI_LEVEL >= n` threshold — cleared from this list. #4 (atomic ring shipping in v2.3.0) and #6 (hook escape hatch from v2.1.0) have functional sakshi-side workarounds; #2 is buildable on cyrius's `defmt`/interning but is a larger lift. Full unblock of the rest is upstream's call.
