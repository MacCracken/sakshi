# `ERR_TIMEOUT` enum constant collides ecosystem-wide — namespace `ErrCode` as `SAKSHI_ERR_*`

**Filed:** 2026-06-23 (by a hoosh consumer — hoosh 2.4.7 toolchain bump to cyrius 6.2.37)
**Severity:** Medium — `last-definition-wins` build warning today; latent
value-dependent-logic hazard when sakshi is compiled alongside another lib that
also defines a bare `ERR_TIMEOUT`.
**Component:** `src/error.cyr:26` (`enum ErrCode { … ERR_TIMEOUT = 5; … }`) →
`dist/sakshi.cyr:1116`.
**sakshi's role:** **NOT the fix owner** (Option B chosen, 2026-07-11). sakshi
keeps its canonical bare `ErrCode` set; the fix lands downstream (leaf libs
prefix their error enums), enforced by a cyrius lint gate. Part of a coordinated
ecosystem-wide error-enum namespacing effort (see Cross-references).
**Repos:** sakshi `2.4.1` (mirrors filed in sigil, yukti, bote, ai-hwaccel).
**Status (2026-07-11):** **Direction chosen — Option B.** sakshi, as the *base
logger*, **keeps** the canonical bare `ERR_*`; downstream libs namespace theirs.
**sakshi's own error surface needs no change.** Enforcement filed as cyrius
proposal [`2026-07-11-error-enum-namespace-lint-gate.md`](https://github.com/MacCracken/cyrius/blob/main/docs/development/proposals/2026-07-11-error-enum-namespace-lint-gate.md)
— a cyrlint gate that keeps bare `ERR_*` sakshi-only. **3.0.0-era** for the
ecosystem coordination (leaf-lib member renames once the gate lands), not for
sakshi code (which is unchanged).

## Summary

Cyrius enum members are **global constants** — `ErrCode` does *not* namespace
them. sakshi's domain-agnostic `ErrCode` members (`ERR_OK`, `ERR_TIMEOUT`,
`ERR_NOT_FOUND`, …) are bare globals and collide by name (different values)
across the ecosystem:

| Library | Enum | `ERR_TIMEOUT` | Source |
|---|---|---|---|
| **sakshi 2.4.1** | `ErrCode` | **5** | `src/error.cyr:26` → `dist/sakshi.cyr:1116` |
| yukti 2.2.6 | `YuktiErrorKind` | 9 | `src/error.cyr:20` |
| ai-hwaccel 2.3.12 | `DetectionError` | 3 | `src/error.cyr:9` |
| (sandhi already prefixes `SANDHI_ERR_TIMEOUT = 4`) | | | |

Note sakshi's *other* enum, `ErrCat`, is already prefixed (`ERR_CAT_*`) and does
**not** collide — only the `ErrCode` members are bare. Cyrius include semantics
are textual paste + **last-definition-wins (with a warning)**: a consumer pairing
sakshi with yukti/ai-hwaccel gets one global `ERR_TIMEOUT`, whichever is last.

## Why this is more than a warning

After last-wins the binary has a single value per name, so intra-module checks
stay consistent. The hazard is **value-dependent logic** — sakshi packs the code
into its `[63:32 ctx][31:16 cat][15:0 code]` i64 (`sakshi_err_new`), so the
low-16 `code` field depends on the literal. If another lib's `ERR_TIMEOUT = 3`
wins, sakshi packs `3` where it documented `5`; any decoder keyed to sakshi's
table mis-classifies.

## The precedent already exists in-tree

`TLS_ERR_IO`, `PATRA_ERR_IO`, `SANDHI_ERR_TIMEOUT`, and sakshi's own `ERR_CAT_*`
all show the namespacing convention. The bare `ErrCode` members should match it.

## Resolution — Option B chosen (2026-07-11); ecosystem coordination at 3.0.0

**Option B is the chosen direction:** sakshi keeps the canonical bare names; the
leaf libs prefix theirs, enforced by a cyrius lint gate (filed 2026-07-11).
sakshi's own code does not change — the ecosystem member-renames land in the
3.0.0 window. Option A is retained below only for the record.

**Option A — sakshi namespaces (original proposal; NOT taken).** Prefix sakshi's entire
`ErrCode` enum `ERR_* → SAKSHI_ERR_*` (e.g. `SAKSHI_ERR_OK`,
`SAKSHI_ERR_TIMEOUT`), update `sakshi_err_new` / `sakshi_err_*` and every
`ErrCode` reference under `src/`, leave `ErrCat` (`ERR_CAT_*`) as-is, regenerate
`dist/sakshi.cyr`. Optionally keep bare aliases for one release.

**Option B — sakshi keeps the bare names; downstream namespaces (CHOSEN).**
sakshi is the **base logger** — the foundation include every AGNOS Cyrius project
pulls in. Its domain-agnostic `ERR_OK`/`ERR_TIMEOUT`/… are arguably the
*canonical* error set, so the bare names belong to it and the sibling libs (yukti
`YuktiErrorKind`, ai-hwaccel `DetectionError`, …) namespace **theirs** instead.
This flips the fix owner off sakshi and onto the colliding consumers — sakshi's
own error-code surface then needs no change (the collision is retired
downstream).

Option B is a **convention, so it needs enforcement** — an unenforced "please
prefix" is precisely what let this collision happen. Deliverables under B:

- **A lint/CI gate** that fails any *non-sakshi* library defining a bare `ERR_*`
  (or redefining sakshi's), so a colliding enum is rejected at review instead of
  emitting a tolerated last-wins warning — a `cyrlint` rule, or a
  first-party-standards CI check across the ecosystem. **FILED** as cyrius
  proposal `2026-07-11-error-enum-namespace-lint-gate.md` (design space: a
  positive `#lint-owns-prefix ERR_` ownership pragma vs config vs universal
  prefix; plus optional compiler-side elevation of the existing `CHKDUPVAL`
  collision warning).
- **Ownership documented where authors look:** sakshi's **README** (`## Error
  Format` — declare that sakshi owns the canonical unprefixed `ERR_*` set, and
  every other AGNOS Cyrius lib must prefix its error enum) and the **vidya**
  `content/tracing/` topic (the ecosystem knowledge base — a *separate repo*, so
  that edit lands there, not in sakshi).

Chosen: **Option B.** The lint gate is **filed** (cyrius proposal 2026-07-11); the
README (`## Error Format`) + vidya (`content/tracing/`) ownership docs are the
remaining B deliverables — written once the gate's exact mechanism is settled at
cyrius review, so we don't document a mechanism that then changes. sakshi's own
code stays unchanged; the ecosystem member-renames land in the **3.0.0** window.

## Interim (consumer-side)

Consumers tolerate the warning today (last-wins benign for reachable paths). The
upstream rename retires it for all sakshi + yukti/ai-hwaccel consumers.

## Cross-references

- **Enforcement (cyrius):** [`docs/development/proposals/2026-07-11-error-enum-namespace-lint-gate.md`](https://github.com/MacCracken/cyrius/blob/main/docs/development/proposals/2026-07-11-error-enum-namespace-lint-gate.md) — the lint gate that keeps bare `ERR_*` sakshi-only.
- yukti `…2026-06-23-err-enum-collision-namespace.md`.
- ai-hwaccel `…2026-06-23-err-timeout-enum-collision-namespace.md`.
- sigil / bote `…2026-06-23-err-io-enum-collision-namespace.md`.
- Precedent: bote × ai-hwaccel `registry_new` collision (`2026-06-11-registry-new-collision.md`).
