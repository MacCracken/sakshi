# Sakshi Development Roadmap

> **v2.2.7** — Windows/PE patch (P1). `#ifdef CYRIUS_TARGET_WIN` literal-syscall branches in `src/output.cyr` / `src/syscalls.cyr` / `src/clock.cyr` un-break PE I/O (the v2.2.2 `var`-dispatch defeated the literal-only PE reroute → silent total output loss); new live `build-windows` CI gate runs the PE smoke under wine. Pin → cyrius 6.1.15. v2.2.0 API surface unchanged.

---

## Completed

- **v2.2.7** — Windows/PE output fix (W1) + live PE CI gate under wine (W2). Pin → cyrius 6.1.15. Closes the Windows/PE P1 lane. UDP stays unsupported on PE (documented).
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
| aarch64 cross-build CI (compile + ELF verification) | Done — v2.2.2 |
| aarch64 *runtime* CI under qemu | Held — upstream stdlib bug |

Held item: original v2.2.2 plan was a qemu-user-static lane that ran sakshi's smoke + full test suite on aarch64 ELFs. Blocked by an upstream cyrius stdlib issue (unresolved `vec_get` / `vec_len` references; the compiler emits "will crash at runtime" warnings on x86 too but x86 paths don't reach them, aarch64 does → exit 127). Sakshi's own source is already arch-portable. Held as a follow-up patch once the stdlib fix lands — same posture as `yukti/.github/workflows/ci.yml`. Tracked in the [blockers doc](issues/2026-04-30-cyrius-lang-blockers.md).

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

## Windows / PE support — **P1** (closed, v2.2.7)

First sakshi consumer to ship a Windows PE binary (ai-hwaccel 2.3.9) found that **all sakshi output was silently dropped on Windows**: the v2.2.2 `var`-slot syscall numbers (`src/syscalls.cyr`) are non-literal at every call site, and cyrius's Win64 PE syscall reroute only fires for a **compile-time-literal** number — so `syscall(_SK_SYS_WRITE, …)` fell through to a raw, non-functional instruction and wrote nothing (no fault, exit 0). Full write-up + repro: [`issues/archive/2026-06-09-windows-pe-var-syscall-no-reroute.md`](issues/archive/2026-06-09-windows-pe-var-syscall-no-reroute.md). Upstream cyrius issue: [`2026-06-09-pe-syscall-variable-number-not-rerouted.md`](https://github.com/MacCracken/cyrius/blob/main/docs/development/issues/2026-06-09-pe-syscall-variable-number-not-rerouted.md).

Both items shipped in **v2.2.7**.

| # | Item | Priority | Status |
|---|------|----------|--------|
| W1 | **PE I/O actually emits** — `#ifdef CYRIUS_TARGET_WIN` literal-syscall branches in `src/output.cyr` (`_sk_write_stderr`/`_sk_write_file` → `1`, close → `3`) and `src/syscalls.cyr` `_sk_open` (→ `2`, takes precedence over the `CYRIUS_ARCH_X86` branch `cycc_win` also predefines). `src/clock.cyr` skips the unrouted `nanosleep`(35) calibration on PE — a bounded busy-spin on the routed literal `clock_gettime`(228) replaces it, and the panic helper uses literal `write(1)`/`exit(60)`. UDP (`socket`/`sendto` 41/44, unrouted on PE) stays unsupported on Windows, documented in `src/output.cyr`. | **P1** | **Done — v2.2.7.** sakshi-side stopgap; the *clean* fix remains upstream runtime-dispatch of non-literal syscall numbers under `_TARGET_PE`. |
| W2 | **Windows CI gate** — `build-windows` lane cross-builds the smoke with `cycc_win` (DCE) and **runs it under wine**, asserting the `sakshi smoke ok` line reaches stderr (not just "it compiled"). The PE analog of the aarch64 qemu lane — and, unlike that held lane, the PE runtime gate is live. | **P1** | **Done — v2.2.7.** |

Both were P1: a consumer shipped a Windows wheel with logging silently dead and there was **no CI** to catch it — W2 is the gate, W1 is the fix.

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
