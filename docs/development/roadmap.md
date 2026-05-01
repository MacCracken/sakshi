# Sakshi Development Roadmap

> **v2.2.2** — aarch64 portability patch. New `src/syscalls.cyr` arch-dispatches syscall numbers + `_sk_open` wrapper; new qemu-user-static CI lane runs smoke + full test suite on aarch64 ELFs. Closes the v2.2.x patch lane. v2.2.0 API surface unchanged.

---

## Completed

- **v2.2.2** — aarch64 portability: `src/syscalls.cyr` arch-dispatch, `_sk_open` wrapper, qemu CI lane. v2.2.x patch lane closed.
- **v2.2.1** — internal patch: trace.cyr dual-define cleanup (cyrius 5.7.48 fn-body `#ifdef` works), `sakshi_clock_recalibrate()` for long-running consumers. 57 tests.
- **v2.2.0** — cycle-counter timestamps (`src/clock.cyr`, x86_64 + aarch64). 53 tests. `timestamp` 373 → 22 ns; cascading hot-path wins.
- **v2.1.1** — toolchain bump to Cyrius 5.7.48. No source changes; 45 tests pass, bundle byte-identical.
- **v2.1.0** — subscriber/vtable hook (`sakshi_set_emit_hook`), per-level `SAKSHI_DISABLE_<LEVEL>` defines, span-path perf fix. `SK_OUT_HOOK = 4` enum variant.
- **v2.0.0** — flat patra-style refactor. Single `dist/sakshi.cyr` bundle + modular `src/lib.cyr`. Manifest moved to `cyrius.cyml`; CI/release aligned with AGNOS first-party template.

Detailed entries: [`CHANGELOG.md`](../../CHANGELOG.md).

---

## Patch lane — v2.2.x (closed)

All four items shipped. v2.2.1 closed the runtime/preprocessor lane; v2.2.2 closed the aarch64 portability lane.

| Item | Status |
|------|--------|
| User-macro `#ifdef` cleanup in `src/trace.cyr` | Done — v2.2.1 |
| Opt-in periodic TSC recalibration (`sakshi_clock_recalibrate`) | Done — v2.2.1 |
| Arch-dispatched syscalls in `src/syscalls.cyr` (+ `_sk_open` wrapper) | Done — v2.2.2 |
| aarch64 runtime CI via qemu-user-static | Done — v2.2.2 |

Residual finding (not actionable on sakshi side): cyrius stdlib emits 10 `syscall arity mismatch` warnings on every `cyrius build --aarch64` invocation regardless of project content. Filed in the [blockers doc](issues/2026-04-30-cyrius-lang-blockers.md); upstream cleanup.

---

## Minor lane — v2.3.0 (next minor)

**Single-producer atomic ring buffer.** Interim partial unblock of roadmap #4 — Cyrius 5.7.x shipped `lib/atomic.cyr` (`atomic_load/store/cas/fetch_add/fence` on x86_64 + aarch64), so a thread-safe global ring is buildable now even though `sched_getcpu` / per-CPU partitioning is still upstream-blocked.

Scope:
- New `SK_OUT_ATOMIC_RING = 5` output target. CAS-based writer (multi-producer), single-reader.
- Public API: `sakshi_set_output(SK_OUT_ATOMIC_RING)` + thread-safe `sakshi_ring_*` reader variants.
- Bench target: ≤2× the current single-threaded `SK_OUT_RING` cost under no contention; document the cache-line-bouncing curve under contention.
- Doc: explicit trade-off note vs. the future per-CPU ring (which lands when sched-affinity wrappers do).

Why minor (not patch): adds a new public output target and ring-reader API surface.

---

## Upstream-blocked — no firm version

These items need cyrius compiler/stdlib work. Each will move into a minor lane once the upstream feature lands. Detailed status, severity, and workarounds: [`docs/development/issues/2026-04-30-cyrius-lang-blockers.md`](../issues/2026-04-30-cyrius-lang-blockers.md).

| # | Item | Cyrius feature needed | Best-effort estimate |
|---|------|-----------------------|----------------------|
| 1 | Compile-time log level elimination (full) | `#if <int-expr>` numeric thresholds | v6.x |
| 2 | Deferred formatting (defmt-style) | String interning / `#strid` | No estimate |
| 3 | Per-module log levels | `__FILE__` / `__MODULE__` / `#module` | v6.x |
| 4 | Per-CPU ring buffers (full) | `sched_getcpu` / `getcpu` syscall wrappers | No estimate |
| 6 | Structured typed fields | Generics / templates / comptime layout | No estimate (v6.x+ if ever) |

Items #1 (workaround shipped in v2.1.0), #4 (atomic ring shipping in v2.3.0), and #6 (hook escape from v2.1.0) all have functional sakshi-side workarounds; full unblock is upstream's call.
