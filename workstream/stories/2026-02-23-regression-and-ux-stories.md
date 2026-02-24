# Stories — Regression + UX Batch (2026-02-23)

Epic: Calendar + Shopping List reliability and recipe authoring completeness.

## Story 1: Sequential pantry readiness forecasting in week/month

Problem:
- Week/month pantry readiness currently evaluates each meal/day independently against the full pantry, which can overstate readiness when the same inventory would be consumed by earlier meals.

In scope:
- Add sequential forecast logic for week/month summary indicators so ingredient depletion is modeled across planned meals in date order.
- Keep day-view per-meal indicators intact unless explicitly changed by this story's implementation requirements.

Acceptance criteria:
- If two planned meals require the same scarce ingredient and pantry only covers one meal, week/month indicators do not mark both meals/day summaries as fully ready.
- Existing pantry coverage tests still pass; new regression test covers sequential depletion behavior.

## Story 2: Calendar double-tap drill-in

Problem:
- Week/month requires segmented control interaction to reach day mode; there is no fast gesture drill-in from a selected date.

In scope:
- Add double-tap interaction on week-row/day-cell that switches mode to day view and focuses the tapped date.

Acceptance criteria:
- Double-tapping a date in week or month view switches to day mode and opens that exact date.
- Single tap behavior (selection without mode change) still works.

## Story 3: Recipe picker quick-create affordance

Problem:
- Recipe picker has search but no quick path to create a missing recipe while planning a meal.

In scope:
- Add a visible create shortcut in the chooser context near search/list controls.
- Allow immediate return to picking flow once recipe is created.

Acceptance criteria:
- From “Choose Recipe”, user can open recipe create flow without leaving calendar context.
- Newly created recipe appears in the picker list.

## Story 4: Calorie-per-serving recipe support

Problem:
- Recipe model and forms do not currently expose calorie-per-serving storage/entry/display.

In scope:
- Add persistent calorie-per-serving field to recipe model.
- Support edit/create in recipe form(s) and display in recipe details.

Acceptance criteria:
- User can create/edit calories per serving.
- Value persists and is shown in recipe details.

## Story 5: Editable magic-wand list rows + deterministic regeneration

Problem:
- Auto-generated shopping rows are not editable.
- Regenerating list can reorder/invert rows unpredictably.
- Some repeated ingredient cases under-aggregate expected quantities.

In scope:
- Add edit interaction for shopping rows (including auto-generated rows).
- Make generation output order deterministic.
- Improve aggregation key normalization for common singular/plural unit variants (for example, `filet`/`filets`) while preserving deliberate unit separation (`g` vs `cups`).

Acceptance criteria:
- User can edit quantity/unit/ingredient for generated rows.
- Re-running generation keeps stable ordering semantics (no random inversion).
- Repeated meal ingredients with equivalent units aggregate correctly.
