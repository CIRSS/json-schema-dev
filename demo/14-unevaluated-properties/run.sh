#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 14: unevaluated properties"

doc "additionalProperties does not look inside allOf" << 'END_DOC'
Demo 09 showed how a schema forbids extra properties:
"additionalProperties": false rejects every property that the
"properties" beside it does not name. Beside it means in the same
schema object: which members are extra is determined by that one
"properties" alone.

In the schema below, "a" and "b" are described in two "allOf"
branches. Each branch is a complete schema of its own (demo 09), and
each branch's "properties" is a member of that branch, not of the
outer schema object. The outer schema object -- the one holding the
"additionalProperties": false -- has no "properties" of its own, so
every member of the instance is extra: both validators reject an
object that satisfies both branches. jsonschema names both extras in
one line; ajv prints one line per extra property, the same words each
time.
END_DOC

show "two allOf branches, closed with additionalProperties: false"  cat schema-additional.json

show "an object with a and b"                                cat instance-a-b.json
show "jsonschema (Python): a and b, additionalProperties"    jsonschema-validate --schema schema-additional.json --instance instance-a-b.json
show "ajv (JavaScript): a and b, additionalProperties"       ajv-validate        --schema schema-additional.json --instance instance-a-b.json

doc "unevaluatedProperties rejects what nothing evaluated" << 'END_DOC'
"unevaluatedProperties" fixes exactly this, and its name says how. A
member of the instance is evaluated when the validator checks it
against a schema -- here, "a" and "b" are evaluated in the branches,
each checked against the schema its "properties" pairs it with. The
value of "unevaluatedProperties" is the schema for every member
evaluated nowhere in the whole schema, branches included -- the same
schema position as in demo 09, and false again rejects them all.

The schema below closes the same two branches with
"unevaluatedProperties": false. The object that was just rejected now
passes, and an object carrying "c" -- a member evaluated nowhere --
is rejected by both validators, in different words but with the same
verdict.
END_DOC

show "the same branches, closed with unevaluatedProperties: false"  cat schema-unevaluated.json

show "jsonschema (Python): a and b, unevaluatedProperties"   jsonschema-validate --schema schema-unevaluated.json --instance instance-a-b.json
show "ajv (JavaScript): a and b, unevaluatedProperties"      ajv-validate        --schema schema-unevaluated.json --instance instance-a-b.json

show "an extra property c"                                   cat instance-a-b-c.json
show "jsonschema (Python): extra c"                          jsonschema-validate --schema schema-unevaluated.json --instance instance-a-b-c.json
show "ajv (JavaScript): extra c"                             ajv-validate        --schema schema-unevaluated.json --instance instance-a-b-c.json

doc "what if a or b is left out?" << 'END_DOC'
Nothing in either schema requires "a" or "b" to be present. A
"properties" entry says what a member must satisfy if the member is
present (demo 02), and "unevaluatedProperties" says what an extra
property must satisfy if one appears; neither makes any member
mandatory. Only "required" does that (demo 04), and these schemas have
no "required". So the schema closed with "unevaluatedProperties"
accepts an object without "b", and the empty object too: no property
present, none extra, nothing required.
END_DOC

show "only a"                                     cat instance-only-a.json
show "jsonschema (Python): only a"                jsonschema-validate --schema schema-unevaluated.json --instance instance-only-a.json
show "ajv (JavaScript): only a"                   ajv-validate        --schema schema-unevaluated.json --instance instance-only-a.json

show "neither a nor b"                            cat instance-empty.json
show "jsonschema (Python): neither a nor b"       jsonschema-validate --schema schema-unevaluated.json --instance instance-empty.json
show "ajv (JavaScript): neither a nor b"          ajv-validate        --schema schema-unevaluated.json --instance instance-empty.json

doc "required and unevaluatedProperties together" << 'END_DOC'
To make "a" and "b" mandatory as well as block everything else, add
"required". The schema below is the previous one -- the two branches
closed with "unevaluatedProperties": false -- with one more member in
the outer schema object: "required": ["a", "b"]. The "required" and
the branches refer to "a" and "b" independently ("required" tests
only presence; demo 04), and their constraints combine: the instance
must include both members (the "required"), and both values must be
strings (the branches), while "unevaluatedProperties" continues to
disallow other members of the instance. So now the object with both
members still passes, the object missing "b" is rejected, and an
extra "c" is still rejected -- each verdict from both validators.
END_DOC

show "the same schema, with required"             cat schema-unevaluated-required.json

show "jsonschema (Python): a and b"               jsonschema-validate --schema schema-unevaluated-required.json --instance instance-a-b.json
show "ajv (JavaScript): a and b"                  ajv-validate        --schema schema-unevaluated-required.json --instance instance-a-b.json

show "jsonschema (Python): only a"                jsonschema-validate --schema schema-unevaluated-required.json --instance instance-only-a.json
show "ajv (JavaScript): only a"                   ajv-validate        --schema schema-unevaluated-required.json --instance instance-only-a.json

show "jsonschema (Python): extra c"               jsonschema-validate --schema schema-unevaluated-required.json --instance instance-a-b-c.json
show "ajv (JavaScript): extra c"                  ajv-validate        --schema schema-unevaluated-required.json --instance instance-a-b-c.json

doc "a caution about older validators" << 'END_DOC'
"unevaluatedProperties" is newer than the other keywords here: it
entered the language in the 2019-09 version. To a validator built for
an earlier version it is an unknown member, and unknown members are
ignored (demo 01) -- such a validator accepts every extra property and
reports nothing. jsonschema-validate and ajv-validate implement
2020-12, and refuse a schema that declares an older version rather
than reinterpreting it (demo 22).
END_DOC

exit 0
