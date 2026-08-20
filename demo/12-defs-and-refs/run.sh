#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 12: defs and refs"

doc "a definition written once, enforced everywhere it is referenced" << 'END_DOC'
"$defs" holds named schemas; "$ref" uses one where a schema is needed.
They play the part that type definitions play in a programming language.
The value of a "$ref" is a path into the schema document: # is the
document itself, and /$defs/Hex walks from there to the definition. The
schema below defines Hex once -- a lowercase hexadecimal string, anchored
with ^ and $ and ending with the $(?!\n) guard against a trailing
newline, both from demo 07 -- and references it from two properties.
Lowercase only is deliberate: a parser reading hex as a number accepts
either case, but a checksum is compared as a string, where DEADC0DE and
deadc0de are different -- so the definition pins one canonical case, as
git does for its object ids.
Editing the definition changes what both properties enforce.

The two instances differ in one value. The error message names the
property that failed, not the definition: the reference reads as if the
definition had been written inline at each place it is used.
END_DOC

show "the schema (Hex defined once, used twice)"  cat schema-reuse.json

show "both values well-formed"           cat instance-both.json
show "jsonschema (Python): both well-formed"      jsonschema-validate --schema schema-reuse.json --instance instance-both.json
show "ajv (JavaScript): both well-formed"         ajv-validate        --schema schema-reuse.json --instance instance-both.json

show "one value malformed"               cat instance-bad-previous.json
show "jsonschema (Python): one malformed"         jsonschema-validate --schema schema-reuse.json --instance instance-bad-previous.json
show "ajv (JavaScript): one malformed"            ajv-validate        --schema schema-reuse.json --instance instance-bad-previous.json

doc "allOf composes named definitions" << 'END_DOC'
Named definitions need a way to be combined. "allOf" -- named in demo 08
as "and" over a list of schemas -- does it: listing "$ref"s under "allOf"
assembles a schema from named parts, satisfied exactly by the instances
that satisfy every part. The schema below composes two one-line
definitions, one requiring "checksum" and the other "previous"; the two
instances differ only in whether "previous" is present. This is the
construction larger schemas are built from: a pool
of named constraints, each testable on its own, composed by listing.

Because every branch must hold, a branch can only add constraints. There
is no way to write "this part, minus that requirement" -- relaxing
anything means composing a different list, not overriding a member of
this one.
END_DOC

show "the schema (two definitions, both required)" cat schema-allof.json

show "both properties present"           cat instance-both.json
show "jsonschema (Python): both present"          jsonschema-validate --schema schema-allof.json --instance instance-both.json
show "ajv (JavaScript): both present"             ajv-validate        --schema schema-allof.json --instance instance-both.json

show "one property missing"              cat instance-one.json
show "jsonschema (Python): one missing"           jsonschema-validate --schema schema-allof.json --instance instance-one.json
show "ajv (JavaScript): one missing"              ajv-validate        --schema schema-allof.json --instance instance-one.json

doc "a reference that resolves to nothing" << 'END_DOC'
In the schema below, the "$ref" names $defs/Hexx while the definition
sits at $defs/Hex -- a one-character typo. The two validators notice at different
moments. Ajv resolves every reference while compiling the schema, so it
refuses the schema outright -- an error, not a verdict -- whatever the
instance holds. Python's jsonschema resolves a reference only when
validation reaches it: handed an instance with a "checksum", it reports
the error; handed one without, the broken reference is never followed
and the verdict is VALID. So a typo'd reference on a rarely-taken path
can sit unnoticed under the lazy engine until the first instance takes
that path -- and the same schema and instance below draw VALID from one
validator and a schema error from the other, a disagreement that shows
only because every demo here runs both.
END_DOC

show "the schema (ref names Hexx, def names Hex)" cat schema-typo.json
show "jsonschema (Python): typo'd ref"            jsonschema-validate --schema schema-typo.json --instance instance-both.json
show "ajv (JavaScript): typo'd ref"               ajv-validate        --schema schema-typo.json --instance instance-both.json
show "an instance that avoids the broken ref"     cat instance-no-checksum.json
show "jsonschema (Python): ref not reached"       jsonschema-validate --schema schema-typo.json --instance instance-no-checksum.json
show "ajv (JavaScript): ref not reached"          ajv-validate        --schema schema-typo.json --instance instance-no-checksum.json

exit 0
