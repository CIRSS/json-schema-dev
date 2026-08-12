#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "pattern is how a string's shape is enforced" << 'END_DOC'
The previous demo established that format annotates and pattern asserts, so
any string shape that must hold — an identifier, a hex digest, a timestamp
— ends up as a regular expression under pattern. This demo is about the two
ways that goes wrong.

The first pair of schemas differ in exactly one thing: anchors. pattern
matches anywhere in the string unless anchored — a substring hit is enough.
The instances are a four-digit hex string and the same four digits buried
in the middle of other text.
END_DOC

show "the unanchored schema"             cat schema-unanchored.json
show "the anchored schema"               cat schema-anchored.json

show "the hex string"                    cat instance-hex.json
show "jsonschema (Python): unanchored, hex"       jsonschema-validate --schema schema-unanchored.json --instance instance-hex.json
show "ajv (JavaScript): unanchored, hex"          ajv-validate        --schema schema-unanchored.json --instance instance-hex.json

show "hex buried in other text"          cat instance-embedded.json
show "jsonschema (Python): unanchored, embedded"  jsonschema-validate --schema schema-unanchored.json --instance instance-embedded.json
show "ajv (JavaScript): unanchored, embedded"     ajv-validate        --schema schema-unanchored.json --instance instance-embedded.json

doc "anchoring closes the loophole" << 'END_DOC'
The same two instances against the anchored schema. The buried hex is now
rejected: ^ and $ pin the match to the whole string. Write every pattern
anchored unless a substring match is genuinely what you mean — an
unanchored pattern asserts far less than it appears to.
END_DOC

show "jsonschema (Python): anchored, hex"         jsonschema-validate --schema schema-anchored.json --instance instance-hex.json
show "ajv (JavaScript): anchored, hex"            ajv-validate        --schema schema-anchored.json --instance instance-hex.json
show "jsonschema (Python): anchored, embedded"    jsonschema-validate --schema schema-anchored.json --instance instance-embedded.json
show "ajv (JavaScript): anchored, embedded"       ajv-validate        --schema schema-anchored.json --instance instance-embedded.json

doc "even an anchored pattern is read by two different engines" << 'END_DOC'
The next instance differs from the hex string in one character: a trailing
newline. The anchored schema is unchanged. The two validators now disagree
— Python's regex engine lets $ match just before a trailing newline, a
convenience inherited from line-oriented text processing, while
JavaScript's $ means the true end of the string.

The standard says patterns SHOULD conform to ECMA-262, but validators use
their host language's engine, and this is what that latitude costs: the
same schema, the same instance, and two defensible verdicts. A string field
populated from a file or a shell command is exactly where a trailing
newline arrives.
END_DOC

show "hex with a trailing newline"       cat instance-trailing-newline.json
show "jsonschema (Python): trailing newline"      jsonschema-validate --schema schema-anchored.json --instance instance-trailing-newline.json
show "ajv (JavaScript): trailing newline"         ajv-validate        --schema schema-anchored.json --instance instance-trailing-newline.json

doc "a regex dialect the engines do not share" << 'END_DOC'
The last schema spells the same intent — hex digits only — with a POSIX
character class, [[:xdigit:]], a form many tools accept but ECMA-262 does
not define. Against the plain hex string, the validators do not just
disagree on the verdict; they disagree on what is wrong. Ajv rejects the
schema itself as an invalid regular expression. Python accepts the schema,
silently reads [[:xdigit:]] as a character class containing the literal
characters it spells, warns only that the bracket nesting looks suspicious,
and then rejects a perfectly good hex string for the wrong reason.

A pattern that validates in one engine and means something else in another
is the sharpest failure mode this module exists to catch. Write patterns in
the portable ECMA-262 subset — explicit character ranges like [0-9a-f],
and the escapes \d, \s, \w — and cross-validate them.
END_DOC

show "the POSIX-class schema"            cat schema-posix.json
show "jsonschema (Python): POSIX class, hex"      jsonschema-validate --schema schema-posix.json --instance instance-hex.json
show "ajv (JavaScript): POSIX class, hex"         ajv-validate        --schema schema-posix.json --instance instance-hex.json

exit 0
