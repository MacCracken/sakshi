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

### `cc5_aarch64` moved to tarball top-level in 5.7.48 (CI install workaround)

5.7.48's `cyrius-5.7.48-x86_64-linux.tar.gz` ships `cc5_aarch64` at the **tarball top level** rather than under `bin/`. Any CI that copies `…/bin/*` to `~/.cyrius/bin/` (the pattern shipped in earlier sakshi/yukti/patra workflows) silently drops it; first aarch64 cross-build then fails with:

```
error: compiler not found: /home/runner/.cyrius/bin/cc5_aarch64
```

Sakshi-side mitigation (applied in v2.2.2 to both `ci.yml` and `release.yml`): one extra line after the `bin/*` copy —
```
[ -f "$CYRIUS_DIR/cc5_aarch64" ] && cp "$CYRIUS_DIR/cc5_aarch64" "$HOME/.cyrius/bin/"
```

Same workaround as `yukti/.github/workflows/ci.yml`. Yukti has the canonical upstream report at [`yukti/docs/development/issues/2026-04-30-cyrius-cc5-aarch64-packaging.md`](https://github.com/MacCracken/yukti/blob/main/docs/development/issues/2026-04-30-cyrius-cc5-aarch64-packaging.md). Upstream fix lands when `install.sh` or a future tarball moves `cc5_aarch64` back under `bin/`.

### Stdlib `--aarch64` cross-build noise (arity + unresolved vec_get/vec_len)

5.7.48 emits two classes of upstream noise on every `cyrius build --aarch64 …` invocation, regardless of project content:

1. **10 `warning: syscall arity mismatch` lines** at fixed line numbers (372, 377, 382, 394, 399, 463, 547, 610, 617, 683) in the bundled compilation unit. Reproduced with a 7-line trivial file. Line numbers track to cyrius stdlib code, not project source. Treated as compile-time noise.
2. **`error: undefined function 'vec_get' / 'vec_len' (will crash at runtime)`.** Same root cause — stdlib paths reference functions that aren't pulled into the bundle. On x86 these references sit in DCE-eligible code that's never reached at runtime, so the binary works. On aarch64, the codegen path actually hits them and the binary crashes (exit 127 from the test framework / qemu).

Sakshi-side mitigation: the v2.2.2 `src/syscalls.cyr` arch-dispatch + `_sk_open` wrapper makes sakshi's own syscalls portable. v2.2.2 originally added a qemu-execution lane to validate end-to-end on aarch64, but the unresolved `vec_get`/`vec_len` blocks that today. The CI lane was downgraded to **cross-build + ELF verification only** — same posture as `yukti/.github/workflows/ci.yml` (yukti has hit this and chose the same compile-only lane).

Runtime aarch64 verification will reattempt as a sakshi patch once the stdlib bug is upstream-fixed. Track upstream — same fix likely closes both the arity warnings and the unresolved-vec issue, since they're both stdlib-bundling problems.

Suggested cyrius-side fix: ensure stdlib auto-deps that get bundled into cross-arch builds resolve all referenced symbols (or DCE them to elimination); silence the arity warnings on stdlib-internal syscall sites.

## Cleared since last audit (5.5.11 → 5.7.48)

- **Atomics shipped** — `lib/atomic.cyr` is now in stdlib (`atomic_load`, `atomic_store`, `atomic_cas`, `atomic_fetch_add`, `atomic_fence`) on x86_64 + aarch64. Was listed as a 5.5.x-pillar item; cleared. Half-unblocks roadmap #4.

## Process

When pinning a new cyrius release in sakshi:

1. `grep` cyrius stdlib + parser for the missing-feature markers in this table (`PARSE_IF`, `__FILE__`, `__MODULE__`, `#strid`, `sched_getcpu`, etc.).
2. For each row, mark **cleared** / **partial** / **unchanged**.
3. Move cleared rows to the **Cleared** section above with a note about the version that landed them.
4. Update the audit-point line at the top of this doc and the corresponding `(5.X.Y)` column header in `roadmap.md`.
5. If the bump unblocks an in-flight roadmap item, link the sakshi version that ships the feature.
