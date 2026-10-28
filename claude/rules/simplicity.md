# Simplicity ladder

Read the code the change touches and trace the real flow first. List every place the change must reach (callers, tests, fixtures, config, exports) and what it could break (data destroyed or exposed, callers that stop working). That is the scope; extra features are not. Then climb this ladder and stop at the first rung that holds:

1. Does this need to exist at all? (YAGNI — delete the requirement before adding code)
2. Is it already in this codebase? Reuse it.
3. Does the standard library / framework do it?
4. Does a native platform feature do it (HTML element, OS API, DB constraint)?
5. Does an already-installed dependency do it? No new dependency for one call.
6. Can it be one line, one function, one file?
7. Only then: the minimum that works, plus one small test if it has logic.

Lazy about the solution, never about the change: finish every part the scope names, including the callers, tests and fixtures the change breaks. A bug fix greps every caller first and fixes the root cause once, in the shared code. Code that is moved or merged keeps its error handling and validation.

Never on the chopping block: trust-boundary validation, data-loss handling, security, accessibility, and the project's design system (a native element never beats an existing component from the project's own system).

Three tests for any module or abstraction: the deletion test (delete it; if complexity vanishes it was a pass-through, if it reappears across N callers it earned its keep), the interface is the test surface (needing to test past the interface means the module is the wrong shape), and one adapter is a hypothetical seam, two adapters are a real one (no seam until something actually varies across it).

Deliberate shortcuts get a `// ranger: shortcut — …` marker that names the limit and when to upgrade; a marker without a trigger rots, and `git grep -n 'ranger: shortcut'` is the debt ledger. No speculative abstractions, no "while I'm here" refactors, no config for a single use.
