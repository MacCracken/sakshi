# Sakshi Development Roadmap

> **v0.9.2** current. All security audit items resolved. Targeting v1.0 stability.

## v0.9.2 — Security Hardening Follow-up (complete)

All items from the 2026-04-15 security audit. See `docs/audit/2026-04-15-audit.md`.

| # | Item | Audit Ref | Status |
|---|------|-----------|--------|
| 1 | Ring decode: `msg_len > 4084` sanity guard | SA-004 | Done |
| 2 | Remove dead `_sk_strlen` | SA-009 | Done |
| 3 | `fd >= 0` check in `sakshi_set_output_fd` | SA-007 | Done |
| 4 | `clock_gettime` return value check | SA-010 | Done |
| 5 | Document single-threaded-only constraint | CVE review | Done |
| 6 | Document UDP transport unencrypted/unauthenticated | CVE review | Done |
| 7 | Document 292-year timestamp overflow limit | SA-005 | Done |

## v1.0.0 — Stable

| # | Item | Status |
|---|------|--------|
| 1 | All security hardening items resolved | Done (v0.9.1 + v0.9.2) |
| 2 | Integration tested across 3+ consumer crates | Not started |
| 3 | Closeout pass (full checklist per CLAUDE.md) | Not started |

---

## Post-v1.0 — Future Work

Items from P(-1) research. Some previously blocked on compiler features.

| # | Item | Requires | Status | Source |
|---|------|----------|--------|--------|
| 1 | Compile-time log level elimination | `#if` value-comparison + `#define` config | **Unblocked** (Cyrius 3.x has `#if`) — needs config to use `#define` instead of `#ref` vars | Rust `log`, Linux kernel |
| 2 | Deferred formatting (string ID + raw args) | Compiler string interning | Blocked | Embedded Rust defmt |
| 3 | Per-module log levels | Module identity system | Blocked | LTTng, Tokio tracing |
| 4 | Per-CPU ring buffers | CPU-affinity primitives | Blocked | Linux ftrace |
| 5 | rdtsc/CNTVCT_EL0 cycle counter timestamps | Bare-metal TSC access | Blocked | ftrace, LTTng |
| 6 | Structured typed fields (key-value per event) | Generics or compile-time layout | Blocked | OTel, Tokio tracing |
| 7 | Slim/full `_sk_emit` level-check divergence | Slim profile expansion | Note | SA-008 |
