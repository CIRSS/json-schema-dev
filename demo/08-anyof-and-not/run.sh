#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 08: anyOf and not"

doc "combining schemas: and, or, not" << 'END_DOC'
An instance satisfies a schema object only if it satisfies every
keyword in it: a schema object is an "and" of its members. JSON
Schema also has keywords whose values are schemas and whose only job
is to combine the verdicts of those schemas. "allOf" holds a list of
schemas and is satisfied when every one of them is; "anyOf" holds a
list and is satisfied when at least one is; "oneOf" holds a list and
is satisfied when exactly one is; "not" holds one schema and is
satisfied when that schema is not; "if", "then", and "else" hold one
schema each, and whether "then" or "else" is applied depends on
whether "if" is satisfied. Together these give a schema author and,
or, exactly-one, negation, and choice.

This demo shows "anyOf" and "not". The schemas they combine here are
each a single "pattern", chosen because what a pattern accepts can
be checked by eye against the string. "oneOf" (demo 10), "if",
"then", and "else" (demo 11), and "allOf" (demo 12) each get their
own demo.
END_DOC

section "anyOf"

doc "or, written two ways" << 'END_DOC'
Suppose a version field must be either a three-part number such as
1.2.3 or the word "latest". As a single pattern:

    ^([0-9]+[.][0-9]+[.][0-9]+|latest)$

Reading it left to right: [0-9]+ is one or more digits. [.] is a
class containing only the dot, and it is written that way because a
bare . in a pattern means "any single character" -- [.] means the
dot itself. So [0-9]+[.][0-9]+[.][0-9]+ is three runs of digits
separated by dots. The | that follows is alternation: the pattern
matches what is on its left or what is on its right, here the word
latest. The parentheses group the two alternatives, so that the
anchors ^ and $ apply to the whole of either one rather than to just
one side.

The same requirement can instead be written with "anyOf" and two
plain patterns, one per alternative:

    "anyOf": [ {"pattern": "^[0-9]+[.][0-9]+[.][0-9]+$"},
               {"pattern": "^latest$"} ]

An instance satisfies "anyOf" if it satisfies at least one schema in
the list. The two forms accept exactly the same strings and reject
exactly the same strings, and the verdicts below agree case for
case. What "anyOf" changes is how the requirement reads: each
alternative is a short pattern on its own line, and a third
alternative is a third entry in the list rather than an edit inside
a longer expression. (Each entry is a complete schema, so it can
also be given a name and referred to from wherever it is needed;
demo 12 shows how.)
END_DOC

doc "the examples" << 'END_DOC'
Both schemas are checked, by both validators, against three strings:
a three-part version, the word "latest", and a two-part version that
neither alternative accepts. On the rejection the verdicts
agree but the reports do not: Python says only that no alternative
matched, while Ajv reports each alternative's failure separately
before the summary -- so a reader of the Ajv output can see which
pattern the value came closest to satisfying, and why it fell short.
END_DOC

show "the alternation pattern"                    cat schema-alternation.json
show "the anyOf schema"                           cat schema-anyof.json
show "a three-part version"                       cat instance-version.json
show "jsonschema (Python): alternation, version"  jsonschema-validate --schema schema-alternation.json --instance instance-version.json
show "ajv (JavaScript): alternation, version"     ajv-validate        --schema schema-alternation.json --instance instance-version.json
show "jsonschema (Python): anyOf, version"        jsonschema-validate --schema schema-anyof.json --instance instance-version.json
show "ajv (JavaScript): anyOf, version"           ajv-validate        --schema schema-anyof.json --instance instance-version.json
show "the word latest"                            cat instance-latest.json
show "jsonschema (Python): alternation, latest"   jsonschema-validate --schema schema-alternation.json --instance instance-latest.json
show "ajv (JavaScript): alternation, latest"      ajv-validate        --schema schema-alternation.json --instance instance-latest.json
show "jsonschema (Python): anyOf, latest"         jsonschema-validate --schema schema-anyof.json --instance instance-latest.json
show "ajv (JavaScript): anyOf, latest"            ajv-validate        --schema schema-anyof.json --instance instance-latest.json
show "a two-part version"                         cat instance-two-part.json
show "jsonschema (Python): alternation, two-part" jsonschema-validate --schema schema-alternation.json --instance instance-two-part.json
show "ajv (JavaScript): alternation, two-part"    ajv-validate        --schema schema-alternation.json --instance instance-two-part.json
show "jsonschema (Python): anyOf, two-part"       jsonschema-validate --schema schema-anyof.json --instance instance-two-part.json
show "ajv (JavaScript): anyOf, two-part"          ajv-validate        --schema schema-anyof.json --instance instance-two-part.json

section "not"

doc "and not this" << 'END_DOC'
"not" holds one schema and inverts its verdict: the instance is
accepted when the schema inside rejects it, and rejected when the
schema inside accepts it.

The schema below has two members, a "pattern" and a "not", and an
instance must satisfy both. The "pattern" is ^[0-9a-f]{4}$: four
lowercase hexadecimal digits. The "not" holds {"pattern": "^0{4}$"},
so it rejects the one string 0000 and accepts everything else.
Together: four hexadecimal digits, and not 0000.

A single regular expression can express "and not" only with
lookahead, which demo 07 used for the trailing newline and which not
every engine supports; "not" needs only a plain keyword and a plain
pattern, and every validator has both.
END_DOC

doc "the examples" << 'END_DOC'
One schema, checked by both validators against a hexadecimal string
and against "0000".
END_DOC

show "the schema"                                 cat schema-hex-not-zero.json
show "a hexadecimal string"                       cat instance-hex.json
show "jsonschema (Python): hex"                   jsonschema-validate --schema schema-hex-not-zero.json --instance instance-hex.json
show "ajv (JavaScript): hex"                      ajv-validate        --schema schema-hex-not-zero.json --instance instance-hex.json
show "all zeros"                                  cat instance-zeros.json
show "jsonschema (Python): zeros"                 jsonschema-validate --schema schema-hex-not-zero.json --instance instance-zeros.json
show "ajv (JavaScript): zeros"                    ajv-validate        --schema schema-hex-not-zero.json --instance instance-zeros.json

doc "the rule: several plain patterns over one clever one" << 'END_DOC'
Where a requirement on a string is a choice between alternatives, or
a match with an exception, write each part as its own plain pattern
and let "anyOf" and "not" do the combining. Each part stays readable
and separately testable, and the combining is done by keywords whose
meaning is the same in every validator rather than by
regular-expression features the validators' engines may not share.
END_DOC

exit 0
