# Trace id is a single i64 — a W3C 128-bit trace-id cannot round-trip

**Status:** RESOLVED in sakshi **2.4.4** — added `sakshi_trace_set_128(hi, lo)` +
`sakshi_trace_id_hi()` / `sakshi_trace_id_lo()` (`span.cyr`). Purely additive:
the i64 `sakshi_trace_set` / `sakshi_trace_id` API is the trace-id's low half
(hi = 0), and a 64-bit set now clears the high half. Span-id (proposal item 2)
was **not** implemented — deferred until a consumer needs W3C `parent-id`.
See CHANGELOG [2.4.4].

**Filed:** 2026-07-03 (by a daimon consumer — daimon 1.3.3 distributed tracing over sakshi)
**Severity:** Low — correlation *within* a sakshi-rooted trace is exact; the gap
is interop with 128-bit distributed traces (W3C Trace Context), where the high
64 bits of an inbound trace-id are dropped.

## What

sakshi's trace correlation holds a single 64-bit id:

```cyrius
var _sk_trace_id: i64 = 0;
fn sakshi_trace_set(id): i64 { _sk_trace_id = id; return 0; }
fn sakshi_trace_id(): i64  { return _sk_trace_id; }
```

A **W3C `traceparent`** trace-id is **128-bit** (`00-<32 hex trace-id>-<16 hex
span-id>-<flags>`). A consumer that adopts an inbound distributed trace can
therefore only keep the **low 64 bits** — daimon 1.3.3 folds the 128-bit
trace-id to its low half when it calls `sakshi_trace_set`. Spans stay correctly
correlated inside the daimon-rooted trace, but the id daimon echoes/carries no
longer matches the caller's full 128-bit trace-id, so an upstream collector that
keys on the full id can't stitch daimon's spans into the caller's trace.

## Impact

- Any consumer bridging sakshi spans into a W3C / OpenTelemetry trace loses the
  high 64 bits of the trace-id.
- There is also no **span-id** concept (W3C `parent-id`), so parent/child links
  across a service boundary can't be expressed — only a flat trace-id + a local
  span stack.

## Proposed fix

1. **128-bit trace id** — store the trace-id as two i64 (hi / lo). Add
   `sakshi_trace_set_128(hi, lo)` + `sakshi_trace_id_hi()` / `sakshi_trace_id_lo()`;
   keep `sakshi_trace_set(id)` / `sakshi_trace_id()` as the low half (hi = 0) for
   back-compat. Emit both halves in the span/event correlation output.
2. **(optional) span id** — an 8-byte per-span id (W3C `parent-id`) pushed with
   each `sakshi_span_enter`, so a consumer can emit a real `traceparent` on
   outbound calls and express parent/child. Lower priority than (1).

Back-compat: the i64 API keeps working (it is the low half); only consumers that
need full 128-bit interop opt into the `_128` surface.

## References

- W3C Trace Context — `traceparent` is `version-<16-byte trace-id>-<8-byte
  parent-id>-flags`.
- Consumer: daimon 1.3.3 (`src/trace.cyr`) — adopts the low 64 bits of an inbound
  `traceparent`; documented as a known limit in its CHANGELOG.
