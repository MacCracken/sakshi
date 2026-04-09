# Sakshi Development Roadmap

> **v0.8.0** in progress. Cyrius 3.2.0 upgrade, language modernization.

## v1.0.0 — Stable

| # | Item | Status |
|---|------|--------|
| 1 | Integration tested across 3+ consumer crates | Not started |

---

## Post-v1.0 — Future Work

Items from P(-1) research. Some previously blocked on compiler features.

| # | Item | Requires | Status | Source |
|---|------|----------|--------|--------|
| 1 | Compile-time log level elimination | `#if` value-comparison + `#define` config | **Unblocked** (Cyrius 3.x has `#if`) — needs config to use `#define` instead of `#ref` vars | Rust `log`, Linux kernel |
| 2 | `defer`-based cleanup patterns | `defer` statement | **Unblocked** (Cyrius 3.2.0) — document `defer { sakshi_output_file_close(); }` pattern for consumers | Cyrius 3.2.0 |
| 3 | Deferred formatting (string ID + raw args) | Compiler string interning | Blocked | Embedded Rust defmt |
| 4 | Per-module log levels | Module identity system | Blocked | LTTng, Tokio tracing |
| 5 | Per-CPU ring buffers | CPU-affinity primitives | Blocked | Linux ftrace |
| 6 | rdtsc/CNTVCT_EL0 cycle counter timestamps | Bare-metal TSC access | Blocked | ftrace, LTTng |
| 7 | Structured typed fields (key-value per event) | Generics or compile-time layout | Blocked | OTel, Tokio tracing |
