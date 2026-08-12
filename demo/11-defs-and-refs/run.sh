#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "a definition written once, enforced everywhere it is referenced" << 'END_DOC'
$defs holds named subschemas; $ref uses one by name. Together they are the
schema language's type definitions: the schema below defines Hex once —
a lowercase hexadecimal string, using the anchored-pattern discipline from
demo 07 — and references it from two properties. Editing the definition
changes what both sites enforce.

The two instances differ in one value. The error message names the site
that failed, not the definition: the reference is transparent, as if the
definition had been written inline at each use.
END_DOC

show "the schema (Hex defined once, used twice)"  cat schema-reuse.json

show "both values well-formed"           cat instance-both.json
show "jsonschema (Python): both well-formed"      jsonschema-validate --schema schema-reuse.json --instance instance-both.json
show "ajv (JavaScript): both well-formed"         ajv-validate        --schema schema-reuse.json --instance instance-both.json

show "one value malformed"               cat instance-bad-previous.json
show "jsonschema (Python): one malformed"         jsonschema-validate --schema schema-reuse.json --instance instance-bad-previous.json
show "ajv (JavaScript): one malformed"            ajv-validate        --schema schema-reuse.json --instance instance-bad-previous.json

doc "allOf composes named definitions by intersection" << 'END_DOC'
Named definitions need a way to be combined. allOf is intersection: the
instance must satisfy every branch, so listing $refs under allOf assembles
a schema from named parts. The schema below composes two one-line
definitions; the instances differ in whether one required property is
present. This is the construction larger schemas are built from — a pool of
named constraints, each testable on its own, composed by listing.

Note what intersection implies: a branch can only add constraints. There is
no way to write "this part, minus that requirement" — relaxing anything
means composing a different list, not overriding a member of this one.
END_DOC

show "the schema (two definitions, both required)" cat schema-allof.json

show "both properties present"           cat instance-both.json
show "jsonschema (Python): both present"          jsonschema-validate --schema schema-allof.json --instance instance-both.json
show "ajv (JavaScript): both present"             ajv-validate        --schema schema-allof.json --instance instance-both.json

show "one property missing"              cat instance-one.json
show "jsonschema (Python): one missing"           jsonschema-validate --schema schema-allof.json --instance instance-one.json
show "ajv (JavaScript): one missing"              ajv-validate        --schema schema-allof.json --instance instance-one.json

doc "a reference that resolves to nothing" << 'END_DOC'
The last schema differs from the first in one character: the $ref names
$defs/Hexx while the definition sits at $defs/Hex. Neither validator can
validate anything with it — but they fail at different moments. Ajv
resolves references while compiling the schema and rejects it before
seeing any instance. Python's jsonschema resolves them lazily, during
validation, so the same defect surfaces only when an instance arrives at
the broken reference. Both exit 2 here — an error, not a verdict — but in a
larger schema the lazy resolver means a typo'd reference on a rarely-taken
path can sit unnoticed until the first instance takes that path.
END_DOC

show "the schema (ref names Hexx, def names Hex)" cat schema-typo.json
show "jsonschema (Python): typo'd ref"            jsonschema-validate --schema schema-typo.json --instance instance-both.json
show "ajv (JavaScript): typo'd ref"               ajv-validate        --schema schema-typo.json --instance instance-both.json

exit 0
