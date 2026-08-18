#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 18: non json instances"

doc "a non-JSON document gets a verdict, not an error" << 'END_DOC'
The wrappers separate facts about the submitted document from facts about
the setup. Everything about the instance is a verdict: VALID (exit 0) or
INVALID (exit 1). Everything else -- bad arguments, unreadable files, a
broken schema -- is an operational error (exit 2, message on stderr).

A document that was delivered but does not parse sits on the verdict side
of that line. Validation is layered grammars -- JSON itself first, then
the shapes a schema asserts over it -- and a document failing the first
tier is invalid, not a malfunction of the validator. Both wrappers report
it with the same first phrase; the parser detail that follows is each
library's own, divergent like all message prose.

The schema here is {} on purpose: this verdict owes nothing to any schema.

A missing file, by contrast, is operational -- nothing was delivered to be
judged -- and remains an error. The two probe pairs below differ in
exactly one way: whether the named instance file exists.
END_DOC

show "the schema (vacuous)"                cat schema-empty.json
show "a truncated document"                cat instance-truncated.json
show "jsonschema (Python): not JSON"       jsonschema-validate --schema schema-empty.json --instance instance-truncated.json
show "ajv (JavaScript): not JSON"          ajv-validate        --schema schema-empty.json --instance instance-truncated.json
show "jsonschema (Python): missing file"   jsonschema-validate --schema schema-empty.json --instance no-such-file.json
show "ajv (JavaScript): missing file"      ajv-validate        --schema schema-empty.json --instance no-such-file.json

exit 0
