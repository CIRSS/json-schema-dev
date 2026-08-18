#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 08: schemas in schema position"

doc "additionalProperties holds a schema, not a flag" << 'END_DOC'
Demo 01 showed that true and false are schemas. This demo shows where that
fact is actually used, and why the language bothers to have it.

additionalProperties takes a schema and applies it to each property that
properties and patternProperties did not match. So additionalProperties:
false says "no extra property can validate," and therefore none may appear;
additionalProperties: true says "every extra property validates," and all
may appear. Both read like flag syntax. Neither is: they are ordinary
schemas sitting in a schema-valued slot, and by demo 01's equivalence, {}
in that slot would behave exactly as true does.

Draft-04 specified this keyword as taking "a boolean or a schema" — a
genuine special case in the grammar. Making booleans schemas removed it.

Two comparisons follow. In the first, one instance is checked against three
schemas that differ only in the value of additionalProperties. In the
second, one schema is checked against two instances that differ only in the
type of the extra property.
END_DOC

show "the instance"  cat instance-number.json

show "extras forbidden (additionalProperties false)"  cat schema-false.json
show "jsonschema (Python): extras forbidden"          jsonschema-validate --schema schema-false.json  --instance instance-number.json
show "ajv (JavaScript): extras forbidden"             ajv-validate        --schema schema-false.json  --instance instance-number.json

show "extras allowed (additionalProperties true)"     cat schema-true.json
show "jsonschema (Python): extras allowed"            jsonschema-validate --schema schema-true.json   --instance instance-number.json
show "ajv (JavaScript): extras allowed"               ajv-validate        --schema schema-true.json   --instance instance-number.json

doc "the proof that it is a schema" << 'END_DOC'
A flag has two settings. If the slot really holds a schema, a non-boolean
one must work there too — and must constrain the extra properties rather
than merely permitting or forbidding them.

The schema below allows extras but requires them to be numbers. It is then
checked against two instances identical except for the type of b. The
verdict turns on that one difference, which is not something a flag could
express.
END_DOC

show "extras must be numbers"                     cat schema-number.json
show "extra b is a number"                        cat instance-number.json
show "jsonschema (Python): extra b is a number"   jsonschema-validate --schema schema-number.json --instance instance-number.json
show "ajv (JavaScript): extra b is a number"      ajv-validate        --schema schema-number.json --instance instance-number.json

show "extra b is a string"                        cat instance-string.json
show "jsonschema (Python): extra b is a string"   jsonschema-validate --schema schema-number.json --instance instance-string.json
show "ajv (JavaScript): extra b is a string"      ajv-validate        --schema schema-number.json --instance instance-string.json

exit 0
