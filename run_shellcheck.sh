#!/usr/bin/env bash

set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

submodule_dirs=$(git submodule | awk '{ printf "-not -path '"$DIR"'/" $2 "/* " }')
other_ignored_dirs=$(echo -e ".git\n.direnv\ntests/.testsupport" | awk '{ printf "-not -path '"$DIR"'/" $1 "/* " }')
ignored_dirs="$submodule_dirs $other_ignored_dirs"
set -f # disable globbing
# shellcheck disable=SC2086
sh_files=$(find "$DIR" \( -name '*.sh' -or -name '*.bash' \) $ignored_dirs)
# shellcheck disable=SC2086
exec_files=$(find "$DIR" $ignored_dirs -type f -exec sh -c 'head -n1 $1 | grep -qE '"'"'^#!(.*/|/usr/bin/env +)bash'"'" sh {} \; -exec echo {} \;)
set +f
all_files=$(echo -e "$sh_files\n$exec_files" | sort | uniq)
pushd "$DIR" > /dev/null
echo -e "Shell checking these files:\n$all_files"
# shellcheck disable=SC2086
shellcheck --shell bash $all_files
popd > /dev/null
