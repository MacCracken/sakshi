# Sakshi Architecture

> The silent witness. Zero-alloc tracing, error handling, and structured logging for Cyrius.

## Module Map

```
sakshi
├── syscalls   — arch-dispatched syscall numbers (x86_64 / aarch64 / AGNOS)
├── clock      — cycle-counter timestamps (rdtsc / cntvct_el0), TSC calibration
├── error      — packed i64 error codes (code + category + optional context)
├── trace      — log levels (fatal/error/warn/info/debug/trace), structured output
├── span       — enter/exit function tracking with timing
├── format     — fixed-buffer text formatting + the 12-byte binary event header
└── output     — six targets: stderr, file, ring, atomic ring, UDP, subscriber hook
```

## Data Flow

```
Application code
  → sakshi_error() / sakshi_info() / sakshi_log_kv() / sakshi_span_enter()
    → _sk_emit() / _sk_emit_span()          — the dispatcher; reads the clock once
      │
      ├─ BINARY targets — no text formatting at all, 12-byte header + raw bytes
      │    → ring buffer   (4KB circular, overwrite-oldest, in-memory)
      │    → atomic ring   (4KB, lock-free multi-producer reservation writer)
      │    → UDP           (sendto; unavailable on Windows PE, macOS and AGNOS)
      │
      ├─ HOOK target — the event is passed to the subscriber fn unformatted
      │    → fncall6(hook, ts, level, category, msg, msg_len, sixth)
      │
      └─ TEXT targets — _sk_fmt_line / _sk_fmt_span into a 256-byte buffer,
           then _sk_write()
             → stderr (default)
             → file (append mode, opened by sakshi_output_file)

Only the text branch goes through the formatter, and _sk_write() dispatches
between stderr and file — it is not the top-level target dispatcher.
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
