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

Each command writes its verdict to stdout — `VALID`, or one `INVALID: <error>` line per validation error — and exits **0** (valid), **1** (invalid), or **2** (error: bad arguments, an unreadable file, a schema or `--ref` file that is not valid JSON, an invalid schema, or an unresolvable `$ref`); diagnostics and `-h`/`--help` text go to stderr/stdout respectively. An *instance* file that reads but does not parse as JSON is a **verdict**, not an error — `INVALID: instance is not valid JSON: …`, exit 1 — because everything about the submitted document is a verdict and everything about the setup is an error; a document failing the JSON grammar itself has failed validation's lowest tier (demo 17). In the same spirit, `--reject-duplicate-members` makes a duplicate object member name anywhere in the instance a verdict (`INVALID: instance contains duplicate member name "…"`, all names sorted, word-for-word identical across the two wrappers): parsers silently keep the last value, so no schema can ever see a duplicate — parse time is the only tier that can check (demo 18). So the two are directly comparable *and* safe to script. The dialect is forced in the wrapper rather than read from the schema's `$schema`, so an old validator cannot silently fall back to a weaker dialect.

Both commands are exported as artifacts of this module, so they are on `PATH` inside this REPRO **and** inside any REPRO that composes it with `repro.require json-schema-dev …` — the module's capability is the uniform cross-validator CLI, not just the two libraries.

## Demos

**What JSON is.** A JSON text is a serialization of exactly one value, and there are six kinds of value: object, array, string, number, `true`/`false`, and `null`. Any of the six can be the entire document — the minimal JSON document is not `{}` but a bare primitive like `5` or `null`. JSON's syntax descends from JavaScript and is (since 2019) literally a syntactic subset of JS expressions, but the converse fails: `undefined`, `NaN`, `Infinity`, unquoted keys, single-quoted strings, trailing commas, and comments are all assignable JavaScript and all rejected by every JSON parser. Numbers are arbitrary-precision decimal in the grammar — implementations impose the precision limits, and `NaN`/`Infinity` are inexpressible. Demo 01 validates maximally unlike instance kinds; demo 17 shows what becomes of a document that fails this grammar.

**What JSON Schema is.** A schema is a predicate over JSON values: handed one instance, it accepts or rejects, and that is all it does. Keywords only ever *remove* instances from the accepted set, so the schema that says nothing — `{}` — accepts everything, and each added keyword narrows; openness is the default, and closing a schema is its own deliberate act (demo 13). Keywords are type-scoped and pass silently on instances of other kinds (demo 05). Every position that takes a schema takes *any* schema — each `properties` entry, array item schema, `$defs` definition, and `allOf` branch is a complete schema in its own right (demo 08) — so large schemas are compositions of small predicates, and reuse and extension are mechanical rather than clever. Annotations describe but can never reject; only assertions reject (demo 06). Everything else in the language is particular keywords playing one of these two roles inside that recursive shape.

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
| `17-non-json-instances` | the exit contract | a document that does not parse as JSON gets a verdict (`INVALID: instance is not valid JSON: …`, exit 1), while a missing file stays an operational error (exit 2) — everything about the instance is a verdict, everything else is an error; the parser detail after the uniform phrase diverges like all message prose |
| `18-duplicate-member-names` | `--reject-duplicate-members` | parsers keep the last value for a repeated member name, so no schema can ever see a duplicate — shown by a `const` on the *last* value passing; the flag makes duplication a parse-time verdict, reported word-for-word identically by both wrappers |

Each demo is built as a controlled experiment: exactly one thing varies between the cases it compares, and everything else — including the instances used as backgrounds — is held constant and deliberately unremarkable. A demo that changed two things at once would report verdicts that could not be attributed to either.

Where the two validators genuinely diverge — from library behavior, host-language differences, or latitude in the standard — the divergence is taught in the demo that owns the construct rather than collected in one place. Current examples: demo 06 (Ajv announces the format it ignores on stderr; `jsonschema` ignores it silently), demo 07 (two verdict-level divergences: Python's `$` accepts a trailing newline, and a POSIX character class is rejected as an invalid schema by Ajv while Python silently computes a different predicate from it), and demos 11 and 12 (an unresolvable `$ref` is a compile-time error in Ajv but surfaces lazily, during validation, in `jsonschema`). Demo 16 is the family's inverse: message text is divergent by default — the standard leaves it to each implementation — and the demo shows a schema-authored `errorMessage` closing that divergence deliberately, with both wrappers emitting the same sentence.

Each demo's `run.sh` is a small shell notebook built from two cell helpers defined in [`demo/cells.sh`](demo/cells.sh): `doc`, which prints a prose cell from a heredoc, and `show`, which prints a command and its output. The prose is therefore part of the captured `run.txt`, so a golden file reads as a self-contained lesson — what the construct does and when to reach for it, followed by the evidence — rather than a bare transcript.

Cells are numbered in their banners (`===== [5] …`), so a golden doubles as the demo's cell index, and `run.sh` accepts a cell selection for interactive experiments: each argument is a cell number or an inclusive range, freely mixed — `bash run.sh 5`, `bash run.sh 1 2 3`, `bash run.sh 2 5-8 12` — while `bash run.sh` alone runs every cell (the form the goldens record). Cells always run in document order whatever the argument order. Selection assumes cells are independent — a demo must not let one cell depend on another's side effects.

## Build and run

The parent image adds Python (via `apt`) and a pinned Node (official prebuilt binary) to the published framework base, so it builds from nothing local; the demo runner (via `shell-notebook`) is composed at build time.

```
make build-parent     # framework base + Python + Node (one-time, slow layer)
make build-image      # compose shell-notebook and this module's validators
make run-demo         # run every demo/NN-*/run.sh, capturing output
```

On the first `make run-demo`, review each demo's output and commit its `run.txt` as the golden file; subsequent runs diff against it.
