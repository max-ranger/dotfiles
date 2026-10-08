---
paths:
  - "**/*.vue"
---
# Vue

- Composition API with `<script setup lang="ts">` only.
- `defineProps<T>()` (+ `withDefaults`) and `defineEmits<T>()` — fully typed, no string `$emit`.
- Multi-word PascalCase component names and filenames (`CourseCard.vue`, never `Card.vue`).
- Shared stateful logic in composables (`useX`); components thin and presentational. Anything with logic in the template becomes a `computed`.
- Pinia for cross-cutting state; props down + emits up for parent/child.
- Styles `scoped` (or CSS modules); no global leaks from components.
