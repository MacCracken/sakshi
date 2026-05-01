# Cyrius language blockers for sakshi

**Audit point:** Cyrius 5.7.48 (sakshi v2.1.1 → v2.2.0 transition).

This is the canonical list of Cyrius language / stdlib features that sakshi roadmap items still need. Each row maps a sakshi roadmap item to the concrete upstream gap, the current workaround (if any), and severity from sakshi's perspective.

Re-audit and update this doc each time sakshi pins a new Cyrius release.

## Open blockers

| # | Sakshi roadmap item | Needed cyrius feature | Current workaround | Severity |
|---|--------------------|----------------------|--------------------|----------|
| 1 | Compile-time log level elimination (`docs/development/roadmap.md` row 1) | `#if <int-expr>` numeric thresholds in the preprocessor (e.g. `#if SAKSHI_LEVEL <= 3`) plus `-D NAME=VAL` macro values | Discrete `SAKSHI_DISABLE_FATAL`/`_ERROR`/`_WARN`/`_INFO`/`_DEBUG`/`_TRACE` defines, dual-defined at module scope (see severity note on `#ifdef` scope below). Shipped in v2.1.0. | **Low.** The workaround is acceptable and ergonomic enough; ROI on landing `#if <int-expr>` is small once consumers know the per-level flags. |
| 2 | Deferred formatting (defmt-style: emit `(string_id, raw_args)` instead of formatted text) | Compiler-level string interning — `#strid "literal"` or equivalent, plus a linker-merged registry pass | None possible. The whole point of deferred formatting is that the format string never lives in the running binary; without compiler interning sakshi can't issue stable IDs. | **Medium.** Significant perf upside on the hot path (no formatting cost, smaller events on the wire) but only matters for high-volume tracing. |
| 3 | Per-module log levels | Module identity at compile time — `__FILE__`, `__MODULE__`, or a `#module NAME` directive that yields a stable per-translation-unit ID | None. A consumer-threaded `mod_id` constant per call site is an API change we don't want. | **Medium.** Most users handle module-level filtering at the consumer side; sakshi-native support would be nicer but isn't blocking adoption. |
| 4 | Per-CPU ring buffers | `sched_getcpu` / `sched_setaffinity` / `getcpu` syscall wrappers in `lib/syscalls*.cyr`. Atomics shipped in 5.7.x — `lib/atomic.cyr` provides `atomic_load/store/cas/fetch_add/fence` for both x86_64 and aarch64. | None for per-CPU partitioning specifically. A global atomic ring is now buildable as an interim. | **Low.** Per-CPU is a perf optimization for multi-threaded high-volume tracing; sakshi is single-threaded by current contract anyway. The atomic-ring interim is the more valuable shorter-term step. |
| 6 | Structured typed fields (key-value per event with type info) | Generics, templates, or comptime layout. Cyrius is monomorphic — `hashmap.cyr` and `hashmap_str_keys.cyr` exist as separate files because parametric types don't. | None at the language level. Pragmatic alternative inside sakshi: define a fixed-shape schema struct that consumers populate and pass through the v2.1.0 emit hook. | **High effort upstream, medium value to sakshi.** A type-system extension is a large compiler project. The hook-based escape hatch already covers most of the use case. |

## Open silent-failure quirks (worth filing as bugs upstream)

### `#ifdef` / `#ifndef` inside fn bodies — fixed in 5.7.x (history retained)

5.5.11 behavior: `#ifdef GUARD ... #endif` placed inside a function body did **not** gate the enclosed statements; they were emitted unconditionally with no diagnostic. Sakshi v2.1.0 worked around it by dual-defining each `sakshi_<level>` fn at module scope.

5.7.48 behavior: works correctly for both arch macros (`CYRIUS_ARCH_X86` / `_AARCH64`) and arbitrary user-defined macros (`SAKSHI_DISABLE_<LEVEL>` etc.). Verified via probe in v2.2.1; the dual-define workaround was removed.

Kept in the blockers doc as historical context — anyone re-pinning a pre-5.7 toolchain needs to know.

### Inline-asm include-boundary store bug (already filed)

Reference: [`cyrius/docs/development/issues/inline-asm-stores-silently-drop-when-fn-included.md`](https://github.com/MacCracken/cyrius/blob/main/docs/development/issues/inline-asm-stores-silently-drop-when-fn-included.md).

Scope confirmed during sakshi v2.1.0 hook implementation: bug is limited to stores through caller-supplied pointers in inline asm. Stores to `[rbp-N]` / `[x29-N]` locals are unaffected. The v2.2.0 `src/clock.cyr` rdtsc / CNTVCT_EL0 implementation follows the local-store pattern (same as `lib/atomic.cyr :: atomic_cas`) and is safe.

Sakshi-side mitigation: keep all sakshi inline asm in the local-store pattern. If a future feature genuinely needs caller-pointer stores, gate the file behind a fix-version pin and document it inline.

### Stdlib `--aarch64` cross-build syscall-arity warnings

5.7.48 emits 10 `warning: syscall arity mismatch` lines on every `cyrius build --aarch64 …` invocation, regardless of project content. Reproduced with a 7-line file containing one `syscall(1, 2, 3, 4, 5, 6)` call: same 10 warnings at the same line numbers (372, 377, 382, 394, 399, 463, 547, 610, 617, 683 in the bundled compilation unit).

The line numbers track to cyrius stdlib code (auto-resolved deps), not to anything sakshi controls. Conclusion: this is upstream noise on cross-build, not a sakshi bug.

Sakshi-side mitigation: the v2.2.2 `src/syscalls.cyr` arch-dispatch + `_sk_open` wrapper makes sakshi's own syscalls portable. The aarch64 CI lane (qemu) added in v2.2.2 is the actual correctness validator — if smoke + tests pass under qemu, the warnings are confirmed-noise.

Suggested cyrius-side fix: silence the arity warnings on cross-build for stdlib's own syscall sites, or ship arity metadata so the warning only fires on user code.

## Cleared since last audit (5.5.11 → 5.7.48)

- **Atomics shipped** — `lib/atomic.cyr` is now in stdlib (`atomic_load`, `atomic_store`, `atomic_cas`, `atomic_fetch_add`, `atomic_fence`) on x86_64 + aarch64. Was listed as a 5.5.x-pillar item; cleared. Half-unblocks roadmap #4.

## Process

When pinning a new cyrius release in sakshi:

1. `grep` cyrius stdlib + parser for the missing-feature markers in this table (`PARSE_IF`, `__FILE__`, `__MODULE__`, `#strid`, `sched_getcpu`, etc.).
2. For each row, mark **cleared** / **partial** / **unchanged**.
3. Move cleared rows to the **Cleared** section above with a note about the version that landed them.
4. Update the audit-point line at the top of this doc and the corresponding `(5.X.Y)` column header in `roadmap.md`.
5. If the bump unblocks an in-flight roadmap item, link the sakshi version that ships the feature.
