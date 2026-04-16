# Sakshi Development Roadmap

> **v0.9.1** current. Security hardening pass complete. Targeting v1.0 stability.

## v0.9.2 — Security Hardening Follow-up

Items deferred from the 2026-04-15 security audit. See `docs/audit/2026-04-15-audit.md` for full details.

| # | Item | Severity | Audit Ref | Status |
|---|------|----------|-----------|--------|
| 1 | Ring decode: add `msg_len > 4084` sanity guard | HIGH | SA-004 | Not started |
| 2 | Remove dead `_sk_strlen` or add max_len param | LOW | SA-009 | Not started |
| 3 | Optional `fd >= 0` check in `sakshi_set_output_fd` | MEDIUM | SA-007 | Not started |
| 4 | Optional `clock_gettime` return value check | LOW | SA-010 | Not started |
| 5 | Document single-threaded-only constraint | — | CVE review | Not started |
| 6 | Document UDP transport is unencrypted/unauthenticated | — | CVE review | Not started |
| 7 | Document 292-year timestamp overflow limit | MEDIUM | SA-005 | Not started |

## v1.0.0 — Stable

| # | Item | Status |
|---|------|--------|
| 1 | All v0.9.1 hardening items resolved | Not started |
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
