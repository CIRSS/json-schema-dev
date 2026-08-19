#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 09: schemas in schema position"

doc "additionalProperties: the schema for the extra properties" << 'END_DOC'
"additionalProperties" gives the schema that every extra property of an
object must satisfy -- extra meaning any property that "properties" does not
name. The schema below names one string property, "a", and requires every
other property to be a number. It is checked against two instances identical
except for the type of "b": the verdict turns on that one difference.
END_DOC

show "extras must be numbers"                     cat schema-number.json
show "extra b is a number"                        cat instance-number.json
show "jsonschema (Python): extra b is a number"   jsonschema-validate --schema schema-number.json --instance instance-number.json
show "ajv (JavaScript): extra b is a number"      ajv-validate        --schema schema-number.json --instance instance-number.json

show "extra b is a string"                        cat instance-string.json
show "jsonschema (Python): extra b is a string"   jsonschema-validate --schema schema-number.json --instance instance-string.json
show "ajv (JavaScript): extra b is a string"      ajv-validate        --schema schema-number.json --instance instance-string.json

doc "false, true, and {} in the same position" << 'END_DOC'
Because the value is a schema, true and false can stand in this position
too, and they mean what demo 01 showed: false rejects every extra property,
so any object with one is rejected; true accepts every extra property; and
{} behaves exactly as true does. Below, one instance with an extra property
is checked against these three schemas, which differ only in the value of
"additionalProperties".
END_DOC

show "the instance"                                   cat instance-number.json

show "extras forbidden (additionalProperties false)"  cat schema-false.json
show "jsonschema (Python): extras forbidden"          jsonschema-validate --schema schema-false.json  --instance instance-number.json
show "ajv (JavaScript): extras forbidden"             ajv-validate        --schema schema-false.json  --instance instance-number.json

show "extras allowed (additionalProperties true)"     cat schema-true.json
show "jsonschema (Python): extras allowed"            jsonschema-validate --schema schema-true.json   --instance instance-number.json
show "ajv (JavaScript): extras allowed"               ajv-validate        --schema schema-true.json   --instance instance-number.json

show "extras allowed (additionalProperties {})"       cat schema-empty.json
show "jsonschema (Python): extras allowed, {}"        jsonschema-validate --schema schema-empty.json  --instance instance-number.json
show "ajv (JavaScript): extras allowed, {}"           ajv-validate        --schema schema-empty.json  --instance instance-number.json

exit 0
