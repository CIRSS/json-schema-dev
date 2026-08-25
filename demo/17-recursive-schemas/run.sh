#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 17: recursive schemas"

doc "a schema that names itself" << 'END_DOC'
The data in this demo is a comment thread, the shape a forum or
a blog stores: a comment has a "text", and can carry "replies"
-- an array whose members are comments again. Data like this
nests to any depth, and a schema for it must describe the
nesting without writing it out: the schema for a comment refers
to the schema for a comment.

The schema below does this with "$ref": "#". The # is demo 12's
path into the document -- with nothing after it, the path names
the document itself, so the "items" schema for "replies" is the
whole schema again. JSON Schema itself is built on this
recursion: what counts as a schema is specified by a schema, the
meta-schema (demo 01), and a schema's parts are schemas (demo
09), so the meta-schema describes those positions with
references back to itself.

An instance is a finite document, so validation always reaches
the bottom: each reply is checked as a comment, its replies
likewise, until the replies run out. Three instances follow: a
comment with no replies; a thread three comments deep, accepted;
and a thread whose deepest reply lacks "text", rejected -- the
error's JSON Pointer (demo 13) walking the whole path down to
the failing comment.
END_DOC

show "the comment schema, referencing itself"  cat schema-comment-root-ref.json

show "a comment with no replies"         cat instance-comment.json
show "jsonschema (Python): no replies"            jsonschema-validate --schema schema-comment-root-ref.json --instance instance-comment.json
show "ajv (JavaScript): no replies"               ajv-validate        --schema schema-comment-root-ref.json --instance instance-comment.json

show "a thread three comments deep"      cat instance-thread.json
show "jsonschema (Python): a thread"              jsonschema-validate --schema schema-comment-root-ref.json --instance instance-thread.json
show "ajv (JavaScript): a thread"                 ajv-validate        --schema schema-comment-root-ref.json --instance instance-thread.json

show "the deepest reply lacks text"      cat instance-textless-reply.json
show "jsonschema (Python): textless reply"        jsonschema-validate --schema schema-comment-root-ref.json --instance instance-textless-reply.json
show "ajv (JavaScript): textless reply"           ajv-validate        --schema schema-comment-root-ref.json --instance instance-textless-reply.json

doc "the same recursion through a named definition" << 'END_DOC'
"$ref": "#" works because the comment schema is the whole
document. The more common spelling puts the definition under
"$defs" and lets it reference itself by its own path: inside the
definition, "$ref": "#/$defs/comment" names the definition it
sits in. In the schema below, the "$defs" holds the definition
and applies nothing (demo 12); the "$ref" beside it is what
applies the definition to the instance. The same three instances
return the same three verdicts.
END_DOC

show "the same schema as a named definition"  cat schema-comment-defs-ref.json

show "jsonschema (Python): defs form, no replies"     jsonschema-validate --schema schema-comment-defs-ref.json --instance instance-comment.json
show "ajv (JavaScript): defs form, no replies"        ajv-validate        --schema schema-comment-defs-ref.json --instance instance-comment.json
show "jsonschema (Python): defs form, a thread"       jsonschema-validate --schema schema-comment-defs-ref.json --instance instance-thread.json
show "ajv (JavaScript): defs form, a thread"          ajv-validate        --schema schema-comment-defs-ref.json --instance instance-thread.json
show "jsonschema (Python): defs form, textless reply" jsonschema-validate --schema schema-comment-defs-ref.json --instance instance-textless-reply.json
show "ajv (JavaScript): defs form, textless reply"    ajv-validate        --schema schema-comment-defs-ref.json --instance instance-textless-reply.json

doc "why the named form: the definition survives inside a larger schema" << 'END_DOC'
Recursion more often lives inside a schema that is not recursive
as a whole: one part of the data nests, the rest does not, and
only the definition for the nesting part refers to itself. The
schema below describes a page -- a "title" and an array of
"comments" -- and its "$defs" holds the same self-referencing
comment definition.
Here "$ref": "#" could not have described a comment: the # names
the whole document, and the whole document is now the page
schema.

The page below carries a thread, and the same textless reply is
caught at the same kind of depth, the JSON Pointer now starting
at /comments.
END_DOC

show "a page schema holding the comment definition"  cat schema-page.json

show "a page with a thread"              cat instance-page.json
show "jsonschema (Python): page, thread"          jsonschema-validate --schema schema-page.json --instance instance-page.json
show "ajv (JavaScript): page, thread"             ajv-validate        --schema schema-page.json --instance instance-page.json

show "a page with a textless reply"      cat instance-page-textless.json
show "jsonschema (Python): page, textless reply"  jsonschema-validate --schema schema-page.json --instance instance-page-textless.json
show "ajv (JavaScript): page, textless reply"     ajv-validate        --schema schema-page.json --instance instance-page-textless.json

exit 0
