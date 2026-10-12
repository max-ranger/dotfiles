# Tests worth keeping

The verify gate proves tests ran. These rules decide whether they were worth writing.

- Test behavior through the public interface at a seam; never private methods, internal collaborators or a side channel (a DB query where the interface would do). Code may change entirely; the tests should not.
- Not tautological: the expected value is a literal or a hand-checked fixture, never recomputed the way the code computes it.
- No horizontal slicing: one behavior, one test, one minimal implementation per cycle. Bulk tests written ahead verify imagined behavior.
- Mock only at system boundaries: external APIs, time and randomness, sometimes the database or file system. Never assert on the mock itself.
- Trivial code (constructors, getters, forwarding) earns no test; the first consumer-visible result that depends on it does.
- Before finishing a test file, run the mutation check in the plugin's `references/writing-good-tests.md`: for each realistic mutation at least one test must fail.
