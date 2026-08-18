#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 03: arrays items and minitems"

doc "\"items\" constrains every element of an array" << 'END_DOC'
Demo 02 described objects with "properties", which gives one schema
per named member. Arrays have no member names -- their elements are
known only by position -- so the keyword that describes them, "items",
takes a simpler form. It is worth recalling first that JSON puts no
restriction on what an array holds: [1, "x", null, {}] is a legal
array, its elements of four different kinds. Uniformity, where a
schema wants it, is a constraint the schema must state. The value of
"items" is one schema, and that one schema applies to every element:
an array satisfies "items" only if each of its elements satisfies the
schema. So {"type": "array", "items": {"type": "number"}} says: the
instance is an array, and each of its elements is a number.

The value of "items" is a complete schema, exactly as each value in a
"properties" object is. That is the same nesting demo 02 pointed at:
the keywords used at the top level are used again inside, and a schema
describes structure at any depth by placing schemas inside schemas
(demo 09). And because the "items" schema is a schema like any other,
it need not name a single kind: {"items": {"type": ["string",
"number"]}} allows strings and numbers to mix freely, in any order.
What "items" cannot do is constrain elements by position -- first a
string, then a number; a separate keyword, "prefixItems", does that.
END_DOC

doc "the examples" << 'END_DOC'
One schema, requiring an array of numbers, is checked against two
arrays that differ in one element: [1, 2, 3], and [1, "x"], where the
second element is a string. The first is accepted; the second is
rejected, and the location reported names the offending element.
END_DOC

show "the schema (an array of numbers)"          cat schema-items.json
show "an array of numbers"                       cat instance-three.json
show "jsonschema (Python): numbers"              jsonschema-validate --schema schema-items.json --instance instance-three.json
show "ajv (JavaScript): numbers"                 ajv-validate        --schema schema-items.json --instance instance-three.json
show "an array with a string among the numbers"  cat instance-mixed.json
show "jsonschema (Python): a string among them"  jsonschema-validate --schema schema-items.json --instance instance-mixed.json
show "ajv (JavaScript): a string among them"     ajv-validate        --schema schema-items.json --instance instance-mixed.json

doc "the empty array satisfies \"items\"" << 'END_DOC'
"items" says what each element must be. It says nothing about how many
elements there are, and in particular it does not require any. An
empty array has no elements, so it has no element that fails, and it
satisfies any "items" schema whatsoever. A schema may describe its
array's elements in full detail and still accept [].

This matters because an empty array is what a program often produces
when it has nothing to report, or when it failed to populate a field.
A schema that meant "one or more" but wrote only "items" validates that
output as clean; the constraint that would have caught it was never
written. So for every array in a schema, decide whether emptiness is
meaningful, and if it is not, say so with the keyword introduced next.
END_DOC

doc "the examples" << 'END_DOC'
The same schema is checked against the empty array, which is
accepted.
END_DOC

show "the empty array"                     cat instance-empty.json
show "jsonschema (Python): empty array"    jsonschema-validate --schema schema-items.json --instance instance-empty.json
show "ajv (JavaScript): empty array"       ajv-validate        --schema schema-items.json --instance instance-empty.json

doc "\"minItems\" sets the least number of elements" << 'END_DOC'
"minItems" is the keyword whose value is a non-negative integer, and an
array satisfies it only if it has at least that many elements. It is
the keyword that rules out the empty array: "minItems": 1 rejects [] and
accepts every array with one element or more.

"minItems" is a floor, not a count. One element satisfies "minItems": 1,
and so does any larger number; the keyword says nothing about an upper
bound. Bounding the other end takes a separate keyword, "maxItems", and
forbidding repeated elements takes another, "uniqueItems"; neither is
implied by "minItems".
END_DOC

doc "the examples" << 'END_DOC'
The schema above with "minItems": 1 added is checked against three
arrays: the empty array, a one-element array, and the three-element
array from above. The empty array is now rejected; the other two are
accepted, the three-element array showing that the floor is not a
count.
END_DOC

show "the schema (an array of numbers, \"minItems\": 1)"  cat schema-items-min1.json
show "jsonschema (Python): empty array"        jsonschema-validate --schema schema-items-min1.json --instance instance-empty.json
show "ajv (JavaScript): empty array"           ajv-validate        --schema schema-items-min1.json --instance instance-empty.json
show "a one-element array"                     cat instance-one.json
show "jsonschema (Python): one element"        jsonschema-validate --schema schema-items-min1.json --instance instance-one.json
show "ajv (JavaScript): one element"           ajv-validate        --schema schema-items-min1.json --instance instance-one.json
show "jsonschema (Python): three elements"     jsonschema-validate --schema schema-items-min1.json --instance instance-three.json
show "ajv (JavaScript): three elements"        ajv-validate        --schema schema-items-min1.json --instance instance-three.json

exit 0
