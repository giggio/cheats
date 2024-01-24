#!/usr/bin/env bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_ARGS=$*
PARSED_ARGS=`getopt -o fh --long files:,help,verbose -n "$(readlink -f "$0")" -- "$@"`
eval set -- "$PARSED_ARGS"
AWK_FILE="$BASEDIR/build.awk"

SHOW_HELP=false
VERBOSE=false
FILES=''
while [[ $# -gt 0 ]]; do
  case "$1" in
  --help | -h)
    SHOW_HELP=true
    break
    ;;
  --verbose)
    VERBOSE=true
    shift
    ;;
  --files | -f)
    FILES="$2"
    shift 2
    ;;
  *)
    shift
    ;;
  esac
done
eval set -- "$PARSED_ARGS"
if [ -z "$FILES" ]; then
  FILES=$(find "$BASEDIR"/cheats -name '*.cheat' -type f -exec realpath {} \;)
fi

if $SHOW_HELP; then
  cat <<EOF
Builds the cheat sheets into directories using tags.

Usage:
  $(readlink -f "$0") [flags]

Flags:
      --verbose            Show verbose output
  -f, --files <FILES>      Files to build
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  echo "Running $(basename "$0") $ALL_ARGS"
  # shellcheck disable=SC2086
  echo "Files are "$FILES
fi

shells='bash nushell pwsh'
oss='linux windows'
oss_excluded=${oss// /|}
shells_excluded=${shells// /|}

# will work on any Shell in any OS
find_dist() {
  local file="$1"
  awk -v oss_excluded="$oss_excluded" -v shells_excluded="$shells_excluded" -f "$AWK_FILE" "$file"
}

# will work on any OS with this Shell
find_dist_shell() {
  local shell="$1"
  local file="$2"
  awk -v shell="$shell" -v oss_excluded="$oss_excluded" -f "$AWK_FILE" "$file"
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
  awk -v os="$os" -v shells_excluded="$shells_excluded" -f "$AWK_FILE" "$file"
}

write_if_not_empty() {
  local file="$1"
  local content="$2"
  if [[ -n "$content" ]]; then
    mkdir -p "$(dirname "$file")"
    echo "$content" >"$file"
  fi
}

create_files() {
  files="$1"
  dist=$2
  rm -rf "$dist"
  for file in $files; do
    if $VERBOSE; then
      echo "Building compatible cheatsheet for $file"
    fi
    write_if_not_empty "$dist/common/$(basename "$file")" "$(find_dist "$file")"
    for os in $oss; do
      if $VERBOSE; then
        echo "Building $os cheatsheet for $file"
      fi
      write_if_not_empty "$dist/$os/common/${os}_$(basename "$file")" "$(find_dist_os "$os" "$file")"
      for shell in $shells; do
        if $VERBOSE; then
          echo "Building $os/$shell cheatsheet for $file"
        fi
        write_if_not_empty "$dist/$os/$shell/${os}_${shell}_$(basename "$file")" "$(find_dist_shell_os "$os" "$shell" "$file")"
      done
    done
    for shell in $shells; do
      if $VERBOSE; then
        echo "Building $shell cheatsheet for $file"
      fi
      write_if_not_empty "$dist/$shell/${shell}_$(basename "$file")" "$(find_dist_shell "$shell" "$file")"
    done
  done
}

if ! (return 0 2>/dev/null); then
  create_files "$FILES" "$BASEDIR/dist"
fi
