---
name: Sakshi is the foundation layer
description: Sakshi has zero external dependencies because it is the bottom layer that all other Cyrius projects incorporate
type: project
---

Sakshi has no external dependencies — it is the foundational layer of the AGNOS/Cyrius ecosystem. Every other Cyrius project depends on sakshi, so it cannot depend on anything external.

Sakshi lives in its own repo rather than being baked into the Cyrius language repo. This keeps tracing/error handling decoupled from the compiler. Since both are Cyrius-native, sakshi can be incorporated into the language as a dependency later — same language, clean boundary.

**Why:** Separation of concerns. Tracing/errors are cross-cutting but shouldn't live in the compiler. Separate repo keeps it usable by any Cyrius project independently.

**How to apply:** Never suggest adding external dependencies. Never suggest merging this into the language repo — it's intentionally separate. Any functionality sakshi needs must be implemented inline.
