#!/usr/bin/env bash
#
# Floor case: degenerate schemas. The empty schema {} and the boolean schema
# true accept every instance; the boolean schema false rejects every instance.
# The instance is null — itself a floor value many tools mishandle. The
# wrappers pin JSON Schema 2020-12, so these schemas need no $schema of their own.

show() {
    local title="$1"; shift
    printf '\n===== %s =====\n\n$ %s\n' "$title" "$*"
    "$@"
}

show "empty schema (accepts anything)"          cat schema-any.json
show "boolean schema true (accepts anything)"   cat schema-true.json
show "boolean schema false (rejects anything)"  cat schema-false.json
show "the instance"                             cat instance.json

show "jsonschema (Python): null vs empty schema"   jsonschema-validate --schema schema-any.json   --instance instance.json
show "ajv (JavaScript): null vs empty schema"      ajv-validate        --schema schema-any.json   --instance instance.json

show "jsonschema (Python): null vs schema true"    jsonschema-validate --schema schema-true.json  --instance instance.json
show "ajv (JavaScript): null vs schema true"       ajv-validate        --schema schema-true.json  --instance instance.json

show "jsonschema (Python): null vs schema false"   jsonschema-validate --schema schema-false.json --instance instance.json
show "ajv (JavaScript): null vs schema false"      ajv-validate        --schema schema-false.json --instance instance.json

exit 0
