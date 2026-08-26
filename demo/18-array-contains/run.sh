#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 18: array contains"

doc "the same schema, required of every element or of some element" << 'END_DOC'
Demo 03's "items" holds a schema and requires every element of the
array to satisfy it. "contains" holds a schema and requires that
some element satisfy it: the array is accepted when at least one
does, and nothing is required of the rest. What each holds is a
complete schema -- any schema (demo 09) -- so a "contains" can
state whatever requirement the data calls for, and the sections
below put several in that position.

The two schemas below hold the same schema, {"type": "number"},
and differ only in the keyword carrying it. The instance holds a
string and a number. Under "items" the string is a violation;
under "contains" the number is enough.
END_DOC

show "an array with a string and a number"  cat instance-string-number.json

show "every element a number"            cat schema-items-number.json
show "jsonschema (Python): items"                 jsonschema-validate --schema schema-items-number.json --instance instance-string-number.json
show "ajv (JavaScript): items"                    ajv-validate        --schema schema-items-number.json --instance instance-string-number.json

show "some element a number"             cat schema-contains-number.json
show "jsonschema (Python): contains"              jsonschema-validate --schema schema-contains-number.json --instance instance-string-number.json
show "ajv (JavaScript): contains"                 ajv-validate        --schema schema-contains-number.json --instance instance-string-number.json

doc "when no element satisfies the schema" << 'END_DOC'
The array below holds no number, so the "contains" is not
satisfied and both validators reject it. jsonschema reports one
error for the array. Ajv reports three: it returns every
assertion failure met during evaluation -- here, each element's
failure to be the matching element, then the "contains" failure
those two produced. The errors are structured objects that a
consuming program is expected to sift; the wrappers used here
print each one as a line, which gives a sub-result the same
standing as the conclusion. So read the lines knowing their
roles: "/0: must be number" states no obligation -- no element
must be a number -- and the requirement actually violated is the
final line's. On a long array, one missing element produces a
line for each innocent element.
END_DOC

show "an array of two strings"           cat instance-two-strings.json
show "jsonschema (Python): no number"             jsonschema-validate --schema schema-contains-number.json --instance instance-two-strings.json
show "ajv (JavaScript): no number"                ajv-validate        --schema schema-contains-number.json --instance instance-two-strings.json

doc "the empty array" << 'END_DOC'
Demo 03 showed [] accepted by any "items" schema: with no
elements, there is no element to reject. The same emptiness has
the opposite effect on "contains": there is no element to
satisfy it, so [] fails every "contains".
END_DOC

show "the empty array"                   cat instance-empty.json
show "jsonschema (Python): empty array, items"    jsonschema-validate --schema schema-items-number.json --instance instance-empty.json
show "ajv (JavaScript): empty array, items"       ajv-validate        --schema schema-items-number.json --instance instance-empty.json
show "jsonschema (Python): empty array, contains" jsonschema-validate --schema schema-contains-number.json --instance instance-empty.json
show "ajv (JavaScript): empty array, contains"    ajv-validate        --schema schema-contains-number.json --instance instance-empty.json

doc "a contains that describes a shape" << 'END_DOC'
The schema in a "contains" can describe as much as any schema
can. Below it describes an object with a string member "id" and
requires that member, so the array must hold at least one record
carrying an "id".

The first array below has one element without "id" and one with
it -- accepted, the element lacking "id" costing nothing. In the
second no element carries "id", and the array is rejected.
END_DOC

show "some element a record with an id"  cat schema-contains-record.json

show "one element carries id"            cat instance-one-record.json
show "jsonschema (Python): id present"            jsonschema-validate --schema schema-contains-record.json --instance instance-one-record.json
show "ajv (JavaScript): id present"               ajv-validate        --schema schema-contains-record.json --instance instance-one-record.json

show "no element carries id"             cat instance-no-record.json
show "jsonschema (Python): id absent"             jsonschema-validate --schema schema-contains-record.json --instance instance-no-record.json
show "ajv (JavaScript): id absent"                ajv-validate        --schema schema-contains-record.json --instance instance-no-record.json

doc "the narrow end: a contains that names one value" << 'END_DOC'
A "const" (demo 10) is satisfied by exactly one value, so a
"contains" holding one requires the array to carry that value
somewhere -- position free, as always. The schemas below take
that form, and it is the form a JSON-LD "@context" needs: an
array required to carry one published entry, whatever else it
also carries.

The second schema names an object. A "const" compares by JSON
equality (demo 10), so the order of an object's members does not
matter and every member matters: the array with the object's
members written in the other order is accepted, and the array
whose element carrying "p1" is missing the second member is
rejected.
END_DOC

show "some element equal to core"        cat schema-contains-core.json

show "core between two other elements"   cat instance-ext1-core-ext2.json
show "jsonschema (Python): core present"          jsonschema-validate --schema schema-contains-core.json --instance instance-ext1-core-ext2.json
show "ajv (JavaScript): core present"             ajv-validate        --schema schema-contains-core.json --instance instance-ext1-core-ext2.json

show "some element equal to an object"   cat schema-contains-object.json

show "the object's members reordered"    cat instance-object-reordered.json
show "jsonschema (Python): members reordered"     jsonschema-validate --schema schema-contains-object.json --instance instance-object-reordered.json
show "ajv (JavaScript): members reordered"        ajv-validate        --schema schema-contains-object.json --instance instance-object-reordered.json

show "one member missing from the object"  cat instance-object-short.json
show "jsonschema (Python): member missing"        jsonschema-validate --schema schema-contains-object.json --instance instance-object-short.json
show "ajv (JavaScript): member missing"           ajv-validate        --schema schema-contains-object.json --instance instance-object-short.json

doc "items and contains combine in one schema object" << 'END_DOC'
An array schema can hold both "items" and "contains". No "allOf"
is needed -- they are different keywords, and a schema object is
an and of its keywords (demo 08), so both requirements are in
force. In the schema below, every element must be a string, and
some element must equal "core".

The first array below satisfies both requirements. The second
includes "core" but also a number, and the "items" rejects the
number at /1. The third holds only strings, none of them "core",
and the "contains" rejects the array.
END_DOC

show "every element a string, some element core"  cat schema-items-and-contains.json

show "jsonschema (Python): core among strings"    jsonschema-validate --schema schema-items-and-contains.json --instance instance-ext1-core-ext2.json
show "ajv (JavaScript): core among strings"       ajv-validate        --schema schema-items-and-contains.json --instance instance-ext1-core-ext2.json

show "a number beside core"              cat instance-core-5.json
show "jsonschema (Python): a number beside core"  jsonschema-validate --schema schema-items-and-contains.json --instance instance-core-5.json
show "ajv (JavaScript): a number beside core"     ajv-validate        --schema schema-items-and-contains.json --instance instance-core-5.json

show "strings without core"              cat instance-ext1-ext2.json
show "jsonschema (Python): strings without core"  jsonschema-validate --schema schema-items-and-contains.json --instance instance-ext1-ext2.json
show "ajv (JavaScript): strings without core"     ajv-validate        --schema schema-items-and-contains.json --instance instance-ext1-ext2.json

doc "two required elements: one contains per allOf branch" << 'END_DOC'
A schema object can hold only one member named "contains", so
requiring two different elements takes an "allOf" (demo 12), one
"contains" per branch. The schema below requires an element
equal to "core" and an element equal to "ext1". The first array
below carries both and passes; the second lacks "ext1", and the
branch that requires it rejects the array.
END_DOC

show "requiring both core and ext1"      cat schema-two-contains.json

show "jsonschema (Python): both present"          jsonschema-validate --schema schema-two-contains.json --instance instance-ext1-core-ext2.json
show "ajv (JavaScript): both present"             ajv-validate        --schema schema-two-contains.json --instance instance-ext1-core-ext2.json

show "ext1 missing"                      cat instance-core-ext2.json
show "jsonschema (Python): ext1 missing"          jsonschema-validate --schema schema-two-contains.json --instance instance-core-ext2.json
show "ajv (JavaScript): ext1 missing"             ajv-validate        --schema schema-two-contains.json --instance instance-core-ext2.json

doc "blocking a value with not" << 'END_DOC'
Keeping "core" out of the array is the opposite requirement, a
negation, and "not" (demo 08) writes it with either keyword. The
first schema below wraps "not" around a "contains": an array
that contains "core" is rejected. The second puts "not" inside
"items": every element must differ from "core". The two accept
and reject exactly the same arrays -- no element equals "core"
and every element differs from "core" are one requirement,
written two ways.

The verdicts below are identical; the messages are not. The
first form reports at the array, Ajv without even a location;
the second reports at /1, the JSON Pointer naming the element
that broke the rule. Where a value must be kept out, the "items"
form tells the author which element to fix.
END_DOC

show "rejecting arrays that contain core"  cat schema-not-contains.json

show "jsonschema (Python): not contains, core present"  jsonschema-validate --schema schema-not-contains.json --instance instance-ext1-core-ext2.json
show "ajv (JavaScript): not contains, core present"     ajv-validate        --schema schema-not-contains.json --instance instance-ext1-core-ext2.json
show "jsonschema (Python): not contains, core absent"   jsonschema-validate --schema schema-not-contains.json --instance instance-ext1-ext2.json
show "ajv (JavaScript): not contains, core absent"      ajv-validate        --schema schema-not-contains.json --instance instance-ext1-ext2.json

show "requiring every element to differ from core"  cat schema-items-not.json

show "jsonschema (Python): items not, core present"     jsonschema-validate --schema schema-items-not.json --instance instance-ext1-core-ext2.json
show "ajv (JavaScript): items not, core present"        ajv-validate        --schema schema-items-not.json --instance instance-ext1-core-ext2.json
show "jsonschema (Python): items not, core absent"      jsonschema-validate --schema schema-items-not.json --instance instance-ext1-ext2.json
show "ajv (JavaScript): items not, core absent"         ajv-validate        --schema schema-items-not.json --instance instance-ext1-ext2.json

exit 0
