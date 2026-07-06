{ pkgs, ... }:

let
  recursiveSource = pkgs.runCommand "recursive-executable-source" { } ''
    mkdir -p $out/nested

    echo source > $out/source
    chmod 644 $out/source

    echo nested > $out/nested/source
    chmod 755 $out/nested/source

    ln -s /nonexistent/nowhere $out/dangling
  '';
in
{
  home.file."executable" = {
    text = "";
    executable = true;
  };

  home.file."recursive-executable" = {
    source = recursiveSource;
    recursive = true;
    executable = true;
  };

  home.file."recursive-non-executable" = {
    source = recursiveSource;
    recursive = true;
    executable = false;
  };

  nmt.script = ''
    assertFileExists home-files/executable
    assertFileIsExecutable home-files/executable;

    assertFileExists home-files/recursive-executable/source
    assertFileIsExecutable home-files/recursive-executable/source
    if [[ -L "$TESTED/home-files/recursive-executable/source" ]]; then
      fail "Expected recursive-executable/source to be copied so its executable bit can be changed."
    fi

    assertFileExists home-files/recursive-executable/nested/source
    assertFileIsExecutable home-files/recursive-executable/nested/source
    assertLinkExists home-files/recursive-executable/nested/source

    assertFileExists home-files/recursive-non-executable/source
    assertFileIsNotExecutable home-files/recursive-non-executable/source
    assertLinkExists home-files/recursive-non-executable/source

    assertFileExists home-files/recursive-non-executable/nested/source
    assertFileIsNotExecutable home-files/recursive-non-executable/nested/source
    if [[ -L "$TESTED/home-files/recursive-non-executable/nested/source" ]]; then
      fail "Expected recursive-non-executable/nested/source to be copied so its executable bit can be changed."
    fi

    # A dangling symlink among the recursively linked leaves has no
    # executable bit to fix. It must be left alone rather than crashing the
    # build when trying to cp/chmod through it.
    assertLinkExists home-files/recursive-executable/dangling
    if [[ -e "$TESTED/home-files/recursive-executable/dangling" ]]; then
      fail "Expected recursive-executable/dangling to remain a dangling symlink."
    fi

    assertLinkExists home-files/recursive-non-executable/dangling
    if [[ -e "$TESTED/home-files/recursive-non-executable/dangling" ]]; then
      fail "Expected recursive-non-executable/dangling to remain a dangling symlink."
    fi
  '';
}
