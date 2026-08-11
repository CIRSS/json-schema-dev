#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "properties does not make a property required" << 'END_DOC'
The object counterpart of the previous demo, and the same trap. "type":
"object" accepts {}. Listing a property under properties does not make it
mandatory — properties says "if this key appears, here is its shape," which
is a constraint on presence, not a demand for it. Only required makes a
property obligatory.

So a schema can describe every field of a record in full detail and still
accept the empty object. This is the single most common defect in a
generated schema: the shape is right, required is missing, and the schema
validates documents that carry none of the data it describes.

The boundary worth testing is {} against the minimal satisfying object —
one required property and nothing else. If the empty object passes, the
schema is not asserting what it appears to assert.
END_DOC

show "the schema (object, required id)"  cat schema.json

show "the empty object"                     cat instance-empty.json
show "jsonschema (Python): empty object"    jsonschema-validate --schema schema.json --instance instance-empty.json
show "ajv (JavaScript): empty object"       ajv-validate        --schema schema.json --instance instance-empty.json

show "the minimal object"                   cat instance-min.json
show "jsonschema (Python): minimal object"  jsonschema-validate --schema schema.json --instance instance-min.json
show "ajv (JavaScript): minimal object"     ajv-validate        --schema schema.json --instance instance-min.json

doc "required asks about presence, not content" << 'END_DOC'
One more instance, differing from the minimal object in exactly one way:
the value of id is null rather than a string.

It passes. required is a question about which keys a document carries, and
a key whose value is null is carried. Null is a value like any other here,
not a way of spelling absence — the two are different states of a document,
and only the missing key is missing.

This matters because null is what a producer emits for a field it could not
populate. required will not catch that; it reports the key as present and
says nothing about whether anything is in it. Ruling it out takes a
constraint on the value, such as declaring the property's type.
END_DOC

show "the minimal object with a null value"  cat instance-null.json
show "jsonschema (Python): null value"       jsonschema-validate --schema schema.json --instance instance-null.json
show "ajv (JavaScript): null value"          ajv-validate        --schema schema.json --instance instance-null.json

exit 0
