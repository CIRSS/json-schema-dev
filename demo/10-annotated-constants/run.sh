#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 10: annotated constants"

doc "two ways to say 'one of these exact values'" << 'END_DOC'
A fixed set of allowed values is usually written as an "enum": a list of
JSON values of any kinds -- strings, numbers, objects, null -- satisfied by
an instance equal to any one of them. The same set can be written as a
"oneOf" whose entries each hold a "const" -- the keyword satisfied only by
one exact JSON value -- one entry per allowed value. The two schemas below
both allow exactly the strings "draft" and "final", and every verdict that
follows agrees across both schemas and both validators.

What the "oneOf" form adds is a place for a description of each value. An
"enum" can carry a "description" for the whole list but not for its
members; each entry of a "oneOf" is a schema, so each can carry its own
"description" saying what choosing that value means. The documentation
sits next to the value it documents, inside the schema.
END_DOC

show "the enum schema"                   cat schema-enum.json
show "the annotated oneOf schema"        cat schema-oneof.json

show "a value in the set"                cat instance-known.json
show "jsonschema (Python): enum, known"           jsonschema-validate --schema schema-enum.json  --instance instance-known.json
show "ajv (JavaScript): enum, known"              ajv-validate        --schema schema-enum.json  --instance instance-known.json
show "jsonschema (Python): oneOf, known"          jsonschema-validate --schema schema-oneof.json --instance instance-known.json
show "ajv (JavaScript): oneOf, known"             ajv-validate        --schema schema-oneof.json --instance instance-known.json

doc "the same rejection, at different lengths" << 'END_DOC'
A value outside the set is rejected by both schemas in both validators.
The reports differ in length. For the "enum", each validator gives one
line (Python's names the allowed values; Ajv's does not). For the "oneOf",
Python again gives one line, while Ajv reports each entry's failure
separately and then the summary. The longer report is the cost of the
annotated form; demo 19 shows how a schema can supply its own message in
place of the validator's.
END_DOC

show "a value outside the set"           cat instance-unknown.json
show "jsonschema (Python): enum, unknown"         jsonschema-validate --schema schema-enum.json  --instance instance-unknown.json
show "ajv (JavaScript): enum, unknown"            ajv-validate        --schema schema-enum.json  --instance instance-unknown.json
show "jsonschema (Python): oneOf, unknown"        jsonschema-validate --schema schema-oneof.json --instance instance-unknown.json
show "ajv (JavaScript): oneOf, unknown"           ajv-validate        --schema schema-oneof.json --instance instance-unknown.json

doc "values of any kind" << 'END_DOC'
The values in an "enum" need not be strings, and an instance matches by
JSON equality: the number 2 is in the list below and the string "2" is not.
(The "oneOf" form naturally provides the same capability, since each
"const" holds any JSON value.)
END_DOC

show "an enum of a number, a string, and null"    cat schema-enum-mixed.json
show "the number 2"                               cat instance-number-two.json
show "jsonschema (Python): mixed, number 2"       jsonschema-validate --schema schema-enum-mixed.json --instance instance-number-two.json
show "ajv (JavaScript): mixed, number 2"          ajv-validate        --schema schema-enum-mixed.json --instance instance-number-two.json
show "the string 2"                               cat instance-string-two.json
show "jsonschema (Python): mixed, string 2"       jsonschema-validate --schema schema-enum-mixed.json --instance instance-string-two.json
show "ajv (JavaScript): mixed, string 2"          ajv-validate        --schema schema-enum-mixed.json --instance instance-string-two.json

exit 0
