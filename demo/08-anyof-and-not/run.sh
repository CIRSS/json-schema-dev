#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 08: anyOf and not"

doc "combining predicates: and, or, not" << 'END_DOC'
Every schema so far has been a single object whose keywords all apply
at once: a schema object is an "and" of its members. JSON Schema also
has keywords whose values are themselves schemas and whose job is to
combine verdicts. "allOf" is "and" made explicit, over a list of
schemas; "anyOf" is "or", satisfied if at least one schema in its
list is; "oneOf" is "exactly one"; "not" is negation, satisfied only
if the schema inside is not; and "if"/"then"/"else" chooses between
schemas by a test. Together they are the boolean applicators, and
they let a schema be assembled from small predicates rather than
written as one large one.

This demo shows "anyOf" and "not", using "pattern" as the small
predicate because a pattern is self-contained: what it accepts can
be read off the string. "oneOf", "if"/"then"/"else", and "allOf"
each get their own demo later.
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
the list. The two forms accept exactly the same strings and
reject exactly the same strings, and the verdicts below agree case
for case. What "anyOf" changes is the reading: each
alternative is a short pattern on its own line, and adding a third
alternative is adding a third entry rather than editing the inside
of a longer expression. (Each entry is a complete schema, so it can
also be given a name and referred to from wherever it is needed;
demo 12 shows how.)
END_DOC

doc "the examples" << 'END_DOC'
Both schemas are checked against three strings: a three-part version,
the word "latest", and a two-part version that neither alternative
admits. Both validators, every case. On the rejection the verdicts
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
"not" takes one schema and inverts its verdict. Placed beside a
"pattern", it says: matches this, and not that. A regular expression
can express "not that" only with lookaround, which demo 07 used for
the trailing newline and which not every engine supports; "not" says
it with a plain keyword and a plain pattern, in every validator.

The example: a four-digit hexadecimal identifier that must not be
all zeros. The pattern admits the hexadecimal strings; "not" removes
the one string among them that is reserved.
END_DOC

doc "the examples" << 'END_DOC'
One schema, checked against a hexadecimal string and against "0000".
Both validators.
END_DOC

show "the schema"                                 cat schema-hex-not-zero.json
show "a hexadecimal string"                       cat instance-hex.json
show "jsonschema (Python): hex"                   jsonschema-validate --schema schema-hex-not-zero.json --instance instance-hex.json
show "ajv (JavaScript): hex"                      ajv-validate        --schema schema-hex-not-zero.json --instance instance-hex.json
show "all zeros"                                  cat instance-zeros.json
show "jsonschema (Python): zeros"                 jsonschema-validate --schema schema-hex-not-zero.json --instance instance-zeros.json
show "ajv (JavaScript): zeros"                    ajv-validate        --schema schema-hex-not-zero.json --instance instance-zeros.json

doc "the rule: several plain patterns over one clever one" << 'END_DOC'
Where a constraint on a string decomposes into alternatives or
exclusions, write each part as its own plain pattern and let "anyOf"
and "not" do the combining. Each part stays readable and separately
testable, and the combining is done by keywords every validator
implements identically rather than by regular-expression features
they may not share.
END_DOC

exit 0
