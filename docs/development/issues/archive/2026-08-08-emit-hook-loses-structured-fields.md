# `sakshi_log_kv` flattens fields into the message before `_sk_emit`, so an emit hook cannot recover them

**Status:** RESOLVED in sakshi **2.4.9**. For `SK_OUT_HOOK`, `sakshi_log_kv`
now passes the message **unflattened** plus a count-prefixed fields block in the
hook's sixth argument (`level` discriminates: 0-5 log, 10-11 span). No public
symbols were added, so it stayed a patch. The silent 256-byte truncation is also
fixed — the return is now the number of bytes that did not fit. Verified through
the generated `dist/sakshi.cyr` with this filing's own agnosai example
(`hoosh_url` arrives as its own field). Measured: the hook path went **36 ns →
25 ns (−31%)**, the composing path 74 → 75 ns. See CHANGELOG [2.4.9].

**Not fixed, deferred to 2.5.0:** the one-pair-per-call limit and the fixed
256-byte scratch. Both need new public API (`sakshi_log_fields` + accessors),
which makes it a minor — tracked in `roadmap.md` under *Multi-field logging*.
Suggested direction **A** was taken in substance, via a fields *pointer* rather
than a wider arity: `fncall` tops out at 8 arguments and a key/value pair needs
four slots, so the block also buys N fields for free.

**Filed:** 2026-08-08 (by an agnosai consumer — agnosai v2.0.0, cyrius 6.5.14, sakshi as vendored in `lib/sakshi.cyr`)
**Severity:** Medium — no crash, no data loss on the text path. It blocks
**structured** output for every consumer that installs an emit hook, which is
the mechanism sakshi documents for exactly that purpose.
**Component:** `src/log.cyr` — `sakshi_log_kv` (`lib/sakshi.cyr:1378` in the
vendored bundle), and the `_sk_emit` hook dispatch it calls
(`lib/sakshi.cyr:1397`).
**sakshi's role:** likely the fix owner — the flattening happens inside sakshi
and no consumer can undo it.
**Repos:** agnosai 2.0.0 (`src/telemetry/mod.cyr`).

## Summary

`sakshi_set_emit_hook` is documented as the way for "downstream consumers (OTel,
custom aggregators, in-memory sinks) to receive structured events without sakshi
knowing their format". That works — agnosai now renders sakshi events as JSON
through it and needs nothing else from sakshi to do so.

But **`sakshi_log_kv` renders its key and value into the message text before the
hook is reached**, so the one API that carries structure is the one whose
structure is lost:

```cyr
# lib/sakshi.cyr:1378 — abridged
fn sakshi_log_kv(level, msg, msg_len, key, key_len, val, val_len): i64 {
    if (level > _sk_log_level) { return 0; }
    var buf[256];
    # ... copies msg, then ' ', then key, then '=', then val into buf ...
    _sk_emit(level, 0, &buf, pos);      # <- the hook sees ONE flat string
    return 0;
}
```

The hook signature is `fn(ts, level, category, msg, msg_len, elapsed_ns)`. There
is no field channel, and by the time it is called the fields are already text.

## Impact, concretely

agnosai's parity oracle is a Rust binary whose `tracing_subscriber::fmt().json()`
emits one JSON object per event with each field as its own member:

```json
{"timestamp":"…","level":"INFO","fields":{"message":"LLM client configured (lazy — init on first use)","hoosh_url":"http://127.0.0.1:8088"},"target":"agnosai"}
```

Through the hook, the best obtainable today is:

```json
{"timestamp":"…","level":"INFO","fields":{"message":"LLM client configured (lazy — init on first use) hoosh_url=http://127.0.0.1:8088"},"target":"agnosai"}
```

That is real output from `./build/agnosai`, not a mock-up. A log shipper can no
longer index or filter on `hoosh_url`; it has to re-parse a `key=value` tail out
of free text, which is ambiguous the moment a message legitimately contains
`=` or a space.

## Two smaller problems in the same function

1. **`var buf[256]` truncates silently.** A message plus its `key=value` longer
   than 256 bytes is cut with no marker and no return code. agnosai has lines
   near this bound already (a 50-byte message plus a URL value).
2. **Exactly one pair per call.** `tracing`'s macros take arbitrary fields; a
   consumer wanting two must either call twice (two log lines) or build the
   text itself, at which point `sakshi_log_kv` adds nothing over `sakshi_info`.

## What agnosai did meanwhile

Nothing is blocked. `src/telemetry/mod.cyr` installs a hook, formats the
oracle's JSON — timestamp, level, `fields.message`, target — and states the
field gap at the call site rather than working around it. **No change is needed
for agnosai to ship**; this is filed because the gap is upstream's to close and
because the next consumer will hit it identically.

## Suggested directions (sakshi's call — not a demand)

- **A. Extend the hook to carry the pairs.** A second hook slot,
  `fn(ts, level, category, msg, msg_len, elapsed_ns, keys, vals, n)`, or a
  variant registered by `sakshi_set_emit_hook_kv`. Keeps the existing 6-arg
  hook working unchanged.
- **B. Pass the pair through the existing hook unflattened** by adding a
  `sakshi_log_kv` path that calls the hook with `key`/`val` in place of
  `category`/`elapsed_ns` when the target is `SK_OUT_HOOK`. Cheaper, but
  overloads two arguments and would be surprising.
- **C. Do nothing, and document it.** If the flattened form is the intended
  contract, saying so in `sakshi_set_emit_hook`'s doc comment would have saved
  this investigation — the current wording ("without sakshi knowing their
  format") reads as though structure survives.

Whichever direction, the 256-byte truncation is worth a separate look: it is
silent today whatever the output target.

## Reproduction

```cyr
fn my_hook(ts, level, category, msg, msg_len, elapsed_ns): i64 {
    # msg is "hello k=v" — one string. There is no way back to ("hello", "k", "v").
    syscall(1, 1, msg, msg_len);
    return 0;
}

fn main(): i64 {
    sakshi_set_emit_hook(&my_hook);
    sakshi_log_kv(SK_INFO, "hello", 5, "k", 1, "v", 1);
    return 0;
}
```
