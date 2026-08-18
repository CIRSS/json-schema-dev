#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 11: tagged unions"

doc "a discriminator property selects which constraints apply" << 'END_DOC'
Records that come in variants usually carry a tag naming which variant this
is — here, kind — with the rest of the record's shape depending on it.
if/then/else expresses that: if is a schema, and whether the instance
matches it decides whether then or else applies. The schema below requires
a radius of circles and a side of everything else.

The three instances vary one thing at a time: a circle with its radius, a
circle carrying a side instead, and a square with its side.
END_DOC

show "the schema (circles need radius, others side)"  cat schema-union.json

show "a circle with a radius"            cat instance-circle.json
show "jsonschema (Python): circle"                jsonschema-validate --schema schema-union.json --instance instance-circle.json
show "ajv (JavaScript): circle"                   ajv-validate        --schema schema-union.json --instance instance-circle.json

show "a circle with a side instead"      cat instance-circle-side.json
show "jsonschema (Python): circle with side"      jsonschema-validate --schema schema-union.json --instance instance-circle-side.json
show "ajv (JavaScript): circle with side"         ajv-validate        --schema schema-union.json --instance instance-circle-side.json

show "a square with a side"              cat instance-square.json
show "jsonschema (Python): square"                jsonschema-validate --schema schema-union.json --instance instance-square.json
show "ajv (JavaScript): square"                   ajv-validate        --schema schema-union.json --instance instance-square.json

doc "the if schema must require its own discriminator" << 'END_DOC'
The trap in this construct comes from demo 02: properties does not make a
property required, and that holds inside an if schema too. The two schemas
below differ in exactly one place — whether the if schema also carries
required: ["kind"] — and the instance is the empty object, which carries no
discriminator at all.

Without the required, the empty object satisfies the if vacuously (kind is
absent, so its const is never tested), then is applied, and the instance is
rejected for lacking a radius it was never obliged to have. With it, the if
fails, no branch applies, and the empty object passes — deciding nothing
about records that do not claim to be circles.
END_DOC

show "if without required kind"          cat schema-loose-if.json
show "if with required kind"             cat schema-strict-if.json

show "the empty object"                  cat instance-empty.json
show "jsonschema (Python): loose if"              jsonschema-validate --schema schema-loose-if.json  --instance instance-empty.json
show "ajv (JavaScript): loose if"                 ajv-validate        --schema schema-loose-if.json  --instance instance-empty.json
show "jsonschema (Python): strict if"             jsonschema-validate --schema schema-strict-if.json --instance instance-empty.json
show "ajv (JavaScript): strict if"                ajv-validate        --schema schema-strict-if.json --instance instance-empty.json

exit 0
