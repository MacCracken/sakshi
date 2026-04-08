# Sakshi Development Roadmap

> **v0.5.0** — All pre-1.0 implementation complete. Zero-alloc tracing, error handling, 4 output targets, binary events, timestamps.

## v0.5.0 — Complete Pre-1.0 Implementation

All items from v0.1.0 through v0.3.0 shipped as a single release.

### Foundation (originally v0.1.0)

| # | Item | Status |
|---|------|--------|
| 1 | Packed i64 error format (code + category + context) | Done |
| 2 | 8 error categories (syscall, io, parse, config, runtime, alloc, net, auth) | Done |
| 3 | Log levels (error, warn, info, debug, trace) | Done |
| 4 | Fixed-buffer formatted output | Done |
| 5 | Stderr output target | Done |
| 6 | Basic span enter/exit with timing | Done |
| 7 | Test program in programs/ | Done |

### Config & Targets (originally v0.2.0)

| # | Item | Status |
|---|------|--------|
| 1 | `#ref` TOML compile-time config (log level, output target) | Done |
| 2 | File output target | Done |
| 3 | Buffer output target (ring buffer for in-memory trace) | Done |
| 4 | Network output target (UDP) | Done |

### P(-1) Research Hardening (originally v0.3.0)

| # | Item | Status |
|---|------|--------|
| 1 | Monotonic timestamps on all trace events | Done |
| 2 | Binary event format for ring buffer (12-byte header + msg) | Done |
| 3 | Binary event format for UDP (same wire format) | Done |
| 4 | Power-of-2 bitmask ring buffer (`& 0xFFF` vs `%`) | Done |
| 5 | Error context field in upper 32 bits (span ID, source hash) | Done |
| 6 | `sakshi_err_with_ctx` / `sakshi_err_context` / `sakshi_err_at_span` | Done |
| 7 | `sakshi_ring_decode_event` for binary-to-text conversion | Done |
| 8 | Unified `_sk_emit` dispatcher (binary vs text by target) | Done |

---

## v1.0.0 — Stable

| # | Item | Status |
|---|------|--------|
| 1 | Slim profile .tcyr test suite | Done |
| 2 | Full profile .tcyr test suite (ring buffer, spans, UDP) | Not started |
| 3 | .bcyr benchmarks (Cyrius v2.0) | Not started |
| 3 | Integration tested across 3+ consumer crates | Not started |
| 4 | Vidya entry for sakshi usage patterns | Not started |

---

## Post-v1.0 — Blocked on Cyrius Compiler (post-2.2.0)

Items from P(-1) research that require compiler features not yet available.

| # | Item | Requires | Source |
|---|------|----------|--------|
| 1 | Compile-time log level elimination (dead code removal for disabled levels) | `#if` value-comparison directive (not just `#ifdef`) | Rust `log`, Linux kernel `#if` |
| 2 | Deferred formatting — store string ID + raw args, decode externally | Compiler string interning (ELF section for format strings) | Embedded Rust defmt |
| 3 | Per-module log levels (module ID → level threshold table) | Module identity / ID system in Cyrius | LTTng, Tokio tracing |
| 4 | Per-CPU ring buffers (eliminate SMP contention) | Multi-core / CPU-affinity primitives | Linux ftrace |
| 5 | rdtsc/CNTVCT_EL0 direct cycle counter timestamps | Bare-metal TSC access + calibration | ftrace, LTTng |
| 6 | Structured typed fields (fixed 4-slot key-value per event) | May benefit from generics or compile-time field layout | OTel, Tokio tracing |
