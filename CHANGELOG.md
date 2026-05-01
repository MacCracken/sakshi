# Changelog

All notable changes to Sakshi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-04-30

Cycle-counter timestamps (roadmap #5 done). `_sk_now_ns` no longer goes through the kernel — `rdtsc` (x86_64) / `mrs cntvct_el0` (aarch64) + a calibrated Q32 mul-shift converts ticks → nanoseconds in ~22 ns. Public API surface is unchanged.

### Added

- **`src/clock.cyr`** — new internal module owning cycle-counter timestamps. Public-internal API: `_sk_now_ticks()`, `_sk_clock_init()`, `_sk_ticks_to_ns(ticks)`, `_sk_now_ns()`. Lazy first-call init: `_sk_now_ns` triggers `_sk_clock_init` on first call (CPUID feature check + 10 ms calibration on x86_64; CNTFRQ_EL0 read on aarch64). Subsequent calls are pure inline asm + arithmetic, no syscalls.
- **`tests/tcyr/sakshi.tcyr` clock test group** — 8 new assertions: TSC freq plausibility (500 MHz < freq < 10 GHz), Q32 scale populated, monotonicity over 1000 raw `_sk_now_ticks()` reads, ticks → ns scale agrees with `nanosleep(10 ms)` to within ±2 ms, init idempotency. Suite size: 45 → 53 tests.
- **`tests/bcyr/sakshi.bcyr :: clock_now_ticks` bench** — raw rdtsc cost.

### Changed

- **`_sk_now_ns()` perf: 373 ns → 22 ns** on x86_64 Linux (5.7.48). Cascading wins on the hot path: `hook_emit` 398 ns → 26 ns (15× faster, dominated by the now-cheap timestamp), `trace_info` 924 ns → 578 ns (saves the full 346 ns of timestamp cost). `span_cycle` reports 1 µs which is the bench reporting-resolution floor — actual is sub-µs. `err_*` benches unchanged (no timestamp dependency).
- **Tick origin shift (visible-but-non-breaking).** v2.2.0 timestamps count from the host's TSC origin (boot or vendor-defined); v2.1.x counted from `CLOCK_MONOTONIC_RAW` epoch. Magnitudes differ; monotonicity, ns scaling, and event ordering are preserved. Span elapsed (`t_exit - t_enter`) is unaffected because both endpoints share the new origin. Consumers comparing absolute timestamps across a 2.1 → 2.2 boundary will see a one-time jump.
- **`_sk_now_ns` migrated** from `src/format.cyr` to `src/clock.cyr`. `src/lib.cyr` includes `clock.cyr` first (other modules depend on it). `scripts/bundle.sh` `MODULES` list updated; `dist/sakshi.cyr` regenerates clean.
- **`.github/workflows/ci.yml`** — lint loop adds `src/clock.cyr`.
- **`docs/development/roadmap.md`** — roadmap #5 moved to Completed (v2.2.0). Roadmap #4 status revised: half-unblocked on 5.7.48 (atomics shipped via `lib/atomic.cyr`); per-CPU partitioning still blocked on `sched_getcpu` / `getcpu` syscall wrappers. Audit-point header updated to 5.7.48.

### Fixed

- **`scripts/version-bump.sh`** — `sed`'s `/PATTERN/i` was inserting the new "## [VERSION] - Unreleased" stub before **every** existing `## [` heading instead of just the first, multiplying duplicates on each call. Two prior bumps (2.1.0 → 2.1.1, 2.1.1 → 2.2.0) left 35 orphan stubs in `CHANGELOG.md`. Now uses a one-shot insertion before the first heading and strips any pre-existing duplicate stubs as a sweep.

### Notes on Cyrius 5.7.48

- **`#ifdef CYRIUS_ARCH_X86` / `_AARCH64` works inside fn bodies** for both `asm` blocks and ordinary cyrius statements (verified on 5.7.48 with a test probe). The v2.1.0 audit note about fn-body `#ifdef` being silently no-op'd applied to user-defined macros (`SAKSHI_DISABLE_<LEVEL>`); arch macros gate correctly. The user-macro case has not been re-verified in v2.2.0 — `SAKSHI_DISABLE_<LEVEL>` still uses the dual-define workaround.
- **Inline-asm local-store pattern is safe across includes.** `src/clock.cyr` follows the same `[rbp-N]` / `[x29-N]` store pattern used in `lib/atomic.cyr` and `lib/fnptr.cyr`. The known cyrius include-boundary store bug only affects writes through caller-supplied pointers and does not apply here.

## [2.1.1] - 2026-04-30

Toolchain bump only. No source changes. 2.1.0 API surface unchanged.

### Changed

- **Toolchain bumped to Cyrius 5.7.48** (from 5.5.11). `.cyrius-toolchain` and `cyrius.cyml` updated. Lint clean, all 45 tests pass, `dist/sakshi.cyr` regenerates byte-identical from `src/`. Bench numbers improve broadly on the 5.7.x compiler — `trace_info` 924 ns, `hook_emit` 398 ns, `span_cycle` 1 µs, `timestamp` 373 ns, `err_with_ctx` 8 ns, `err_unpack` 16 ns. The roadmap notes about `#if <int-expr>`, `__MODULE__`/`__FILE__`, and the in-fn-body `#ifdef` scope limitation remain unchanged on 5.7.48; no item moves from blocked to unblocked with this bump.


## [2.1.0] - 2026-04-20

Toolchain bump, subscriber-hook API (roadmap #7 done), compile-time level disables (roadmap #1 partial), span-path perf fix, housekeeping. No breaking changes — 2.0.0 API surface is a strict subset of 2.1.0.

### Added

- **`sakshi_set_emit_hook(fp)` / `sakshi_clear_emit_hook()`** — subscriber-vtable output target (`SK_OUT_HOOK = 4`). Closes roadmap item #7. Hook signature is `fn(ts, level, category, msg, msg_len, elapsed_ns)` and covers both log and span events (span enter/exit use level `SK_SPAN_ENTER` / `SK_SPAN_EXIT`; log events use `elapsed_ns = 0`). Dispatch goes through `lib/fnptr.cyr`'s `fncall6`; external consumers of `dist/sakshi.cyr` must `include "lib/fnptr.cyr"` before the sakshi include (the bundle strips its own includes). In-benchmark cost: **1 µs per event** when routed to a no-op hook — faster than the stderr path (2 µs) because the hook bypasses text formatting and the write syscall. `tests/tcyr/sakshi.tcyr` now has a 10-assertion hook regression.
- **`SAKSHI_DISABLE_FATAL` / `_ERROR` / `_WARN` / `_INFO` / `_DEBUG` / `_TRACE` compile-time defines** — partially unblocks roadmap item #1. `cyrius build -D SAKSHI_DISABLE_TRACE` replaces the corresponding public fn's body with an early return so per-call cost drops from ~1–2 µs to the overhead of an empty fn. Binary-size savings only appear when consumer code also drops the call site (DCE then removes the stub). `#if <expr>` numeric thresholds are still absent from cyrius 5.5.11, so we use one flag per level rather than `SAKSHI_LEVEL=<n>`.
- **Span bench** (`tests/bcyr/sakshi.bcyr :: span_cycle`) and **hook bench** (`hook_emit`). `span_cycle` lands at 4 µs (enter + exit), down from ~6 µs pre-fix. `hook_emit` is 1 µs.
- **`OutputTarget::SK_OUT_HOOK = 4`** — new enum variant.

### Changed

- **Toolchain bumped to Cyrius 5.5.11** (from 5.1.13). `.cyrius-toolchain`, `cyrius.cyml`, `lib/` symlink all moved. Cyrius 5.5.2's enum-constant fold inlines `SK_*` / `ERR_CAT_*` values at call sites; `err_with_ctx` max tightened from 12 → 7 ns as a side effect. The stale "cyrius 5.1.10" self-report noted in our 2.0.0 Known issues is resolved upstream.
- **Centralized timestamp on span + emit paths** (`src/span.cyr`, `src/output.cyr`). `sakshi_span_enter` / `_exit` were each doing two `_sk_now_ns` syscalls (one in the caller, another inside `_sk_emit_span`). Refactor: caller reads the clock once, passes `ts` through `_sk_emit_span(ts, ...)` → `_sk_write_ring_event(ts, ...)` / `_sk_write_udp_event(ts, ...)`. Saves ~1 µs per span event on x86_64 Linux (one syscall at ~1 µs each).
- **`src/trace.cyr`** — `_sk_log_level` default now `SK_INFO` instead of magic `3`; doc comment explains the dual-definition gate pattern forced by the preprocessor-in-fn-body limitation (see Notes on Cyrius 5.5.11).
- **`src/output.cyr`** — `_sk_output_target` default now `SK_OUT_STDERR` instead of magic `0`. New `include "lib/fnptr.cyr"` at the top (needed by the hook dispatch; external bundle consumers inherit this requirement).
- **`src/lib.cyr`** — API listing adds `sakshi_set_emit_hook`, `sakshi_clear_emit_hook`; usage comment now lists the two canonical include forms.
- **`docs/development/roadmap.md`** — post-v1.0 table rewritten with evidence per row and an "Unblocks when" column pointing at the specific Cyrius feature needed.

### Fixed

- **`scripts/version-bump.sh`** — was `sed`-patching `cyrius.toml` (stale path from before the 2.0.0 flatten). The manifest version was silently skipped on every bump since 2.0.0. Now targets `cyrius.cyml`.

### Removed

- **Historical v0.9.2 → v0.9.3 log-level renumber note** in `src/trace.cyr`. Stale; the CHANGELOG owns it.

### Notes on Cyrius 5.5.11

- **Preprocessor scope**: `#ifdef` / `#ifndef` are only evaluated at module scope in 5.5.11 — a guard placed inside a fn body does nothing. The `SAKSHI_DISABLE_<LEVEL>` pattern therefore dual-defines each public `sakshi_<level>` at outer scope. Worth filing upstream; failure mode is silent (no diagnostic).
- **Inline-asm include-boundary bug** ([cyrius/docs/development/issues/inline-asm-stores-silently-drop-when-fn-included.md](https://github.com/MacCracken/cyrius)): scoped to stores through caller-supplied pointers. fnptr.cyr (used by the hook) stores only to `[rbp-N]` locals and is safe. rdtsc-based timestamps (roadmap #5) follow the same pattern and are now mechanically unblocked; landing deferred to 2.2.0 / 2.3.0 pending a calibration policy.




## [2.0.0] - 2026-04-16

Flat patra-style refactor. **Breaking** — the hand-maintained `sakshi.cyr` (slim) and `sakshi_full.cyr` (full) bundles at the repo root are gone. Consumers include `src/lib.cyr` directly, or pull the generated `dist/sakshi.cyr` single-file bundle. Scaffold also modernized to match the AGNOS first-party template (Ark reference).

### Breaking

- **Removed root-level `sakshi.cyr` and `sakshi_full.cyr`**. Replace any `include "sakshi.cyr"` or `include "sakshi_full.cyr"` with either:
  - `include "src/lib.cyr"` — modular source, recommended for consumers that live alongside sakshi (Cyrius stdlib, sibling crates).
  - `include "dist/sakshi.cyr"` — single-file bundle, recommended for external consumers that pull sakshi via `[deps.sakshi] modules = [...]`.
  The public API is unchanged (same function names, same signatures); only the include path moves. The slim profile is retired — DCE (`CYRIUS_DCE=1`) prunes unused surface to roughly the same size.
- **Test layout reorganized** to `tests/tcyr/` and `tests/bcyr/` (patra convention). `tests/test_sakshi.tcyr` (slim-only coverage, fully subsumed by full) is removed; `tests/test_sakshi_full.tcyr` moves to `tests/tcyr/sakshi.tcyr`. `benches/sakshi.bcyr` moves to `tests/bcyr/sakshi.bcyr`; the top-level `benches/` directory is removed.

### Changed

- **Manifest migrated `cyrius.toml` → `cyrius.cyml`** — adds `cyrius = "5.1.13"` pin, `[build]` (entry=`programs/smoke.cyr`, defines=`SAKSHI_SMOKE`), and `[deps].stdlib` list.
- **Toolchain bumped to Cyrius 5.1.13** — `.cyrius-toolchain` updated from 5.1.1. Tests and benchmarks verified on the new toolchain (err_new 6ns, err_unpack 11ns — unchanged from 1.0.0 baseline).
- **CI workflow rewritten** — reads `.cyrius-toolchain` at runtime (was hardcoded `CYRIUS_VERSION: 3.2.6` env — stale). Adds `cyrius deps`, per-file `cyrius lint`, `CYRIUS_DCE=1 cyrius build` + smoke run, `cyrius test tests/tcyr/sakshi.tcyr`, and `cyrius bench tests/bcyr/sakshi.bcyr`. Security scan and docs job retained.
- **Release workflow** — runs the same DCE build + smoke as CI before packaging, and verifies `cyrius.cyml` version matches the tag (in addition to `VERSION`).

### Added

- **`programs/smoke.cyr`** — minimal end-to-end smoke program. Includes `src/lib.cyr`, exercises `set_level` / `info` / `span_enter` / `err_new` / `span_exit`. Built in CI with `CYRIUS_DCE=1` to validate the library compiles cleanly, DCE prunes unused surface, and the public API is consumable from a downstream project.
- **`scripts/bundle.sh`** — generates `dist/sakshi.cyr` from `src/*.cyr`, matching the patra bundling pattern. CI regenerates and diffs against the committed `dist/sakshi.cyr` to catch drift between `src/` and the bundle.
- **`fuzz/` directory** — placeholder for fuzz harnesses (patra-style layout). Empty in 2.0.0; populated in a follow-up.

### Removed

- **`src/config.cyr` + `sakshi.toml`** — the `#ref "sakshi.toml"` compile-time configuration mechanism never actually resolved under `cyrius check` / `build` / `test` on the 5.x toolchain. Previous tests only passed because they included the root bundles, which bypassed `config.cyr` entirely and used hardcoded defaults. Moving tests onto `src/lib.cyr` surfaced the dead path. Defaults (log level INFO = 3, output target stderr = 0) are baked into `src/trace.cyr` and `src/output.cyr` at their declaration sites — the runtime behavior is identical to the previous default-only configuration. Roadmap item #1 now tracks a `#define`-based replacement via `cyrius.cyml` `defines`.

### Fixed

- **`docs/architecture/overview.md`** — trace module description now lists `fatal` alongside `error/warn/info/debug/trace` (added in v0.9.3).
- **`src/span.cyr` doc-comment indentation** — normalized via `cyrius fmt` (code-example lines inside the `defer { … }` usage block were at column 1; `cyrfmt` expects them indented to match their enclosing block).

### Known issues

- The Cyrius 5.1.12 and 5.1.13 release tarballs' `cyrius` binary internally self-reports as `cyrius 5.1.10` when invoked with `cyrius version`. The tarball contents are correct; the stale version string is an upstream release-script bug in the Cyrius toolchain, not sakshi. Pinning by tarball name (`.cyrius-toolchain = 5.1.13`) still resolves the right artifact.




## [1.0.0] - 2026-04-16

**Stable release.** Zero-alloc tracing, error handling, and structured logging for the Cyrius ecosystem. Ships as part of Cyrius stdlib since v5.1.1.

### Changed

- **Toolchain pinned to Cyrius 5.1.1** — stdlib integration verified (bundled sakshi 0.9.3, log.cyr level mapping fixed, output routing fixed, sakshi_sakshi.cyr duplicate removed)
- **54 tests passing** — 19 slim profile, 35 full profile

### Summary since v0.5.0

- 6 log levels: FATAL, ERROR, WARN, INFO, DEBUG, TRACE
- Packed i64 error codes with 32-bit context field (8 categories, 8 codes)
- 16-deep span stack with nanosecond timing and trace ID correlation
- 4 output targets: stderr, file, 4KB ring buffer, UDP
- Self-describing binary format with metadata event
- Security audited (11 findings, all resolved)
- Zero heap allocation, zero external dependencies




## [0.9.3] - 2026-04-15

### Breaking

- **Log level enum renumbered** — `SK_FATAL=0` added, all existing levels shifted +1. `SK_ERROR` is now 1 (was 0), `SK_WARN` is 2 (was 1), `SK_INFO` is 3 (was 2), `SK_DEBUG` is 4 (was 3), `SK_TRACE` is 5 (was 4). Default log level updated to 3 (INFO). Consumers using enum names (`SK_INFO`, etc.) need only recompile — no source changes required. Consumers using hardcoded numeric values must update them.
- **Ring buffer metadata event** — `sakshi_output_buffer()` now emits a metadata event (level=0xFF) as the first event when ring buffer output is activated. Consumers reading raw ring data should skip or handle events with level 255. `sakshi_ring_event_count()` includes this event in the count.

### Added

- **`SK_FATAL` log level** — new most-severe level (value 0). `sakshi_fatal(msg, msg_len)` API. Always emitted at any log level setting. `_sk_level_str` outputs "FATAL". (`src/trace.cyr`, `src/output.cyr`, `sakshi.cyr`, `sakshi_full.cyr`)
- **Trace ID correlation** — `sakshi_trace_set(id)` / `sakshi_trace_id()` API for stamping a u64 correlation token across spans and events. Zero-alloc, single global. (`src/span.cyr`, `sakshi_full.cyr`)
- **Binary format metadata event** — ring buffer init emits a self-describing header: format version (1), header size (12), magic ("sakshi"). Level 0xFF marker. Enables offline tooling to validate format without hardcoding layout. (`src/output.cyr`, `sakshi_full.cyr`)
- **`.cyrius-toolchain`** — toolchain pinned to 4.10.3 (latest stdlib). Lib symlink updated from Cyrius 2.2.0.

### Changed

- **Performance: eliminated double timestamp on text path** — `_sk_fmt_line` and `_sk_fmt_span` now accept a pre-captured timestamp parameter instead of calling `_sk_now_ns()` internally. Saves one `clock_gettime` syscall per text event. (`src/format.cyr`, `src/output.cyr`, `sakshi.cyr`, `sakshi_full.cyr`)
- **Performance: ring buffer header write** — replaced 12 individual `_sk_ring_put` function calls with stack-build + byte-copy loop. Eliminates function call overhead for header construction. (`src/output.cyr`, `sakshi_full.cyr`)
- **Performance: `_sk_memcpy` 8-byte bulk copy** — uses `store64`/`load64` for aligned 8-byte chunks, byte loop for remainder. ~8x faster for larger payloads. (`src/format.cyr`, `sakshi_full.cyr`)




## [0.9.2] - 2026-04-15

### Security

- **SA-004 (HIGH): Ring decode msg_len sanity guard** — `sakshi_ring_decode_event` now rejects events with `msg_len > 4084` (max message that fits in a 4KB ring buffer). Prevents misaligned decode chains from corrupted ring data. (`src/output.cyr`, `sakshi_full.cyr`)
- **SA-007 (MEDIUM): fd validation in `sakshi_set_output_fd`** — rejects negative file descriptors, returns -1 on invalid input. Prevents silent log loss from bad fd. (`src/output.cyr`, `sakshi.cyr`, `sakshi_full.cyr`)
- **SA-010 (LOW): `clock_gettime` return check** — `_sk_now_ns()` now checks syscall return value and falls back to 0 on failure. (`src/format.cyr`, `sakshi.cyr`, `sakshi_full.cyr`)

### Fixed

- **SA-009: Removed dead `_sk_strlen`** — unused function removed from `src/format.cyr` and `sakshi_full.cyr`. Eliminates unbounded loop on non-null-terminated input risk.

### Added

- **Constraints documentation** — all public API headers (`lib.cyr`, `sakshi.cyr`, `sakshi_full.cyr`) now document: single-threaded only, UDP unencrypted/unauthenticated, 292-year timestamp overflow limit
- **UDP security warning** — `sakshi_output_udp` function comments warn that transport is unencrypted

### Changed

- All 7 deferred items from 2026-04-15 security audit resolved




## [0.9.1] - 2026-04-15

### Security

- **SA-001 (CRITICAL): UDP header msg_len unclamped** — `_sk_write_udp_event` wrote the original unclamped `msg_len` into the binary packet header while clamping only the memcpy. A receiver decoding the packet would read past the payload. Fixed: header now contains the clamped value. (`src/output.cyr`, `sakshi_full.cyr`)

### Fixed

- **`_sk_apply_config` now applies output target** — `config.cyr` was loading `sk_cfg_output_target` from `sakshi.toml` but never applying it at init. Output target config is now honored.
- **Slim profile `_sk_file_fd` init** — initialized to `-1` instead of `0` (stdin). `sakshi_output_file_close` also resets to `-1`. Prevents accidental write to fd 0 if close was called without a prior open.

### Added

- **Security audit** — `docs/audit/2026-04-15-audit.md` — 11 findings (1 CRITICAL, 3 HIGH, 4 MEDIUM, 3 LOW), CVE/0day pattern review against 7 known attack classes
- **Test coverage** — level filtering (debug/trace suppressed at INFO), TRACE level, `sakshi_set_output_fd` redirect, error edge cases (max values, overflow clamping) in slim test; span overflow (16-deep fill + reject 17th), level filtering, fd redirect in full test
- **API contract documentation** — `sakshi_ring_read_raw` (caller buffer responsibility), `sakshi_output_file` (trusted path only), `_sk_fmt_int` (24-byte minimum buffer)

### Changed

- **CLAUDE.md** — aligned with agnosticos first-party standards template (P(-1), work loop, security hardening, closeout pass processes)
- **Roadmap** — added v0.9.1 security follow-up milestone (7 deferred items), updated v1.0.0 prerequisites
- **Architecture docs** — fixed stale references: "serial" → "stderr", removed phantom `[module]` trace field, corrected `sakshi_error` → `sakshi_err_new`




## [0.9.0] - 2026-04-09

### Changed
- **Cyrius 3.2.6** — toolchain pinned to v3.2.6 (composable `#derive(Serialize)`, json_parse fix)
- **Modular src/ constants → enums** — `format.cyr`, `span.cyr`, `output.cyr` converted `var` constants to `enum` types, eliminating 5 global variable slots (matches distribution profile pattern)
- **Slim profile refactored** — `sakshi.cyr` now uses `_sk_level_str` helper and `_sk_fmt_line` formatter, matching full profile structure
- **`defer` pattern documented** — `span.cyr` documents recommended `defer { sakshi_span_exit(); }` usage for guaranteed span cleanup (Cyrius >= 3.2.0)




## [0.8.2] - 2026-04-09

### Changed
- Cyrius toolchain pinned to v3.2.5 (cc3 compiler, minimum version)





### Fixed

- Formatting fixes to distribution lib files




## [0.8.0]

### Changed

- **Cyrius 3.2.0** — upgraded compiler target from 2.7.2 to 3.2.0
- **Slim profile uses enums** — `sakshi.cyr` constants converted from `var` declarations to proper `enum` types, matching the full profile (bug #16 workaround removed)
- **`match` for level dispatch** — replaced `if` chains with `match` expressions in both distribution profiles and modular source
- **`_sk_level_str` helper** — centralized level-to-string mapping (full profile + modular src) using `match`, covers log levels + span actions




## [0.7.0]

### Added

- **Full profile test suite** — `tests/test_sakshi_full.tcyr` (28 assertions: spans, ring buffer, binary decode, edge cases)
- **Benchmarks** — `benches/sakshi.bcyr` (err_new 6ns, err_with_ctx 7ns, err_unpack 13ns, timestamp 430ns, trace_info 1us, trace_filtered 7ns)
- **Vidya entry** — `content/tracing/` topic with concept.toml (4 best practices, 4 gotchas, 3 performance notes with evidence) and runnable cyrius.cyr

### Fixed

- Cyrius bug #16 resolved in Cyrius 2.2.0 — enums no longer shift data section layout; full profile works without var workaround
- CI pinned to Cyrius 2.2.0




## [0.5.0]

### Added

- **error.cyr** — packed i64 error codes with 32-bit context field
  - `sakshi_err_new(code, category)` — pack code + category
  - `sakshi_err_with_ctx(code, category, context)` — pack with caller-defined context (source hash, span ID)
  - `sakshi_err_at_span(code, category)` — auto-fill context with current span depth
  - `sakshi_err_code`, `sakshi_err_category`, `sakshi_err_context` — extractors
  - `sakshi_is_err`, `sakshi_is_ok` — predicates
  - 8 error categories: syscall, io, parse, config, runtime, alloc, net, auth
  - 8 common error codes: ok, unknown, invalid, not_found, permission, timeout, overflow, busy
- **trace.cyr** — 5 log levels (error/warn/info/debug/trace) with runtime level filtering
  - `sakshi_error`, `sakshi_warn`, `sakshi_info`, `sakshi_debug`, `sakshi_trace`
  - `sakshi_set_level`, `sakshi_get_level`
  - Monotonic nanosecond timestamps on all events
- **span.cyr** — function enter/exit tracking with nanosecond timing
  - `sakshi_span_enter`, `sakshi_span_exit`, `sakshi_span_depth`
  - 16-deep fixed span stack (384 bytes, no heap)
- **output.cyr** — 4 output targets with unified dispatcher
  - **stderr** (default) — `sakshi_set_output_fd`
  - **file** — `sakshi_output_file` / `sakshi_output_file_close` (append mode)
  - **ring buffer** — 4KB power-of-2 circular buffer, binary events, overwrite-oldest policy. `sakshi_output_buffer`, `sakshi_ring_read_raw`, `sakshi_ring_len`, `sakshi_ring_clear`, `sakshi_ring_event_count`, `sakshi_ring_decode_event`
  - **UDP** — `sakshi_output_udp` / `sakshi_output_udp_close` / `sakshi_ipv4` (sendto-based)
  - `sakshi_set_output` — switch targets at runtime
  - `_sk_emit` dispatcher: binary format for buffer/UDP, text format for stderr/file
- **format.cyr** — zero-alloc internal formatting
  - Monotonic timestamps via `clock_gettime(CLOCK_MONOTONIC_RAW)`
  - 12-byte binary event header (`u64 timestamp`, `u8 level`, `u8 category`, `u16 msg_len`) — ~340 events in 4KB ring buffer
  - Text formatter: `[timestamp] [LEVEL] msg\n` for human-readable targets
- **config.cyr** — `#ref "sakshi.toml"` compile-time configuration (log level, output target)
- **lib.cyr** — single-include public API with auto-init
- **sakshi.toml** — default config file with documented options
- Test program: `programs/test_sakshi.cyr`
