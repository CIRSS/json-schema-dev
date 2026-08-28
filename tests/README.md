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

**1. That each wrapper behaves as recorded.** The corpus records what the wrappers do today — including where that is wrong — so any change in behavior surfaces as a failing test rather than as a golden file nobody regenerated.

**2. That the two implementations agree.** On the parts of the output that are the wrappers' own rather than the libraries': exit status, the number of verdict lines, and each failure's location. Message *prose* is the library's, and the standard leaves it to implementations, so it is not compared — except on cases carrying `identicalMessages`, which assert that something the wrappers generate (an authored `errorMessage`, a parse-tier verdict) really does come out word for word on both legs.

The second check is what converts "cross-validated" from a claim into a check. The demo gallery in [`json-schema-demos`](https://github.com/CIRSS/json-schema-demos) has been standing in for it: its goldens do record both legs' output side by side, but nothing asserts anything about the relationship, and a golden only notices a change if someone regenerates it and reads the diff.

## What a case is

One JSON object in the `cases` array of a file under [`corpus/`](corpus). The files group cases by what they are about; the grouping is for reading, not for semantics.

| Field | Meaning |
| --- | --- |
| `name` | the claim the case makes, as an independent clause — this is the `describe` title in the report, and what `--grep` selects on |
| `description` | why the claim is worth asserting, when that is not obvious from the claim; omitted when it would only restate it |
| `schema` | the schema, as inline JSON |
| `schemaText` | the schema as raw text, when it must not be valid JSON |
| `instance` / `instanceText` | the same two forms, for the instance |
| `refs` | array of additional schemas, each passed as one `--ref` |
| `args` | extra flags appended to the command line |
| `argv` | the whole argument list instead, for cases about the argument parser; `{schema}` and `{instance}` stand in for the materialized paths |
| `omit` | documents to leave unwritten (`"schema"`, `"instance"`) — the missing-file cases |
| `makeDirectory` | documents to create as a directory instead of a file |
| `expect` | the recorded behavior: `exit`, `stdout`, `stderrContains` |
| `identicalMessages` | assert the two legs emit the same lines word for word |
| `defect` | this case pins behavior known to be wrong; see below |

A case's `name` is written as a claim — *"an array element's location is its index"*, not `array-index` — so the Mocha report reads as a list of assertions about the wrappers rather than a list of identifiers. Where the current behavior is wrong, the claim states the wrong behavior and a `defect` says so; the corpus records what is, and the defect records what ought to be.

Raw text (`schemaText`, `instanceText`) is not a convenience. A duplicate object member name cannot survive a round trip through a JSON value, and neither can a malformed document, so those cases have to carry the bytes.

`expect` fields are either a single value, which binds both legs, or an object keyed by wrapper name, which records that the two differ. `stderrContains` matches as a substring. The scratch directory's path is scrubbed to `{dir}` in both streams before anything is compared, so expectations that quote a filename stay stable across runs.

The corpus is deliberately **language-neutral data rather than JavaScript**. This repo is to publish a package per ecosystem, and both must run the same cases; if the cases lived in one language, the other would either duplicate them or reach across ecosystems to import them, and divergence between the two implementations would become the hardest thing to test — which inverts the point of the module.

## The corpus has a schema, and we validate it ourselves

The table above is documentation; [`corpus-schema.json`](corpus-schema.json) is the specification. It is a 2020-12 schema for a corpus file, and [`corpus-schema.test.js`](corpus-schema.test.js) runs every corpus file through **both wrappers** against it.

Before the schema existed, the corpus format lived in the table above and in whatever `corpus-case.js` happened to read, and nothing checked that a case conformed. A mistyped key was silently ignored — write `instanceTxt` and the case gets no instance file, records whatever that produces, and passes from then on. Both objects are closed (`additionalProperties: false`), so that mistake is now a verdict.

The schema also states two things the table could only imply: a case carries **exactly one** form of each document (`oneOf` over `schema`/`schemaText`, and again for the instance — so a case carrying both, where the runner would silently prefer one, is rejected), and a `defect` must say both what is wrong and what it should become.

**A schema that accepts everything also accepts every corpus file**, so the conformance check proves nothing on its own. The same test file therefore carries canaries — nine malformations the schema exists to catch, each of which both wrappers must reject: a mistyped field, both instance forms at once, a missing document, a defect with no `should`, an exit status the contract does not define, a per-leg expectation naming a wrapper that does not exist, an empty group, an expectation with no recorded stdout.

## Recording rather than inventing

Inside a started REPRO:

```
npm run record                              every case
node tests/record-corpus.js --grep "chain of components"
```

`--grep` matches a substring of a case's claim or its group's title, case-insensitively — the same handle Mocha takes, so selecting a case to record and selecting it to run read the same way.

Recording reruns each selected case and replaces its `expect` with what the run observed. It is not part of the suite, deliberately: recording is corpus maintenance, and running it is not the same as passing.

It exists because the alternative is writing down what you believe the wrappers do, and a belief that is wrong becomes an expectation that is wrong — which the suite then defends against every future change.

**Recording an expectation is not approving it.** What it produces is a diff, and the diff is the thing to read. A recorded value that looks wrong is a finding.

## Defects

A case carrying a `defect` pins behavior known to be wrong:

```json
"defect": {
  "summary": "what is wrong",
  "should": "what the behavior should become",
  "divergent": true
}
```

The `summary` becomes a test name, so the defect inventory *is* part of the test report and cannot drift from the cases that demonstrate it. Its recorded expectations still hold — that is what makes the defect visible — and repairing it will break them, which is the correct signal: update the case and delete the `defect` note in the same change.

`divergent` marks a defect that actually splits the two legs, and suspends only that case's agreement check. A defect both legs share — the root sentinel, for one — leaves them agreeing, and there is no reason to stop asserting that.

The current defects are summarized in [the contract's Known defects table](../CONTRACT.md#known-defects).

## Adding a case

In a started REPRO:

1. Write the case with its claim as `name`, its inputs, and a `description` only if the claim leaves something unexplained — no `expect`.
2. `node tests/record-corpus.js --grep "<part of the claim>"` and read what the wrappers actually do.
3. Read the diff. If the recorded behavior is wrong, restate the claim to say what actually happens and add a `defect` saying what it should be — rather than accepting the baseline silently.
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

The ordering follows the order the areas were written in, not an even spread of risk, so the gaps are worth naming. Not yet covered: `$ref` boundary cases beyond the one in group 02; `--ignore-declared-version` interacting with `--ref` chains; instances large or deeply nested enough to matter; anything about stderr beyond a substring; and a third implementation, which is the only way to tell a shared misreading from a correct one.
