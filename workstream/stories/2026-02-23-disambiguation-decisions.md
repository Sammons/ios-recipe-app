# Story Disambiguation — 2026-02-23

## Decisions locked for this batch

1. Pantry forecasting scope:
   - Apply sequential inventory-depletion forecasting to week/month summary indicators.
   - Keep day-view meal badges as direct “can cook this meal now” checks.

2. Double-tap behavior:
   - Week row/day cell single tap = select date.
   - Double tap = select date and switch to Day segment.

3. Recipe picker quick-create UX:
   - Add an in-context “Add Recipe” shortcut inside `RecipePickerView`.
   - Use a modal recipe form and return to picker on dismiss.

4. Calories storage semantics:
   - Use integer `caloriesPerServing` on `Recipe`.
   - `0` means unknown/not provided.

5. Editable generated list items:
   - Allow editing all shopping rows (manual and auto-generated) from row tap.
   - Editing does not forcibly convert auto-generated rows to manual; regeneration semantics remain generation-controlled.

6. Shopping list ordering:
   - Enforce deterministic ordering by category + ingredient display name + unit in UI.
   - Enforce deterministic insertion order in generator so repeated generations are stable.

7. Aggregation normalization:
   - Keep unit-aware aggregation, but normalize equivalent singular/plural text units (`filet`/`filets`, etc.) before grouping.
   - Keep materially different units separate (`g`, `oz`, `cups`, etc.).
