# Changelog

All notable changes to Sakshi will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - Unreleased

### Added

- Project scaffolded
- Architecture defined: error, trace, span, format, output, config modules
- Packed i64 error format designed (code + category)
- 8 error categories: syscall, io, parse, config, runtime, alloc, net, auth
