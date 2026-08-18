#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 10: annotated constants"

doc "two ways to say 'one of these exact values'" << 'END_DOC'
A fixed set of allowed values is usually written as an enum. There is a
second way to write it: oneOf over subschemas that each pin a single
value with const. The two schemas below define the same set — draft and
final — and the demo's first job is to show they accept and reject
exactly the same values: every verdict that follows agrees across both
schemas and both validators.

What the oneOf form buys is a place to put prose. An enum is a bare
list; a const subschema is a schema, so each value can carry its own
description saying what choosing it means. The documentation lives next to
the value it documents and travels with the schema into editors, viewers,
and generated docs.
END_DOC

show "the enum schema"                   cat schema-enum.json
show "the annotated oneOf schema"        cat schema-oneof.json

show "a value in the set"                cat instance-known.json
show "jsonschema (Python): enum, known"           jsonschema-validate --schema schema-enum.json  --instance instance-known.json
show "ajv (JavaScript): enum, known"              ajv-validate        --schema schema-enum.json  --instance instance-known.json
show "jsonschema (Python): oneOf, known"          jsonschema-validate --schema schema-oneof.json --instance instance-known.json
show "ajv (JavaScript): oneOf, known"             ajv-validate        --schema schema-oneof.json --instance instance-known.json

doc "the same rejection, at different levels of detail" << 'END_DOC'
A value outside the set, against both schemas. All four runs reject it, so
the two forms really are interchangeable. The error output is where they
part: the enum failure can name the allowed list in
one line, while the oneOf failure reports each branch's disappointment
separately before concluding. That verbosity is the cost of the annotated
form, and a message map or report layer pays it, not the schema author.
END_DOC

show "a value outside the set"           cat instance-unknown.json
show "jsonschema (Python): enum, unknown"         jsonschema-validate --schema schema-enum.json  --instance instance-unknown.json
show "ajv (JavaScript): enum, unknown"            ajv-validate        --schema schema-enum.json  --instance instance-unknown.json
show "jsonschema (Python): oneOf, unknown"        jsonschema-validate --schema schema-oneof.json --instance instance-unknown.json
show "ajv (JavaScript): oneOf, unknown"           ajv-validate        --schema schema-oneof.json --instance instance-unknown.json

exit 0
