#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "most keywords do not apply to most instances" << 'END_DOC'
Validation keywords are type-scoped. minLength constrains strings, minimum
constrains numbers, minItems constrains arrays — and each is simply silent
about an instance of any other type. Silent means satisfied: a keyword that
does not apply contributes no error, so it passes.

This is the single most surprising rule in JSON Schema, because a schema
that lists many constraints can assert almost nothing about a given
document, and it will not tell you so. The constraints did not fail. They
were never consulted.

Null is the value that makes this visible, for two reasons. It is a value
of its own type, so nearly every type-scoped keyword is inapplicable to it;
and it is the value people already misread as meaning "nothing is here,"
which is exactly the misreading the rule punishes.

Demo 04 covers the related trap on the other side — that a null-valued
property still satisfies required.
END_DOC

doc "null is a type, and there is no nullable keyword" << 'END_DOC'
JSON Schema has no nullable modifier. Permitting null is done by naming it
in type, which takes either one type name or a list of them. The two
schemas below differ in that list and nothing else.

(OpenAPI 3.0 did have nullable: true, which is where the expectation comes
from; 3.1 dropped it in favour of this form.)
END_DOC

show "the instance"  cat instance-null.json

show "type is string"                              cat schema-string.json
show "jsonschema (Python): null vs string"         jsonschema-validate --schema schema-string.json   --instance instance-null.json
show "ajv (JavaScript): null vs string"            ajv-validate        --schema schema-string.json   --instance instance-null.json

show "type is string or null"                      cat schema-nullable.json
show "jsonschema (Python): null vs string-or-null" jsonschema-validate --schema schema-nullable.json --instance instance-null.json
show "ajv (JavaScript): null vs string-or-null"    ajv-validate        --schema schema-nullable.json --instance instance-null.json

doc "making a field nullable exempts it from its own constraints" << 'END_DOC'
Now add a length constraint to that nullable field. One schema, three
instances: a string that is too short, a string that is long enough, and
null.

The first two behave as written. The third is the one to look at. null does
not fail the length check — minLength does not apply to it, so there is
nothing to fail. Every string constraint on this field silently exempts
null, and the schema still reads as though the field is constrained.

The lesson is not "avoid null." It is that widening a type widens what the
type-scoped keywords decline to examine, and nothing in the schema records
that you meant those constraints to bind.
END_DOC

show "a nullable string of at least 5 characters"  cat schema-nullable-minlength.json

show "a string that is too short"                  cat instance-short.json
show "jsonschema (Python): short string"           jsonschema-validate --schema schema-nullable-minlength.json --instance instance-short.json
show "ajv (JavaScript): short string"              ajv-validate        --schema schema-nullable-minlength.json --instance instance-short.json

show "a string that is long enough"                cat instance-long.json
show "jsonschema (Python): long string"            jsonschema-validate --schema schema-nullable-minlength.json --instance instance-long.json
show "ajv (JavaScript): long string"               ajv-validate        --schema schema-nullable-minlength.json --instance instance-long.json

show "null again"                                  cat instance-null.json
show "jsonschema (Python): null"                   jsonschema-validate --schema schema-nullable-minlength.json --instance instance-null.json
show "ajv (JavaScript): null"                      ajv-validate        --schema schema-nullable-minlength.json --instance instance-null.json

doc "not every keyword is type-scoped" << 'END_DOC'
The rule has an important exception, and the two schemas below make it
visible against the same instance.

enum and const do not assert anything about a type; they compare the
instance to a list of literal values. null is a value, it is not in the
list, and so it is rejected. minimum is a numeric assertion, inapplicable
to null, and so it passes.

Both keywords read like "restrict what may appear here." Only one of them
restricts null. Knowing which family a keyword belongs to — value
comparison or type-scoped assertion — is what tells you whether it will
hold when an unexpected type arrives.
END_DOC

show "an enumeration of two strings"     cat schema-enum.json
show "jsonschema (Python): null vs enum" jsonschema-validate --schema schema-enum.json    --instance instance-null.json
show "ajv (JavaScript): null vs enum"    ajv-validate        --schema schema-enum.json    --instance instance-null.json

show "a numeric lower bound"                cat schema-minimum.json
show "jsonschema (Python): null vs minimum" jsonschema-validate --schema schema-minimum.json --instance instance-null.json
show "ajv (JavaScript): null vs minimum"    ajv-validate        --schema schema-minimum.json --instance instance-null.json

exit 0
