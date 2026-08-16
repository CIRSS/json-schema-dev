#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "\"required\" is what makes a member mandatory" << 'END_DOC'
Demo 02 showed that "properties" is conditional: it says what a member
must look like if the member is present, and it does not require any
member to be present. So a schema whose members are described in full
detail under "properties" still accepts the empty object {} -- the
object counterpart of demo 03's empty array, and the same shape of
trap: the constraint the author had in mind was never written.

The keyword that demands presence is "required". Its value is a list of
member names, and an object satisfies it only if it has a member of
every name in the list. The value is a list even when it names one
member: "required": ["id"]. "required" and "properties" are independent
keywords doing separate jobs -- one asks which members must be
present, the other what each member must look like -- and a schema
that means "this member must be here and must be a string" needs
both.
END_DOC

doc "the examples" << 'END_DOC'
Two schemas differ in one keyword: both describe a member "id" under
"properties", and only the second adds "required": ["id"]. Each is
checked against the empty object. The first accepts it; the second
rejects it. The second is then checked against {"id": "x"}, which it
accepts.
END_DOC

show "a schema describing \"id\" but not requiring it"  cat schema-properties-id.json
show "the empty object"                             cat instance-empty.json
show "jsonschema (Python): {} vs \"properties\" only"   jsonschema-validate --schema schema-properties-id.json --instance instance-empty.json
show "ajv (JavaScript): {} vs \"properties\" only"      ajv-validate        --schema schema-properties-id.json --instance instance-empty.json
show "the same schema with \"id\" required"             cat schema-properties-required-id.json
show "jsonschema (Python): {} vs \"required\""          jsonschema-validate --schema schema-properties-required-id.json --instance instance-empty.json
show "ajv (JavaScript): {} vs \"required\""             ajv-validate        --schema schema-properties-required-id.json --instance instance-empty.json
show "an object with \"id\" present"                    cat instance-id-string.json
show "jsonschema (Python): \"id\" present"              jsonschema-validate --schema schema-properties-required-id.json --instance instance-id-string.json
show "ajv (JavaScript): \"id\" present"                 ajv-validate        --schema schema-properties-required-id.json --instance instance-id-string.json

doc "\"required\" asks about presence, not content" << 'END_DOC'
"required" tests whether a member of the given name is present. It says
nothing about the member's value. In particular, a member whose value
is null is present: null is a value like any other, not a way of
spelling absence. An object with "id": null and an object with no "id"
member are two different documents, and only the second lacks the
member.

This matters because null is often what a program produces for a
member it could not populate. "required" alone will not catch that; it
reports the member present and asks nothing further. Ruling out the
null takes a constraint on the value -- and describing the member's
type under "properties", as the schema above does, is one.
END_DOC

doc "the examples" << 'END_DOC'
The instance {"id": null} is checked against two schemas: one with
"required" alone, which accepts it, and the schema from above, whose
"properties" entry types "id" as a string, which rejects it. The
difference is the value constraint, not "required".
END_DOC

show "an object whose \"id\" is null"                   cat instance-id-null.json
show "a schema requiring \"id\" and nothing more"       cat schema-required-only.json
show "jsonschema (Python): null vs \"required\" only"   jsonschema-validate --schema schema-required-only.json --instance instance-id-null.json
show "ajv (JavaScript): null vs \"required\" only"      ajv-validate        --schema schema-required-only.json --instance instance-id-null.json
show "jsonschema (Python): null vs \"required\" + \"type\"" jsonschema-validate --schema schema-properties-required-id.json --instance instance-id-null.json
show "ajv (JavaScript): null vs \"required\" + \"type\""    ajv-validate        --schema schema-properties-required-id.json --instance instance-id-null.json

exit 0
