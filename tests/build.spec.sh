#!/usr/bin/env bats

setup_file() {
  export file="$BATS_TEST_DIRNAME"/basic1.cheat
}

setup() {
  load '_test-helpers.sh'
  # shellcheck source=/dev/null
  source "$BATS_TEST_DIRNAME"/../build.sh #--curl "$curl_mock"
}

@test "Without shell and os" {
  run find_dist "$file"
  assert_success
  assert_output '% z
a
b'
}

@test "With shell, without os" {
  run find_dist_shell bash $file
  assert_success
  assert_output '% y
c
d'
}

@test "Without shell, with os" {
  run find_dist_os linux "$file"
  assert_success
  assert_output '% v
i
j'
}

@test "With shell and os" {
  run find_dist_shell_os linux nushell "$file"
  assert_success
  assert_output '% w
g
h'
}

@test "With shell, without os, twice" {
  run find_dist_shell pwsh "$file"
  assert_success
  assert_output '% t
m
n

% u
k
l'
}

@test "Create files" {
  dist=$(mktemp --directory)
  run create_files "$BATS_TEST_DIRNAME"/basic1.cheat "$dist"
  assert_success
  assert_output ''
  assert_equal "$(cat "$dist"/common/basic1.cheat)" $'% z\na\nb'
  assert_equal "$(cat "$dist"/bash/bash_basic1.cheat)" $'% y\nc\nd'
  assert_equal "$(cat "$dist"/nushell/nushell_basic1.cheat)" $'% x\ne\nf'
  assert_equal "$(cat "$dist"/linux/nushell/linux_nushell_basic1.cheat)" $'% w\ng\nh'
  assert_equal "$(cat "$dist"/linux/common/linux_basic1.cheat)" $'% v\ni\nj'
  assert_equal "$(cat "$dist"/pwsh/pwsh_basic1.cheat)" $'% t\nm\nn\n\n% u\nk\nl'
  assert [ ! -d "$dist"/windows ]
  assert [ ! -d "$dist"/linux/pwsh ]
  assert [ ! -d "$dist"/linux/bash ]
  rm -rf "$dist"
}
