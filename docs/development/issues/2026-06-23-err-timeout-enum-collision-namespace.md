# `ERR_TIMEOUT` enum constant collides ecosystem-wide — namespace `ErrCode` as `SAKSHI_ERR_*`

**Filed:** 2026-06-23 (by a hoosh consumer — hoosh 2.4.7 toolchain bump to cyrius 6.2.37)
**Severity:** Medium — `last-definition-wins` build warning today; latent
value-dependent-logic hazard when sakshi is compiled alongside another lib that
also defines a bare `ERR_TIMEOUT`.
**Component:** `src/error.cyr:26` (`enum ErrCode { … ERR_TIMEOUT = 5; … }`) →
`dist/sakshi.cyr:1116`.
**sakshi's role: FIX OWNER for its `ErrCode` enum.** Part of a coordinated
ecosystem-wide error-enum namespacing effort (see Cross-references).
**Repos:** sakshi `2.4.1` (mirrors filed in sigil, yukti, bote, ai-hwaccel).

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

## Recommended fix

Prefix the **entire `ErrCode` enum** `ERR_* → SAKSHI_ERR_*` (e.g.
`SAKSHI_ERR_OK`, `SAKSHI_ERR_TIMEOUT`) and update `sakshi_err_new` /
`sakshi_err_*` and every `ErrCode` reference under `src/`. Leave `ErrCat`
(`ERR_CAT_*`) as-is. Regenerate `dist/sakshi.cyr`. Breaking change to the
exported error surface → suggest **sakshi 2.5.0**, optionally keeping bare
aliases for one minor.

## Interim (consumer-side)

Consumers tolerate the warning today (last-wins benign for reachable paths). The
upstream rename retires it for all sakshi + yukti/ai-hwaccel consumers.

## Cross-references

- yukti `…2026-06-23-err-enum-collision-namespace.md`.
- ai-hwaccel `…2026-06-23-err-timeout-enum-collision-namespace.md`.
- sigil / bote `…2026-06-23-err-io-enum-collision-namespace.md`.
- Precedent: bote × ai-hwaccel `registry_new` collision (`2026-06-11-registry-new-collision.md`).
