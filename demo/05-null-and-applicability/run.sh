#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 05: null and applicability"

doc "most keywords apply only to instances of one kind" << 'END_DOC'
Most validation keywords are scoped to one kind of value. "minLength",
whose value is an integer, is the least number of characters a string
may have; "minimum", whose value is a number, is the least value a
number may have; "minItems" (demo 03) is the least number of elements
an array may have. Each constrains values of its own kind and is
simply silent about an instance of any other kind -- and silent means
satisfied: a keyword that does not apply contributes no error, so the
instance passes it.

The consequence is easy to overlook. A schema that lists several
constraints can assert nothing at all about a particular document, and
it will not say so: the constraints did not fail, they were never
consulted. Null makes this visible more sharply than any other value.
It is a value of its own kind, so nearly every kind-scoped keyword is
inapplicable to it, and it is also the value people already tend to
read as "nothing here" -- the very misreading that demo 04 addressed
from the other side, where a null-valued member still satisfies
"required".
END_DOC

doc "null is a kind, and permitting it means naming it" << 'END_DOC'
JSON Schema has no keyword meaning "this may also be null." Null is
one of the six kinds, and a schema permits it the way it permits any
kind: by naming it in "type", using the list form from demo 02, as in
"type": ["string", "null"]. Nothing else about the schema changes.
(Readers who expect a separate switch usually know it from OpenAPI, a
widely used specification for describing web APIs whose schema
language is based on JSON Schema: its version 3.0 had "nullable":
true, and version 3.1 dropped it in favor of naming "null" in "type".)
END_DOC

doc "the examples" << 'END_DOC'
The instance in the next cells is the bare value null, and it recurs
through most of the demo; only the schema changes from case to case,
so each difference in verdict is the schema's doing. First, two
schemas differing only in whether "null" is named in "type":
{"type": "string"} rejects the instance, and {"type": ["string",
"null"]} accepts it.
END_DOC

show "the instance"                                cat instance-null.json
show "\"type\" is string"                          cat schema-type-string.json
show "jsonschema (Python): null vs string"         jsonschema-validate --schema schema-type-string.json         --instance instance-null.json
show "ajv (JavaScript): null vs string"            ajv-validate        --schema schema-type-string.json         --instance instance-null.json
show "\"type\" is string or null"                  cat schema-type-string-or-null.json
show "jsonschema (Python): null vs string-or-null" jsonschema-validate --schema schema-type-string-or-null.json --instance instance-null.json
show "ajv (JavaScript): null vs string-or-null"    ajv-validate        --schema schema-type-string-or-null.json --instance instance-null.json

doc "permitting null exempts it from the string constraints" << 'END_DOC'
The cost of permitting null appears as soon as the schema also
constrains the string. Take {"type": ["string", "null"]} and add
"minLength": 5. A string shorter than five characters is now rejected
and a longer one accepted, as written. But null is not a string, so
"minLength" does not apply to it, and there is nothing for null to
fail: it is accepted. Every string constraint in the schema exempts
null in the same way, while the schema still reads as though the value
were constrained.

Each kind added to "type" is a kind of value the string keywords will
not examine. And the schema gives no sign of the gap: nothing in it
says whether the author intended the length constraint to hold for
every value, or only for strings. A schema that means "a string of at
least five characters, or nothing" is saying exactly that; a schema
whose author meant "at least five characters, always" and admitted
null by reflex has opened a gap the schema cannot show.
END_DOC

doc "the examples" << 'END_DOC'
One schema, permitting a string or null and requiring at least five
characters, is checked against three instances: a two-character
string, an eleven-character string, and null. The short string is
rejected; the long string and null are both accepted.
END_DOC

show "a string of at least 5 characters, or null"  cat schema-type-string-or-null-minlength.json
show "a two-character string"                      cat instance-short.json
show "jsonschema (Python): short string"           jsonschema-validate --schema schema-type-string-or-null-minlength.json --instance instance-short.json
show "ajv (JavaScript): short string"              ajv-validate        --schema schema-type-string-or-null-minlength.json --instance instance-short.json
show "an eleven-character string"                  cat instance-long.json
show "jsonschema (Python): long string"            jsonschema-validate --schema schema-type-string-or-null-minlength.json --instance instance-long.json
show "ajv (JavaScript): long string"               ajv-validate        --schema schema-type-string-or-null-minlength.json --instance instance-long.json
show "jsonschema (Python): null"                   jsonschema-validate --schema schema-type-string-or-null-minlength.json --instance instance-null.json
show "ajv (JavaScript): null"                      ajv-validate        --schema schema-type-string-or-null-minlength.json --instance instance-null.json

doc "keywords that compare values are not kind-scoped" << 'END_DOC'
Some keywords compare the instance to literal values rather than
asserting something about a kind. "enum", whose value is a list of
JSON values, is satisfied only by an instance equal to one of them;
"const" is the one-value form of the same idea. (Demo 09 takes both
up in full.) These apply to an instance of any kind: null is a value,
and if it is not in the list, it is rejected.

So two keywords that both read as "restrict what may appear here"
behave differently when null arrives. {"enum": ["x", "y"]} rejects
null, because null is not "x" or "y". {"minimum": 5} accepts null,
because "minimum" is a numeric constraint and null is not a number.
Knowing which of the two families a keyword belongs to -- value
comparison, or kind-scoped assertion -- is what tells you whether it
will hold when an unexpected kind of value arrives.
END_DOC

doc "the examples" << 'END_DOC'
The null instance is checked against two schemas of one keyword each:
an "enum" of two strings, which rejects it, and a "minimum" of 5,
which accepts it.
END_DOC

show "an enumeration of two strings"          cat schema-enum.json
show "jsonschema (Python): null vs \"enum\""  jsonschema-validate --schema schema-enum.json    --instance instance-null.json
show "ajv (JavaScript): null vs \"enum\""     ajv-validate        --schema schema-enum.json    --instance instance-null.json
show "a numeric lower bound"                  cat schema-minimum.json
show "jsonschema (Python): null vs \"minimum\""  jsonschema-validate --schema schema-minimum.json --instance instance-null.json
show "ajv (JavaScript): null vs \"minimum\""     ajv-validate        --schema schema-minimum.json --instance instance-null.json

exit 0
