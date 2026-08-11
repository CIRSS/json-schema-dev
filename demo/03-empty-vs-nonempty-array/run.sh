#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "the empty array is the default, not the exception" << 'END_DOC'
"type": "array" accepts the empty array. Nothing about declaring an item
type changes that — items constrains the elements that are present and says
nothing about how many there must be. Only minItems does that.

This is the most common way a schema means less than its author thought.
The array is described carefully, every element constrained, and the schema
still accepts [] — so a producer that emits an empty list for "nothing to
report," or for a field it failed to populate, validates clean. The
constraint that would have caught it was never written.

The rule of thumb: for every array in a schema, decide whether emptiness is
meaningful. If it is not, say minItems: 1 explicitly. The boundary below is
the one to test — [] against [1], not a long list against a longer one.
END_DOC

show "the schema (array, minItems 1)"  cat schema.json

show "the empty array"                         cat instance-empty.json
show "jsonschema (Python): empty array"        jsonschema-validate --schema schema.json --instance instance-empty.json
show "ajv (JavaScript): empty array"           ajv-validate        --schema schema.json --instance instance-empty.json

show "a one-element array"                     cat instance-one.json
show "jsonschema (Python): one-element array"  jsonschema-validate --schema schema.json --instance instance-one.json
show "ajv (JavaScript): one-element array"     ajv-validate        --schema schema.json --instance instance-one.json

doc "minItems is a floor, not a count" << 'END_DOC'
One element satisfies minItems: 1, and so does any larger number — the
keyword sets a lower bound and says nothing about an upper one. Three
elements are as acceptable as one.

Worth demonstrating because the empty/one boundary above can leave the
impression that the schema is picky about length. It is not: it rules out
exactly one case, the empty array. Bounding the other end takes maxItems,
and forbidding repeats takes uniqueItems; neither is implied here.
END_DOC

show "a three-element array"                     cat instance-three.json
show "jsonschema (Python): three-element array"  jsonschema-validate --schema schema.json --instance instance-three.json
show "ajv (JavaScript): three-element array"     ajv-validate        --schema schema.json --instance instance-three.json

exit 0
