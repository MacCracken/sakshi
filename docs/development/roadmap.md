# Sakshi Development Roadmap

> **v0.2.0** — Config & all output targets implemented.

## v0.1.0 — Foundation

| # | Item | Status |
|---|------|--------|
| 1 | Packed i64 error format (code + category) | Done |
| 2 | 8 error categories (syscall, io, parse, config, runtime, alloc, net, auth) | Done |
| 3 | Log levels (error, warn, info, debug, trace) | Done |
| 4 | Fixed-buffer formatted output | Done |
| 5 | Stderr output target | Done |
| 6 | Basic span enter/exit with timing | Done |
| 7 | Test program in programs/ | Done |

## v0.2.0 — Config & Targets

| # | Item | Status |
|---|------|--------|
| 1 | `#ref` TOML compile-time config (log level, output target) | Done |
| 2 | File output target | Done |
| 3 | Buffer output target (ring buffer for in-memory trace) | Done |
| 4 | Network output target (UDP) | Done |

## v1.0.0 — Stable

| # | Item | Status |
|---|------|--------|
| 1 | Migrate test program to .tcyr test suite (Cyrius v2.0) | Not started |
| 2 | Migrate to .bcyr benchmarks (Cyrius v2.0) | Not started |
| 3 | Integration tested across 3+ consumer crates | Not started |
| 4 | Vidya entry for sakshi usage patterns | Not started |
