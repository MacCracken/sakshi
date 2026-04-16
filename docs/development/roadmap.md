# Sakshi Development Roadmap

> **v1.0.0** stable. Part of Cyrius stdlib (v5.1.1+). 54 tests, security audited, zero-alloc.

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
| 7 | Subscriber/vtable pattern for open-ended output targets | Function pointers | Feasible | Rust tracing |
| 8 | Migrate manifest to cyrius.cyml | Cyrius CLI support | Blocked (CLI still generates .toml) | Cyrius 5.0.0 |
