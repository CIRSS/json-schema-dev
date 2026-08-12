#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

doc "type asserts what kind of value the instance is" << 'END_DOC'
The previous demo showed that {} accepts everything. Constraining anything
starts with type: the schema below adds one keyword, and instances now
divide into the kind it names and everything else. The two instances that
follow differ only in kind — one is an object, one is a string.
END_DOC

show "the schema (type object)"          cat schema-type.json

show "an object"                         cat instance-object.json
show "jsonschema (Python): object"       jsonschema-validate --schema schema-type.json --instance instance-object.json
show "ajv (JavaScript): object"          ajv-validate        --schema schema-type.json --instance instance-object.json

show "a string"                          cat instance-string.json
show "jsonschema (Python): string"       jsonschema-validate --schema schema-type.json --instance instance-string.json
show "ajv (JavaScript): string"          ajv-validate        --schema schema-type.json --instance instance-string.json

doc "properties constrains the shape of a named member" << 'END_DOC'
The second schema adds a properties entry: the member a, if present, must
be a number. The two instances below differ only in the value of a. This is
how nearly every real schema is built — an object type with a properties
map — and each entry in the map is itself a schema, a point later demos
return to.
END_DOC

show "the schema (a must be a number)"     cat schema-properties.json

show "a is a number"                       cat instance-object.json
show "jsonschema (Python): a is a number"  jsonschema-validate --schema schema-properties.json --instance instance-object.json
show "ajv (JavaScript): a is a number"     ajv-validate        --schema schema-properties.json --instance instance-object.json

show "a is a string"                       cat instance-wrong-type.json
show "jsonschema (Python): a is a string"  jsonschema-validate --schema schema-properties.json --instance instance-wrong-type.json
show "ajv (JavaScript): a is a string"     ajv-validate        --schema schema-properties.json --instance instance-wrong-type.json

doc "what properties does not do" << 'END_DOC'
Two more instances against the same schema. The first omits a entirely; the
second carries an extra member the schema never mentions. Both pass.

properties is conditional: "if this key appears, here is its shape." It
neither demands that a key appear (that is required's job — demo 04) nor
forbids keys it does not list (closing a schema is its own construct, taken
up in demo 13). A schema built from type and properties alone describes
shapes, and only shapes.
END_DOC

show "a omitted"                          cat instance-empty.json
show "jsonschema (Python): a omitted"     jsonschema-validate --schema schema-properties.json --instance instance-empty.json
show "ajv (JavaScript): a omitted"        ajv-validate        --schema schema-properties.json --instance instance-empty.json

show "an undeclared extra member"         cat instance-extra.json
show "jsonschema (Python): extra member"  jsonschema-validate --schema schema-properties.json --instance instance-extra.json
show "ajv (JavaScript): extra member"     ajv-validate        --schema schema-properties.json --instance instance-extra.json

exit 0
