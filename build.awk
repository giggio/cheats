BEGIN {
  FS = "^% *| *, *";
  # Separator in two parts:
  # `^% *` -> Considers the % at the beginning followed by 0 or more spaces
  # ` *, *` -> Considers the comma between 0 or more spaces (greedy)

  if (os != "" && oss_excluded != "") {
    print "os and oss_excluded are mutually exclusive"
    exit 1
  }
  if (shell != "" && shells_excluded != "") {
    print "shell and shells_excluded are mutually exclusive"
    exit 1
  }
  # Are we excluding or including?
  exclude_shell = shells_excluded != ""
  exclude_os = oss_excluded != ""

  shell_pattern = exclude_shell ? shells_excluded : shell
  os_pattern = exclude_os ? oss_excluded : os
}
show && !/^%/ { print $0 }
/^%/{
  # Start the show flags with the opposite value
  # if excluding -> show = 1
  # if including -> show = 0

  show_shell = exclude_shell
  show_os = exclude_os
  delete tags

  for (i=2; i<=NF; i++) {
    keep = 1
    # Match against the patterns and set the show flags
    # if excluding -> show = 0 if match
    # if including -> show = 1 if match

    if ($i ~ shell_pattern) {
      show_shell = !exclude_shell
      keep = 0
    }
    if ($os ~ os_pattern) {
      show_os = !exclude_os
      keep = 0
    }

    # Keep tag in the tag line if it was not processed
    if (keep) tags[length(tags)] = $i
  }
  # Set show flag
  show = show_shell && show_os

  # Print the tags we kept if show is true
  if (show) {
    tagsf = ""
    for (i in tags) {
      if (tagsf != "") tagsf = tagsf ", "
      tagsf = tagsf tags[i]
    }
    tagsf = "% " tagsf
    print tagsf
  }
}