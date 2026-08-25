#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 21: duplicate member names"

doc "duplicate member names vanish before any schema can see them" << 'END_DOC'
JSON's grammar does not forbid an object from repeating a member name --
RFC 8259 says only that names SHOULD be unique -- and parsers cope by
silently keeping the last value. The consequence for validation is
absolute: every JSON Schema validator receives the already-parsed value,
so {"a": 1, "a": 2} and {"a": 2} are indistinguishable to every schema
ever written. No keyword can reject what the parser has already erased.

The instance below carries the same member twice with divergent values.
The schema asserts that a equals 2 -- and both validators say VALID,
proving it is the last value, not the first, that survived parsing. A
document whose author may well have meant a to be 1 sails through.

Parse time is the only tier that can still see the duplication, so the
wrappers offer --reject-duplicate-members: with the flag, a duplicate
member name anywhere in the instance is a verdict, not tolerated noise.
Every duplicate name is collected and reported sorted, one line per name,
so the two wrappers emit word-for-word identical output -- authored
uniformity in the same family as demo 19. Data models built atop JSON
often require what JSON merely recommends: JSON-LD's maps must have
unique keys, so a JSON-LD checking pipeline turns this flag on.

The two verdict pairs below differ in exactly one way: the flag.
END_DOC

show "an instance with a duplicate member"     cat instance-duplicate.json
show "the schema (a must equal 2)"             cat schema-last-wins.json
show "jsonschema (Python): without the flag"   jsonschema-validate --schema schema-last-wins.json --instance instance-duplicate.json
show "ajv (JavaScript): without the flag"      ajv-validate        --schema schema-last-wins.json --instance instance-duplicate.json
show "jsonschema (Python): with the flag"      jsonschema-validate --schema schema-last-wins.json --instance instance-duplicate.json --reject-duplicate-members
show "ajv (JavaScript): with the flag"         ajv-validate        --schema schema-last-wins.json --instance instance-duplicate.json --reject-duplicate-members

exit 0
