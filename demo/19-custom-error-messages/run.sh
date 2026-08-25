#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 19: custom error messages"

doc "error messages are the validator's, not the schema's" << 'END_DOC'
Nothing in the JSON Schema standard lets a schema say what its error
messages should be. The standard fixes the structure of validation output —
which keyword failed, where in the instance — but the message text is each
implementation's own. The baseline below shows the consequence: one schema,
one failing instance, and two different sentences for the same failure.
Every INVALID line in the previous fifteen demos has this property.
END_DOC

show "the schema, with no message of its own"  cat schema-stock.json

show "the failing instance"              cat instance-bad-checksum.json
show "jsonschema (Python): library message"       jsonschema-validate --schema schema-stock.json --instance instance-bad-checksum.json
show "ajv (JavaScript): library message"          ajv-validate        --schema schema-stock.json --instance instance-bad-checksum.json

doc "errorMessage: the schema author's message, as data in the schema" << 'END_DOC'
The second schema differs in one addition: an errorMessage keyword beside
the pattern it explains. errorMessage is not part of the standard — it is
defined by Ajv's ajv-errors plugin, and 2020-12's rule that unknown
keywords are ignored is what makes carrying it legal everywhere.

But "ignored by the library" does not mean unusable: a schema is JSON, and
the messages are right there in it. The Python wrapper reads them itself —
for each failure, it looks for the nearest enclosing errorMessage — so both
validators now produce the same authored sentence, and for the first time
in this gallery two INVALID lines agree word for word. The message also
reads as documentation in place: description says what a constraint is,
errorMessage says what violating it means.
END_DOC

show "the schema with an errorMessage"   cat schema-message.json
show "jsonschema (Python): authored message"      jsonschema-validate --schema schema-message.json --instance instance-bad-checksum.json
show "ajv (JavaScript): authored message"         ajv-validate        --schema schema-message.json --instance instance-bad-checksum.json

doc "interpolation restores what the authored message lost" << 'END_DOC'
Compare the authored message with the library messages above it: something
went missing. Python's library message quoted the offending value — 'XYZ' —
and the fixed sentence does not. A reader of a long validation report wants
to see what the bad value was, not just where it lives.

errorMessage templates recover it. The next schema differs from the last in
one way: the message contains ${/checksum}, a JSON pointer resolved against
the instance and replaced by the value found there, JSON-encoded. Both
validators print the offending value inside the authored sentence — the
message is once again about this instance, not just about the rule.
END_DOC

show "the schema with an interpolated message"  cat schema-template.json
show "jsonschema (Python): interpolated"          jsonschema-validate --schema schema-template.json --instance instance-bad-checksum.json
show "ajv (JavaScript): interpolated"             ajv-validate        --schema schema-template.json --instance instance-bad-checksum.json

doc "an absolute pointer is the wrong locator when cardinality exceeds one" << 'END_DOC'
The pointer above worked because checksum has exactly one location, known
when the schema was written. The next schema constrains the items of an
array, and its message tries the same trick with the absolute pointer
${/artifacts/0}. The instance carries two items — a well-formed one first,
a malformed one second — and the failing item is not item 0.

The verdict correctly names /artifacts/1, but the authored sentence quotes
"cafe", the innocent neighbor: an absolute pointer is a fixed address, and
no fixed address written into a schema can name which item will fail.
END_DOC

show "the items schema with an absolute pointer"  cat schema-items-absolute.json

show "two artifacts, the second malformed"  cat instance-artifacts.json
show "jsonschema (Python): absolute pointer"      jsonschema-validate --schema schema-items-absolute.json --instance instance-artifacts.json
show "ajv (JavaScript): absolute pointer"         ajv-validate        --schema schema-items-absolute.json --instance instance-artifacts.json

doc "a relative pointer names the failing value, wherever it occurs" << 'END_DOC'
The fix is the second pointer form, differing from the schema above in one
place: ${0} instead of ${/artifacts/0}. A relative JSON pointer resolves
from the failing value's own location — the integer climbs that many
levels up from it, a following path descends from there — so ${0} is
always the value under validation, whichever item that turns out to be.
Both validators now quote the malformed digest, and the same schema would
do so for item 40 of a different instance. For repeated structures, this
is the only pointer form that works.
END_DOC

show "the items schema with a relative pointer"  cat schema-items-relative.json
show "jsonschema (Python): relative pointer"      jsonschema-validate --schema schema-items-relative.json --instance instance-artifacts.json
show "ajv (JavaScript): relative pointer"         ajv-validate        --schema schema-items-relative.json --instance instance-artifacts.json

doc "one message per keyword, and library messages where none is given" << 'END_DOC'
errorMessage also takes an object form, supplying one message per keyword.
The schema below asserts two things — the instance is an object, and it
carries a checksum — but gives an authored message only for the second.
The two instances that follow fail one assertion each.

The missing checksum gets the authored sentence, identically from both
validators. The non-object gets each library's own message: coverage is
per keyword, and anything not covered falls back to the baseline behavior.
The portable subset shown in this demo — a plain string covering its
subschema, an object keyed by keyword, and ${/pointer} value interpolation
— is what both wrappers implement and cross-validate; schemas meant to be
portable should stay within it.
END_DOC

show "the schema (messages for required only)"  cat schema-per-keyword.json

show "missing checksum"                  cat instance-empty.json
show "jsonschema (Python): covered keyword"       jsonschema-validate --schema schema-per-keyword.json --instance instance-empty.json
show "ajv (JavaScript): covered keyword"          ajv-validate        --schema schema-per-keyword.json --instance instance-empty.json

show "not an object at all"              cat instance-string.json
show "jsonschema (Python): uncovered keyword"     jsonschema-validate --schema schema-per-keyword.json --instance instance-string.json
show "ajv (JavaScript): uncovered keyword"        ajv-validate        --schema schema-per-keyword.json --instance instance-string.json

exit 0
