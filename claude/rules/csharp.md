---
paths:
  - "**/*.cs"
  - "**/*.csproj"
---
# C# / .NET

- Nullable reference types enabled; warnings are errors. No `!` (null-forgiving) unless the invariant is locally provable.
- Naming: PascalCase public members, `_camelCase` private fields, `Async` suffix on async methods, `I` prefix on interfaces.
- `async`/`await` all the way down — never `.Result` / `.Wait()`. `ConfigureAwait(false)` in library code.
- LINQ when clearer than a loop; watch for multiple enumeration of `IEnumerable`.
- Immutable data as `record` / `init`; mutate only where mutation is the point.
- Constructor injection only — no service locator, no `new`-ing services inside classes.
- Exceptions for exceptional cases — validate and return early instead of exception-driven flow.
- `.editorconfig` + `dotnet format` are the formatting truth.
