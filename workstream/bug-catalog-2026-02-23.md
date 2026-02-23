# Bug Catalog — 2026-02-23

Scope: Post-TestFlight behavior regressions and UX gaps reported during manual app usage.

## Intake Bugs

1. Week view pantry readiness can overstate availability across multiple days (example: Tue and Thu both marked `1/1` ready, but pantry only supports one meal total).
2. Double-tapping a day in week/month should switch calendar mode to day view for that date.
3. Recipe picker ("choose recipe") should include a fast shortcut to create a new recipe near search.
4. Recipes need explicit calorie-per-serving support and discoverability in recipe create/edit/detail flows.
5. Magic-wand generated shopping list rows should be user-editable.
6. Re-running magic wand against an existing list can invert row ordering.
7. Magic wand 7-day generation can fail to aggregate repeated ingredients correctly (example: two trout meals at 2 filets each should produce 4 filets, not 2).

## Execution Plan

1. Research current behavior and identify root causes in code/tests.
2. Convert bugs into implementation stories with acceptance criteria.
3. Disambiguate story decisions where behavior is currently underspecified.
4. Implement fixes with regression tests and run stable validation.
