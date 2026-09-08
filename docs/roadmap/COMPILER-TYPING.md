# Core typing fixes are part of the work

## Binding policy

When valid editor code reveals a compiler typing defect, fix the general rule
in the compiler. Do not weaken the editor's types to route around the defect.
The user's intent is lasting core typing fixes, even when they take longer than
an application workaround. This policy applies to every milestone and handoff.

Do not introduce `Dynamic`, `untyped`, unchecked casts, duplicated monomorphic
APIs, special cases for editor class names, or unnecessary annotations solely
to bypass broken inference. Legitimate dynamic boundaries and useful explicit
public API annotations remain valid; explain their actual semantic purpose.
Do not disable diagnostics or make assignability universally permissive.

## Diagnosis and implementation protocol

1. Reduce the failure to the smallest independent source program. Capture the
   diagnostic, expected type, actual type and failing editor task ID.
2. Establish intended semantics using existing language contracts and tests;
   use the local reference Haxe compiler for supported Haxe-compatible features.
   If code is genuinely invalid, fix the application. Do not broaden the type
   system to accept an application mistake.
3. Identify the responsible layer: parsing, declaration resolution, inference,
   type relations, flow narrowing, typed AST, lowering, runtime representation
   or incremental invalidation. A crash in code generation may originate in
   an unsound typed tree. Fix the responsible abstraction, not just the symptom.
4. Add a failing regression before the fix. Include accepted and rejected nearby
   cases so increased coverage does not accidentally reduce soundness.
5. Implement the smallest general correction. Centralize shared rules and keep
   declaration, call-site, field and assignment checking consistent.
6. Exercise generated execution when representation/conversion is involved.
   Exercise edit/recompile behavior when dependencies or inferred types change.
7. Run focused tests, compiler integration tests and the original editor build
   and behavior check. Remove temporary diagnostic/workaround edits.
8. Record root cause, semantic rule, touched layers and evidence in STATUS.

## Current source map

Paths are relative to `HAXEON_ROOT`; verify before editing.

| Concern | Starting points |
| --- | --- |
| Type representation and compatibility | `src/compiler/types/Type.hx`, `TypeRelations.hx` |
| Expression/declaration typing | `src/compiler/types/Typer.hx`, `DeclarationIndex.hx`, `TypeRegistry.hx` |
| Inferred fields and signatures | `src/compiler/types/FieldInference.hx`, `SignatureInference.hx` |
| Inheritance and abstract conversions | `NominalInheritance.hx`, `AbstractConversionGraph.hx` in the types directory |
| Narrowing, joins and closures | `src/compiler/types/analysis/` |
| Typed output | `src/compiler/types/TypedAst.hx`, downstream IR and HL lowering |
| Runtime representation | `src/compiler/runtime/RuntimeType.hx`, `src/compiler/hl/HlType.hx` |
| Regression integration | `tests/TestMain.hx`, `tests/compiler/`, `tests/runtime/`, `tests/driver/TestDriver.hx` |
| Reference behavior | `tests/differential/run.sh` and its fixtures |

## Regression matrix

Choose relevant dimensions, rather than duplicating this entire matrix for
every bug: inferred/annotated forms; direct/generic use; nested containers;
null/non-null branches and joins; structural/nominal types; callbacks and captured
variables; mutable fields; valid/invalid variance; declaration order and module
boundaries; cold compile and incremental signature/body edits.

For invalid cases assert diagnostic meaning and location where stable. For
valid cases assert behavior, not only compilation. If a fix affects cached
typing, compare incremental results with a fresh compile, including rejection
after a formerly valid dependency changes.

## Completion and blockers

A typing issue is complete only when the reduced case, nearby rejection case,
relevant incremental/runtime cases and original editor usage pass. Register new
tests with the actual runner; an unexecuted test file is not coverage.

An unsupported language feature requiring a larger design becomes a recorded
compiler subtask with prerequisites. Continue independent editor work if possible.
Never leave a workaround marked as a completed permanent solution. Do not fix
unrelated compiler issues discovered incidentally unless they block this plan.
