# Sakshi Development Roadmap

> **Current: v2.5.3** (pin: cyrius 6.6.6 — current). ⚠ Until 2.4.10 this repo was pinned to 6.5.0 with a developer `lib/` symlink into **6.4.49**, so it was tested and benchmarked against a language two minors behind the one it is folded into. For a stdlib repo that makes the results describe the wrong compiler; bump the pin as part of any change here, never as a follow-up. Linux x86_64 / aarch64 / AGNOS / macOS and **Windows PE** all build from one portable source — as of v2.2.10 the hot timestamp path (`_sk_now_ns`) has no `#ifdef CYRIUS_TARGET_WIN` branch — PE shares the calibrated-rdtsc path; the only Windows branch left in `src/clock.cyr` is the one-time TSC-calibration anchor in `_sk_clock_now_ns_raw` (`GetTickCount64`). The `build-windows` (wine) and `build-aarch64` (qemu) CI lanes both run the smoke and assert output reaches stderr. Compile-time log-level elimination (`#define SAKSHI_LEVEL <0..5>`) shipped. v2.3.0 adds the lock-free multi-producer `SK_OUT_ATOMIC_RING` target. v2.2.0 public API is stable.
>
> Shipped history lives in [`CHANGELOG.md`](../../CHANGELOG.md). This file tracks only what's ahead.

---

## Minor arcs — ahead

Feature arcs, **each a self-contained minor (`x.Y.0`), not a bundle.** Per-module
levels is the recommended next; the rest sequence by consumer pull.

### Per-module log levels — next up

Filtering today is a single global `_sk_log_level` (`trace.cyr:55`, checked in
`_sk_log` at `:70`). Add a per-module override: `sakshi_set_module_level(mod,
level)` backed by a small `_sk_module_level[]` table, and a module-aware log path
that honors the override and falls back to the global. The consumer supplies
`mod` as its own small int constant (e.g. `#define MOD_NET 3`) — **explicit ids,
no `__FILE__`/`#module`.** That is the design the retired blockers doc rejected
("a consumer-threaded `mod_id` … an API change we don't want") while waiting on an
upstream feature that may never ship; reversed here — sakshi is the logger, so it
provides the knob. Composes with the compile-time `SAKSHI_LEVEL` elimination.

### Error + log composition — `sakshi_log_err`

`error.cyr` (packed i64 errors) and `trace.cyr` (leveled logging) don't meet: no
single call logs a message *with* its decoded error. Add `sakshi_log_err(level,
msg, len, err)` that emits the message plus the unpacked code / category / context
(reusing the `sakshi_log_kv` field path). Additive; the two halves of sakshi's
remit finally compose.

### Multi-field logging — `sakshi_log_fields`

2.4.9 gave the emit hook a **fields block** (count-prefixed
`{key, key_len, val, val_len}` records) so a subscriber can recover structured
fields instead of a flattened string. `sakshi_log_kv` builds a one-record block;
the wire shape already carries N. What is missing is a public way to *pass* N:
a `sakshi_log_fields(level, msg, msg_len, fields)` entry, plus accessor fns so
consumers stop hand-parsing offsets with `load64`.

Deliberately deferred out of 2.4.9: new public symbols make it a **minor**, and
a minor needs the closeout pass. `sakshi_log_err` above wants the same path, so
the two should land together as one minor — **now `2.6.0`**. The `2.5.0` slot was
taken by the P(-1) hardening sweep (see CHANGELOG and
[`audit/2026-09-07-audit.md`](../audit/2026-09-07-audit.md)), which is what
P(-1) is for: harden the scaffold *before* the next feature arc, not after.

⚠ Also owed from the same report: `sakshi_log_kv` takes **exactly one pair**,
and its 256-byte scratch is fixed. 2.4.9 made the truncation *reported* rather
than silent; it did not make it go away.

### Rate-limit / sampling — gated on a consumer driver

Drop-repeated (suppress runs of identical events) and/or 1-in-K sampling for
high-volume trace paths. A real logger capability, but **no consumer needs it
yet** — scheduled only when one does, not built on spec.

### Env-driven log level — `sakshi_init_from_env` (deferred)

Read a level name (`trace`/`debug`/…/`off`) from an env var (`SAKSHI_LOG`) via
cyrius's cross-target `getenv` — not the Linux-only `/proc/self/environ` the
agnosys `log_init_from_env` original hand-parsed — and call `sakshi_set_level`.
**Deferred:** no consumer needs it (the agnosys→agnodrm fold dropped its only
caller, `audit`, into kavach).

---

## 3.0 — ecosystem coordination (no sakshi code change)

- **Error-enum namespace ownership: decided (Option B), and closed for sakshi in
  2.5.3.** sakshi, the base logger, keeps the canonical bare `ERR_*`, and downstream
  libs prefix theirs. The cyrlint gate shipped in cyrius 6.4.51
  (`lint_error_enum_namespace`, note-level for now), and the README now declares the
  ownership. **sakshi's own surface does not change.** Two things are left to watch,
  and neither is sakshi's work:
  1. the leaf-lib member renames (yukti, ai-hwaccel, sigil, bote);
  2. the cyrius fix for the gate's owner check, which today notes sakshi's own
     `src/error.cyr` when it is linted by relative path. That fix must land
     **before** the note → warn flip, or this repo's lint gate fails on its own
     enums
     (`cyrius/docs/development/issues/2026-09-23-sakshi-err-enum-lint-owner-matched-by-path-spelling.md`).

  Detail:
  [`issues/archive/2026-06-23-err-timeout-enum-collision-namespace.md`](issues/archive/2026-06-23-err-timeout-enum-collision-namespace.md).

## Patch follow-ups (from the 2.5.3 / cyrius 6.6.6 bump)

- **Restore `CYRIUS_DCE=1` on the `build-windows` CI lane.** It was dropped in
  2.4.13 because DCE-on PEs faulted at address 0 before `main`, and the lane's
  comment says to restore it "once that lands". It landed in cyrius **6.6.1**, so
  the comment has been stale since the 6.6.2 pin. On 6.6.6 a DCE-on PE NOPs 242
  unreachable fns and runs clean under wine. The image size is unchanged at
  164,864 B because DCE no longer compacts on PE, so the only gain is that the lane
  tests the same configuration as the others. Needs one green CI run before the
  comment is rewritten.
- **Cross-process timestamps are not comparable.** `_sk_now_ns` returns raw TSC
  ticks × this process's calibrated scale, with no anchor to the reference clock.
  Each process's calibration error is therefore multiplied by the whole uptime.
  Two back-to-back runs appending to one log measured −213 ms apart on Linux and
  **−445 s** under wine, where PE calibrates against the ms-granular
  `GetTickCount64`. The 6.6.6 append fix is what makes this visible on Windows:
  sessions now accumulate side by side in one file. The fix is to anchor at
  calibration, `ns0 + (tsc − tsc0) × scale`, with bench numbers for `timestamp`
  and `clock_now_ticks`. On PE, also calibrate against the QueryPerformanceCounter
  reroutes that cyrius 6.6.5 added (`0xF038`/`0xF039`, wrapped as
  `sys_qpc`/`sys_qpf`/`sys_qpc_ns` in `lib/syscalls_windows.cyr`). The comment at
  `src/clock.cyr:138`, which calls the 15 ms `GetTickCount64` the only Windows
  reference, is stale.
- **UDP output on macOS may now be possible.** `sakshi_output_udp` refuses macOS
  because "the Mach-O ESYSXLAT table … has NO entry for `sendto`"
  (`src/output.cyr:447`). cyrius 6.6.5 (`a7477256`) added Mach-O routes for
  `sendto` (44). Lifting the refusal needs a run on a real Mac, since there is no
  macOS CI lane. Until then the refusal stays; it is safe, only no longer
  necessary.
- **Confirm the Windows append fix on real hardware.** 2.5.3 verified it under
  wine: a DCE-off PE built by 6.6.2 left 1 line after two sessions, and one built
  by 6.6.6 left 2. cyrius pins the flag decoding on real Windows through
  `tests/tcyr/crossos/open_flag_translation.tcyr`. To close this, run the same
  two-session probe once on a real Windows host.
