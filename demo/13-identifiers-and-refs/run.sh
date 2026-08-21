#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 13: identifiers and refs"

doc "what \$id is for" << 'END_DOC'
"$id" declares the identity of a schema -- a URI that names it.

An "$id" on the outermost schema object of a document names the
document's schema as a whole. It is how other documents refer to this
one (demo 16), and it is what a #-less "$ref" in the same document is
completed against. An "$id" deeper inside -- on a subschema under
"$defs" -- names just that one subschema.

Only one thing ever consults the "$id": a "$ref" that does not start
with #. A "$ref" that starts with # looks inside the current document
(demo 12's #/$defs/Hex) and ignores the "$id" entirely -- so a schema whose
"$ref"s all start with # can carry an "$id", or not, with no
difference in behavior.

Two instances serve the whole demo -- "a" as a number and "a" as a
string -- so that only the schemas vary.
END_DOC

show "a number for a"  cat instance-number.json
show "a string for a"  cat instance-string.json

doc "three ways to reference a subschema in the same document" << 'END_DOC'
The three schemas that follow hold the same definition -- "a" must be
a number -- as a subschema under "$defs", and differ only in how the
"$ref" reaches it. Each is checked by both validators against both
instances: the number is accepted, the string rejected.
END_DOC

doc "by local path" << 'END_DOC'
The "$ref" walks to the definition by its position: #/$defs/named,
demo 12's way. The path after the # is JSON Pointer, a small standard
of its own (RFC 6901) for naming a location in any JSON document. The
error messages below use the same notation: the /a in
INVALID: /a: 'hello' is not of type 'number' is a JSON Pointer naming
the failing member of the instance.
END_DOC

show "referencing by local path"               cat schema-local-path.json
show "jsonschema (Python): by local path, number"   jsonschema-validate --schema schema-local-path.json --instance instance-number.json
show "ajv (JavaScript): by local path, number"      ajv-validate        --schema schema-local-path.json --instance instance-number.json
show "jsonschema (Python): by local path, string"   jsonschema-validate --schema schema-local-path.json --instance instance-string.json
show "ajv (JavaScript): by local path, string"      ajv-validate        --schema schema-local-path.json --instance instance-string.json

doc "by local anchor" << 'END_DOC'
The keyword "$anchor", written as a member of the subschema itself
with a plain name as its value, makes that subschema reachable as
#named -- a # form, but a name rather than a path. It is the
"$anchor" value that #named reaches, not the "$defs" key: the two
match here, as they usually do in practice, but only the anchor is a
name a "$ref" can use.
END_DOC

show "referencing by local anchor"             cat schema-anchor.json
show "jsonschema (Python): by local anchor, number"  jsonschema-validate --schema schema-anchor.json --instance instance-number.json
show "ajv (JavaScript): by local anchor, number"     ajv-validate        --schema schema-anchor.json --instance instance-number.json
show "jsonschema (Python): by local anchor, string"  jsonschema-validate --schema schema-anchor.json --instance instance-string.json
show "ajv (JavaScript): by local anchor, string"     ajv-validate        --schema schema-anchor.json --instance instance-string.json

doc "by full URI" << 'END_DOC'
The subschema carries an "$id" of its own, and the "$ref" names it by
that full URI. The URI looks like something to be fetched. It is not:
the validator matches it, as a string, against the "$id"s of the
schemas it already holds. Nothing goes over the network.
END_DOC

show "referencing by full URI"                 cat schema-subschema-id.json
show "jsonschema (Python): by full URI, number"     jsonschema-validate --schema schema-subschema-id.json --instance instance-number.json
show "ajv (JavaScript): by full URI, number"        ajv-validate        --schema schema-subschema-id.json --instance instance-number.json
show "jsonschema (Python): by full URI, string"     jsonschema-validate --schema schema-subschema-id.json --instance instance-string.json
show "ajv (JavaScript): by full URI, string"        ajv-validate        --schema schema-subschema-id.json --instance instance-string.json
doc "the trap: a relative \$ref against an \$id" << 'END_DOC'
There is one more form a "$ref" can take: a relative URI -- neither a
# form nor a full URI, but a shorthand, completed against the "$id"
the way a relative link on a web page is completed against the page's
address. In a document with top-level schema "$id"
https://example.org/schemas/root, a "$ref" of "sibling" means
https://example.org/schemas/sibling. Between documents that share a
base, the shorthand saves repeating it.

The trap is that this shorthand also captures honest mistakes. The
schema below writes "$ref": "named", intending the "$defs" entry of
that name. But without the #, named is not looked up inside the
document at all: it is completed to
https://example.org/schemas/named, a document neither validator has
and neither will go looking for. The definition sitting right there
is never consulted.

By now the word named has been reached three ways: #/$defs/named (a
path), #named (an anchor), and bare named (another document). The word is
the same; only the marks around it decide what it means -- and with an
"$id" declared, forgetting the marks silently changes which one you
wrote.

Both validators report an error rather than a verdict, and exit 2, at
the moments demo 12 established: Ajv while compiling the schema,
jsonschema when validation reaches the reference.
END_DOC

show "referencing by relative URI"             cat schema-relative-ref.json
show "jsonschema (Python): by relative URI"    jsonschema-validate --schema schema-relative-ref.json --instance instance-string.json
show "ajv (JavaScript): by relative URI"       ajv-validate        --schema schema-relative-ref.json --instance instance-string.json

doc "the rules" << 'END_DOC'
1. A "$ref" that starts with # looks inside the current document: by
   path (#/$defs/Name) or by anchor (#name).

2. A "$ref" that does not start with # is resolved by "$id". Written
   in full, it is looked up among the schemas the validator already
   holds -- this document (its outermost "$id"), a subschema with its
   own "$id", or another file it was handed (demo 16). Written as a
   relative URI, it is first completed against the current document's
   "$id", then looked up the same way. Nothing is ever fetched.

3. "$id" exists to give schemas the names rule 2 uses. Until a "$ref"
   without # is in play, an "$id" changes nothing.

4. The trap is a "$ref" meant for rule 1 that falls under rule 2: with
   an "$id" declared, leaving the # off turns an inside-the-document
   path into the name of another document.
END_DOC

exit 0
