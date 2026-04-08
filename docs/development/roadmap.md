# Sakshi Development Roadmap

> **v0.1.0** — Scaffolded. First Cyrius-native crate.

## v0.1.0 — Foundation

| # | Item | Status |
|---|------|--------|
| 1 | Packed i64 error format (code + category) | Designed |
| 2 | 8 error categories (syscall, io, parse, config, runtime, alloc, net, auth) | Designed |
| 3 | Log levels (error, warn, info, debug, trace) | Designed |
| 4 | Fixed-buffer formatted output | Not started |
| 5 | Serial output target | Not started |
| 6 | Basic span enter/exit with timing | Not started |
| 7 | Test programs in programs/ | Not started |

## v0.2.0 — Config & Targets

| # | Item | Status |
|---|------|--------|
| 1 | `#ref` TOML compile-time config (log level, output target) | Not started |
| 2 | File output target | Not started |
| 3 | Buffer output target (ring buffer for in-memory trace) | Not started |
| 4 | Network output target (UDP) | Not started |

## v1.0.0 — Stable

| # | Item | Status |
|---|------|--------|
| 1 | .tcyr test suite (when Cyrius v2.0 lands) | Not started |
| 2 | .bcyr benchmarks | Not started |
| 3 | Integration tested across 3+ consumer crates | Not started |
| 4 | Vidya entry for sakshi usage patterns | Not started |
