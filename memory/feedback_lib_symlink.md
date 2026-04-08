---
name: Stdlib lib/ symlink required for local builds
description: cc2 resolves includes from CWD — sakshi needs lib/ symlinked to the Cyrius stdlib, and distribution files must not live in lib/
type: feedback
---

cc2 resolves `include "lib/..."` relative to CWD. If sakshi has its own `lib/` directory, it shadows the Cyrius stdlib and produces broken binaries (silent include failure, tiny output, segfault).

**Why:** Discovered after multiple segfault debugging rounds. Distribution files in `lib/` shadowed stdlib.

**How to apply:** Never put sakshi files in `lib/`. Distribution files live at project root (`sakshi.cyr`, `sakshi_full.cyr`). `lib/` is a gitignored symlink to the installed stdlib. CI creates it via `ln -sf "$CYRIUS_HOME/lib" ./lib`. Locally, repoint after Cyrius version updates.
