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
# and two structural constructs, which are not cells:
#
#   title "text"                  the notebook's title, printed once at the
#                                 top so run.txt says what it is; the first
#                                 line of every run.sh
#
#   section "title"               a header dividing the demo into groups of
#                                 cells that go together; numbered on its
#                                 own, printed in a distinct style, and not
#                                 counted in cell numbering
#
# The title is printed only on a full run; a selective run is an excerpt
# and carries no title. A section header is printed lazily -- just before
# the first selected cell that follows it -- so a full run shows every
# header in place, and a selective run shows only the headers of sections
# it touches.
#
# Cells are numbered in banner order, and the numbers appear inline in the
# banners ("===== [5] title ====="), so a demo's run.txt doubles as its cell
# index. A run.sh invocation may select cells by those numbers; each argument
# names cells, as a bare number or an inclusive FIRST-LAST range:
#
#   bash run.sh              all cells (the form the goldens record)
#   bash run.sh 5            cell 5 only
#   bash run.sh 1 2 3        cells 1, 2, and 3
#   bash run.sh 2 5-8 12     bare numbers and ranges compose freely
#
# Cells always run in document order whatever the argument order, and
# overlapping arguments select a cell only once — selection is a set, not a
# playlist. Selection assumes cells are independent: a skipped show cell's
# command is simply not executed. Demos must not let one cell depend on
# another cell's side effects, or selective runs will misbehave.
#
# shell-notebook exports one cell primitive, bash_cell, which prints a
# hardcoded "bash cell | ..." banner and offers no prose cell. That banner is
# shared across every REPRO and so is not ours to change, hence these local
# helpers. The heredoc form of doc deliberately mirrors bash_cell's own
# << END_CELL idiom, so that a doc_cell contributed upstream would look
# familiar rather than novel.

# Sourcing with no arguments leaves the caller's positional parameters in
# effect, so these are run.sh's own arguments. Each becomes a (first, last)
# pair in CELL_RANGES; a bare number is a one-cell range.
CELL_RANGES=()
for CELL_ARG in "$@"; do
    if [[ $CELL_ARG =~ ^[0-9]+$ ]]; then
        CELL_RANGES+=("$CELL_ARG $CELL_ARG")
    elif [[ $CELL_ARG =~ ^([0-9]+)-([0-9]+)$ ]]; then
        CELL_RANGES+=("${BASH_REMATCH[1]} ${BASH_REMATCH[2]}")
    else
        echo "usage: bash run.sh [CELL | FIRST-LAST]..." >&2
        exit 2
    fi
done
CELL_INDEX=0

# Called once at the top of every cell: advances the cell counter, then
# reports whether the current cell is selected.
cell_in_range() {
    CELL_INDEX=$(( CELL_INDEX + 1 ))
    (( ${#CELL_RANGES[@]} == 0 )) && return 0
    local range first last
    for range in "${CELL_RANGES[@]}"; do
        read -r first last <<< "$range"
        (( CELL_INDEX >= first && CELL_INDEX <= last )) && return 0
    done
    return 1
}

# Three fills, one per level: sections in '#', prose (doc) cells in '=',
# command (show) cells in '-', so the banners alone show the structure --
# grouping, teaching, evidence -- while scrolling.
BANNER_WIDTH=78
DOC_FILL='=========================================================================================='
SHOW_FILL='------------------------------------------------------------------------------------------'
SECTION_FILL='##########################################################################################'

title() {
    (( ${#CELL_RANGES[@]} > 0 )) && return 0
    printf '%s\n#\n#   %s\n#\n%s\n' \
        "${SECTION_FILL:0:BANNER_WIDTH}" "$1" "${SECTION_FILL:0:BANNER_WIDTH}"
}

# A section header waits in SECTION_PENDING until a selected cell prints,
# so that selective runs show only the sections they touch.
SECTION_INDEX=0
SECTION_PENDING=''

section() {
    SECTION_INDEX=$(( SECTION_INDEX + 1 ))
    SECTION_PENDING="$1"
}

flush_section() {
    [[ -z $SECTION_PENDING ]] && return 0
    local label="##### ${SECTION_INDEX}. ${SECTION_PENDING} "
    local pad=$(( BANNER_WIDTH - ${#label} ))
    (( pad < 5 )) && pad=5
    printf '\n\n%s\n%s%s\n%s\n' "${SECTION_FILL:0:BANNER_WIDTH}" \
        "$label" "${SECTION_FILL:0:pad}" "${SECTION_FILL:0:BANNER_WIDTH}"
    SECTION_PENDING=''
}

banner() {
    flush_section
    local fill="$1" title="$2"
    local label="${fill:0:5} [${CELL_INDEX}] ${title} "
    local pad=$(( BANNER_WIDTH - ${#label} ))
    (( pad < 5 )) && pad=5
    printf '\n%s%s\n\n' "$label" "${fill:0:pad}"
}

doc() {
    cell_in_range || return 0
    banner "$DOC_FILL" "$1"
    cat
}

show() {
    cell_in_range || return 0
    local title="$1"; shift
    banner "$SHOW_FILL" "$title"
    printf '$ %s\n' "$*"
    # stderr is folded into stdout so the golden file records everything the
    # command emitted, not just the part that happened to go to stdout. A
    # diagnostic a demo never shows is a diagnostic no golden can regress on.
    "$@" 2>&1
}
