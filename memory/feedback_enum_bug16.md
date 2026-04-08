---
name: Cyrius bug #16 — enums cause segfault in full profile
description: sakshi_full.cyr segfaults at span_enter due to enum-heavy includes shifting data section layout. Slim profile works because enums were replaced with var constants.
type: project
---

sakshi_full.cyr uses 6 enums (~30 values) and segfaults at runtime when combined with stdlib includes. The slim profile (sakshi.cyr) works because enums were converted to `var` constants as a workaround.

**Why:** Cyrius compiler bug #16 — enum-heavy includes shift global data section addresses, corrupting runtime memory layout. Confirmed still present in Cyrius 2.1.3.

**How to apply:** Leave sakshi_full.cyr in its current broken (enum) state so the Cyrius compiler team can reproduce and fix bug #16. Do not apply the var workaround to the full profile until the compiler team has reviewed.
