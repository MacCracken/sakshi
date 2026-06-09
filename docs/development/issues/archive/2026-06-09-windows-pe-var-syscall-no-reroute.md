# Windows / PE target: all sakshi output silently dropped — `var` syscall numbers defeat the cyrius PE reroute — FULLY RESOLVED (v2.2.8 / cyrius 6.1.16)

**Filed:** 2026-06-09
**Reporter:** ai-hwaccel v2.3.9 (first sakshi consumer to ship a Windows PE binary).
**Cyrius version at time of report:** 6.1.15 (`cycc_win`).
**Affected sakshi source:** `src/syscalls.cyr`, `src/output.cyr`, `src/clock.cyr` (everything that emits I/O).
**Severity:** **P1.** sakshi produces a clean-looking PE binary that logs **nothing** — no fault, exit 0, zero bytes on stderr/file/UDP. Silent total feature loss on a tier-1 target, and it is the *portable* arch-dispatch idiom (v2.2.2) that triggers it.
**Status:** **fully resolved (v2.2.8 / cyrius 6.1.16).** Resolved sakshi-side in v2.2.7 — the "sakshi stopgap" below shipped (`#ifdef CYRIUS_TARGET_WIN` literal-syscall branches + busy-spin clock calibration), and a `build-windows` CI lane now runs the PE smoke under wine and asserts the log line reaches stderr. **Upstream now closed too:** cyrius **6.1.16** emits a runtime dispatch (`cmp`/`jne` switch on the syscall number) for non-literal PE syscall numbers — the clean fix — and ships the previously-missing `cycc_win` in the x86_64 release tarball (the actual CI blocker for a pinned install). sakshi re-pinned 6.1.15 → 6.1.16 in v2.2.8; the per-call-site stopgap is retained (redundant but harmless) and retiring it is a separate follow-up.

## Summary

Since v2.2.2, `src/syscalls.cyr` holds syscall numbers in `var` slots (`var _SK_SYS_WRITE = 1;`) so the arch dispatch is a value swap rather than a per-call `#ifdef`. Every sakshi I/O call is therefore `syscall(_SK_SYS_WRITE, fd, …)` — a **runtime** number. cyrius's Win64 PE syscall reroute (`syscall(1,…)` → `GetStdHandle+WriteFile`) is a **compile-time match on a constant-folded number**; a variable number doesn't fold, no case matches, and lowering falls through to the raw x86_64 `syscall` instruction (`0F 05`), which is non-functional on Windows. For `rax=1` it returns silently → `_sk_write_stderr` writes zero bytes and does not fault.

Net: on Windows PE, `sakshi_warn`/`info`/`debug`/span/trace all run, allocate, format, and emit **nothing**. On x86-Linux the same `var`-number call works (real `syscall` instruction), so this is PE-only and was invisible until ai-hwaccel built the first PE consumer.

## Reproduction

Confirmed on `cass` (Windows 10.0.26200, x86_64), `cycc_win` 6.1.15. Minimal, no sakshi:

```cyrius
var w = 1; var fd2 = 2;
syscall(1, 2,   "lit_num\n", 8);   # writes to stderr
syscall(w, 2,   "var_num\n", 8);   # SILENT — no bytes, no fault, exit 0
```
Only `lit_num` appears. The fd arg may be a variable; only the **number** must be literal.

sakshi-level: a PE program that `sakshi_set_level(SK_TRACE)` then `sakshi_warn("X",1)` prints nothing to stderr and exits 0 (verified — the level is set correctly, `_sk_log` reaches `_sk_emit`, the write is the silent no-op). `_sk_write_stderr` swapped for a literal `syscall(1, _sk_stderr_fd, buf, len)` writes correctly on the same host.

## Root cause

Upstream: `cyrius/src/frontend/parse_expr.cyr` syscall lowering — `sc_num` is only captured when the first arg constant-folds (`if (_cfo == 1) { sc_num = _cfv; }`); the `_TARGET_PE` reroute cases all test `sc_num == <literal>`. Filed upstream:
`cyrius/docs/development/issues/2026-06-09-pe-syscall-variable-number-not-rerouted.md`.

sakshi side: the v2.2.2 `var`-slot dispatch (this repo's own `src/syscalls.cyr`) is what produces non-literal numbers at every call site.

## Proposed fix

**Preferred (upstream):** cyrius emits a runtime dispatch for non-literal syscall numbers under `_TARGET_PE` (switch on `rax` → the routed `E*_PE` sequence). Then sakshi needs no change and the portable idiom just works. Tracked in the upstream issue.

**sakshi stopgap (ship without waiting on cyrius) — P1:** add a `#ifdef CYRIUS_TARGET_WIN` branch to the I/O helpers that uses **literal** syscall numbers:
- `src/output.cyr` `_sk_write_stderr` / `_sk_write_file` → `syscall(1, fd, buf, len)` (literal `1`); `_sk_open` → literal `syscall(2, …)` (CreateFileW is routed); close → literal `syscall(3, fd)`.
- `src/clock.cyr` calibration: `clock_gettime` is literal-routed (228); **`nanosleep` (35) is not routed on PE at all** — under `CYRIUS_TARGET_WIN`, skip the nanosleep-based TSC calibration (use a fixed/CPUID-derived frequency or a busy-spin delta) so the default stderr path needs only `write(1)` + `clock_gettime(228)`, both routed.
- UDP target (`socket`/`sendto`, 41/44) is **not** routed on PE — leave `SK_OUT_UDP` unsupported on Windows for now and document it.

This keeps the x86/aarch64 `var`-dispatch paths exactly as-is (guarded out on PE) and gives Windows consumers working stderr + file logging immediately.

## Severity rationale

P1: a real consumer (ai-hwaccel 2.3.9) ships a Windows wheel **now** with logging silently dead; the failure has no diagnostic at the call site; and the trigger is the correctness-motivated v2.2.2 change, so future portability work would keep re-hitting it. Not P0 only because it doesn't crash or corrupt — it loses output.

## Related

- Upstream: `cyrius .../2026-06-09-pe-syscall-variable-number-not-rerouted.md`.
- This repo: `docs/development/issues/2026-04-30-cyrius-lang-blockers.md` (new row added), `docs/development/roadmap.md` (new Windows/PE P1 lane + Windows CI gate).
- Consumer: ai-hwaccel `src/log.cyr`, roadmap 2.3.9.
