{
  time = "2026-07-24T12:00:00+00:00";
  condition = true;
  message = ''
    New Bash, Zsh, and Fish shells now refresh session variables after
    `home-manager switch`. Search variables add missing entries without
    reordering existing ones. Empty entries are ignored; spell out `.` if
    you want the current directory on a search path.

    Plain session variables must not reference themselves. Use
    `home.sessionPath`, `home.sessionSearchVariables`, or
    `home.sessionSearchVariablesAppend` for search paths. See the 26.11
    release notes for compatibility details.

    Interactive Bash shells started inside a Fish or Zsh login session have no
    Bash ownership manifest. When Bash-owned session variables or
    `programs.bash.profileExtra` exist, such shells refresh conservatively and
    keep existing values until the next Bash login.

    On Darwin, setting `home.sessionVariables.TERMINFO_DIRS` no longer replaces
    the Home Manager handling; it now composes with the prepended profile
    directory and the appended `/usr/share/terminfo`. Set
    `targets.darwin.terminfo.enable = false` to opt out entirely.
  '';
}
