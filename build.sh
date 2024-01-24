#!/usr/bin/env bash
set -TCEeuo pipefail

VERBOSE=false
function info() {
  echo "$@" >&2
}
function debug() {
  if $VERBOSE; then
    info "$@"
  fi
}
function error() {
  info "$@"
  exit 1
}

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_ARGS=$*
PARSED_ARGS=`getopt -o fh --long files:,help,verbose -n "$(readlink -f "$0")" -- "$@"`
eval set -- "$PARSED_ARGS"
AWK_FILE="$BASEDIR/build.awk"

ALL_ARGS="$*"
SHOW_HELP=false
FILES=()

while (($# > 0)); do
  case "$1" in
  --help | -h)
    SHOW_HELP=true
    break
    ;;
  --verbose)
    VERBOSE=true
    shift
    ;;
  --file | -f)
    if (($# < 2)); then
      error "Flag $1 requires an argument, none was given."
    fi
    FILES+=("$2")
    shift 2
    ;;
  *)
    info "Unknown flag $1!"
    info "For multiple files, use --file multiple times."
    error "Example: ./$(basename "$0") --file file1.cheat --file file2.cheat"
    ;;
  esac
done

if [ -z "${FILES[*]}" ]; then
  readarray -t FILES < <(
    find "${BASEDIR}/cheats" -name '*.cheat' -type f -exec realpath {} \; | sort -u
  )
fi

if $SHOW_HELP; then
  cat <<EOF
Builds the cheat sheets into directories using tags.

Usage:
  $(readlink -f "$0") [flags]

Flags:
      --verbose            Show verbose output
  -f, --file <FILE>        File to build (can be repeated)
  -h, --help               help
EOF
  exit 0
fi

debug "Running $(basename "$0") ${ALL_ARGS}"
debug -e "Files are" "${FILES[@]}" "\n"

SHELLS='bash nushell pwsh'
OSS='linux windows'
OSS_EXCLUDED=${OSS// /|}
SHELLS_EXCLUDED=${SHELLS// /|}

# will work on any Shell in any OS
find_dist() {
  local file="$1"
  awk -v oss_excluded="$OSS_EXCLUDED" -v shells_excluded="$SHELLS_EXCLUDED" -f "$AWK_FILE" "$file"
}

# will work on any OS with this Shell
find_dist_shell() {
  local shell="$1"
  local file="$2"
  awk -v shell="$shell" -v oss_excluded="$OSS_EXCLUDED" -f "$AWK_FILE" "$file"
}

# will work on this OS with this Shell
find_dist_shell_os() {
  local os="$1"
  local shell="$2"
  local file="$3"
  awk -v shell="$shell" -v os="$os" -f "$AWK_FILE" "$file"
}

# will work on this OS with any Shell
find_dist_os() {
  local os="$1"
  local file="$2"
  awk -v os="$os" -v shells_excluded="$SHELLS_EXCLUDED" -f "$AWK_FILE" "$file"
}

write_if_not_empty() {
  local file="$1"
  local content
  content="$(cat)"

  if [[ -n "$content" ]]; then
    mkdir -p "$(dirname "$file")"
    echo "$content" >"$file"
  fi
}

create_files() {
  local dist=$1
  shift
  
  for file in "$@"; do
    [[ ! -f "$file" ]] && error "Cheat file $file does not exist!"
  done

  # Only clean up if all cheat files are present
  rm -rf "$dist"

  for file in "$@"; do
    debug "Building compatible cheatsheet for $file"
    find_dist "$file" | write_if_not_empty "$dist/common/$(basename "$file")"
    for os in $OSS; do
      debug "Building $os cheatsheet for $file"
      find_dist_os "$os" "$file" | write_if_not_empty "$dist/$os/common/${os}_$(basename "$file")"
      for shell in $SHELLS; do
        debug "Building $os/$shell cheatsheet for $file"
        find_dist_shell_os "$os" "$shell" "$file" | write_if_not_empty "$dist/$os/$shell/${os}_${shell}_$(basename "$file")"
      done
    done
    for shell in $SHELLS; do
      debug "Building $shell cheatsheet for $file"
      find_dist_shell "$shell" "$file" | write_if_not_empty "$dist/$shell/${shell}_$(basename "$file")"
    done
  done
}

# If not being sourced, run script
# https://stackoverflow.com/questions/2683279
if ! (return 0 2>/dev/null); then
  create_files "$BASEDIR/dist" "${FILES[@]}"
fi
