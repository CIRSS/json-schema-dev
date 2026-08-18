#!/usr/bin/env bash

source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"

title "json-schema-dev  ·  demo 07: pattern pitfalls"

doc "what this demo shows" << 'END_DOC'
Demo 06 established that "format" annotates and "pattern" asserts, so
any shape a string must have -- an identifier, a checksum written in
hexadecimal, a timestamp -- ends up as a "pattern". This demo shows
four ways a "pattern" can fail to mean what its author intended, each
with the same hexadecimal string as the subject.

The first failure is the author's: a pattern that is not anchored
matches anywhere inside the string, so a substring is enough to
satisfy it. The other three are the engines'. JSON Schema specifies
the regular-expression dialect of ECMA-262, the JavaScript standard,
but validators use whatever engine their host language provides, and
the engines differ at the edges: the Python engine accepts a string
that ends in a newline where JavaScript's does not, because its end
anchor $ is satisfied ahead of a final newline; a POSIX character
class is an error to one engine and a silently different expression
to the other; and the shorthand escape \d means the ASCII digits 0-9
to the JavaScript engine but, to the Python engine, any character
that Unicode classifies as a decimal digit -- the digits of Arabic,
Devanagari, Bengali, Thai, and dozens of other scripts along with
0-9. Each failure is shown by verdicts that disagree on the same
schema and instance.
END_DOC

doc "\"pattern\" and the notation used here" << 'END_DOC'
The value of "pattern" is a regular expression: a compact notation
for describing a set of strings. A string satisfies "pattern" if the
regular expression matches it. The expression is carried in the
schema as a JSON string, so JSON's own escaping applies on top of the
expression's: every backslash must be doubled, and the escape written
\d in a regular expression appears as "\\d" in a schema file.

The notation used in this demo is small. [0-9a-f] matches any one
character in the ranges 0-9 or a-f, that is, one hexadecimal digit;
{4} after it means exactly four of those; + means one or more; and ^
and $ are anchors, matching the start and the end of the string
respectively rather than any character. So ^[0-9a-f]{4}$ matches a
string that consists of exactly four hexadecimal digits and nothing
else.
END_DOC

section "an unanchored pattern"

doc "a pattern matches anywhere unless anchored" << 'END_DOC'
A regular expression is satisfied if it matches any part of the
string. Without ^ and $, [0-9a-f]{4} is satisfied by any string that
contains four hexadecimal digits somewhere, however much surrounds
them. Only the anchors turn "contains" into "is".
END_DOC

doc "the examples" << 'END_DOC'
Two schemas differ in exactly one thing: whether the pattern is
anchored. Each is checked against two instances: a four-digit
hexadecimal string, and the same four digits buried in other text.
The unanchored pattern accepts both; the anchored pattern accepts the
bare digits and rejects the buried ones.
END_DOC

show "the unanchored schema"                     cat schema-unanchored.json
show "the hex string"                            cat instance-hex.json
show "jsonschema (Python): unanchored, hex"      jsonschema-validate --schema schema-unanchored.json --instance instance-hex.json
show "ajv (JavaScript): unanchored, hex"         ajv-validate        --schema schema-unanchored.json --instance instance-hex.json
show "hex buried in other text"                  cat instance-embedded.json
show "jsonschema (Python): unanchored, embedded" jsonschema-validate --schema schema-unanchored.json --instance instance-embedded.json
show "ajv (JavaScript): unanchored, embedded"    ajv-validate        --schema schema-unanchored.json --instance instance-embedded.json
show "the anchored schema"                       cat schema-anchored.json
show "jsonschema (Python): anchored, hex"        jsonschema-validate --schema schema-anchored.json --instance instance-hex.json
show "ajv (JavaScript): anchored, hex"           ajv-validate        --schema schema-anchored.json --instance instance-hex.json
show "jsonschema (Python): anchored, embedded"   jsonschema-validate --schema schema-anchored.json --instance instance-embedded.json
show "ajv (JavaScript): anchored, embedded"      ajv-validate        --schema schema-anchored.json --instance instance-embedded.json

doc "the rule: anchor every pattern" << 'END_DOC'
An unanchored pattern asserts far less than it appears to: "contains
four hexadecimal digits somewhere" rather than "is four hexadecimal
digits". Write every pattern anchored with ^ and $ unless a substring
match is genuinely what is meant.
END_DOC

section "a trailing newline"

doc "even an anchored pattern is read by two different engines" << 'END_DOC'
The instance below is the JSON text "cafe\n": \n is JSON's escape
for a newline character inside the string, so the value is five
characters, the last of them a newline. A trailing newline is a
common defect in exactly the values patterns guard -- identifiers,
checksums, versions -- arising whenever a program reads such a value
from a file or a shell command and writes it into JSON without
stripping the newline that ended the output. An anchored pattern is
the check meant to catch it.

The anchor $ tests whether a position is the end of the string. In
JavaScript's engine only the true end passes. Python's engine makes
one exception: $ also passes just before a newline that is the last
character of the string, as though that final newline were not there
-- a habit inherited from tools that process files a line at a time.
So Python matches ^[0-9a-f]{4} to cafe, applies $ with the newline
still to come, passes, and accepts; JavaScript matches cafe, applies
$, sees a character remaining, and rejects. The same schema, the same
instance, and two verdicts -- and here only one of them is right for
the purpose. The pattern was written to catch a stray newline, and
under Python it never will: an anchored pattern alone, validated with
Python, passes the very defect it exists to reject, and gives no sign
of having done so. A schema that must catch the newline in both
engines therefore needs something more than $, which is the subject
of the next cells.
END_DOC

doc "the examples" << 'END_DOC'
One instance differs from the hex string in one character, a newline
at the end of the string value; the anchored schema is unchanged.
Python accepts it; Ajv rejects it.
END_DOC

show "hex with a trailing newline"               cat instance-trailing-newline.json
show "jsonschema (Python): trailing newline"     jsonschema-validate --schema schema-anchored.json --instance instance-trailing-newline.json
show "ajv (JavaScript): trailing newline"        ajv-validate        --schema schema-anchored.json --instance instance-trailing-newline.json

doc "catching the newline: two remedies" << 'END_DOC'
A schema cannot rely on $ alone to reject the trailing newline: under
JavaScript the plain $ rejects it, under Python it does not, and the
schema gives no sign which. A schema that must make this check has
two ways to do it.

The first is to follow the $ with a negative lookahead for a newline,
$(?!\n). Where $ passes at the true end, nothing follows and the
lookahead is satisfied; where Python's $ passes ahead of a final
newline, the lookahead sees that newline and fails, and the match
cannot succeed any other way. Its virtue is that it declares its own
purpose: anyone reading the pattern sees a construct that exists only
to refuse a trailing newline. Its cost is portability. Both engines
here support lookahead, as do most others, but the RE2 family used by
Go and Rust does not, and there the idiom is a schema error.

The second stays inside the plainest regular-expression notation and
works in every engine, because it never asks $ the question the
engines answer differently. Beside the pattern, add a second keyword:

    "not": { "pattern": "\n$" }

"not" takes a schema and inverts its verdict: the instance passes
only if it fails the schema inside. And keywords placed side by side
in one schema object are all required at once -- a schema object is
an "and" of its keywords -- so this schema says: matches
^[0-9a-f]{4}$, and does not match \n$. (This is the first appearance
of "not" in these demos; demo 08 covers it and its relatives
properly.) The inner pattern, a newline followed by $ ("\n" in a
JSON string is a newline), matches any string that ends in a newline,
in every engine; "not" turns that into "reject those". Its cost is
indirection: the intent is split across two keywords, and the stock
error message names the "not" rather than the newline.
END_DOC

doc "the examples" << 'END_DOC'
Two schemas, one per remedy, are each checked against the plain hex
string and the one with the trailing newline. Both schemas accept the
plain string and reject the newline -- in both engines.
END_DOC

show "the pattern with a lookahead"              cat schema-anchored-lookahead.json
show "jsonschema (Python): lookahead, hex"       jsonschema-validate --schema schema-anchored-lookahead.json --instance instance-hex.json
show "ajv (JavaScript): lookahead, hex"          ajv-validate        --schema schema-anchored-lookahead.json --instance instance-hex.json
show "jsonschema (Python): lookahead, newline"   jsonschema-validate --schema schema-anchored-lookahead.json --instance instance-trailing-newline.json
show "ajv (JavaScript): lookahead, newline"      ajv-validate        --schema schema-anchored-lookahead.json --instance instance-trailing-newline.json
show "the pattern with a \"not\" beside it"      cat schema-anchored-not-newline.json
show "jsonschema (Python): not, hex"             jsonschema-validate --schema schema-anchored-not-newline.json --instance instance-hex.json
show "ajv (JavaScript): not, hex"                ajv-validate        --schema schema-anchored-not-newline.json --instance instance-hex.json
show "jsonschema (Python): not, newline"         jsonschema-validate --schema schema-anchored-not-newline.json --instance instance-trailing-newline.json
show "ajv (JavaScript): not, newline"            ajv-validate        --schema schema-anchored-not-newline.json --instance instance-trailing-newline.json

doc "the rule: do not leave the newline to \$" << 'END_DOC'
For a value that must not end in a newline, end the pattern with
$(?!\n), or place "not": {"pattern": "\n$"} beside it. The first
reads better; the second runs everywhere. A pattern that does neither
is checked for the newline under JavaScript and not under Python, and
nothing in the schema says so.
END_DOC

section "a POSIX character class"

doc "a regex dialect the engines do not share" << 'END_DOC'
Some regular-expression dialects offer named character classes such
as [[:xdigit:]] -- the POSIX form, meaning any hexadecimal digit --
and many tools accept them. ECMA-262 does not define them. Handed
such a pattern, the two engines do not merely disagree on the
verdict; they disagree on what is wrong. Ajv rejects the schema
itself, as containing an invalid regular expression. Python accepts
the schema, reads [[:xdigit:] as an ordinary bracket expression
containing the literal characters [ : x d i g t, and the ]+ after
it as one or more literal ] characters, warns only that the nested
brackets look suspicious, and then applies that reading: it rejects
a perfectly good hexadecimal string, and accepts "[]" -- one
character from the bracket expression, then a ] -- which is not
hexadecimal at all.

A pattern that is valid in one engine and means something else in
another is invisible to anyone checking with only one of them -- which
is why every demo here runs both.
END_DOC

doc "the examples" << 'END_DOC'
A schema that writes "hexadecimal digits only" as the POSIX class
[[:xdigit:]] is checked against the plain hex string, and then
against the two-character string "[]". Ajv refuses the schema both
times; Python warns, reports the hex string invalid, and reports "[]"
valid.
END_DOC

show "the POSIX-class schema"                    cat schema-posix.json
show "jsonschema (Python): POSIX class, hex"     jsonschema-validate --schema schema-posix.json --instance instance-hex.json
show "ajv (JavaScript): POSIX class, hex"        ajv-validate        --schema schema-posix.json --instance instance-hex.json
show "a pair of brackets"                        cat instance-brackets.json
show "jsonschema (Python): POSIX class, brackets" jsonschema-validate --schema schema-posix.json --instance instance-brackets.json
show "ajv (JavaScript): POSIX class, brackets"   ajv-validate        --schema schema-posix.json --instance instance-brackets.json

section "the shorthand escapes"

doc "even the shorthand escapes are not shared" << 'END_DOC'
Regular expressions offer shorthand escapes for common classes: \d
for a digit, \s for a space, \w for a word character. They look like
the safe, portable choice, and both engines accept them -- but they
do not mean the same thing. For example, JavaScript's \d matches
only the ASCII digits 0-9. Python's matches any character Unicode
classifies as a decimal digit, which includes the Arabic-Indic
digits, the Devanagari digits, and dozens of other scripts' numerals.
So a string of Arabic-Indic digits satisfies ^\d+$ under one engine
and not the other, with no warning from either.
END_DOC

doc "the examples" << 'END_DOC'
A schema whose pattern is ^\d+$ is checked against a string of two
Arabic-Indic digits. Python accepts it; Ajv rejects it.
END_DOC

show "the digit-escape schema"                   cat schema-digit-escape.json
show "two Arabic-Indic digits"                   cat instance-arabic-indic-digits.json
show "jsonschema (Python): Arabic-Indic digits"  jsonschema-validate --schema schema-digit-escape.json --instance instance-arabic-indic-digits.json
show "ajv (JavaScript): Arabic-Indic digits"     ajv-validate        --schema schema-digit-escape.json --instance instance-arabic-indic-digits.json

doc "the rule: write patterns in the subset the engines share" << 'END_DOC'
Three of the four failures above come from the engines, not the
author, and no wording of a pattern can make two engines agree on a
construct they define differently. What an author can do is stay
where they already agree: explicit ranges and classes such as
[0-9a-f], the anchors ^ and $, and plain quantifiers such as + and
{4}. Spell out the classes the shorthands would have abbreviated, and
check every pattern with more than one validator, since the shared
subset is known only by testing.
END_DOC

exit 0
