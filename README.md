# json-schema-dev

A [REPRO](https://github.com/repros-dev) capability module that bundles two JSON Schema validators and a gallery of minimal, runnable demonstrations of individual JSON Schema constructs. Each demo is one `(schema, instance)` pair validated through **both** validators; the committed `run.txt` golden file records the two verdicts side by side. Divergences in verdicts recorded in the golden files are expected and called out explicitly in the demo documentation cells. Re-run a demo and `git diff` its golden file to confirm that neither validator's behavior has changed since the golden was committed.

## Validators

Both pinned, both driven at the **JSON Schema 2020-12** dialect:

| Language | Library | Command |
| --- | --- | --- |
| Python | [`jsonschema`](https://pypi.org/project/jsonschema/) `4.23.0` (`Draft202012Validator`) | `jsonschema-validate --schema FILE --instance FILE [--ref FILE]...` |
| JavaScript | [`ajv`](https://ajv.js.org/) `8.17.1` (`ajv/dist/2020`) | `ajv-validate --schema FILE --instance FILE [--ref FILE]...` |

Arguments are **named** (`--schema`/`--instance`, or `-s`/`-i`), not positional, so the schema and instance can't be transposed by accident — a swap that would otherwise pass silently, since any JSON object is itself a valid, permissive schema.

Each `--ref FILE` (repeatable) loads an additional schema and registers it under its `$id`, making it available to `$ref` in the main schema — this is how a schema spread across several files is validated. A `--ref` schema must carry a `$id`; nothing is ever fetched from the `$id`'s URI, which serves purely as a name to resolve against (demo 15).

Both wrappers honor the nonstandard `errorMessage` keyword (a portable subset of [`ajv-errors`](https://github.com/ajv-validator/ajv-errors): a plain string covering its subschema, or an object keyed by keyword, either containing `${pointer}` interpolations that JSON-encode an instance value — absolute JSON Pointers resolving from the instance root, and relative ones resolving from the failing value's own location, so `${0}` is the failing value itself): Ajv through the plugin, the Python wrapper by reading the messages directly out of the schema JSON. Failures no message covers keep each library's own message (demo 16).

Each command writes its verdict to stdout — `VALID`, or one `INVALID: <error>` line per validation error — and exits **0** (valid), **1** (invalid), or **2** (error: bad arguments, an unreadable file, malformed JSON, an invalid schema, or an unresolvable `$ref`); diagnostics and `-h`/`--help` text go to stderr/stdout respectively. So the two are directly comparable *and* safe to script. The dialect is forced in the wrapper rather than read from the schema's `$schema`, so an old validator cannot silently fall back to a weaker dialect.

Both commands are exported as artifacts of this module, so they are on `PATH` inside this REPRO **and** inside any REPRO that composes it with `repro.require json-schema-dev …` — the module's capability is the uniform cross-validator CLI, not just the two libraries.

## Demos

The demos are ordered as a curriculum: **no construct appears in a demo before it has been the focus of an earlier one**, so reading the `run.txt` goldens in numeric order is a complete, self-contained course — from what a schema *is* through the composition machinery a real vocabulary schema is built from.

| # | Construct | Shows |
| --- | --- | --- |
| `01-empty-and-boolean-schemas` | `{}`, `true`, `false` | accept-all and reject-all at the schema floor |
| `02-types-and-properties` | `type`, `properties` | the basic vocabulary — and that `properties` neither requires the members it names nor forbids the ones it doesn't |
| `03-empty-vs-nonempty-array` | `minItems: 1` | empty array rejected, one-element array accepted |
| `04-empty-vs-nonempty-object` | `required` | empty object rejected, minimal object accepted — and a null-valued property satisfies `required` |
| `05-null-and-applicability` | `type` lists, `minLength`, `enum` vs `minimum` | keywords are type-scoped and pass silently when inapplicable; widening a type to admit `null` exempts it from the field's own constraints |
| `06-annotations-vs-assertions` | `title`/`description`/`$comment`, `format` vs `pattern` | annotations cannot make an instance invalid, and `format` is one of them by default — enforce with `pattern` |
| `07-value-shapes` | `pattern` | unanchored patterns match substrings; Python's `$` tolerates a trailing newline where JavaScript's does not; a POSIX class is a schema error in one engine and a silently different predicate in the other |
| `08-schemas-in-schema-position` | `additionalProperties` | the slot holds a schema, not a flag — shown by putting a non-boolean one in it |
| `09-annotated-constants` | `oneOf`, `const` vs `enum` | alternation over documented constants — the same predicate as a flat `enum`, with a place for per-value prose; noisier errors are the cost |
| `10-tagged-unions` | `if`/`then`/`else` | a discriminator property selects which constraints apply — and the `if` schema must `require` its own discriminator or the empty object falls into `then` |
| `11-defs-and-refs` | `$defs`, `$ref`, `allOf` | a definition written once, enforced at every reference site; composition by intersection; a typo'd `$ref` fails at compile time in Ajv but only on first use in `jsonschema` |
| `12-identifiers-and-refs` | `$id`, `$anchor`, `$ref` | `$id` is inert until a `$ref` needs a base URI to resolve against — then it decides where the `$ref` goes, including away from the `$def` you meant |
| `13-unevaluated-properties` | `unevaluatedProperties: false` over `allOf` | closure that sees through `allOf`, which `additionalProperties: false` cannot |
| `14-closure-scope` | `$ref`, `$defs`, `unevaluatedProperties` vs `additionalProperties` | how far closure reaches: through `$ref` sideways, but not downward into a nested object |
| `15-multi-file-extension` | `--ref`, `$id`-based `$ref`, `unevaluatedProperties` over both | a base schema validating standalone, plus an overlay in its own file that references it, adds constraints, and closes over the union |
| `16-custom-error-messages` | `errorMessage` (nonstandard) | the standard leaves message text to each validator; an authored message carried in the schema — honored by Ajv via `ajv-errors`, and read directly out of the schema JSON by the Python wrapper — makes both emit the same sentence, with `${0}` quoting the failing value even inside arrays, where an absolute pointer names the wrong item |

Each demo is built as a controlled experiment: exactly one thing varies between the cases it compares, and everything else — including the instances used as backgrounds — is held constant and deliberately unremarkable. A demo that changed two things at once would report verdicts that could not be attributed to either.

Where the two validators genuinely diverge — from library behavior, host-language differences, or latitude in the standard — the divergence is taught in the demo that owns the construct rather than collected in one place. Current examples: demo 06 (Ajv announces the format it ignores on stderr; `jsonschema` ignores it silently), demo 07 (two verdict-level divergences: Python's `$` accepts a trailing newline, and a POSIX character class is rejected as an invalid schema by Ajv while Python silently computes a different predicate from it), and demos 11 and 12 (an unresolvable `$ref` is a compile-time error in Ajv but surfaces lazily, during validation, in `jsonschema`). Demo 16 is the family's inverse: message text is divergent by default — the standard leaves it to each implementation — and the demo shows a schema-authored `errorMessage` closing that divergence deliberately, with both wrappers emitting the same sentence.

Each demo's `run.sh` is a small shell notebook built from two cell helpers defined in [`demo/cells.sh`](demo/cells.sh): `doc`, which prints a prose cell from a heredoc, and `show`, which prints a command and its output. The prose is therefore part of the captured `run.txt`, so a golden file reads as a self-contained lesson — what the construct does and when to reach for it, followed by the evidence — rather than a bare transcript.

## Build and run

The parent image adds Python (via `apt`) and a pinned Node (official prebuilt binary) to the published framework base, so it builds from nothing local; the demo runner (via `shell-notebook`) is composed at build time.

```
make build-parent     # framework base + Python + Node (one-time, slow layer)
make build-image      # compose shell-notebook and this module's validators
make run-demo         # run every demo/NN-*/run.sh, capturing output
```

On the first `make run-demo`, review each demo's output and commit its `run.txt` as the golden file; subsequent runs diff against it.
