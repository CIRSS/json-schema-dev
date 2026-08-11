#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "what \$id is for" << 'END_DOC'
$id declares the identity of a schema — a URI that names it. It is an
identifier, not a location: nothing is ever fetched from it, and it may
point at a host that does not exist.

Its only job is to be the base URI that $ref values resolve against. So a
schema whose $refs are all fragment-only, like #/$defs/named, never
consults its $id at all, and can carry one, or not, with no difference in
behaviour. The first two schemas below make that concrete.

Every instance in this demo is the same object, so that only the schema's
identifiers vary.
END_DOC

show "the instance"  cat instance.json

doc "inert: an \$id that nothing resolves against" << 'END_DOC'
Two schemas, identical but for the presence of an $id — and that $id names
a host that could not be reached even if something tried. Same verdict.
END_DOC

show "no \$id at all"                          cat schema-no-id.json
show "jsonschema (Python): no \$id"            jsonschema-validate --schema schema-no-id.json --instance instance.json
show "ajv (JavaScript): no \$id"               ajv-validate        --schema schema-no-id.json --instance instance.json

show "an \$id at an unreachable URI"           cat schema-unreachable-id.json
show "jsonschema (Python): unreachable \$id"   jsonschema-validate --schema schema-unreachable-id.json --instance instance.json
show "ajv (JavaScript): unreachable \$id"      ajv-validate        --schema schema-unreachable-id.json --instance instance.json

doc "load-bearing: naming a subschema so \$ref can address it" << 'END_DOC'
An $id inside $defs does something different: it declares that subschema to
be a schema resource in its own right, with its own identity, which $ref
can then target by URI instead of by JSON Pointer.

$anchor does the same job more cheaply. It attaches a plain-name fragment
to a subschema without making it a separate resource, reached as #named.

Both schemas below constrain a to be a number, so the string instance is
rejected — which is how you can tell the reference resolved rather than
being quietly skipped. A $ref that went nowhere would not produce this.
END_DOC

show "\$id on the subschema, \$ref by URI"      cat schema-subschema-id.json
show "jsonschema (Python): \$ref by URI"        jsonschema-validate --schema schema-subschema-id.json --instance instance.json
show "ajv (JavaScript): \$ref by URI"           ajv-validate        --schema schema-subschema-id.json --instance instance.json

show "\$anchor, \$ref by plain name"            cat schema-anchor.json
show "jsonschema (Python): \$ref by anchor"     jsonschema-validate --schema schema-anchor.json --instance instance.json
show "ajv (JavaScript): \$ref by anchor"        ajv-validate        --schema schema-anchor.json --instance instance.json

doc "the footgun: a relative \$ref against an \$id" << 'END_DOC'
Here is why $id is worth understanding even when you are not composing
across documents. The schema below declares an $id and then writes $ref as
the bare word "named", intending the $def of that name.

It is not a fragment, so it is not looked up inside the document. It is a
relative URI reference, resolved against the $id — yielding
https://example.org/schemas/named, a document neither validator has and
neither will go looking for. The $def sitting right there is never
consulted.

Both report it as an error rather than a verdict, and exit 2. Note that the
two disagree about when they notice: Ajv resolves references while
compiling the schema and calls it an invalid schema, whereas jsonschema
resolves lazily during validation, so the failure arrives later and is
described differently. Same conclusion, different stage.
END_DOC

show "a relative \$ref"                        cat schema-relative-ref.json
show "jsonschema (Python): relative \$ref"     jsonschema-validate --schema schema-relative-ref.json --instance instance.json
show "ajv (JavaScript): relative \$ref"        ajv-validate        --schema schema-relative-ref.json --instance instance.json

exit 0
