{
  pkgs,
  expectedXdgDataDirs,
}:

''
  set -eu

  testHome="$TMPDIR/generic-linux-bash-home"
  ${pkgs.coreutils}/bin/rm -rf "$testHome"
  ${pkgs.coreutils}/bin/mkdir -p "$testHome"
  ${pkgs.coreutils}/bin/cp "$TESTED/home-files/.bash_profile" "$testHome/.bash_profile"
  ${pkgs.coreutils}/bin/cp "$TESTED/home-files/.bashrc" "$testHome/.bashrc"
  ${pkgs.coreutils}/bin/cp "$TESTED/home-files/.profile" "$testHome/.profile"
  ${pkgs.coreutils}/bin/ln -s "$TESTED/home-path" "$testHome/.nix-profile"

  initialPath="/usr/bin:/bin"
  initialXdgDataDirs="/fixture/xdg-data"
  bashPath="$BASH"
  ${pkgs.coreutils}/bin/env -i \
    HOME="$testHome" \
    PATH="$initialPath" \
    TMPDIR="$TMPDIR" \
    XDG_DATA_DIRS="$initialXdgDataDirs" \
    EXPECTED_XDG_DATA_DIRS="${expectedXdgDataDirs}:$initialXdgDataDirs:$testHome/.nix-profile/share" \
    __HM_SESS_VARS_SOURCED=1 \
    "$bashPath" --noprofile --norc -i -c '
        . "$HOME/.bash_profile" || exit 1
        firstPath="$PATH"
        firstXdgDataDirs="$XDG_DATA_DIRS"
        [ "$XDG_DATA_DIRS" = "$EXPECTED_XDG_DATA_DIRS" ] \
          || { echo "XDG_DATA_DIRS did not refresh on startup"; exit 1; }
        . "$HOME/.bash_profile" || exit 1
        [ "$(command -v hm-profile-command)" = "$HOME/.nix-profile/bin/hm-profile-command" ] \
          || { echo "profile command was not found through PATH"; exit 1; }
        [ "$PATH" = "$firstPath" ] \
          || { echo "PATH changed on repeated startup"; exit 1; }
        [ "$XDG_DATA_DIRS" = "$firstXdgDataDirs" ] \
          || { echo "XDG_DATA_DIRS changed on repeated startup"; exit 1; }
        profileBinCount=$(
          printf "%s" ":$PATH:" | ${pkgs.coreutils}/bin/tr : "\n" |
            ${pkgs.gnugrep}/bin/grep -cFx "$HOME/.nix-profile/bin"
        )
        [ "$profileBinCount" = 1 ] \
          || { echo "profile bin appeared $profileBinCount times"; exit 1; }
      ' \
    || fail "Bash startup did not preserve profile command lookup or session variables"

  ${pkgs.coreutils}/bin/mkdir -p "$testHome/precedence"
  ${pkgs.coreutils}/bin/ln -s "$testHome/.nix-profile/bin/hm-profile-command" \
    "$testHome/precedence/hm-profile-command"
  ${pkgs.coreutils}/bin/env -i \
    HOME="$testHome" \
    PATH="$testHome/precedence:$testHome/.nix-profile/bin:$initialPath" \
    TMPDIR="$TMPDIR" \
    XDG_DATA_DIRS="$initialXdgDataDirs" \
    __HM_SESS_VARS_SOURCED=1 \
    "$bashPath" --noprofile --norc -i -c '
        . "$HOME/.bash_profile" || exit 1
        [ "$(command -v hm-profile-command)" = "$HOME/precedence/hm-profile-command" ] \
          || { echo "existing profile command lost precedence"; exit 1; }
      ' \
    || fail "Bash startup changed precedence of an existing profile command"
''
