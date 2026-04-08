# Changelog

All notable changes to Sakshi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - Unreleased

### Added

- Project scaffolded
- **error.cyr** — packed i64 error codes (`sakshi_err_new`, `sakshi_err_code`, `sakshi_err_category`, `sakshi_is_err`, `sakshi_is_ok`), 8 categories + common error codes via enums
- **trace.cyr** — 5 log levels (error/warn/info/debug/trace), `sakshi_error`/`sakshi_warn`/`sakshi_info`/`sakshi_debug`/`sakshi_trace`, configurable via `sakshi_set_level`
- **span.cyr** — `sakshi_span_enter`/`sakshi_span_exit` with nanosecond timing, 16-deep fixed stack
- **format.cyr** — internal zero-alloc formatting helpers (fixed-buffer line and span formatters)
- **output.cyr** — stderr output target, configurable fd via `sakshi_set_output_fd`
- **config.cyr** — placeholder for v0.2.0 `#ref` TOML compile-time config
- **lib.cyr** — single-include public API
- Test program: `programs/test_sakshi.cyr`
