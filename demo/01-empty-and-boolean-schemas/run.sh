#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 01: empty and boolean schemas"

doc "a schema need not be an object" << 'END_DOC'
A schema is itself JSON -- a single JSON document. And what may serve
as a schema is specified the way anything in JSON is specified: by a
schema. That published schema-for-schemas, the meta-schema, admits
exactly two of JSON's six kinds of values: boolean, and object --
which, despite its name, is just a string-keyed map, written {...}.
Both boolean values are schemas: true is the schema that accepts every
instance, false the schema that rejects every instance. Some objects
are valid schemas and some are not; the last cells below show the
difference. The empty object {} is a schema, declares no constraints,
and so behaves exactly like true.

That {} accepts everything is the fact people most often misread. A
schema can reject an instance only by stating a constraint the
instance violates, and every constraint can only remove instances from
the accepted set -- so a schema that states no constraints accepts
everything.
END_DOC

doc "schemas can declare a version of JSON Schema" << 'END_DOC'
JSON Schema has evolved through several versions, and a schema
ordinarily declares the version it targets: a top-level entry in the
schema whose key is "$schema" and whose value is that version's URI.
In all of these demos, the validation tools invoked assume and enforce
the current version, 2020-12; for that reason the demos generally omit
the declaration, and by default the tools refuse to validate against a
schema that declares a different version (demo 19 shows this).
END_DOC

doc "the examples" << 'END_DOC'
Every check in this demo runs twice, through two commands this
repository provides: jsonschema-validate, wrapping the Python
jsonschema library, and ajv-validate, wrapping the JavaScript ajv
library. Each prints a verdict, VALID or INVALID.

The claim under test in these examples is that each of the three
schemas employed -- {}, true, and false -- gives the same verdict no
matter what instance it is handed. One instance cannot show that, so
each schema is tried on two instances of different kinds: an object
with one member, and null. The same verdict twice is what shows the
instance did not matter. Neither instance is the subject; the schema
is the only thing whose meaning is at stake. Each file is introduced
just before its first use.
END_DOC

show "the first instance"                       cat instance.json
show "empty schema (accepts anything)"          cat schema-empty.json
show "jsonschema (Python): object vs {}"        jsonschema-validate --schema schema-empty.json   --instance instance.json
show "ajv (JavaScript): object vs {}"           ajv-validate        --schema schema-empty.json   --instance instance.json
show "the second instance"                      cat instance-null.json
show "jsonschema (Python): null vs {}"          jsonschema-validate --schema schema-empty.json   --instance instance-null.json
show "ajv (JavaScript): null vs {}"             ajv-validate        --schema schema-empty.json   --instance instance-null.json

doc "an instance can be any JSON value" << 'END_DOC'
The null instance above is an ordinary JSON document. JSON has
exactly six kinds of values -- object, array, string, number, boolean,
and null -- and a JSON document is a serialization of exactly one
value, of any of the six kinds. Nothing requires the value to be an
object or an array. A file containing only 5, or only "hello", or only
null, is a complete JSON document. The notation alone decides the
kind: 5 is a number, but "5" -- the same digit between quotation
marks -- is a string, and the two are values of different kinds.

JSON's syntax comes from JavaScript, and it is easy to assume that
whatever JavaScript accepts as a literal value, JSON accepts too. The
reverse is true: every JSON document is a legal JavaScript expression,
but much that JavaScript accepts is not JSON. Keys without quotes,
single-quoted strings, trailing commas, comments, and JavaScript's
undefined and NaN values are all rejected by every JSON parser.

The next cells show a bare number and a bare string, each as an entire
document, checked against the empty schema. The verdict is not the
point -- {} accepts everything, so VALID is assured. The point is that
both validators accept each file as an instance at all: a single
number is a document, and a single string is a document. And a schema
can require exactly that -- that the whole instance be a string, say,
and nothing else; demo 02 shows how.
END_DOC

show "a number as the entire document"          cat instance-number.json
show "jsonschema (Python): number vs {}"        jsonschema-validate --schema schema-empty.json   --instance instance-number.json
show "ajv (JavaScript): number vs {}"           ajv-validate        --schema schema-empty.json   --instance instance-number.json
show "a string as the entire document"          cat instance-string.json
show "jsonschema (Python): string vs {}"        jsonschema-validate --schema schema-empty.json   --instance instance-string.json
show "ajv (JavaScript): string vs {}"           ajv-validate        --schema schema-empty.json   --instance instance-string.json

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

doc "not every object is a valid schema" << 'END_DOC'
When a schema is an object, its members are how it states constraints.
JSON Schema defines a fixed set of member names, called keywords, and
gives each a meaning: "type", for example, is the keyword whose value
names which of the six kinds of values an instance must be. Later demos
introduce the keywords one at a time. Two facts about them settle
which objects are valid schemas.

First, a member whose name is not a keyword is simply ignored -- name
and value together; the value may be anything and is never examined.
This is deliberate, and useful in two ways. A schema can carry
explanations for the people who read it -- welcome, since JSON has no
comment syntax -- and it can carry extra instructions for tools that
look for members beyond the standard's own (demo 16 uses this to give
validators the exact error message to print). But the same tolerance
has a sharp edge: a misspelled keyword is not an error, just an
ignored member, and the constraint it was meant to state silently
disappears. It follows that an object none of whose member names is a
keyword states no constraints, so it is a valid schema and behaves
exactly like {}.

Second, a member whose name is a keyword must have a value of the form
that keyword requires. The value of "type" must be a string naming a
kind (or a list of such strings); the number 5 is neither. An object
containing "type": 5 is therefore not a valid schema, and both
validators refuse to proceed rather than render a verdict. That
refusal is the meta-schema described in the first cell doing its job:
the offered "schema" was checked against the schema for schemas, and
its "type" member, paired with the value 5, failed to be meaningful.

The two "schemas" below illustrate the two facts in turn. The first,
{"foo": "bar"}, has one member, "foo", whose name is not a keyword; the
member is ignored, its value "bar" along with it, and the first schema
is valid and states no constraints. The second, {"type": 5}, has one
member, "type", whose name is a keyword but whose value 5 is not of the
form "type" requires; the second "schema" is not valid.
END_DOC

show "a schema with a member no keyword recognizes"   cat schema-unknown-member.json
show "jsonschema (Python): unknown member"            jsonschema-validate --schema schema-unknown-member.json --instance instance.json
show "ajv (JavaScript): unknown member"               ajv-validate        --schema schema-unknown-member.json --instance instance.json
show "a \"schema\" that is not valid"                 cat schema-type-5.json
show "jsonschema (Python): refusal, not a verdict"    jsonschema-validate --schema schema-type-5.json --instance instance.json
show "ajv (JavaScript): refusal, not a verdict"       ajv-validate        --schema schema-type-5.json --instance instance.json

exit 0
