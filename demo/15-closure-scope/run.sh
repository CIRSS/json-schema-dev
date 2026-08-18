#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 15: closure scope"

doc "how far does closure reach?" << 'END_DOC'
Demo 14 showed unevaluatedProperties: false closing an object over allOf.
That raises the question this demo answers: how far does "evaluated" reach?
Not the whole document, and not the whole schema. The unit is one instance
location together with the keywords that apply at that same location — the
in-place applicators: allOf, anyOf, oneOf, if/then/else, and $ref.

Two consequences follow, and they pull in opposite directions. Closure
reaches further sideways than expected, through $ref into a named $def. It
reaches less far downward than expected — not at all, in fact, into a
nested object.
END_DOC

doc "sideways: through \$ref" << 'END_DOC'
$defs holds named subschemas and $ref invokes one — the closest thing JSON
Schema has to a named production. The two schemas below are identical
except for the closing keyword, and property a is declared only inside the
$def. The verdicts disagree.

$ref is an in-place applicator: it applies to the same instance location as
the schema containing it, so the properties annotation it produces is
visible to unevaluatedProperties. additionalProperties reads only the
properties and patternProperties declared as its own siblings, and there
are none here — so from where it sits, a is an addition.

This is what makes unevaluatedProperties the keyword that composes. A
schema built from named parts can only be closed by something that can see
what the parts claimed.
END_DOC

show "the instance"  cat instance.json

show "closing with unevaluatedProperties"                cat schema-unevaluated.json
show "jsonschema (Python): unevaluatedProperties"        jsonschema-validate --schema schema-unevaluated.json --instance instance.json
show "ajv (JavaScript): unevaluatedProperties"           ajv-validate        --schema schema-unevaluated.json --instance instance.json

show "closing with additionalProperties"                 cat schema-additional.json
show "jsonschema (Python): additionalProperties"         jsonschema-validate --schema schema-additional.json  --instance instance.json
show "ajv (JavaScript): additionalProperties"            ajv-validate        --schema schema-additional.json  --instance instance.json

doc "downward: not at all" << 'END_DOC'
The other direction is the one that costs people data. unevaluatedProperties
at the root closes the root object and nothing beneath it. A nested object
sits at a different instance location, so the root's closure has no opinion
about its contents; only a closure declared inside that subschema does.

One instance is checked against two schemas below. Both close the root and
both declare inner the same way; they differ in exactly one place, whether
the subschema for inner also closes itself. The instance gives inner an
undeclared property y.

Showing only the first schema would demonstrate nothing: y surviving could
be explained by the closure not working at all. The pair is what locates
the effect — same instance, same root closure, verdict turning solely on
where the inner closure is declared.
END_DOC

show "the instance"  cat instance-nested.json

show "root closed, inner open"                    cat schema-nested.json
show "jsonschema (Python): inner open"            jsonschema-validate --schema schema-nested.json        --instance instance-nested.json
show "ajv (JavaScript): inner open"               ajv-validate        --schema schema-nested.json        --instance instance-nested.json

show "root closed, inner closed too"              cat schema-nested-closed.json
show "jsonschema (Python): inner closed"          jsonschema-validate --schema schema-nested-closed.json --instance instance-nested.json
show "ajv (JavaScript): inner closed"             ajv-validate        --schema schema-nested-closed.json --instance instance-nested.json

doc "so closure is a per-object obligation" << 'END_DOC'
Not a document-wide switch. Every nested object that should be closed has
to say so where it is defined, and the top level looking closed is exactly
what makes the omission easy to miss.
END_DOC

exit 0
