# json-schema-dev

A [REPRO](https://github.com/repros-dev) capability module that bundles two JSON Schema validators behind one command-line contract, so the same `(schema, instance)` pair can be put to both and their verdicts compared.

The gallery of runnable JSON Schema demonstrations that grew up alongside these wrappers now lives in [`json-schema-demos`](https://github.com/CIRSS/json-schema-demos), which requires this module. The numbered demos cited below are demos of that gallery.

## Validators

Both pinned, both driven at the **JSON Schema 2020-12** dialect:

| Language | Library | Command |
| --- | --- | --- |
| Python | [`jsonschema`](https://pypi.org/project/jsonschema/) `4.23.0` (`Draft202012Validator`) | `jsonschema-validate --schema FILE --instance FILE [--ref FILE]...` |
| JavaScript | [`ajv`](https://ajv.js.org/) `8.17.1` (`ajv/dist/2020`) | `ajv-validate --schema FILE --instance FILE [--ref FILE]...` |

Arguments are **named** (`--schema`/`--instance`, or `-s`/`-i`), not positional, so the schema and instance can't be transposed by accident — a swap that would otherwise pass silently, since any JSON object is itself a valid, permissive schema.

Each `--ref FILE` (repeatable) loads an additional schema and registers it under its `$id`, making it available to `$ref` in the main schema — this is how a schema spread across several files is validated. A `--ref` schema must carry a `$id`; nothing is ever fetched from the `$id`'s URI, which serves purely as a name to resolve against (demo 16).

Neither wrapper checks `format`: it is the annotation the 2020-12 specification makes it by default, on both legs alike and in silence (Ajv's "unknown format ignored" warning is switched off, since ignoring is all the wrapper ever does with a format). Format assertion, if ever added, will be added to both wrappers together as an explicit option, with the unknown-format case handled identically on both.

Both wrappers honor the nonstandard `errorMessage` keyword (a portable subset of [`ajv-errors`](https://github.com/ajv-validator/ajv-errors): a plain string covering its subschema, or an object keyed by keyword, either containing `${pointer}` interpolations that JSON-encode an instance value — absolute JSON Pointers resolving from the instance root, and relative ones resolving from the failing value's own location, so `${0}` is the failing value itself): Ajv through the plugin, the Python wrapper by reading the messages directly out of the schema JSON. Failures no message covers keep each library's own message (demo 19).

Each command writes its verdict to stdout — `VALID`, or one `INVALID: <error>` line per validation error — and exits **0** (valid), **1** (invalid), or **2** (error: bad arguments, an unreadable file, a schema or `--ref` file that is not valid JSON, an invalid schema, or an unresolvable `$ref`); diagnostics and `-h`/`--help` text go to stderr/stdout respectively. An *instance* file that reads but does not parse as JSON is a **verdict**, not an error — `INVALID: instance is not valid JSON: …`, exit 1 — because everything about the submitted document is a verdict and everything about the setup is an error; a document failing the JSON grammar itself has failed validation's lowest tier (demo 20). In the same spirit, `--reject-duplicate-members` makes a duplicate object member name anywhere in the instance a verdict (`INVALID: instance contains duplicate member name "…"`, all names sorted, word-for-word identical across the two wrappers): parsers silently keep the last value, so no schema can ever see a duplicate — parse time is the only tier that can check (demo 21). On the schema side, a schema (or `--ref` file) whose `$schema` entry declares any version other than 2020-12 is refused (exit 2) rather than silently reinterpreted; `--ignore-declared-version` discards the declaration and validates as 2020-12 anyway, making the reinterpretation an explicit choice (demo 22). So the two are directly comparable *and* safe to script. The dialect is forced in the wrapper rather than read from the schema's `$schema`, so an old validator cannot silently fall back to a weaker dialect.

Both commands are exported as artifacts of this module, so they are on `PATH` inside this REPRO **and** inside any REPRO that composes it with `repro.require json-schema-dev …` — the module's capability is the uniform cross-validator CLI, not just the two libraries.

## Tests

The wrappers do not yet have a test suite. `Makefile-tests` exercises the REPRO lifecycle, not the validator contract. Building one — a language-neutral fixture corpus of `(schema, instance, flags)` cases mapped to expected exit code and output, run against both implementations, with cross-implementation agreement asserted mechanically — is the reason this module was separated from the gallery.

## Build

The parent image adds Python (via `apt`) and a pinned Node (official prebuilt binary) to the published framework base, so it builds from nothing local.

```
make build-parent     # framework base + Python + Node (one-time, slow layer)
make build-image      # install the two libraries and export the wrappers
```
