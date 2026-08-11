# json-schema-dev

A [REPRO](https://github.com/repros-dev) capability module that bundles two JSON Schema validators and a gallery of minimal, runnable demonstrations of individual JSON Schema constructs. Each demo is one `(schema, instance)` pair validated through **both** validators; the committed `run.txt` golden file records — and asserts — that the two agree on the verdict. Re-run a demo and `git diff` its golden file to confirm.

## Validators

Both pinned, both driven at the **JSON Schema 2020-12** dialect:

| Language | Library | Command |
| --- | --- | --- |
| Python | [`jsonschema`](https://pypi.org/project/jsonschema/) `4.23.0` (`Draft202012Validator`) | `jsonschema-validate --schema FILE --instance FILE` |
| JavaScript | [`ajv`](https://ajv.js.org/) `8.17.1` (`ajv/dist/2020`) | `ajv-validate --schema FILE --instance FILE` |

Arguments are **named** (`--schema`/`--instance`, or `-s`/`-i`), not positional, so the schema and instance can't be transposed by accident — a swap that would otherwise pass silently, since any JSON object is itself a valid, permissive schema.

Each command writes its verdict to stdout — `VALID`, or one `INVALID: <error>` line per validation error — and exits **0** (valid), **1** (invalid), or **2** (error: bad arguments, an unreadable file, malformed JSON, an invalid schema, or an unresolvable `$ref`); diagnostics and `-h`/`--help` text go to stderr/stdout respectively. So the two are directly comparable *and* safe to script. The dialect is forced in the wrapper rather than read from the schema's `$schema`, so an old validator cannot silently fall back to a weaker dialect.

Both commands are exported as artifacts of this module, so they are on `PATH` inside this REPRO **and** inside any REPRO that composes it with `repro.require json-schema-dev …` — the module's capability is the uniform cross-validator CLI, not just the two libraries.

## Demos

| # | Construct | Shows |
| --- | --- | --- |
| `01-unevaluated-properties` | `unevaluatedProperties: false` over `allOf` | closure that sees through `allOf`, which `additionalProperties: false` cannot |
| `02-empty-and-boolean-schemas` | `{}`, `true`, `false` | accept-all and reject-all at the schema floor |
| `03-empty-vs-nonempty-array` | `minItems: 1` | empty array rejected, one-element array accepted |
| `04-empty-vs-nonempty-object` | `required` | empty object rejected, minimal object accepted — and a null-valued property satisfies `required` |
| `05-closure-scope` | `$ref`, `$defs`, `unevaluatedProperties` vs `additionalProperties` | how far closure reaches: through `$ref` sideways, but not downward into a nested object |
| `06-schemas-in-schema-position` | `additionalProperties` | the slot holds a schema, not a flag — shown by putting a non-boolean one in it |
| `07-null-and-applicability` | `type` lists, `minLength`, `enum` vs `minimum` | keywords are type-scoped and pass silently when inapplicable; widening a type to admit `null` exempts it from the field's own constraints |
| `08-identifiers-and-refs` | `$id`, `$anchor`, `$ref` | `$id` is inert until a `$ref` needs a base URI to resolve against — then it decides where the `$ref` goes, including away from the `$def` you meant |
| `09-annotations-vs-assertions` | `title`/`description`/`$comment`, `format` vs `pattern` | annotations cannot make an instance invalid, and `format` is one of them by default — enforce with `pattern` |

Each demo is built as a controlled experiment: exactly one thing varies between the cases it compares, and everything else — including the instances used as backgrounds — is held constant and deliberately unremarkable. A demo that changed two things at once would report verdicts that could not be attributed to either.

Each demo's `run.sh` is a small shell notebook built from two cell helpers defined in [`demo/cells.sh`](demo/cells.sh): `doc`, which prints a prose cell from a heredoc, and `show`, which prints a command and its output. The prose is therefore part of the captured `run.txt`, so a golden file reads as a self-contained lesson — what the construct does and when to reach for it, followed by the evidence — rather than a bare transcript.

## Build and run

The parent image adds Python (via `apt`) and a pinned Node (official prebuilt binary) to the published framework base, so it builds from nothing local; the demo runner (via `shell-notebook`) is composed at build time.

```
make build-parent     # framework base + Python + Node (one-time, slow layer)
make build-image      # compose shell-notebook and this module's validators
make run-demo         # run every demo/NN-*/run.sh, capturing output
```

On the first `make run-demo`, review each demo's output and commit its `run.txt` as the golden file; subsequent runs diff against it.
