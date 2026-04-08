# Sakshi

> **Sakshi** (Sanskrit: साक्षी — the witness) — Tracing, error handling, and structured logging for the Cyrius ecosystem.

In Advaita Vedanta, the *sakshi* is pure observer-consciousness — always present, never interfering, simply recording what is. That is what this crate does for every AGNOS binary.

## What It Does

- **Error codes** — Packed i64 error representation (code + category in a single integer). Zero-alloc error creation and propagation.
- **Tracing** — Structured log output with levels (error, warn, info, debug, trace). Fixed-buffer formatting. No heap allocation on the hot path.
- **Spans** — Function enter/exit tracking with timing. Nestable context for tracing call chains.
- **Output targets** — Serial, file, buffer, network. Configurable at compile time via `#ref` from TOML.

## Design Principles

- **Zero allocation on the hot path** — fixed buffers, packed integers, no heap in the error/trace fast path
- **Cyrius-native** — first crate designed for Cyrius, not ported from Rust. No serde, no thiserror, no tracing crate abstractions
- **Foundational** — every AGNOS Cyrius project includes sakshi. It is the first dependency.
- **Tiny** — target compiled size: 2-3KB. The witness should be invisible.

## Architecture

```
sakshi/
  src/
    lib.cyr         — public API, includes all modules
    error.cyr       — packed error codes, categories, context
    trace.cyr       — log levels, structured output, fixed buffers
    span.cyr        — enter/exit tracking, timing
    format.cyr      — timestamp, level, module, message formatting
    output.cyr      — serial, file, buffer, network targets
    config.cyr      — #ref TOML config loading at compile time
```

## Usage

```cyrius
include "sakshi/src/lib.cyr"

# Errors — packed i64
var err = sakshi_err_new(ERR_NOT_FOUND, ERR_CAT_IO);
var code = sakshi_err_code(err);
var cat = sakshi_err_category(err);

# Tracing — zero-alloc
sakshi_info("service started", 15);
sakshi_error("bind failed", 11);
sakshi_debug("fd=", 3);

# Spans — timing
sakshi_span_enter("boot_init", 9);
# ... work ...
sakshi_span_exit();
```

## Error Format

Packed i64: `[63:32 reserved] [31:16 category] [15:0 error code]`

| Category | Value | Domain |
|----------|-------|--------|
| ERR_CAT_SYSCALL | 0x0001 | Kernel syscall failures |
| ERR_CAT_IO | 0x0002 | File/network I/O |
| ERR_CAT_PARSE | 0x0003 | Config/data parsing |
| ERR_CAT_CONFIG | 0x0004 | Configuration errors |
| ERR_CAT_RUNTIME | 0x0005 | Runtime logic errors |
| ERR_CAT_ALLOC | 0x0006 | Memory allocation |
| ERR_CAT_NET | 0x0007 | Network protocol |
| ERR_CAT_AUTH | 0x0008 | Authentication/authorization |

## License

GPL-3.0-only

## Project

Part of [AGNOS](https://agnosticos.org) — the AI-native operating system.
