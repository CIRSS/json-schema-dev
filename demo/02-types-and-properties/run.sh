#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "\"type\" names which kind of value the instance must be" << 'END_DOC'
Demo 01 introduced keywords: the member names that JSON Schema itself
defines. Each keyword has a fixed meaning, and each requires its value
to take a particular form. "type" is the first keyword to learn: it is
the simplest, and nearly every schema begins with it. Its value is a
string naming one of JSON's six kinds of values -- "object", "array",
"string", "number", "boolean", or "null" -- and an instance satisfies
it only if the instance is a value of that kind. One further name,
"integer", is accepted for the numbers with no fractional part.

A schema consisting only of a "type" keyword therefore constrains
exactly one thing, the kind of the whole instance. That answers the
question demo 01 left open -- whether a schema can require the whole
instance to be a single string: {"type": "string"} does exactly that,
and rejects everything else, objects included.
END_DOC

doc "the examples" << 'END_DOC'
Two schemas, each a single "type" keyword -- one naming object, one
naming string -- are each checked against the same two instances, an
object with one member and a bare string. Each schema accepts the
instance of its kind and rejects the other; the pair of results shows
that "type" constrains the kind of the whole instance and nothing more.
END_DOC

show "the object instance"                       cat instance-object.json
show "a schema requiring an object"              cat schema-type-object.json
show "jsonschema (Python): object vs \"type\": \"object\""  jsonschema-validate --schema schema-type-object.json --instance instance-object.json
show "ajv (JavaScript): object vs \"type\": \"object\""     ajv-validate        --schema schema-type-object.json --instance instance-object.json
show "the string instance"                       cat instance-string.json
show "jsonschema (Python): string vs \"type\": \"object\""  jsonschema-validate --schema schema-type-object.json --instance instance-string.json
show "ajv (JavaScript): string vs \"type\": \"object\""     ajv-validate        --schema schema-type-object.json --instance instance-string.json
show "a schema requiring a string"               cat schema-type-string.json
show "jsonschema (Python): object vs \"type\": \"string\""  jsonschema-validate --schema schema-type-string.json --instance instance-object.json
show "ajv (JavaScript): object vs \"type\": \"string\""     ajv-validate        --schema schema-type-string.json --instance instance-object.json
show "jsonschema (Python): string vs \"type\": \"string\""  jsonschema-validate --schema schema-type-string.json --instance instance-string.json
show "ajv (JavaScript): string vs \"type\": \"string\""     ajv-validate        --schema schema-type-string.json --instance instance-string.json

doc "\"type\" can allow more than one kind" << 'END_DOC'
The value of "type" may instead be a list of type names. An instance
satisfies such a list if it is a value of any type in the list -- the
list means "one of these." So {"type": ["string", "number"]} accepts
every string and every number, and rejects values of the other four
kinds. Nothing else about the keyword changes: it still constrains
only the kind of the whole instance.
END_DOC

doc "the examples" << 'END_DOC'
One schema whose "type" lists string and number is checked against three
instances: the string and object from above, and a bare number. The
string and the number are accepted; the object is rejected.
END_DOC

show "a schema allowing a string or a number"      cat schema-type-string-or-number.json
show "jsonschema (Python): string vs the list"     jsonschema-validate --schema schema-type-string-or-number.json --instance instance-string.json
show "ajv (JavaScript): string vs the list"        ajv-validate        --schema schema-type-string-or-number.json --instance instance-string.json
show "the number instance"                         cat instance-number.json
show "jsonschema (Python): number vs the list"     jsonschema-validate --schema schema-type-string-or-number.json --instance instance-number.json
show "ajv (JavaScript): number vs the list"        ajv-validate        --schema schema-type-string-or-number.json --instance instance-number.json
show "jsonschema (Python): object vs the list"     jsonschema-validate --schema schema-type-string-or-number.json --instance instance-object.json
show "ajv (JavaScript): object vs the list"        ajv-validate        --schema schema-type-string-or-number.json --instance instance-object.json

doc "\"properties\" constrains named members of an object" << 'END_DOC'
"properties" is the keyword that describes the members of an object
(JSON Schema's own word for an object's members is properties, which
is where the keyword's name comes from). Its value is itself an
object: each key is a member name, and each value is a schema that the
member of that name must satisfy, if the member is present. So
{"properties": {"a": {"type": "number"}}} says: if the instance has a
member named "a", that member's value must be a number. Because each
value in a "properties" object is a complete schema, the same keywords
used at the top level are used again inside it -- here, "type" -- and
this nesting is how schemas describe structure at any depth. Demo 08
takes up what it means for a schema to sit inside a schema.

Nearly every schema in practice is "type": "object" together with a
"properties" map, so this pattern recurs in almost every demo that
follows.
END_DOC

doc "the examples" << 'END_DOC'
One schema, requiring an object whose member "a", if present, is a
number, is checked against two instances that differ only in the value
of "a": a number in one, a string in the other.
END_DOC

show "the schema (\"a\", if present, must be a number)"  cat schema-properties.json
show "\"a\" is a number"                       cat instance-object.json
show "jsonschema (Python): \"a\" is a number"  jsonschema-validate --schema schema-properties.json --instance instance-object.json
show "ajv (JavaScript): \"a\" is a number"     ajv-validate        --schema schema-properties.json --instance instance-object.json
show "\"a\" is a string"                       cat instance-string-member.json
show "jsonschema (Python): \"a\" is a string"  jsonschema-validate --schema schema-properties.json --instance instance-string-member.json
show "ajv (JavaScript): \"a\" is a string"     ajv-validate        --schema schema-properties.json --instance instance-string-member.json

doc "what \"properties\" does not do" << 'END_DOC'
"properties" is conditional. Each entry says "if a member of this name
is present, here is what its value must satisfy," and nothing more. It
does not require the member to be present -- that is a separate
keyword's job ("required", demo 04) -- and it does not forbid members
it does not list; an instance may carry any number of members the
schema never mentions. Forbidding unlisted members takes a keyword of
its own, taken up in demo 13.

A schema built from "type" and "properties" alone therefore accepts the
empty object, and accepts an object full of members it knows nothing
about. It says what the members it names must look like, and is
silent about everything else.
END_DOC

doc "the examples" << 'END_DOC'
Two more instances against the same schema. The first omits "a"
entirely; the second has "a" alongside a member the schema never
mentions. Both are accepted.
END_DOC

show "\"a\" omitted"                          cat instance-empty.json
show "jsonschema (Python): \"a\" omitted"     jsonschema-validate --schema schema-properties.json --instance instance-empty.json
show "ajv (JavaScript): \"a\" omitted"        ajv-validate        --schema schema-properties.json --instance instance-empty.json
show "an unlisted extra member"           cat instance-extra.json
show "jsonschema (Python): extra member"  jsonschema-validate --schema schema-properties.json --instance instance-extra.json
show "ajv (JavaScript): extra member"     ajv-validate        --schema schema-properties.json --instance instance-extra.json

exit 0
