# Cyrius language blockers for sakshi

**Audit point:** Cyrius 6.1.16 (sakshi v2.2.8).

This is the canonical list of Cyrius language / stdlib features that sakshi roadmap items still need. Each row maps a sakshi roadmap item to the concrete upstream gap, the current workaround (if any), and severity from sakshi's perspective.

Re-audit and update this doc each time sakshi pins a new Cyrius release.

## Open blockers

| # | Sakshi roadmap item | Needed cyrius feature | Current workaround | Severity |
|---|--------------------|----------------------|--------------------|----------|
| 2 | Deferred formatting (defmt-style: emit `(string_id, raw_args)` instead of formatted text) | Compiler-level string interning — `#strid "literal"` or equivalent, plus a linker-merged registry pass | None possible. The whole point of deferred formatting is that the format string never lives in the running binary; without compiler interning sakshi can't issue stable IDs. (cyrius has `defmt`/interning since 4.8.3 — buildable but a larger lift.) | **Medium.** Significant perf upside on the hot path (no formatting cost, smaller events on the wire) but only matters for high-volume tracing. |
| 3 | Per-module log levels | Module identity at compile time — `__FILE__`, `__MODULE__`, or a `#module NAME` directive that yields a stable per-translation-unit ID | None. A consumer-threaded `mod_id` constant per call site is an API change we don't want. | **Medium.** Most users handle module-level filtering at the consumer side; sakshi-native support would be nicer but isn't blocking adoption. |
| 4 | Per-CPU ring buffers | `sched_getcpu` / `sched_setaffinity` / `getcpu` syscall wrappers in `lib/syscalls*.cyr`. Atomics shipped in 5.7.x — `lib/atomic.cyr` provides `atomic_load/store/cas/fetch_add/fence` for both x86_64 and aarch64. | **Interim shipped in v2.3.0:** the global MPSC atomic ring (`SK_OUT_ATOMIC_RING`, `fetch_add`-reservation writer + `sakshi_aring_*` single-reader API). Per-CPU *partitioning* specifically still needs `sched_getcpu`. | **Low.** Per-CPU is a perf optimization for multi-threaded high-volume tracing; sakshi is single-threaded by current contract anyway. The atomic-ring interim (the more valuable shorter-term step) is now done — only the per-CPU partitioning remains. |
| 6 | Structured typed fields (key-value per event with type info) | Generics, templates, or comptime layout. Cyrius is monomorphic — `hashmap.cyr` and `hashmap_str_keys.cyr` exist as separate files because parametric types don't. | None at the language level. Pragmatic alternative inside sakshi: define a fixed-shape schema struct that consumers populate and pass through the v2.1.0 emit hook. | **High effort upstream, medium value to sakshi.** A type-system extension is a large compiler project. The hook-based escape hatch already covers most of the use case. |

(Item 1, compile-time log-level elimination, shipped in v2.2.8 — see Cleared.
Item 7, Windows / PE output, cleared in 6.1.16 — see Cleared.)

## Open silent-failure quirks (worth filing as bugs upstream)

### `#ifdef` / `#ifndef` inside fn bodies — fixed in 5.7.x (history retained)

5.5.11 behavior: `#ifdef GUARD ... #endif` placed inside a function body did **not** gate the enclosed statements; they were emitted unconditionally with no diagnostic. Sakshi v2.1.0 worked around it by dual-defining each `sakshi_<level>` fn at module scope.

5.7.48 behavior: works correctly for both arch macros (`CYRIUS_ARCH_X86` / `_AARCH64`) and arbitrary user-defined macros (`SAKSHI_DISABLE_<LEVEL>` etc.). Verified via probe in v2.2.1; the dual-define workaround was removed.

Kept in the blockers doc as historical context — anyone re-pinning a pre-5.7 toolchain needs to know.

### Inline-asm include-boundary store bug (already filed)

Reference: [`cyrius/docs/development/issues/inline-asm-stores-silently-drop-when-fn-included.md`](https://github.com/MacCracken/cyrius/blob/main/docs/development/issues/inline-asm-stores-silently-drop-when-fn-included.md).

Scope confirmed during sakshi v2.1.0 hook implementation: bug is limited to stores through caller-supplied pointers in inline asm. Stores to `[rbp-N]` / `[x29-N]` locals are unaffected. The v2.2.0 `src/clock.cyr` rdtsc / CNTVCT_EL0 implementation follows the local-store pattern (same as `lib/atomic.cyr :: atomic_cas`) and is safe.

Sakshi-side mitigation: keep all sakshi inline asm in the local-store pattern. If a future feature genuinely needs caller-pointer stores, gate the file behind a fix-version pin and document it inline.

### Cross-backend binary packaging (`cycc_aarch64` / `cycc_win`) — resolved via `install.sh`

Historically (cyrius 5.7.x, when the binary was named `cc5_aarch64`) the aarch64 cross-backend shipped at the **tarball top level** rather than under `bin/`, so CI that copied only `…/bin/*` to `~/.cyrius/bin/` silently dropped it and the first aarch64 cross-build failed. Cyrius 6.0 renamed the binary to `cycc_aarch64`.

Resolved sakshi-side: both `ci.yml` and `release.yml` now bootstrap the toolchain with the upstream `install.sh`, which lays out `$HOME/.cyrius/{bin,lib}` (including `cycc_aarch64`) correctly — no manual `cp` of cross-backends — plus an explicit `Verify cycc_aarch64 present` gate that fails the run early if the install is incomplete. The same `cycc_win` packaging gap (PE cross-compiler missing from x86_64 tarballs since cyrius 6.0.50) was the CI blocker fixed upstream in **6.1.16** and is guarded the same way (`Verify cycc_win present`).

### Residual `vec_get` / `vec_len` warning on x86 builds (harmless)

`cyrius build` (x86_64) still prints `warning: undefined function 'vec_get' / 'vec_len'` — stdlib paths reference functions not pulled into the bundle. These sit in DCE-eligible code never reached at runtime, so the binary works (confirmed: smoke + 57/57 tests green). Cosmetic only. The earlier, far noisier aarch64 form of this (10 arity-mismatch warnings + an aarch64-codegen path that actually hit `vec_get`/`vec_len` and crashed the binary) **cleared in cyrius 6.1.16** — see Cleared below.

## Cleared

- **Windows / PE output (item 7) — cleared in cyrius 6.1.16.** 6.1.16 emits a runtime `cmp`/`jne` dispatch for **non-literal** PE syscall numbers over the Windows-routable POSIX calls (read/write/open/close/lseek/mmap/exit/mkdir/unlink/clock_gettime), so sakshi's portable `var`-slot idiom routes on PE with no per-call-site workaround — and it ships the previously-missing `cycc_win` in the x86_64 tarball (the CI blocker). sakshi v2.2.7 pins 6.1.16 and carries **no syscall stopgap** (the prototyped `#ifdef CYRIUS_TARGET_WIN` literal branches were retired before v2.2.7 shipped). One Windows-specific path remains in `src/clock.cyr`: `nanosleep`(35) is the single sakshi syscall 6.1.16 still does not route on PE (returns `-38`), so the rdtsc calibration window is skipped and timestamps come from `GetTickCount64`. PE smoke verified under wine in CI (`build-windows`). Detail: [`archive/2026-06-09-windows-pe-var-syscall-no-reroute.md`](archive/2026-06-09-windows-pe-var-syscall-no-reroute.md).
- **Compile-time log-level elimination (item 1) — shipped in v2.2.8.** The `#if NAME >= VALUE` directive (added to cyrius in 2.1.0 *for sakshi* — the changelog example is `#if sk_cfg_log_level >= 3`) backs a `#define SAKSHI_LEVEL <0..5>` threshold gated per level in `src/trace.cyr`, defaulted to 5 via `#ifndef`. A consumer drops every more-verbose level at compile time in one knob (zero bytes/cycles), composing with the existing per-level `SAKSHI_DISABLE_<LEVEL>` flags. Caveat captured in source: set it via in-source `#define`, not `-D` (`cyrius build -D NAME` carries presence only, no integer value). Regression test: `tests/tcyr/level_gate.tcyr`.
- **aarch64 cross-build noise — cleared in cyrius 6.1.16; runtime CI live in v2.2.8.** The 10 stdlib `syscall arity mismatch` warnings and the aarch64-codegen `vec_get`/`vec_len` references (which crashed the aarch64 binary, exit 127 — the reason the qemu runtime CI lane was held) are all gone on 6.1.16: `cyrius build --aarch64` is clean (no arity warnings, no vec refs), and the resulting static ELF **runs under `qemu-aarch64`** — smoke emits all lines, exit 0. The `build-aarch64` CI lane is now a cross-build + RUN gate (installs `qemu-user-static`, runs the binary, asserts the log line) — the aarch64 analog of the live wine lane. A harmless `vec_get`/`vec_len` warning remains on x86 only — see the residual quirk above.
- **Atomics shipped (cyrius 5.7.x)** — `lib/atomic.cyr` is now in stdlib (`atomic_load`, `atomic_store`, `atomic_cas`, `atomic_fetch_add`, `atomic_fence`) on x86_64 + aarch64. Was listed as a 5.5.x-pillar item; cleared. Half-unblocks item #4 (atomic ring lands in v2.3.0).

## Process

When pinning a new cyrius release in sakshi:

1. `grep` cyrius stdlib + parser for the missing-feature markers in this table (`PARSE_IF`, `__FILE__`, `__MODULE__`, `#strid`, `sched_getcpu`, etc.).
2. For each row, mark **cleared** / **partial** / **unchanged**.
3. Move cleared rows to the **Cleared** section above with a note about the version that landed them.
4. Update the audit-point line at the top of this doc and the corresponding `(5.X.Y)` column header in `roadmap.md`.
5. If the bump unblocks an in-flight roadmap item, link the sakshi version that ships the feature.
