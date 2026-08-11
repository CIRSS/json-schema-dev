#!/usr/bin/env bash
#
# Floor case: empty vs minimally-nonempty array. minItems:1 rejects the empty
# array and accepts a one-element array — the boundary many tools get wrong.

show() {
    local title="$1"; shift
    printf '\n===== %s =====\n\n$ %s\n' "$title" "$*"
    "$@"
}

show "the schema (array, minItems 1)"  cat schema.json
show "the empty array"                 cat instance-empty.json
show "a one-element array"             cat instance-one.json

show "jsonschema (Python): empty array"        jsonschema-validate --schema schema.json --instance instance-empty.json
show "ajv (JavaScript): empty array"           ajv-validate        --schema schema.json --instance instance-empty.json

show "jsonschema (Python): one-element array"  jsonschema-validate --schema schema.json --instance instance-one.json
show "ajv (JavaScript): one-element array"     ajv-validate        --schema schema.json --instance instance-one.json

exit 0
