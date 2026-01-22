#!/usr/bin/env bats

setup_file() {
  export file="${BATS_TEST_DIRNAME}/basic1.cheat"
}

setup() {
  load '_test-helpers.sh'
  # shellcheck source=/dev/null
  source "${BATS_TEST_DIRNAME}/../build.sh"

  DIST="$(mktemp --directory)"
}

teardown() {
  rm -rf "${DIST}"
}

# Assert output without escaped lines
assert_output_esc() {
  assert_output "$(echo "$1" | awk '!/^\\$/')"
}

@test "Without shell and os" {
  run find_dist "${file}"
  assert_success && assert_output_esc '\
% z
a
b'
}

@test "With shell, without os" {
  run find_dist_shell bash "${file}"
  assert_success && assert_output_esc '\
% y
c
d

% y1, y2, y3
c1
d2'
}

@test "Without shell, with os" {
  run find_dist_os linux "${file}"
  assert_success && assert_output_esc '\
% v
i
j'
}

@test "With shell and os" {
  run find_dist_shell_os linux nushell "${file}"
  assert_success && assert_output_esc '\
% w
g
h'
}

@test "With shell, without os, twice" {
  run find_dist_shell pwsh "${file}"
  assert_success && assert_output_esc '\
% u
k
l

% t
m
n'
}

@test "Create files" {
  run create_files "${DIST}" "${BATS_TEST_DIRNAME}/basic1.cheat"
  assert_success
  assert_output ''

  run cat "${DIST}/common/basic1.cheat" && assert_output_esc '\
% z
a
b'

  run cat "${DIST}/bash/bash_basic1.cheat" && assert_output_esc '\
% y
c
d

% y1, y2, y3
c1
d2'

  run cat "${DIST}/nushell/nushell_basic1.cheat" && assert_output_esc '\
% x
e
f'

  run cat "${DIST}/linux/nushell/linux_nushell_basic1.cheat" && assert_output_esc '\
% w
g
h'

  run cat "${DIST}/linux/common/linux_basic1.cheat" && assert_output_esc '\
% v
i
j'

  run cat "${DIST}/pwsh/pwsh_basic1.cheat" && assert_output_esc '\
% u
k
l

% t
m
n'
  assert [ ! -d "${DIST}/windows" ]
  assert [ ! -d "${DIST}/linux/pwsh" ]
  assert [ ! -d "${DIST}/linux/bash" ]
}
