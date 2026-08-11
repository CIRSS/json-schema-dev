# json-schema-dev

A [REPRO](https://github.com/repros-dev) capability module that bundles two JSON Schema validators and a gallery of minimal, runnable demonstrations of individual JSON Schema constructs. Each demo is one `(schema, instance)` pair validated through **both** validators; the committed `run.txt` golden file records — and asserts — that the two agree on the verdict. Re-run a demo and `git diff` its golden file to confirm.

## Validators

Both pinned, both driven at the **JSON Schema 2020-12** dialect:

| Language | Library | Command |
| --- | --- | --- |
| Python | [`jsonschema`](https://pypi.org/project/jsonschema/) `4.23.0` (`Draft202012Validator`) | `jsonschema-validate --schema FILE --instance FILE` |
| JavaScript | [`ajv`](https://ajv.js.org/) `8.17.1` (`ajv/dist/2020`) | `ajv-validate --schema FILE --instance FILE` |

Arguments are **named** (`--schema`/`--instance`, or `-s`/`-i`), not positional, so the schema and instance can't be transposed by accident — a swap that would otherwise pass silently, since any JSON object is itself a valid, permissive schema.

Each command writes its verdict to stdout — `VALID`, or one `INVALID: <error>` line per validation error — and exits **0** (valid), **1** (invalid), or **2** (error: bad arguments, an unreadable file, malformed JSON, or an invalid schema); diagnostics and `-h`/`--help` text go to stderr/stdout respectively. So the two are directly comparable *and* safe to script. The dialect is forced in the wrapper rather than read from the schema's `$schema`, so an old validator cannot silently fall back to a weaker dialect.

Both commands are exported as artifacts of this module, so they are on `PATH` inside this REPRO **and** inside any REPRO that composes it with `repro.require json-schema-dev …` — the module's capability is the uniform cross-validator CLI, not just the two libraries.

## Demos

| # | Construct | Shows |
| --- | --- | --- |
| `01-unevaluated-properties` | `unevaluatedProperties: false` over `allOf` | closure that sees through `allOf`, which `additionalProperties: false` cannot |
| `02-empty-and-boolean-schemas` | `{}`, `true`, `false` | accept-all / reject-all at the schema floor — including boolean schemas and a `null` instance |
| `03-empty-vs-nonempty-array` | `minItems: 1` | empty array rejected, one-element array accepted |
| `04-empty-vs-nonempty-object` | `required` | empty object rejected, minimal object accepted |

## Build and run

The parent image supplies Python (from source, with pip) and a pinned Node; the demo runner (via `shell-notebook`) is composed at build time.

```
make build-parent     # framework base + Python + Node (one-time, slow layer)
make build-image      # compose shell-notebook and this module's validators
make run-demo         # run every demo/NN-*/run.sh, capturing output
```

On the first `make run-demo`, review each demo's output and commit its `run.txt` as the golden file; subsequent runs diff against it.
