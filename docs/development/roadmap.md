# Sakshi Development Roadmap

> **Current: v2.4.9** (pin: cyrius 6.5.0 — ⚠ the installed toolchain is 6.5.14, so the pin and `lib/` snapshot are both stale; a bump is owed and is deliberately NOT bundled with the 2.4.9 fix). Linux x86_64 / aarch64 / AGNOS / macOS and **Windows PE** all build from one portable source — as of v2.2.10 the hot timestamp path (`_sk_now_ns`) has no `#ifdef CYRIUS_TARGET_WIN` branch — PE shares the calibrated-rdtsc path; the only Windows branch left in `src/clock.cyr` is the one-time TSC-calibration anchor in `_sk_clock_now_ns_raw` (`GetTickCount64`). The `build-windows` (wine) and `build-aarch64` (qemu) CI lanes both run the smoke and assert output reaches stderr. Compile-time log-level elimination (`#define SAKSHI_LEVEL <0..5>`) shipped. v2.3.0 adds the lock-free multi-producer `SK_OUT_ATOMIC_RING` target. v2.2.0 public API is stable.
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
the two should land together as one `2.5.0`.

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

- **Error-enum namespace ownership — decided (Option B).** sakshi, the base
  logger, keeps the canonical bare `ERR_*`; downstream libs prefix theirs,
  enforced by a cyrius lint gate (proposal filed 2026-07-11). **sakshi's own
  surface does not change** — this is a watch item pending the cyrius gate + the
  leaf-lib member renames, plus the README/vidya ownership docs once the gate's
  mechanism settles. Detail:
  [`issues/2026-06-23-err-timeout-enum-collision-namespace.md`](issues/2026-06-23-err-timeout-enum-collision-namespace.md).
