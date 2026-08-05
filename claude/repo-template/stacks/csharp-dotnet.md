## C# / .NET

- Nullable reference types enabled; warnings are errors. No `!` (null-forgiving) unless the
  invariant is locally provable.
- Naming: PascalCase public members, `_camelCase` private fields, `Async` suffix on async
  methods, `I` prefix on interfaces.
- `async`/`await` all the way down — never `.Result` / `.Wait()` (deadlocks).
  `ConfigureAwait(false)` in library code.
- LINQ when it's clearer than a loop; watch for multiple enumeration of `IEnumerable`.
- Immutable data as `record` types / `init` setters; mutate only where mutation is the point.
- Dependency injection via constructor — no service-locator pattern, no `new`-ing services
  inside classes.
- Exceptions are for exceptional cases — no exception-driven control flow; validate and
  return early instead.
- `.editorconfig` + `dotnet format` are the formatting truth — don't fight them.
