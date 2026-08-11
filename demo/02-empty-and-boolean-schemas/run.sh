#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "a schema need not be an object" << 'END_DOC'
JSON Schema defines a schema as either an object or a boolean. The two
booleans are the degenerate ends of the lattice: true accepts every
instance, false rejects every instance. The empty object {} declares no
constraints and so behaves exactly like true.

These forms are easy to dismiss as curiosities, but they arrive on their
own: false is what a generator emits for "this may not appear," {} is what
it emits for "no constraints known yet," and both turn up as base cases
when schemas are composed. Tooling that assumes a schema is always an
object — indexing keys, counting keywords, walking properties — crashes or
silently misreads on exactly these inputs.

The wrappers pin 2020-12, so these schemas need no $schema of their own.

Each schema below is checked against two instances chosen to be as unlike
each other as JSON allows: an object with a property, and null. The claim
is that these schemas decide irrespective of what they are handed, and a
claim about everything is poorly served by a single example — two unlike
instances agreeing is what makes "regardless" visible. Neither instance is
the subject here; the schema is the only thing whose meaning is at stake.
END_DOC

show "the first instance"   cat instance.json
show "the second instance"  cat instance-null.json

show "empty schema (accepts anything)"          cat schema-any.json
show "jsonschema (Python): object vs {}"        jsonschema-validate --schema schema-any.json   --instance instance.json
show "ajv (JavaScript): object vs {}"           ajv-validate        --schema schema-any.json   --instance instance.json
show "jsonschema (Python): null vs {}"          jsonschema-validate --schema schema-any.json   --instance instance-null.json
show "ajv (JavaScript): null vs {}"             ajv-validate        --schema schema-any.json   --instance instance-null.json

show "boolean schema true (accepts anything)"   cat schema-true.json
show "jsonschema (Python): object vs true"      jsonschema-validate --schema schema-true.json  --instance instance.json
show "ajv (JavaScript): object vs true"         ajv-validate        --schema schema-true.json  --instance instance.json
show "jsonschema (Python): null vs true"        jsonschema-validate --schema schema-true.json  --instance instance-null.json
show "ajv (JavaScript): null vs true"           ajv-validate        --schema schema-true.json  --instance instance-null.json

show "boolean schema false (rejects anything)"  cat schema-false.json
show "jsonschema (Python): object vs false"     jsonschema-validate --schema schema-false.json --instance instance.json
show "ajv (JavaScript): object vs false"        ajv-validate        --schema schema-false.json --instance instance.json
show "jsonschema (Python): null vs false"       jsonschema-validate --schema schema-false.json --instance instance-null.json
show "ajv (JavaScript): null vs false"          ajv-validate        --schema schema-false.json --instance instance-null.json

exit 0
