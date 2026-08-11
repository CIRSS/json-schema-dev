#!/usr/bin/env bash
#
# unevaluatedProperties:false closing over allOf, validated identically by a
# Python (jsonschema) and a JavaScript (Ajv) validator, both at JSON Schema
# 2020-12. Each cell shows a title, the command you would type, and its
# output; the two validators agree on both the valid and the invalid instance.

show() {
    local title="$1"; shift
    printf '\n===== %s =====\n\n$ %s\n' "$title" "$*"
    "$@"
}

show "the schema"            cat schema.json
show "the valid instance"    cat instance-valid.json
show "the invalid instance"  cat instance-invalid.json

show "jsonschema (Python): valid instance"    jsonschema-validate --schema schema.json --instance instance-valid.json
show "ajv (JavaScript): valid instance"       ajv-validate        --schema schema.json --instance instance-valid.json

show "jsonschema (Python): invalid instance"  jsonschema-validate --schema schema.json --instance instance-invalid.json
show "ajv (JavaScript): invalid instance"     ajv-validate        --schema schema.json --instance instance-invalid.json

exit 0
