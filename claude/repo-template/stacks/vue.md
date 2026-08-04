## Vue

- Composition API with `<script setup lang="ts">` only — no Options API in new code.
- Props via `defineProps<T>()` (+ `withDefaults`), events via `defineEmits<T>()` — fully
  typed, no untyped `$emit` strings.
- Multi-word PascalCase component names/filenames (`CourseCard.vue`, never `Card.vue`).
- Shared stateful logic goes into composables (`useX`); components stay thin and
  presentational. Template expressions stay trivial — anything with logic becomes a
  `computed`.
- State: Pinia for cross-cutting/global state; props down + emits up for parent-child —
  don't reach for the store when a prop does the job.
- Styles `scoped` (or CSS modules); no global style leaks from components.
