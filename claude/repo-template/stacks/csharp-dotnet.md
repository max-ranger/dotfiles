## C# / .NET

- Nullable reference types enabled; warnings are errors. No `!` (null-forgiving) unless the
  invariant is locally provable.
- `async`/`await` all the way down — never `.Result` / `.Wait()` (deadlocks).
  `ConfigureAwait(false)` in library code.
- Immutable data as `record` types / `init` setters; mutate only where mutation is the point.
- Dependency injection via constructor — no service-locator pattern, no `new`-ing services
  inside classes.
- Exceptions are for exceptional cases — no exception-driven control flow; validate and
  return early instead.
- `.editorconfig` + `dotnet format` are the formatting truth — don't fight them.
