#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 06: annotations vs assertions"

doc "keywords are either assertions or annotations" << 'END_DOC'
Every keyword met so far -- "type", "properties", "items", "required",
"minLength", and the rest -- is an assertion: a keyword that can make
an instance invalid. JSON Schema also defines annotations: keywords
that attach information to a schema for people and tools to read, and
that never contribute an error. A validator reads an annotation and
moves on; whatever it says, the verdict is unaffected.

The division is invisible in the syntax. Annotations sit beside
assertions in the same object, spelled the same way, and a schema
full of them looks more rigorous than the same schema without them.
Nothing marks which members are inert.
END_DOC

doc "\"title\", \"description\", and \"\$comment\" are annotations" << 'END_DOC'
Three annotations carry prose. "title" is a short name for what the
schema describes; "description" is a longer explanation of it; and
"$comment" is a note for the schema's maintainers, meant never to be
shown to users of the schema. Each has a string value, and none is
ever checked against an instance. Demo 01 noted that a schema can
carry explanations for its readers because unknown members are
ignored; these three keywords are the standard's own provision for
exactly that, and using them is better than inventing member names,
since tools know to display them.

Because they assert nothing, prose that contradicts the schema's
assertions goes unremarked. A description can say the value is a JSON
number and never a JSON string, beside "type": "string", and a
validator sees no contradiction, because from its side the
description was never a claim about the instance at all. That is what
makes a stale description worse than none: it reads as a constraint
and behaves as a comment.
END_DOC

doc "the examples" << 'END_DOC'
One schema whose "description" and "$comment" both say the value is a
JSON number and never a JSON string, and whose one assertion is
"type": "string", is checked against two instances that differ only
in their quotation marks: "12.50", a string, and 12.50, a number. The
string -- the very thing the prose forbids -- is accepted by both
validators. The number -- exactly what the prose asks for -- is
rejected by both. Only the assertion was ever consulted. The irony is
the lesson: a schema's description can say the opposite of what its
assertions enforce, validation will enforce the assertions, and a
reader who turns to the description to learn why a document failed
will be pointed the wrong way.
END_DOC

show "a schema whose prose disagrees with its assertion"  cat schema-annotated.json
show "an amount written as a string"                      cat instance-string.json
show "jsonschema (Python): the string"                    jsonschema-validate --schema schema-annotated.json --instance instance-string.json
show "ajv (JavaScript): the string"                       ajv-validate        --schema schema-annotated.json --instance instance-string.json
show "the same amount as a number"                        cat instance-number.json
show "jsonschema (Python): the number"                    jsonschema-validate --schema schema-annotated.json --instance instance-number.json
show "ajv (JavaScript): the number"                       ajv-validate        --schema schema-annotated.json --instance instance-number.json

doc "\"format\" is an annotation too, by default" << 'END_DOC'
"format" is a keyword whose value names a well-known form of string
-- "email", "date-time", "uri", and others. The keyword is intended
to provide a means of validating the format of string values, but
unfortunately different implementations disagree on what counts as,
say, a valid email address. For this reason, in the 2020-12
specification "format" is an annotation by default: an implementation
may check the format, but checking is a separate option that must be
switched on. The two commands used in these demos leave it off, on
both legs alike, so to them "format" is a pure annotation, accepted in
silence like "title" or "description". Where a string's shape
matters, these demos state it with "pattern".

The keyword that can reliably constrain the shape of a string is
"pattern", whose value is a regular expression the string must match;
demo 07 takes it up in full. So a rule such as "this must be an email
address" can be written two ways that look equally strict and behave
oppositely: as a "format", which passes anything, or as a "pattern",
which rejects what does not match.

The "pattern" below -- runs of letters and digits separated by dots,
one @, then a domain of one or more dotted runs ending in a run of
letters -- is not a definition of an email address; no short regular
expression is, and this one excludes hyphens, underscores, and plus
signs that real addresses may contain. Its virtue is different: what
it checks is exactly what it says, no more and no less, on every
validator alike. "format": "email" promises a correctness that no
implementation quite delivers, and each delivers differently. A
"pattern" makes the author decide, and disclose, how much of the
syntax is actually being enforced.

The rule that follows: whatever must be enforced, write as a
"pattern". Use "format" to say what a value means, never to make it
so.
END_DOC

doc "the examples" << 'END_DOC'
Two schemas differ only in how the rule is written: as "format":
"email", or as the "pattern" just described. Each is checked against
two instances that differ in one character: an email address, and the
same string with its @ replaced by a dot, which is not one. The
"format" schema accepts both. The "pattern" schema accepts the address
and rejects the near-miss.
END_DOC

show "an email address"                              cat instance-email.json
show "the same string with a dot for the @"          cat instance-missing-at-sign.json
show "the rule written as a \"format\""              cat schema-format.json
show "jsonschema (Python): address vs \"format\""    jsonschema-validate --schema schema-format.json  --instance instance-email.json
show "ajv (JavaScript): address vs \"format\""       ajv-validate        --schema schema-format.json  --instance instance-email.json
show "jsonschema (Python): near-miss vs \"format\""  jsonschema-validate --schema schema-format.json  --instance instance-missing-at-sign.json
show "ajv (JavaScript): near-miss vs \"format\""     ajv-validate        --schema schema-format.json  --instance instance-missing-at-sign.json
show "the rule written as a \"pattern\""             cat schema-pattern.json
show "jsonschema (Python): address vs \"pattern\""   jsonschema-validate --schema schema-pattern.json --instance instance-email.json
show "ajv (JavaScript): address vs \"pattern\""      ajv-validate        --schema schema-pattern.json --instance instance-email.json
show "jsonschema (Python): near-miss vs \"pattern\"" jsonschema-validate --schema schema-pattern.json --instance instance-missing-at-sign.json
show "ajv (JavaScript): near-miss vs \"pattern\""    ajv-validate        --schema schema-pattern.json --instance instance-missing-at-sign.json

exit 0
