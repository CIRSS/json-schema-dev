#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "unevaluatedProperties closes over allOf" << 'END_DOC'
An object schema is "closed" when it rejects properties it did not declare.
The obvious way to close one is additionalProperties: false — but that
keyword only sees the properties declared in its own schema object. It is
blind to properties contributed through allOf, so on a composed schema it
rejects everything the branches introduced.

unevaluatedProperties: false is the keyword that sees through composition.
It runs after the branches and rejects only what no evaluated subschema
claimed. That makes it the construct closure rests on whenever a schema is
assembled from parts rather than written flat.

Both validators below are pinned to JSON Schema 2020-12. The keyword was
introduced in 2019-09: a draft-07 validator does not know it, and unknown
keywords are ignored rather than rejected, so the same schema silently
fails open — the invalid instance would pass.
END_DOC

show "the schema"  cat schema.json

doc "what to watch for" << 'END_DOC'
Property "c" appears in no allOf branch. The valid instance omits it and
passes; the invalid instance carries it and is rejected by both validators,
in different words but with the same verdict.
END_DOC

show "the valid instance"                     cat instance-valid.json
show "jsonschema (Python): valid instance"    jsonschema-validate --schema schema.json --instance instance-valid.json
show "ajv (JavaScript): valid instance"       ajv-validate        --schema schema.json --instance instance-valid.json

show "the invalid instance"                   cat instance-invalid.json
show "jsonschema (Python): invalid instance"  jsonschema-validate --schema schema.json --instance instance-invalid.json
show "ajv (JavaScript): invalid instance"     ajv-validate        --schema schema.json --instance instance-invalid.json

doc "what if a or b is left out?" << 'END_DOC'
Nothing rejects them. unevaluatedProperties governs which properties may
appear, not which must — and properties is likewise a conditional: it says
"if this key is present, here is its shape." Neither keyword makes anything
mandatory. Only required does that, and this schema has no required.

So the schema closes the object without populating it: omit b, or omit
both, and it still validates. The empty object passes a schema that reads
at a glance as describing two string properties.

That is the pairing to remember. unevaluatedProperties: false answers "may
anything else appear?"; required answers "must these appear?" A closed
schema with no required is closed and empty-able at the same time, which is
almost never what the author meant. See demo 04 for the same trap without
the composition.
END_DOC

show "only a"                                 cat instance-only-a.json
show "jsonschema (Python): only a"            jsonschema-validate --schema schema.json --instance instance-only-a.json
show "ajv (JavaScript): only a"               ajv-validate        --schema schema.json --instance instance-only-a.json

show "neither a nor b"                        cat instance-empty.json
show "jsonschema (Python): neither a nor b"   jsonschema-validate --schema schema.json --instance instance-empty.json
show "ajv (JavaScript): neither a nor b"      ajv-validate        --schema schema.json --instance instance-empty.json

exit 0
