#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 15: closure scope"

doc "closing affects only the object being validated" << 'END_DOC'
Demo 14 closed a composed schema with "unevaluatedProperties": false,
the schema for every member evaluated nowhere in the whole schema.
The members affected were the members -- the top-level entries -- of
the object being validated; members of nested objects were
unaffected. The two sections below show what follows for closed
schemas: a schema can still be closed when its members are described
in a "$defs" definition, but only with "unevaluatedProperties"; and
closing the root object leaves nested objects open.
END_DOC

doc "closing over a \$ref" << 'END_DOC'
Below, "a" is described in a definition under "$defs", and "$ref"
applies that definition (demo 12). One instance is checked against
two such schemas, one closed with "unevaluatedProperties": false and
the other with "additionalProperties": false.
END_DOC

show "the instance"  cat instance-a.json

doc "with unevaluatedProperties: a is evaluated" << 'END_DOC'
To "unevaluatedProperties", a member is extra only if no schema
evaluated it. The "$ref" below applies the definition to the object
being validated, and the definition evaluates "a". So "a" is not
extra, and the instance passes.
END_DOC

show "closing with unevaluatedProperties"                cat schema-unevaluated.json
show "jsonschema (Python): unevaluatedProperties"        jsonschema-validate --schema schema-unevaluated.json --instance instance-a.json
show "ajv (JavaScript): unevaluatedProperties"           ajv-validate        --schema schema-unevaluated.json --instance instance-a.json

doc "with additionalProperties: every member is extra" << 'END_DOC'
To "additionalProperties", a member is extra when the "properties"
beside it does not name the member (demo 14). Here there is no
"properties" beside it, so every member of the instance is extra, and
"a" is rejected.
END_DOC

show "closing with additionalProperties"                 cat schema-additional.json
show "jsonschema (Python): additionalProperties"         jsonschema-validate --schema schema-additional.json  --instance instance-a.json
show "ajv (JavaScript): additionalProperties"            ajv-validate        --schema schema-additional.json  --instance instance-a.json

doc "required does not repair it" << 'END_DOC'
"required" demands that a member be present; it does not name the
member for "additionalProperties", which reads only the "properties"
beside it. Adding "required": ["a"] to the schema just rejected
produces a schema no object satisfies: an object without "a" fails
the "required", and an object with "a" still fails
"additionalProperties": false. Both validators reject both instances
below.
END_DOC

show "required beside additionalProperties  ---- ☠ DO NOT EMULATE ☠"  cat schema-required-additional.json

show "jsonschema (Python): a present"     jsonschema-validate --schema schema-required-additional.json --instance instance-a.json
show "ajv (JavaScript): a present"        ajv-validate        --schema schema-required-additional.json --instance instance-a.json

show "the empty object"                   cat instance-empty.json
show "jsonschema (Python): a absent"      jsonschema-validate --schema schema-required-additional.json --instance instance-empty.json
show "ajv (JavaScript): a absent"         ajv-validate        --schema schema-required-additional.json --instance instance-empty.json

doc "a nested object is not closed from outside" << 'END_DOC'
Both schemas below place "unevaluatedProperties": false at the top
level, beside a "properties" that names "details". That closes the
root object of the instance and nothing else: "details" is a member
of the root object, evaluated by that "properties", so it is not
extra. "x" and "y" are members of the inner object, and what is
extra there depends only on the schemas applied to the inner object.

The two schemas differ in exactly one place: whether
"unevaluatedProperties": false appears in the subschema for
"details" as well. The instance gives the inner object a member "y"
that no "properties" names. Against the first schema "y" passes --
by itself that would prove little, since a schema with no closing
keyword anywhere would accept it too. Against the second, the same
instance is rejected, both error messages placing the failure at
/details (a JSON Pointer, demo 13).
END_DOC

show "the instance"  cat instance-nested.json

show "root closed, inner open"                    cat schema-inner-open.json
show "jsonschema (Python): inner open"            jsonschema-validate --schema schema-inner-open.json   --instance instance-nested.json
show "ajv (JavaScript): inner open"               ajv-validate        --schema schema-inner-open.json   --instance instance-nested.json

show "root closed, inner closed too"              cat schema-inner-closed.json
show "jsonschema (Python): inner closed"          jsonschema-validate --schema schema-inner-closed.json --instance instance-nested.json
show "ajv (JavaScript): inner closed"             ajv-validate        --schema schema-inner-closed.json --instance instance-nested.json

doc "each object is closed by its own subschema" << 'END_DOC'
There is no document-wide switch: an object that should reject extra
members is closed only by its own subschema. And the root being
closed is what makes the omission easy to miss: the schema looks
closed at the top, while a nested object without its own
"unevaluatedProperties" accepts extra members silently.
END_DOC

doc "close only where it earns its keep" << 'END_DOC'
The machinery in this demo is subtle: what a "$ref" lets a closing
keyword reach, what nesting takes away, what "required" cannot
repair. A schema that depends on it will not be transparent to most
of its readers, and changes to it are easy to get wrong. Openness is
the language's default; close a schema only where extra members must
be rejected, and save the maintenance everywhere else. Where a
schema does close, put the reason beside the keyword: a "$comment"
(demo 06) can say what mistake the closure is there to catch, at no
cost to any verdict.
END_DOC

doc "the commented form" << 'END_DOC'
Below, the demo's two situations combine into one commented schema.
The record's members are described in a "$defs" definition, so the
root object is closed with "unevaluatedProperties": false. The inner
object's members are described in place, so the simpler
"additionalProperties": false is enough there. Each closing keyword
carries a "$comment" stating the author's intent -- what mistake
that closure is there to catch -- not what the keyword does, which
the language already defines. The instance -- whose root object has
the single member "details" -- is rejected at /details as before,
the messages now naming additional rather than unevaluated
properties.
END_DOC

show "the instance"                       cat instance-nested.json

show "the two restrictions, each explained in place"  cat schema-commented.json

show "jsonschema (Python): commented form"  jsonschema-validate --schema schema-commented.json --instance instance-nested.json
show "ajv (JavaScript): commented form"     ajv-validate        --schema schema-commented.json --instance instance-nested.json

exit 0
