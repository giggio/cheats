BEGIN {
  # Separator in two parts:
  # `^% *` -> Matches the % at the beginning followed by 0 or more spaces
  # ` *, *` -> Matches the comma between 0 or more spaces (greedy)
  FS = "^% *| *, *";

  # Parameter condition checking
  if (os != "" && oss_excluded != "") {
    print "os and oss_excluded are mutually exclusive"
    exit 1
  }
  if (shell != "" && shells_excluded != "") {
    print "shell and shells_excluded are mutually exclusive"
    exit 1
  }

  # Are we excluding or including?
  is_excluding_shell = shells_excluded != ""
  is_excluding_os = oss_excluded != ""

  # Centralise patterns in a single variable
  shell_pattern = is_excluding_shell ? shells_excluded : shell
  os_pattern = is_excluding_os ? oss_excluded : os
}

# Print out content lines of the section is marked to be shown
show && !/^%/ { print $0 }

# Parse tag line
/^%/{
  # Start the validation flags with the opposite value to the current mode
  # if excluding -> valid = 1
  # if including -> valid = 0
  valid_shell = is_excluding_shell
  valid_os    = is_excluding_os

  # Unprocessed tag line
  unp_tags = ""

  for (i=2; i<=NF; i++) {
    processed = 0

    # Match the current tag against the patterns
    # if excluding -> valid = 0 if match
    # if including -> valid = 1 if match
    if ($i ~ shell_pattern) {
      valid_shell = !is_excluding_shell
      processed = 1
    }
    if ($i ~ os_pattern) {
      valid_os = !is_excluding_os
      processed = 1
    }

    # Add tag to the unprocessed tags if it was not processed
    if (!processed) {
      if (unp_tags != "") unp_tags = unp_tags ", "
      unp_tags = $i unp_tags
    }
  }
  # Show section if both shell and os is valid
  show = valid_shell && valid_os

  # Print the unprocessed tags if we are showing the section
  if (show) print "% " unp_tags
}