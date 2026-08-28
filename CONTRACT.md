# The validator contract

`jsonschema-validate` and `ajv-validate` are two implementations of one command-line contract. This document states that contract: what a caller may rely on, what is deliberately left to the underlying library, and where the current implementations do not yet keep their side of it.

The contract is what makes the pair useful. Either wrapper alone is a thin CLI over a validator; together, run over the same input, they are a check on each other, and the check is only as good as the statement of what they are supposed to agree about. Every clause below is exercised by the conformance corpus in [`tests/`](tests/README.md); a clause with no case behind it is a wish, not a contract.

The corpus is also the pair's first consumer: it has [a schema of its own](tests/corpus-schema.json), and both wrappers validate every corpus file against it on each run.

## Invocation

```
jsonschema-validate --schema FILE --instance FILE [--ref FILE]...
                    [--reject-duplicate-members] [--ignore-declared-version]
ajv-validate        --schema FILE --instance FILE [--ref FILE]...
                    [--reject-duplicate-members] [--ignore-declared-version]
```

Arguments are **named**, never positional (`-s`/`-i`/`-r` are the short forms). This is deliberate: any JSON object is itself a valid, permissive schema, so a transposed schema and instance would not fail — it would quietly pass. A positional argument is refused rather than guessed at.

Both implementations force the **JSON Schema 2020-12** dialect rather than reading it from the schema's `$schema`, so an older or differently-configured validator cannot silently fall back to weaker semantics.

## Exit status

| Status | Meaning |
| --- | --- |
| `0` | the instance satisfies the schema |
| `1` | the instance does not satisfy the schema |
| `2` | error: the run could not be made to happen as asked |

**The governing rule: everything about the submitted instance is a verdict; everything else is an error.** A document that was delivered but does not parse as JSON has failed validation's lowest tier — the JSON grammar — so it is `INVALID` and exits 1, not an error. A *schema* that does not parse is a broken setup and exits 2. The same rule places a missing instance file at exit 2: failing to read the file is not a fact about the instance, because there is no instance.

Exit status is the wrappers' own, not the libraries', and the two implementations must always agree on it.

## Output

The verdict goes to **stdout**. Everything else — diagnostics, warnings, usage — goes to **stderr**.

A valid instance produces exactly one line:

```
VALID
```

An invalid instance produces one line per failure:

```
INVALID: <message>                  a failure of the instance as a whole
INVALID: <location>: <message>      a failure at a location inside it
```

`<location>` is a JSON Pointer into the instance.

> **Known weakness.** The two line forms are told apart by whether the text after `INVALID: ` begins with `/`, and a message beginning with `/` would be misread as a location. The format has no escape for this. Any reimplementation should carry the location as a field rather than recovering it from the line.

### What must agree, and what need not

The two implementations must agree on:

- **exit status**, always;
- **the number of verdict lines**;
- **the location of each failure**.

They need not agree on **message prose**. The standard leaves message text to the implementation, and the two libraries word the same finding differently — `'b' is a required property` against `must have required property 'b'`. Prose divergence is expected and is not a defect.

There are two places where the text *is* contracted to be identical, because the wrappers generate it rather than the libraries:

- an authored `errorMessage` (below), which is the schema author's whole statement and is printed as written;
- the parse-tier verdicts of `--reject-duplicate-members`.

The corpus asserts agreement on exit status, line count, and locations for every case, and asserts word-for-word agreement on the cases that carry `identicalMessages`.

## `--ref FILE`

Loads an additional schema and registers it under its `$id`, making it reachable by `$ref` from the main schema. Repeatable; chains and embedded `$id`s both resolve.

**Nothing is ever fetched.** A `$id` is a name to resolve against, not an address to retrieve. A schema that refers to something no `--ref` supplied is an **error** (exit 2), not an invalid instance — the setup is incomplete. The two libraries notice at different moments (Ajv when compiling, python-jsonschema on first use of the reference) and word it differently, but both exit 2.

A `--ref` file with no `$id` is refused: there is nothing to register it under.

## `errorMessage`

A nonstandard keyword — Ajv gets it from the `ajv-errors` plugin, and `jsonschema-validate` implements the same behavior independently by reading the messages out of the schema JSON. The **portable subset** both implement:

- a plain-string `errorMessage` covers every failure within its subschema;
- an object form supplies one message per failing keyword;
- the lookup walks outward from the failing keyword and takes the first message it meets, so an inner message beats an enclosing one;
- `${/a/json/pointer}` interpolates the instance value at that absolute pointer, JSON-encoded;
- `${0}`, `${1/member}` interpolate relative to the failing value: the integer climbs that many levels, an optional path descends from there;
- a failure no message covers keeps the library's own message.

An authored message is printed exactly as authored, with the location but never any other decoration. That is the point: it is the one place a schema author can close the prose divergence between the two legs deliberately.

Two implementations of one behavior is precisely the shape that needs a conformance suite, and the corpus has already found them disagreeing — see the defects below.

## `--reject-duplicate-members`

JSON's grammar permits an object to repeat a member name; every parser silently keeps the last value. No schema can therefore ever see a duplicate — parse time is the only tier that can check, which is why this is a flag on the wrapper rather than a keyword in a schema.

With the flag, a duplicate anywhere in the instance is a **verdict** (exit 1), reported as one line per duplicated name, deduplicated and sorted:

```
INVALID: instance contains duplicate member name "status"
```

Sorting is what makes the output cross-validated: the Python leg finds duplicates through a parse hook that sees objects innermost-first, the Node leg by scanning the raw text in document order, and sorting reconciles the two into the same lines in the same order. Names are compared after escape sequences are decoded, so `a` and `a` are the same member, and printed JSON-encoded without ASCII escaping so a non-ASCII name is byte-identical on both legs.

## Declared versions

A schema — or a `--ref` file — whose top-level `$schema` names any version other than 2020-12 is **refused** (exit 2) rather than silently reinterpreted. The declaration is the author's statement of which semantics the schema was written for, and 2020-12 would quietly change its meaning: a draft-07 author's `definitions` and `dependencies` are simply ignored unknown members here.

`--ignore-declared-version` discards the declaration and validates as 2020-12 anyway. The reinterpretation is the same; making it a flag makes it a choice.

Declaring 2020-12, or declaring nothing, passes through untouched.

## `format`

Neither wrapper checks `format`. It is the annotation that 2020-12 makes it by default, on both legs alike and in silence — Ajv's "unknown format ignored" warning is switched off, because ignoring is all the wrapper ever does with a format and a wrapper may not warn about a capability it never has.

Format *assertion*, if it is ever added, goes on both legs together as an explicit option, with the unknown-format case handled identically.

## Known defects

These are behaviors the corpus pins as current and wrong. Each has a case whose `defect` carries the same summary and becomes a test name, so the inventory cannot drift from the tests; repairing one breaks its recorded expectation, and the case and the note are updated together.

| Defect | Where |
| --- | --- |
| **A crash exits 1.** An exception during validation leaves Node's default exit status, which collides with the INVALID code, and stdout is empty. A caller scripting on exit status reads a crash as a verdict. Reproduced by a relative `errorMessage` pointer in a subschema whose failing keyword is `type`: `ajv-errors` emits `JSON.stringify(dataN)` for a variable Ajv's codegen never bound, and the generated validator throws. | `05-error-message.json` — `--grep "crashes ajv-validate"` |
| **The `errorMessage` implementations disagree on an unresolvable pointer.** `jsonschema-validate` leaves it in the message as written; `ajv-errors` substitutes the text `undefined`, asserting a value the instance does not have. | `05-error-message.json` — `--grep "unresolvable pointer"` |
| **JSON Pointers are not escaped on the Python leg.** Path segments are joined with `/` without RFC 6901's `~0`/`~1` escapes, so a member named `a/b` renders as `/a/b` — indistinguishable from a nested member — and one named `a~b` renders as a pointer that does not address it. Ajv escapes correctly, so the legs disagree on location. | `01-location-rendering.json` — `--grep "goes unescaped"` |
| **The instance root is represented by the string `/`.** RFC 6901 gives the root the *empty* pointer and gives `/` to the member named `""`, so a failure on that member is rendered as though it were a failure of the whole instance. Both legs share the fault. | `01-location-rendering.json` — `--grep "as though the whole instance"` |
| **Sub-results are printed as peers of their conclusion, or not at all.** Ajv returns an applicator's conclusion and the sub-results behind it in one flat array and the wrapper prints them as equal `INVALID` lines, which gives a reason the standing of a requirement; python-jsonschema yields only conclusions, keeping sub-results in each error's `context`, which the wrapper never reads. So the two report different numbers of lines for every applicator. | all of `02-sub-result-nesting.json` |
| **`params` is discarded from Ajv's errors.** The offending member's identity travels in `err.params` (`missingProperty`, `additionalProperty`, `unevaluatedProperty`, `allowedValues`, `limit`) and the wrapper prints only `err.message` — so two extra members produce two identical lines, and an `enum` failure names no allowed values. | `03-offender-identity.json` |


## Running the corpus

```
make test-code
```

See [`tests/README.md`](tests/README.md) for the case format and how to add one.
