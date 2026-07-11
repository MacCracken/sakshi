# Sakshi Development Roadmap

> **Current: v2.4.6** (pin: cyrius 6.4.49). Linux x86_64 / aarch64 / AGNOS / macOS and **Windows PE** all build from one portable source — as of v2.2.10 the hot timestamp path (`_sk_now_ns`) has no `#ifdef CYRIUS_TARGET_WIN` branch — PE shares the calibrated-rdtsc path; the only Windows branch left in `src/clock.cyr` is the one-time TSC-calibration anchor in `_sk_clock_now_ns_raw` (`GetTickCount64`). The `build-windows` (wine) and `build-aarch64` (qemu) CI lanes both run the smoke and assert output reaches stderr. Compile-time log-level elimination (`#define SAKSHI_LEVEL <0..5>`) shipped. v2.3.0 adds the lock-free multi-producer `SK_OUT_ATOMIC_RING` target. v2.2.0 public API is stable.
>
> Shipped history lives in [`CHANGELOG.md`](../../CHANGELOG.md). This file tracks only what's ahead.

---

## Next minor — unscheduled

- **Env-driven log level (`sakshi_init_from_env`).** Read a level name
  (`trace`/`debug`/`info`/`warn`/`error`/`off`) from an env var (e.g.
  `SAKSHI_LOG`) and call `sakshi_set_level`. Folded-from-agnosys context:
  agnosys `logging.cyr` had `log_init_from_env` reading `AGNOSYS_LOG` by
  hand-parsing `/proc/self/environ` — **Linux-eccentric** (that path doesn't
  exist on agnos/macOS/Windows). The sakshi version should go through cyrius's
  cross-target `getenv` instead, so it's portable. **Deferred:** no consumer
  needs it yet (the agnosys→agnodrm fold dropped `logging.cyr`'s only caller,
  `audit`, into kavach). Pick up when a consumer wants env-driven verbosity.

The single key=value emit (`sakshi_log_kv`) **landed** (folded from agnosys
`logging.cyr` `log_msg_kv`) — composes `msg key=value` into one event routed
through every output target. The atomic ring buffer **shipped in v2.3.0** —
`SK_OUT_ATOMIC_RING`, `fetch_add`-reservation MPSC writer, `sakshi_aring_*`
single-reader API, benched at 1.0× the plain ring cost (no contention). See
[`CHANGELOG.md`](../../CHANGELOG.md).

---

## Cleanup / hardening — no firm version

- **[3.0 — parked] `ErrCode` enum members are bare globals — ecosystem-wide name
  collision** — `src/error.cyr:26`. Filed 2026-06-23 (hoosh consumer). Cyrius enum
  members are global constants, so sakshi's domain-agnostic `ERR_OK`/`ERR_TIMEOUT`/…
  collide by name (different values) with other libs' error enums (yukti
  `ERR_TIMEOUT=9`, ai-hwaccel `=3` vs sakshi `=5`) under textual-include
  last-definition-wins; `sakshi_err_new` packs the literal into the low-16 `code`
  field, so a foreign winner silently repacks a wrong value. `ErrCat` (`ERR_CAT_*`)
  is already prefixed and does **not** collide. **3.0.0-era** — any rename is
  breaking across every downstream consumer, so the ecosystem coordination belongs
  at a major. **Direction chosen — Option B:** sakshi, the **base logger**, keeps
  the canonical bare names; downstream libs namespace theirs, so sakshi's own code
  does **not** change. The enforcing lint gate is **filed** as cyrius proposal
  `2026-07-11-error-enum-namespace-lint-gate.md`; the README + vidya ownership docs
  follow once its mechanism settles. Detail:
  [`issues/2026-06-23-err-timeout-enum-collision-namespace.md`](issues/2026-06-23-err-timeout-enum-collision-namespace.md).

The `_sk_open` `O_RDWR → AO_WRONLY` agnos remap (filed 2026-07-08) and the
clock-path items (timespec sizing in v2.2.9; Windows
busy-spin + `GetTickCount64` removal in v2.2.10) are shipped — see
[`CHANGELOG.md`](../../CHANGELOG.md).
