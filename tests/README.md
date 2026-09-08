# The conformance corpus

The corpus states, as data, what [the contract](../CONTRACT.md) says the two wrappers do. [`conformance.test.js`](conformance.test.js) turns it into a Mocha suite: one `describe` per case, checking two different things about each run.

From the host, one command:

```
make test-code
```

That is the REPRO framework's standard target for testing a repo's own code; it starts a session and runs the suite inside the image, where both wrappers are on `PATH` and Mocha is installed.

Inside a started REPRO (`make start-repro`), the suite is plain Mocha:

```
npm test                                        every case
npm test -- --grep "several files"              one group
npm test -- --grep "chain of components"        one case
npm test -- --grep "duplicate"                  everything about duplicates
npm test -- --reporter dot                      totals only
```

`npm test` on the *host* will not work, and is not meant to: the wrappers live in the image, not on the host, so there is nothing there to test. Everything that runs them runs in the container.

## What the suite checks

**1. That each wrapper behaves as recorded.** The corpus records what the wrappers do today — including where that is wrong — so any change in behavior surfaces as a failing test.

**2. That the two implementations agree.** Every case is run once asking for both output forms, and the two are held to different standards. The **JSON report** must match in every part but `message`, which is what the report exists for. The **text form** must match on exit status, the number of verdict lines and each failure's location; its message prose is the library's, and the standard leaves it to implementations, so it is not compared — except on cases carrying `identicalMessages`, which assert that something the wrappers generate (an authored `errorMessage`, a parse-tier verdict) really does come out word for word on both legs.

A `divergent` defect suspends the text-form comparison and never the report's: those defects record the text form showing what each library said, which is what the text form is for.

## What a case is

One JSON object in the `cases` array of a file under [`corpus/`](corpus). The files group cases by what they are about; the grouping is for reading, not for semantics.

| Field | Meaning |
| --- | --- |
| `name` | the claim the case makes, as an independent clause — this is the `describe` title in the report, and what `--grep` selects on |
| `description` | what the claim leaves unexplained; omitted when it would only restate the claim |
| `schema` | the schema, as inline JSON |
| `schemaText` | the schema as raw text, when it must not be valid JSON |
| `instance` / `instanceText` | the same two forms, for the instance |
| `refs` | array of additional schemas, each passed as one `--ref` |
| `args` | extra flags appended to the command line |
| `argv` | the whole argument list instead, for cases about the argument parser; `{schema}` and `{instance}` stand in for the materialized paths |
| `omit` | documents to leave unwritten (`"schema"`, `"instance"`) — the missing-file cases |
| `makeDirectory` | documents to create as a directory instead of a file |
| `expect` | the recorded behavior: `exit`, `stdout`, `report`, `stderrContains` |
| `identicalMessages` | assert the two legs emit the same lines word for word |
| `defect` | this case pins behavior known to be wrong; see below |

A case's `name` is written as a claim — *"an array element's location is its index"*, not `array-index` — so the Mocha report reads as a list of assertions about the wrappers rather than a list of identifiers. Where the current behavior is wrong, the claim states the wrong behavior and a `defect` says so; the corpus records what is, and the defect records what ought to be.

A duplicate object member name cannot survive a round trip through a JSON value, and neither can a malformed document, so those cases carry raw text (`schemaText`, `instanceText`) instead.

`report` is the JSON report the run saved, with every `message` removed — the part the two legs are contracted to produce identically — or `null` where the run never got as far as writing one.

`expect` fields are either a single value, which binds both legs, or an object keyed by wrapper name, which records that the two differ. `stderrContains` matches as a substring. The scratch directory's path is scrubbed to `{dir}` in both streams before anything is compared, so expectations that quote a filename stay stable across runs.

The corpus is **language-neutral data rather than JavaScript**, so an implementation in either ecosystem runs the same cases without importing across ecosystems.

## The corpus has a schema of its own

The table above is documentation; [`corpus-schema.json`](corpus-schema.json) is the specification. It is a 2020-12 schema for a corpus file, and [`corpus-schema.test.js`](corpus-schema.test.js) runs every corpus file through **both wrappers** against it.

Both objects are closed (`additionalProperties: false`), so a mistyped key is a verdict rather than a silently ignored field: write `instanceTxt` and the case is rejected instead of running with no instance file.

The schema states two things the table leaves implicit: a case carries **exactly one** form of each document (`oneOf` over `schema`/`schemaText`, and again for the instance, so a case carrying both is rejected rather than resolved by the runner), and a `defect` carries both what is wrong and what it should become.

A schema that accepts everything also accepts every corpus file, so the conformance check establishes nothing on its own. The same test file carries canaries — nine malformations the schema exists to catch, each of which both wrappers must reject: a mistyped field, both instance forms at once, a missing document, a defect with no `should`, an exit status the contract does not define, a per-leg expectation naming a wrapper that does not exist, an empty group, an expectation with no recorded stdout.

## Recording expectations

Inside a started REPRO:

```
npm run record                              every case
node tests/record-corpus.js --grep "chain of components"
```

`--grep` matches a substring of a case's claim or its group's title, case-insensitively — the same handle Mocha takes, so selecting a case to record and selecting it to run read the same way.

Recording reruns each selected case and replaces its `expect` with what the run observed. It is not part of the suite: recording is corpus maintenance, and running it is not the same as passing. What it produces is a diff.

## Defects

A case carrying a `defect` pins behavior known to be wrong:

```json
"defect": {
  "summary": "what is wrong",
  "should": "what the behavior should become",
  "divergent": true
}
```

The `summary` becomes a test name, so the defect inventory appears in the test report. The case's recorded expectations still hold, and repairing the defect breaks them: update the case and delete the `defect` note in the same change.

`divergent` marks a defect that splits the two legs in the text form, and suspends only that case's text-form comparison. A defect both legs share — the root sentinel, for one — leaves them agreeing, so that check still runs. Neither suspends the report comparison, which every case must pass.

The current defects are summarized in [the contract's Known defects table](../CONTRACT.md#known-defects).

## Adding a case

In a started REPRO:

1. Write the case with its claim as `name`, its inputs, and a `description` only if the claim leaves something unexplained — no `expect`.
2. `node tests/record-corpus.js --grep "<part of the claim>"` and read what the wrappers actually do.
3. Read the diff. Where the recorded behavior is wrong, restate the claim to say what actually happens and add a `defect` saying what it should be.
4. `npm test -- --grep "<part of the claim>"`.

## What is not covered yet

| File | Group title in the report |
| --- | --- |
| `01-location-rendering` | where a failure is reported |
| `02-sub-result-nesting` | conclusions and the sub-results behind them |
| `03-offender-identity` | naming the member at fault |
| `04-exit-codes` | verdicts, errors, and exit status |
| `05-error-message` | authored messages |
| `06-ref-registration` | schemas spread over several files |
| `07-parse-tier-flags` | checks no schema can make |

The ordering follows the order the areas were written in, not an even spread of risk. Not yet covered: `$ref` boundary cases beyond those in groups 02, 05 and 06 — `$dynamicRef`, nested `$id` scoping, recursion; `--ignore-declared-version` interacting with `--ref` chains; instances large or deeply nested enough to matter; anything about stderr beyond a substring; and a third implementation.
