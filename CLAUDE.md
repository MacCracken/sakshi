# Sakshi — Claude Code Instructions

## Project Identity

**Sakshi** (Sanskrit: साक्षी — witness) — Tracing, error handling, and structured logging for the Cyrius ecosystem.

- **Type**: Foundational library — every AGNOS Cyrius project depends on this
- **License**: GPL-3.0-only
- **Language**: Cyrius (native — not ported from Rust)
- **Version**: SemVer, version file at `VERSION`
- **Status**: Implemented, approaching v1.0

## Genesis Layer

This project is part of **AGNOS** — an AI-native operating system. The genesis repo at `/home/macro/Repos/agnosticos` owns system-level docs, roadmap, and CI/CD.

- **Recipes**: `MacCracken/zugot` (Hebrew: pairs that enter the ark)
- **Standards**: `agnosticos/docs/development/applications/first-party-standards.md`
- **Shared crates**: `agnosticos/docs/development/applications/shared-crates.md`

## Development Process

### Work Loop

1. **P(-1)** — Research: vidya entry before implementation
2. Work phase — implement in Cyrius, test, benchmark
3. `cyrius build` — verify compilation
4. `cyrius test` — run .tcyr test files
5. Documentation — CHANGELOG, roadmap
6. Version check — VERSION in sync

### Task Sizing

- **Low/Medium**: Batch freely
- **Large**: Small bites, verify each
- **If unsure**: Treat as large

## DO NOT

- **Do not commit or push** — the user handles all git operations
- **NEVER use `gh` CLI** — use `curl` to GitHub API only
- Do not add unnecessary dependencies (there should be close to zero)

## Architecture

```
src/
  lib.cyr         — public API
  error.cyr       — packed i64 error codes (code + category)
  trace.cyr       — log levels, structured output
  span.cyr        — enter/exit timing
  format.cyr      — message formatting, fixed buffers
  output.cyr      — serial, file, buffer, network targets
  config.cyr      — #ref TOML config at compile time
```

## Key Design Constraints

- **Zero heap allocation on hot path** — all error creation and trace output uses fixed buffers
- **Packed error format** — error code + category in a single i64, matching agnosys pattern
- **Compile-time config** — `#ref` loads TOML log config, no runtime parsing
- **Target size** — compiled binary contribution: 2-3KB
- **No external dependencies** — this is the foundation everything else builds on
