# Changelog

All notable changes to Sakshi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - Unreleased

### Added

- **error.cyr** — packed i64 error codes with 32-bit context field
  - `sakshi_err_new(code, category)` — pack code + category
  - `sakshi_err_with_ctx(code, category, context)` — pack with caller-defined context (source hash, span ID)
  - `sakshi_err_at_span(code, category)` — auto-fill context with current span depth
  - `sakshi_err_code`, `sakshi_err_category`, `sakshi_err_context` — extractors
  - `sakshi_is_err`, `sakshi_is_ok` — predicates
  - 8 error categories: syscall, io, parse, config, runtime, alloc, net, auth
  - 8 common error codes: ok, unknown, invalid, not_found, permission, timeout, overflow, busy
- **trace.cyr** — 5 log levels (error/warn/info/debug/trace) with runtime level filtering
  - `sakshi_error`, `sakshi_warn`, `sakshi_info`, `sakshi_debug`, `sakshi_trace`
  - `sakshi_set_level`, `sakshi_get_level`
  - Monotonic nanosecond timestamps on all events
- **span.cyr** — function enter/exit tracking with nanosecond timing
  - `sakshi_span_enter`, `sakshi_span_exit`, `sakshi_span_depth`
  - 16-deep fixed span stack (384 bytes, no heap)
- **output.cyr** — 4 output targets with unified dispatcher
  - **stderr** (default) — `sakshi_set_output_fd`
  - **file** — `sakshi_output_file` / `sakshi_output_file_close` (append mode)
  - **ring buffer** — 4KB power-of-2 circular buffer, binary events, overwrite-oldest policy. `sakshi_output_buffer`, `sakshi_ring_read_raw`, `sakshi_ring_len`, `sakshi_ring_clear`, `sakshi_ring_event_count`, `sakshi_ring_decode_event`
  - **UDP** — `sakshi_output_udp` / `sakshi_output_udp_close` / `sakshi_ipv4` (sendto-based)
  - `sakshi_set_output` — switch targets at runtime
  - `_sk_emit` dispatcher: binary format for buffer/UDP, text format for stderr/file
- **format.cyr** — zero-alloc internal formatting
  - Monotonic timestamps via `clock_gettime(CLOCK_MONOTONIC_RAW)`
  - 12-byte binary event header (`u64 timestamp`, `u8 level`, `u8 category`, `u16 msg_len`) — ~340 events in 4KB ring buffer
  - Text formatter: `[timestamp] [LEVEL] msg\n` for human-readable targets
- **config.cyr** — `#ref "sakshi.toml"` compile-time configuration (log level, output target)
- **lib.cyr** — single-include public API with auto-init
- **sakshi.toml** — default config file with documented options
- Test program: `programs/test_sakshi.cyr`
