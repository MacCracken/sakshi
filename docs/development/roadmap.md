# Sakshi Development Roadmap

> **v0.5.0** released. Dual-profile distribution, CI/release pipeline, 12 tests passing.

## v0.5.0 — Released

### Core

| # | Item | Status |
|---|------|--------|
| 1 | Packed i64 error format: `[context:32][category:16][code:16]` | Done |
| 2 | Input validation — category/context masked to prevent field overflow | Done |
| 3 | 8 error categories, 8 common error codes (enums) | Done |
| 4 | 5 log levels (error/warn/info/debug/trace) with runtime filtering | Done |
| 5 | Monotonic nanosecond timestamps on all events | Done |
| 6 | Fixed-buffer text formatting (`[timestamp] [LEVEL] msg\n`) | Done |

### Output Targets

| # | Item | Profile | Status |
|---|------|---------|--------|
| 1 | Stderr (default) | slim + full | Done |
| 2 | File (append mode, tee in slim, exclusive in full) | slim + full | Done |
| 3 | Ring buffer (4KB, binary events, power-of-2 bitmask, overwrite-oldest) | full | Done |
| 4 | UDP (binary events via sendto) | full | Done |
| 5 | Binary event format (12-byte header + msg), `sakshi_ring_decode_event` | full | Done |
| 6 | Unified `_sk_emit` dispatcher (binary vs text by target) | full | Done |

### Spans (full profile only)

| # | Item | Status |
|---|------|--------|
| 1 | `sakshi_span_enter` / `sakshi_span_exit` with nanosecond timing | Done |
| 2 | 16-deep fixed span stack (384 bytes, no heap) | Done |
| 3 | `sakshi_err_at_span` — error-to-span correlation via context field | Done |

### Distribution

| # | Item | Status |
|---|------|--------|
| 1 | `sakshi.cyr` — slim stderr profile (4 globals, 0 arrays) | Done |
| 2 | `sakshi_full.cyr` — full profile (spans, ring buffer, UDP) | Done |
| 3 | `src/*.cyr` — modular source (7 files) | Done |
| 4 | `#ref "sakshi.toml"` compile-time config in modular source | Done |

### CI/Release

| # | Item | Status |
|---|------|--------|
| 1 | GitHub Actions CI (build, check, security, test, benchmarks, docs) | Done |
| 2 | GitHub Actions release (CI gate, source archive, SHA256, changelog extract) | Done |
| 3 | `scripts/test.sh` — auto-discover .tcyr, auto-find cyrb | Done |
| 4 | `scripts/version-bump.sh` — atomic VERSION/cyrius.toml/CHANGELOG update | Done |
| 5 | Stdlib `lib/` symlink pattern (gitignored, CI creates per-job) | Done |

### Tests

| # | Item | Status |
|---|------|--------|
| 1 | Slim profile .tcyr test suite (12 assertions) | Done |

---

## v1.0.0 — Stable

| # | Item | Status |
|---|------|--------|
| 1 | Full profile .tcyr test suite (ring buffer, spans, UDP, binary decode) | Not started |
| 2 | .bcyr benchmarks (err_new 6ns, trace_info 1us, filtered 7ns) | Done |
| 3 | Integration tested across 3+ consumer crates | Not started |
| 4 | Vidya entry for sakshi usage patterns | Done |
| 5 | Resolve Cyrius bug #16 (enum data section shift) or confirm var workaround permanent | Not started |

---

## Post-v1.0 — Blocked on Cyrius Compiler

Items from P(-1) research that require compiler features not yet available.

| # | Item | Requires | Source |
|---|------|----------|--------|
| 1 | Compile-time log level elimination | `#if` value-comparison directive | Rust `log`, Linux kernel |
| 2 | Deferred formatting (string ID + raw args) | Compiler string interning | Embedded Rust defmt |
| 3 | Per-module log levels | Module identity system | LTTng, Tokio tracing |
| 4 | Per-CPU ring buffers | CPU-affinity primitives | Linux ftrace |
| 5 | rdtsc/CNTVCT_EL0 cycle counter timestamps | Bare-metal TSC access | ftrace, LTTng |
| 6 | Structured typed fields (key-value per event) | Generics or compile-time layout | OTel, Tokio tracing |
