# Sakshi Architecture

> The silent witness. Zero-alloc tracing, error handling, and structured logging for Cyrius.

## Module Map

```
sakshi
├── error      — packed i64 error codes (code + category + optional context)
├── trace      — log levels (fatal/error/warn/info/debug/trace), structured output
├── span       — enter/exit function tracking with timing
├── format     — fixed-buffer message formatting (timestamp, level, module, message)
└── output     — output targets (stderr, file, ring buffer, UDP)
```

## Data Flow

```
Application code
  → sakshi_error() / sakshi_info() / sakshi_span_enter()
    → format (fixed buffer, no alloc)
      → _sk_write() dispatcher
        → stderr (default)
        → file (append mode, opened by sakshi_output_file)
        → ring buffer (4KB circular, in-memory)
        → UDP (sendto, opened by sakshi_output_udp)
```

## Error Format

Packed i64: `[63:32 context] [31:16 category] [15:0 error code]`

Creation: `sakshi_err_new(code, category)` — single OR + shift, no heap.
Extraction: `sakshi_err_code(err)`, `sakshi_err_category(err)` — single AND + shift.

Matches the agnosys packed error pattern that benchmarks at 6ns (1.8x faster than Rust Result<T,E>).

## Trace Format

Fixed buffer output: `[timestamp] [LEVEL] message`

No heap. No serde. No format strings. Direct byte writes to the output buffer.

## Consumers

Every AGNOS Cyrius project. This is the first `include` in every crate.

- **Internal** (Cyrius stdlib, sibling AGNOS crates): `include "sakshi/src/lib.cyr"` — resolves via `[deps.sakshi] path = "../sakshi"`.
- **External**: `include "lib/sakshi.cyr"` — resolves to the generated `dist/sakshi.cyr` bundle via `[deps.sakshi] modules = ["dist/sakshi.cyr"]`.

The pre-2.0 slim/full split is retired. `CYRIUS_DCE=1` prunes unused API surface on a per-consumer basis — callers that never touch UDP or the ring buffer pay nothing for those paths.

## Design Constraints

- Zero heap allocation on error/trace hot path
- Compiled contribution: 2-3KB target
- No external dependencies (this IS the foundation)
- Defaults (log level INFO, output stderr) are baked into `src/trace.cyr` and `src/output.cyr`. Override at runtime via `sakshi_set_level` / `sakshi_set_output` before the first emit.
