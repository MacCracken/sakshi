# `_sk_clock_now_ns_raw` timespec is byte-undersized — the sibling the v2.2.9 `sleep_ts` fix missed

**Filed:** 2026-06-12
**Severity:** MEDIUM — latent (layout-masked) 8-byte OOB on every raw clock read
**Status:** RESOLVED — shipped in v2.2.11 (tag `2.2.11`). `src/clock.cyr`
`_sk_clock_now_ns_raw` now declares `var ts[16]`, the dist bundle is
regenerated, and the fix is documented under CHANGELOG `[2.2.11] → Fixed`.

> **Resolution note — the pin did NOT stay at 6.1.17.** This issue recommended
> holding the pin at 6.1.17. In the actual fix it moved to **6.2.1** anyway, as
> part of the deliberate ecosystem-wide stdlib pin sweep (documented in
> CHANGELOG `[2.2.11] → Changed`), independent of this byte-buffer resize. The
> resize itself stayed toolchain-agnostic (`[16]`, not the 6.2.1 `i64[2]`
> spelling), exactly as advised. Nothing to reset. Archived during the v2.3.0
> closeout pass after confirming the tree matches the intended end state.

## The bug

`src/clock.cyr` `_sk_clock_now_ns_raw` declares its `clock_gettime` output as
`var ts[2]`. Cyrius `var[N]` is **byte-sized** (rounded to 8), so `[2]` reserves
**8 bytes** — but:
- the kernel writes a 16-byte `struct timespec { i64 tv_sec; i64 tv_nsec; }`, and
- the function reads `tv_nsec` at `load64(&ts + 8)`.

Both the kernel write and the `+8` read run 8 bytes past the buffer into the next
stack local. Works by luck today (the neighbor is unused), but it's layout-fragile.

This is the **exact same class** the maintainer already fixed in **v2.2.9** for the
*other* timespec in this file — `calibrate()`'s `var sleep_ts[2]` → `var
sleep_ts[16]` (see CHANGELOG [2.2.9]). `_sk_clock_now_ns_raw`'s `ts` is the sibling
site that fix missed.

## The fix (match the v2.2.9 precedent — byte-bump, NOT a new spelling)

```
var ts[16];   # timespec = 16 bytes (two i64), same as the v2.2.9 sleep_ts[16] fix
```

- **Pin stays 6.1.17.** This is a plain byte-buffer resize — toolchain-agnostic.
  Do NOT introduce `var ts: i64[2]` (the cyrius 6.2.1 element-typed-array spelling):
  it would force a 6.1.17 → 6.2.1 pin jump for no benefit, and `[16]` matches the
  lib's own established convention.

Verify + cut:
```sh
sh scripts/bundle.sh           # regen dist/sakshi.cyr
cyrius build programs/smoke.cyr build/sakshi-smoke -D SAKSHI_SMOKE
cyrius test && cyrius bench
```

## Surfaced by

The cyrius v6.2.1 address-taken-local-array audit (the daimon byte-vs-slot class)
flagged this site in the vendored `lib/sakshi.cyr` fold; root cause is in
`src/clock.cyr`.

## Working-tree note

If a session already edited `src/clock.cyr` and/or bumped VERSION, diff against this
issue: the correct end state is `var ts[16]`, pin 6.1.17, dist regenerated, and a
`### Fixed` CHANGELOG entry under the in-progress 2.2.11. Reset with `git restore`
if the edit used `i64[2]` or bumped the pin to 6.2.1.
