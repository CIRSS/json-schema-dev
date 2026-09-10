# The validator contract

`jsonschema-validate` and `ajv-validate` are two implementations of one command-line contract. This document states that contract: what a caller may rely on, what is deliberately left to the underlying library, and where the current implementations do not yet keep their side of it.

Every clause below is exercised by the conformance corpus in [`tests/`](tests/README.md).

The corpus has [a schema of its own](tests/corpus-schema.json), and both wrappers validate every corpus file against it on each run.

## Invocation

```
jsonschema-validate --schema FILE --instance FILE [--ref FILE]...
                    [--reject-duplicate-members] [--ignore-declared-version]
                    [--text FILE|-] [--json FILE|-]
ajv-validate        --schema FILE --instance FILE [--ref FILE]...
                    [--reject-duplicate-members] [--ignore-declared-version]
                    [--text FILE|-] [--json FILE|-]
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

There are two forms of the verdict, and a run may ask for either or both.

| Option | Form |
| --- | --- |
| `--text FILE`, `--text -` | the verdict lines below, one per failure |
| `--json FILE`, `--json -` | the JSON report |

`-` means stdout, and both options may name a file. Passing neither writes the text form to stdout, which is what a caller who names no option has always got. Naming one turns the other off. Both resolving to stdout is an error (exit 2), the two forms being unreadable interleaved.

**Both forms may be produced by one run**, and that is the usual way to ask for them: a consumer that publishes a validator's own output beside a report built from the structure gets two representations of one execution, rather than two executions that might not describe the same thing.

Exit status is the same whichever form is asked for, and diagnostics, warnings and usage go to **stderr** in every case.

### The text form

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

> **Known weakness.** The two line forms are told apart by whether the text after `INVALID: ` begins with `/`, and a message beginning with `/` would be misread as a location. The format has no escape for this.

## The JSON report

```json
{ "valid": false, "errors": [ … ] }
```

Every run produces a report, so a valid instance gives `{"valid": true, "errors": []}`. One entry in `errors` is one violation.

| Field | |
| --- | --- |
| `site` | where in the instance, as segments — `["@graph", 0]` distinguishes an index from a member name, and a member named `a/b` needs no escape |
| `keyword` | the keyword that failed |
| `clause` | where that keyword lives in the schema, as segments, resolved through any `$ref` that led to it |
| `document` | which of the schemas you supplied the clause is in, by its `$id` |
| `constraint` | what the schema demanded — `allowedValues`, `limit`, `pattern` |
| `particulars` | what specifically went wrong — `missingProperty`, `additionalProperty`, the two indexes of a duplicate |
| `found` | the value the instance actually had at `site` |
| `message` | the library's wording, or an authored `errorMessage` where one covers the failure |
| `rejections` | on a branching clause: what was tried, and why each was refused |

**Absent is not unknown; it is nothing to say.** No `site` means the document as a whole. No `document` means the schema given on the command line. An empty `constraint` or `particulars` is omitted rather than written as a pair of braces. Across the keywords implemented, `constraint` and `particulars` never both appear: a keyword reports one kind or the other.

**`found` is the value at `site`**, resolved against the instance rather than taken from whatever the library attached to its error — a site is sometimes relocated, an `additionalProperties` failure being reported at the offending member and a cause recomputed under a `contains` conclusion being re-rooted beneath it, and in both the library's own value is the parent's. It is carried whole, whatever its size, which the instance bounds: a consumer of this form does not have the instance parsed, and a violation reported without the value that caused it frequently cannot be interpreted at all. A `found` that does not resolve is a defect in the wrapper and stops the run. The `parse` and `duplicateMember` entries carry none, for the same reason they carry no `clause`: they are defects of the document rather than findings against a rule.

**A clause is always a path from the root of a document the caller supplied** — the command-line schema, or a `--ref` file. A subschema may name itself with an `$id`, making it a resource in its own right, or with an `$anchor`; both are navigation the wrapper does and neither appears in a report, because the file a reader has open is the one they were handed.

**Locations are segments rather than JSON Pointers**, because a rendered pointer cannot distinguish an array index from a member named `0`, and is ambiguous about a member whose name contains `/` or `~`. That ambiguity is harmless to a reader who has the document open and fatal to a program that does not, which is the consumer this form is for.

### What becomes an entry

**A transparent applicator produces none.** `if`/`then`/`else`, `$ref`, `properties`, `items`, `prefixItems`, `propertyNames`, `allOf`, `dependentSchemas`: a conclusion that some subschema failed repeats a location already reported and states nothing about the instance. What it enclosed stays traceable through `clause`.

**A branching applicator produces one, with its rejections beneath it.** `anyOf`, `oneOf`, `contains`, `not`. A rejection names who refused — `clause` for a branch of `anyOf` or `oneOf`, `site` for an element `contains` tried — and carries the `errors` that were its grounds. Within one rejection those really are errors and all of them would have to be cleared; **between rejections, clearing any single one satisfies the clause.** That is the whole reason they are not reported as peers of the conclusion: they are not each a fault to fix.

**`additionalProperties` and `unevaluatedProperties` produce one entry per rejected member, located at that member**, rather than one at the parent naming several.

The parse tier appears in the report too, since exit status and `valid` must agree: a document that does not parse is one entry with the keyword `parse`, and `--reject-duplicate-members` produces one with the keyword `duplicateMember` per repeated name.

### What must agree, and what need not

The two implementations must agree on:

- **exit status**, always;
- **the JSON report**, in every part but `message`, on every case — a `divergent` defect suspends the text comparison and never this one;
- in the text form, **the number of verdict lines** and **the location of each failure**.

They need not agree on **message prose**. The standard leaves message text to the implementation, and the two libraries word the same finding differently — `'b' is a required property` against `must have required property 'b'`. Prose divergence is expected and is not a defect.

There are two places where the text *is* contracted to be identical, because the wrappers generate it rather than the libraries:

- an authored `errorMessage` (below), which is the schema author's whole statement and is printed as written;
- the parse-tier verdicts of `--reject-duplicate-members`.

**The two forms carry different obligations, and that is deliberate.** The text form shows what each library said, divergence included; the JSON report is where the two are contracted to describe one thing. So the applicator divergences in the defect table below are properties of the text form, and are absent from the report.

The corpus asserts agreement on the whole report for every case, on exit status, line count and locations for the text form, and word-for-word agreement on the cases that carry `identicalMessages`.

## `--ref FILE`

Loads an additional schema and registers it under its `$id`, making it reachable by `$ref` from the main schema. Repeatable; chains and embedded `$id`s both resolve.

**Nothing is ever fetched.** A `$id` is a name to resolve against, not an address to retrieve. A schema that refers to something no `--ref` supplied is an **error** (exit 2), not an invalid instance — the setup is incomplete. The two libraries notice at different moments (Ajv when compiling, python-jsonschema on first use of the reference) and word it differently, but both exit 2.

A `--ref` file with no `$id` is refused: there is nothing to register it under.

## `errorMessage`

A nonstandard keyword that both libraries ignore. Both wrappers read it out of the schema JSON and implement it the same way; neither uses Ajv's `ajv-errors` plugin. It is an annotation: it changes what a failure is called, never whether it is one, so the verdict and every field of the JSON report but `message` are the same with or without it.

**Forms.** In the subschema it sits in:

- a **string** covers every failure within the subschema, however deep;
- an **object** keyed by keyword covers a failure of that keyword *in this subschema only* — an outer `type` message does not reach a `type` failure inside a member's own subschema;
- under `required`, an object keyed by member name gives each missing member its own message;
- `properties`, an object keyed by member name, covers any failure inside that member, whatever keyword failed and however deep;
- `items`, an array, covers any failure inside the element at that index;
- `_` covers whatever no other entry in the object does.

**The nearest message wins.** The lookup walks outward from the failing keyword through every subschema that led to it — across a `$ref`, into a `--ref` file, through a `contains` element — and takes the first message that covers the failure. So a message stated with a factored-out definition covers the definition's failures everywhere it is applied and beats one written beside the `$ref`; and a message beside the `$ref` covers the definition's failures where the definition states none.

**Interpolation.** `${…}` in a message is replaced by an instance value, JSON-encoded:

- `${/a/json/pointer}` resolves from the instance root;
- `${0}`, `${1/member}` resolve from **the location the message is written for** — the subschema's own instance location for a string, keyword or `_` message, the member or element for a `properties` or `items` message — the integer climbing that many levels and an optional path descending from there. `${0}` in a message beside the failing keyword is the failing value itself; in a string message covering a deeper failure it is the value the message's subschema was applied to;
- `${0#}`, `${1#}` give the member name or index at that level;
- a pointer that resolves to nothing is left in the message as written.

A failure no message covers keeps the library's own message. An authored message is printed exactly as authored, with the location but never any other decoration.

## `--reject-duplicate-members`

JSON's grammar permits an object to repeat a member name; every parser silently keeps the last value. No schema can therefore ever see a duplicate — parse time is the only tier that can check, which is why this is a flag on the wrapper rather than a keyword in a schema.

With the flag, a duplicate anywhere in the instance is a **verdict** (exit 1), reported as one line per duplicated name, deduplicated and sorted:

```
INVALID: instance contains duplicate member name "status"
```

Sorting is what makes the output cross-validated: the Python leg finds duplicates through a parse hook that sees objects innermost-first, the Node leg by scanning the raw text in document order, and sorting reconciles the two into the same lines in the same order. Names are compared after escape sequences are decoded, so `a` and `a` are the same member, and printed JSON-encoded without ASCII escaping so a non-ASCII name is byte-identical on both legs.

## Declared versions

A schema — or a `--ref` file — whose top-level `$schema` names any version other than 2020-12 is **refused** (exit 2) rather than silently reinterpreted. The declaration is the author's statement of which semantics the schema was written for, and 2020-12 would quietly change its meaning: a draft-07 author's `definitions` and `dependencies` are simply ignored unknown members here.

`--ignore-declared-version` discards the declaration and validates as 2020-12 anyway.

Declaring 2020-12, or declaring nothing, passes through untouched.

## `format`

Neither wrapper checks `format`. It is the annotation that 2020-12 makes it by default, on both legs alike and in silence — Ajv's "unknown format ignored" warning is switched off, because ignoring is all the wrapper ever does with a format.

Format *assertion*, if it is ever added, goes on both legs together as an explicit option, with the unknown-format case handled identically.

## Limitations

These are not defects and will not be repaired. They are the edges of what this pair can be used for, and a schema written for both wrappers should stay inside them.

**The Python leg does not implement the regular expression dialect the specification names.** JSON Schema says a `pattern` is an ECMA-262 regular expression; python-jsonschema hands the string to Python's `re`, whose dialect differs. The difference that is known: `$` matches before a trailing newline in Python and only at the end of input in JavaScript, so `^[0-9a-f]{4}$` accepts `"abcd\n"` on one leg and rejects it on the other. Others have not been enumerated — `\d`, `\w` and `\b` are Unicode-aware in Python and ASCII in ECMA-262, for a start. **A schema meant for both wrappers should not lean on the anchor**, and there is no portable way to write "end of input" that both read alike. Demo 07 in [`json-schema-demos`](https://github.com/CIRSS/json-schema-demos) exhibits it.

**A report cannot be traced back to the files the run was given.** `document` names a schema by its `$id`, which is the same in every run, where a path is a fact about one run on one machine — and comparability between runs is what the cross-validation rests on. A caller that needs the file supplied both, and holds the mapping.

## Known defects

These are behaviors the corpus pins as current and wrong. Each has a case whose `defect` carries the same summary and becomes a test name. Repairing one breaks its recorded expectation; the case and the note are updated together.

Four of them are properties of the **text form** and do not reach the JSON report: the unescaped pointers and the `/` root sentinel, which a path of segments has no way to express, and the two rows about sub-results and `params`, which the report's causes and fields carry. They are listed here as recorded rather than repaired, since the text form is left as each library reports it.

| Defect | Where |
| --- | --- |
| **JSON Pointers are not escaped on the Python leg.** Path segments are joined with `/` without RFC 6901's `~0`/`~1` escapes, so a member named `a/b` renders as `/a/b` — indistinguishable from a nested member — and one named `a~b` renders as a pointer that does not address it. Ajv escapes correctly, so the legs disagree on location. | `01-location-rendering.json` — `--grep "goes unescaped"` |
| **The text form locates a `false` subschema's failure at the parent on the Python leg.** python-jsonschema extends neither path for a boolean subschema, and the text line prints its error as reported. The JSON report locates the member correctly on both legs, having recovered it from the applicator and the rejected value; the text form would have to be built from the report to follow. | `01-location-rendering.json` — `--grep "false subschema"` |
| **The instance root is represented by the string `/`.** RFC 6901 gives the root the *empty* pointer and gives `/` to the member named `""`, so a failure on that member is rendered as though it were a failure of the whole instance. Both legs share the fault. | `01-location-rendering.json` — `--grep "as though the whole instance"` |
| **Sub-results are printed as peers of their conclusion, or not at all.** Ajv returns an applicator's conclusion and the sub-results behind it in one flat array and the wrapper prints them as equal `INVALID` lines; python-jsonschema yields only conclusions, keeping sub-results in each error's `context`, which the wrapper never reads. So the two report different numbers of lines for every applicator. | all of `02-sub-result-nesting.json` |
| **`params` is discarded from Ajv's errors.** The offending member's identity travels in `err.params` (`missingProperty`, `additionalProperty`, `unevaluatedProperty`, `allowedValues`, `limit`) and the wrapper prints only `err.message` — so two extra members produce two identical lines, and an `enum` failure names no allowed values. | `03-offender-identity.json` |


## Running the corpus

```
make test-code
```

See [`tests/README.md`](tests/README.md) for the case format and how to add one.
