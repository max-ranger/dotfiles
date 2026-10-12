# Writing good tests

Distilled from obra/superpowers `skills/test-driven-development/writing-good-tests.md` (MIT). The always-on rules are in `~/.claude/rules/testing.md`; this is the checklist the verifier and the author run.

## Gate before writing the test body

Name the production change that would make this test fail.

- Cannot name one → redesign the test around an observable behavior.
- "The source text changed" → run the artifact and assert its effects instead.
- Only an intentional decision would → that is a change detector; test the behavior that depends on the decision.

Confirm the expected value is derived without the code under test. If it reuses the code's logic or helpers, replace it with a literal or a hand-checked fixture.

## Gate before adding a mock or helper

List the real method's side effects; keep the ones the test depends on real and mock the slow or external level below them. Mock responses mirror the complete real structure. A method only tests call lives in test utilities, not production. About to assert on the mock itself? Unmock it or delete the assertion.

## Mutation check, before finishing a test file

Mentally mutate the production code; at least one test should fail for each realistic mutation:

- wrong constant or argument
- wrong branch handler
- missing state change or side effect
- empty or default return
- missing validation for zero, empty, nil, unauthorized or malformed input

A mutation nothing catches marks the behavior as unprotected, or the test as tautological.

## Warning signs

- Setup and assertion share the same object, guaranteeing equality
- The test can fail only through a crash or a missing selector
- The test fails on every intentional change, never on accidental breakage
- Expected values hidden behind loops, builders or helpers
- The test greps source text, or asserts a removed symbol stays removed
- The test exists for coverage and checks no outcome
- An assertion checks a mock test id, or fails if the mock is removed
- A method called only from test files
- Mock setup is more than half the test, or "just to be safe"
