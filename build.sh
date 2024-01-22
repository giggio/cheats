#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THIS_FILE="${BASH_SOURCE[0]}"

if (return 0 2>/dev/null); then
  echo "Don't source this script ($THIS_FILE)."
  exit 1
fi

SHOW_HELP=false
VERBOSE=false
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
  *)
    shift
    ;;
  esac
done
eval set -- "$PARSED_ARGS"

if $SHOW_HELP; then
  cat <<EOF
Builds the cheat sheets into directories using tags.

Usage:
  $(readlink -f "$0") [flags]

Flags:
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  echo "Running $(basename "$0") $ALL_ARGS"
fi

shells='bash nushell pwsh'
oss='linux windows'
oss_excluded=${oss// /|}
shells_excluded=${shells// /|}
rm -rf "$BASEDIR/dist"

awk_script='
/^%/ {
  current_tag = $0;
  getline;
  tags[current_tag] = $0;
  next;
}
{
  content[current_tag] = content[current_tag] $0 RS;
}
END {
  for (tag in tags) {
    the_content = content[tag];
    if (os) {
      os_pattern = ",[[:space:]]*" os "[[:space:]]*";
      if (tag ~ os_pattern "(,|$)") {
        sub(os_pattern, "", tag);
        if (shell) {
          shell_pattern = ",[[:space:]]*" shell "[[:space:]]*";
          if (tag ~ shell_pattern "(,|$)") {
            sub(shell_pattern, "", tag);
            printf "%s\n\n%s", tag, the_content;
          }
        }
        else {
          if (!(tag ~ shells_excluded)) {
            printf "%s\n\n%s", tag, the_content;
          }
        }
      }
    }
    else if (shell) {
      shell_pattern = ",[[:space:]]*" shell "[[:space:]]*";
      if (tag ~ shell_pattern "(,|$)") {
        if (!(tag ~ oss_excluded)) {
          sub(shell_pattern, "", tag);
          printf "%s\n\n%s", tag, the_content;
        }
      }
    }
    else {
      if (!(tag ~ oss_excluded)) {
        if (!(tag ~ shells_excluded)) {
          printf "%s\n\n%s", tag, the_content;
        }
      }
    }
  }
}
'

# will work on any Shell in any OS
find_dist() {
  local file="$1"
  awk "$awk_script" oss_excluded="$oss_excluded" shells_excluded="$shells_excluded" "$file"
}

# will work on any OS with this Shell
find_dist_shell() {
  local shell="$1"
  local file="$2"
  awk "$awk_script" shell="$shell" oss_excluded="$oss_excluded" "$file"
}

# will work on this OS with this Shell
find_dist_shell_os() {
  local os="$1"
  local shell="$2"
  local file="$3"
  awk "$awk_script" shell="$shell" os="$os" "$file"
}

# will work on this OS with any Shell
find_dist_os() {
  local os="$1"
  local file="$2"
  awk "$awk_script" os="$os" shells_excluded="$shells_excluded" "$file"
}

write_if_not_empty() {
  local file="$1"
  local content="$2"
  if [[ -n "$content" ]]; then
    mkdir -p "$(dirname "$file")"
    echo "$content" >"$file"
  fi
}

for file in "$BASEDIR"/cheats/*.cheat; do
  if $VERBOSE; then
    echo "Building compatible cheatsheet for $file"
  fi
  write_if_not_empty "$BASEDIR/dist/common/$(basename "$file")" "$(find_dist "$file")"
  for os in $oss; do
    if $VERBOSE; then
      echo "Building $os cheatsheet for $file"
    fi
    write_if_not_empty "$BASEDIR/dist/$os/common/${os}_$(basename "$file")" "$(find_dist_os "$os" "$file")"
    for shell in $shells; do
      if $VERBOSE; then
        echo "Building $os/$shell cheatsheet for $file"
      fi
      write_if_not_empty "$BASEDIR/dist/$os/$shell/${os}_${shell}_$(basename "$file")" "$(find_dist_shell_os "$os" "$shell" "$file")"
    done
  done
  for shell in $shells; do
    if $VERBOSE; then
      echo "Building $shell cheatsheet for $file"
    fi
    write_if_not_empty "$BASEDIR/dist/$shell/${shell}_$(basename "$file")" "$(find_dist_shell "$shell" "$file")"
  done
done
