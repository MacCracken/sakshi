# Sakshi Development Roadmap

> **v2.0.0** — flat patra-style layout, single `dist/sakshi.cyr` bundle, dead-config removed. Still bundled in Cyrius stdlib (v5.1.1+). 35 tests, security audited, zero-alloc. Toolchain pinned to Cyrius 5.1.13.

---

## Completed since v1.0.0

- **v2.0.0** — flat patra-style refactor. Removed root-level `sakshi.cyr` / `sakshi_full.cyr` bundles; single generated `dist/sakshi.cyr` + modular `src/lib.cyr`. Reorganized tests to `tests/tcyr/` + `tests/bcyr/`. Deleted dead `src/config.cyr` + `sakshi.toml` — `#ref` mechanism never resolved on 5.x, defaults now baked at declaration sites. Added `programs/smoke.cyr` (DCE build target), `scripts/bundle.sh` (bundler, CI-enforced in-sync), `fuzz/` placeholder. Scaffold modernized to match AGNOS first-party template (Ark reference): manifest migrated to `cyrius.cyml`, CI/release workflows aligned (`.cyrius-toolchain` pin, `cyrius deps`, per-file `cyrius lint` + `cyrius fmt --check`, `CYRIUS_DCE=1` build, explicit test/bench file paths). Toolchain bumped to Cyrius 5.1.13.

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
