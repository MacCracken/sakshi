# Sakshi Development Roadmap

> **v1.1.0** — scaffold modernization (cyrius.cyml + DCE CI). v1.0.0 stable, bundled in Cyrius stdlib (v5.1.1+). 54 tests, security audited, zero-alloc.

---

## Completed since v1.0.0

- **v1.1.0** — manifest migrated to `cyrius.cyml`, CI/release workflows aligned with AGNOS scaffold (`.cyrius-toolchain` pin, `cyrius deps`, per-file lint, `CYRIUS_DCE=1` build via `programs/smoke.cyr`, explicit per-file test invocation). Toolchain bumped to Cyrius 5.1.12.

## Post-v1.0 — Future Work

Items from P(-1) research. Some previously blocked on compiler features.

| # | Item | Requires | Status | Source |
|---|------|----------|--------|--------|
| 1 | Compile-time log level elimination | `#if` value-comparison + `#define` config | **Unblocked** (Cyrius 3.x has `#if`). Config is no longer `#ref`-based — a thin `#define SAKSHI_LEVEL=<n>` in consumer `cyrius.cyml` `defines` would do it. | Rust `log`, Linux kernel |
| 2 | Deferred formatting (string ID + raw args) | Compiler string interning | Blocked | Embedded Rust defmt |
| 3 | Per-module log levels | Module identity system | Blocked | LTTng, Tokio tracing |
| 4 | Per-CPU ring buffers | CPU-affinity primitives | Blocked | Linux ftrace |
| 5 | rdtsc/CNTVCT_EL0 cycle counter timestamps | Bare-metal TSC access | Blocked | ftrace, LTTng |
| 6 | Structured typed fields (key-value per event) | Generics or compile-time layout | Blocked | OTel, Tokio tracing |
| 7 | Subscriber/vtable pattern for open-ended output targets | Function pointers | Feasible | Rust tracing |
