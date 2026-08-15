#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "a declared version is honored or refused, never reinterpreted" << 'END_DOC'
JSON Schema has evolved through several versions, and a schema may
declare the one it targets in its top-level "$schema" entry (demo 01).
These commands implement 2020-12 only, and a schema declaring any other
version is refused. The declaration states which semantics its author
wrote for, and old constructs can change meaning silently under new
semantics: a draft-07 author's "definitions" and "dependencies" are
merely unknown members to 2020-12 -- ignored -- so constraints the
author wrote would simply stop constraining. No verdict from a
reinterpreted schema can be trusted, so no verdict is rendered.

The refusal has an override. --ignore-declared-version discards the
declaration and validates as 2020-12 anyway -- the same
reinterpretation, but chosen explicitly rather than performed silently.
It exists for deliberately probing schemas written for other versions.

The two command pairs below differ in exactly one way: the flag.
END_DOC

show "the instance"                              cat instance.json
show "a schema declaring draft-07"               cat schema-draft7.json
show "jsonschema (Python): declared version"     jsonschema-validate --schema schema-draft7.json --instance instance.json
show "ajv (JavaScript): declared version"        ajv-validate        --schema schema-draft7.json --instance instance.json
show "jsonschema (Python): with the override"    jsonschema-validate --schema schema-draft7.json --instance instance.json --ignore-declared-version
show "ajv (JavaScript): with the override"       ajv-validate        --schema schema-draft7.json --instance instance.json --ignore-declared-version

exit 0
