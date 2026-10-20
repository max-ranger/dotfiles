---
paths:
  - "**/*.vue"
---
# Vue

- Composition API with `<script setup lang="ts">` only.
- `defineProps<T>()` (+ `withDefaults`) and `defineEmits<T>()` — fully typed, no string `$emit`.
- Read props as `props.x`, defaults via `withDefaults`; no reactive props destructure (`const { x = 1 } = defineProps<T>()`), even on Vue 3.5+. This beats the `vue-best-practices` skill.
- Multi-word PascalCase component names and filenames (`CourseCard.vue`, never `Card.vue`).
- Shared stateful logic in composables (`useX`); components thin and presentational. Anything with logic in the template becomes a `computed`.
- Pinia for cross-cutting state; props down + emits up for parent/child.
- Styles `scoped` (or CSS modules); no global leaks from components.
