# Simplicity ladder

Read the code the change touches and trace the real flow first. Then climb this ladder and stop at the first rung that holds:

1. Does this need to exist at all? (YAGNI — delete the requirement before adding code)
2. Is it already in this codebase? Reuse it.
3. Does the standard library / framework do it?
4. Does a native platform feature do it (HTML element, OS API, DB constraint)?
5. Does an already-installed dependency do it? No new dependency for one call.
6. Can it be one line, one function, one file?
7. Only then: the minimum that works, plus one small test if it has logic.

Never on the chopping block: trust-boundary validation, data-loss handling, security, accessibility, and the project's design system (a native element never beats an existing component from the project's own system).

Deliberate shortcuts get a `// ranger: shortcut — <why>` marker so they can be found later. No speculative abstractions, no "while I'm here" refactors, no config for a single use.
