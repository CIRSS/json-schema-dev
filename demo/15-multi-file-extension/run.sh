#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "a base schema in its own file, validating on its own" << 'END_DOC'
Everything so far lived in one file. This demo splits a schema across two:
a base that stands alone, and an overlay that extends it. The base below
declares an id property and requires it — and nothing more. It is
deliberately open: no closure, no opinion about members it does not name.

Four instances run against it, varying one thing at a time: the minimal
record; the same record with a stray member; the record with a status
member the base never mentions; and both additions at once. The base
accepts all four — openness is not an oversight here but the property that
makes the base extendable, and every verdict that follows is evidence of
what the overlay adds, not something the base already did.
END_DOC

show "the base schema"                   cat base.json

show "the minimal record"                cat instance-minimal.json
show "jsonschema (Python): base, minimal"         jsonschema-validate --schema base.json --instance instance-minimal.json
show "ajv (JavaScript): base, minimal"            ajv-validate        --schema base.json --instance instance-minimal.json

show "with a stray member"               cat instance-stray.json
show "jsonschema (Python): base, stray"           jsonschema-validate --schema base.json --instance instance-stray.json
show "ajv (JavaScript): base, stray"              ajv-validate        --schema base.json --instance instance-stray.json

show "with a status"                     cat instance-full.json
show "jsonschema (Python): base, status"          jsonschema-validate --schema base.json --instance instance-full.json
show "ajv (JavaScript): base, status"             ajv-validate        --schema base.json --instance instance-full.json

show "with status and a stray member"    cat instance-full-stray.json
show "jsonschema (Python): base, both"            jsonschema-validate --schema base.json --instance instance-full-stray.json
show "ajv (JavaScript): base, both"               ajv-validate        --schema base.json --instance instance-full-stray.json

doc "an overlay that extends the base and closes over the union" << 'END_DOC'
The overlay references the base by its $id (demo 12), adds its own
requirement under allOf (demo 11), and closes the whole with
unevaluatedProperties: false — which sees through both the allOf and the
$ref (demos 13 and 14), so properties declared by the base count as
evaluated. Each validator needs to be handed the base file explicitly
(--ref); the $id is a name to resolve against, not a URL anyone fetches.

The same four instances, in the same order. The minimal record now fails
for lacking status; the stray member now fails closure; the record with
status passes; status plus a stray member fails closure alone. Everything
the base accepted and the overlay rejects is the overlay's doing — the
base file is untouched, still open, and still valid on its own. That is
the extension contract: a base schema usable standalone, and stricter
profiles layered on it by reference, each in its own file.
END_DOC

show "the overlay schema"                cat overlay.json

show "jsonschema (Python): overlay, minimal"      jsonschema-validate --schema overlay.json --ref base.json --instance instance-minimal.json
show "ajv (JavaScript): overlay, minimal"         ajv-validate        --schema overlay.json --ref base.json --instance instance-minimal.json
show "jsonschema (Python): overlay, stray"        jsonschema-validate --schema overlay.json --ref base.json --instance instance-stray.json
show "ajv (JavaScript): overlay, stray"           ajv-validate        --schema overlay.json --ref base.json --instance instance-stray.json
show "jsonschema (Python): overlay, status"       jsonschema-validate --schema overlay.json --ref base.json --instance instance-full.json
show "ajv (JavaScript): overlay, status"          ajv-validate        --schema overlay.json --ref base.json --instance instance-full.json
show "jsonschema (Python): overlay, both"         jsonschema-validate --schema overlay.json --ref base.json --instance instance-full-stray.json
show "ajv (JavaScript): overlay, both"            ajv-validate        --schema overlay.json --ref base.json --instance instance-full-stray.json

doc "the overlay is not self-contained, and says so" << 'END_DOC'
One last run, differing from the passing case in one way: the --ref is
omitted. Both validators refuse — an error, not a verdict — because the
overlay's $ref now resolves to nothing. They refuse at their usual
different moments (demo 11): Ajv while compiling, jsonschema during
validation. A multi-file schema is a set of files that must travel
together, and the error is the reminder.
END_DOC

show "jsonschema (Python): overlay without --ref" jsonschema-validate --schema overlay.json --instance instance-full.json
show "ajv (JavaScript): overlay without --ref"    ajv-validate        --schema overlay.json --instance instance-full.json

exit 0
