# Cell helpers shared by every demo's run.sh. Sourced, not executed:
#
#   source "${JSON_SCHEMA_DEV_CELLS_DIR}/cells.sh"
#
# That variable is set by repro.env in the Dockerfile and points at this
# directory, so the line above is identical in every demo no matter how
# deeply the demo is nested (the demo runner recurses into any subdirectory
# whose name starts with a digit).
#
# A demo's run.txt is simply whatever its run.sh prints, so the notebook
# format is defined entirely here. Two cell kinds:
#
#   doc "title" << 'END_DOC'      a prose cell, body read from stdin
#   ...text...
#   END_DOC
#
#   show "title" cmd args...      a command cell: the command as you would
#                                 type it, then its output
#
# shell-notebook exports one cell primitive, bash_cell, which prints a
# hardcoded "bash cell | ..." banner and offers no prose cell. That banner is
# shared across every REPRO and so is not ours to change, hence these local
# helpers. The heredoc form of doc deliberately mirrors bash_cell's own
# << END_CELL idiom, so that a doc_cell contributed upstream would look
# familiar rather than novel.

BANNER_WIDTH=78
BANNER_FILL='=========================================================================================='

banner() {
    local label="===== $1 "
    local pad=$(( BANNER_WIDTH - ${#label} ))
    (( pad < 5 )) && pad=5
    printf '\n%s%s\n\n' "$label" "${BANNER_FILL:0:pad}"
}

doc() {
    banner "$1"
    cat
}

show() {
    local title="$1"; shift
    banner "$title"
    printf '$ %s\n' "$*"
    # stderr is folded into stdout so the golden file records everything the
    # command emitted, not just the part that happened to go to stdout. A
    # diagnostic a demo never shows is a diagnostic no golden can regress on.
    "$@" 2>&1
}
