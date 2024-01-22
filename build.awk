/^%/ {
  current_tag = $0;
  getline;
  tags[current_tag] = $0;
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
            printf "%s\n%s\n", tag, the_content;
          }
        }
        else {
          if (!(tag ~ shells_excluded)) {
            printf "%s\n%s\n", tag, the_content;
          }
        }
      }
    }
    else if (shell) {
      shell_pattern = ",[[:space:]]*" shell "[[:space:]]*";
      if (tag ~ shell_pattern "(,|$)") {
        if (!(tag ~ oss_excluded)) {
          sub(shell_pattern, "", tag);
          printf "%s\n%s\n", tag, the_content;
        }
      }
    }
    else {
      if (!(tag ~ oss_excluded)) {
        if (!(tag ~ shells_excluded)) {
          printf "%s\n%s\n", tag, the_content;
        }
      }
    }
  }
}
