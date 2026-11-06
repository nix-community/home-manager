{
  config,
  lib,
  pkgs,
  ...
}:

let
  source = builtins.toFile "managed.txt" "managed\n";
  userData = builtins.toFile "user-data.txt" "user data\n";

  # The backup name of this target is one character over NAME_MAX, so the
  # backup cannot be created while the link itself can.
  unbackable = lib.concatStrings (lib.replicate 255 "a");

  link = pkgs.writeShellScript "link-generation" ''
    set -euo pipefail
    PATH="$(dirname "$BASH"):${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.diffutils
        pkgs.findutils
        pkgs.gettext
      ]
    }:$PATH"
    ${config.lib.bash.initHomeManagerLib}
    newGenPath="$TESTED"
    ${config.home.activation.linkGeneration.data}
  '';
in
{
  home.file = {
    ${unbackable}.source = source;
    "backed-up".source = source;
  };

  nmt.script = ''
    export TESTED HOME_MANAGER_BACKUP_COMMAND= HOME_MANAGER_BACKUP_EXT= HOME_MANAGER_BACKUP_OVERWRITE=
    export HOME="$TMPDIR/hm-user"
    mkdir -p "$HOME"

    # A failed backup command must not be followed by replacing the file.
    install -m600 ${userData} "$HOME/${unbackable}"
    if HOME_MANAGER_BACKUP_COMMAND=false ${link}; then
      fail "Linking succeeded although the backup command failed"
    fi
    test ! -L "$HOME/${unbackable}"
    assertFileContent "$HOME/${unbackable}" ${userData}

    # The same holds when moving the file to the backup extension fails.
    if HOME_MANAGER_BACKUP_EXT=bak ${link}; then
      fail "Linking succeeded although the backup could not be created"
    fi
    test ! -L "$HOME/${unbackable}"
    assertFileContent "$HOME/${unbackable}" ${userData}
    rm "$HOME/${unbackable}"

    # A working backup still precedes the link.
    install -m600 ${userData} "$HOME/backed-up"
    HOME_MANAGER_BACKUP_EXT=bak ${link}
    test -L "$HOME/backed-up"
    assertFileContent "$HOME/backed-up.bak" ${userData}
    assertFileContent "$HOME/backed-up" ${source}
  '';
}
