# Sakshi Architecture

> The silent witness. Zero-alloc tracing, error handling, and structured logging for Cyrius.

## Module Map

```
sakshi
├── error      — packed i64 error codes (code + category + reserved)
├── trace      — log levels (error/warn/info/debug/trace), structured output
├── span       — enter/exit function tracking with timing
├── format     — fixed-buffer message formatting (timestamp, level, module, message)
├── output     — output targets (serial, file, buffer, network)
└── config     — compile-time #ref TOML configuration
```

## Data Flow

```
Application code
  → sakshi_error() / sakshi_info() / sakshi_span_enter()
    → format (fixed buffer, no alloc)
      → output target (serial / file / buffer / network)
```

## Error Format

Packed i64: `[63:32 reserved] [31:16 category] [15:0 error code]`

Creation: `sakshi_error(code, category)` — single OR + shift, no heap.
Extraction: `sakshi_err_code(err)`, `sakshi_err_category(err)` — single AND + shift.

Matches the agnosys packed error pattern that benchmarks at 6ns (1.8x faster than Rust Result<T,E>).

## Trace Format

Fixed buffer output: `[timestamp] [LEVEL] [module] message`

No heap. No serde. No format strings. Direct byte writes to the output buffer.

## Consumers

Every AGNOS Cyrius project. This is the first `include` in every crate.

## Design Constraints

- Zero heap allocation on error/trace hot path
- Compiled contribution: 2-3KB target
- No external dependencies (this IS the foundation)
- #ref TOML for compile-time config (log levels, output targets)
