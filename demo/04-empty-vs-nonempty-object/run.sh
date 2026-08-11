#!/usr/bin/env bash
#
# Floor case: empty vs minimally-nonempty object. required:["id"] rejects the
# empty object and accepts an object carrying just that one property.

show() {
    local title="$1"; shift
    printf '\n===== %s =====\n\n$ %s\n' "$title" "$*"
    "$@"
}

show "the schema (object, required id)"  cat schema.json
show "the empty object"                  cat instance-empty.json
show "the minimal object"                cat instance-min.json

show "jsonschema (Python): empty object"    jsonschema-validate --schema schema.json --instance instance-empty.json
show "ajv (JavaScript): empty object"       ajv-validate        --schema schema.json --instance instance-empty.json

show "jsonschema (Python): minimal object"  jsonschema-validate --schema schema.json --instance instance-min.json
show "ajv (JavaScript): minimal object"     ajv-validate        --schema schema.json --instance instance-min.json

exit 0
