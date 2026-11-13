{
  config,
  lib,
  pkgs,
  ...
}:

let
  source = builtins.toFile "static-settings.json" ''
    {"managed":true}
  '';
  changed = builtins.toFile "changed-settings.json" ''
    {"managed":true,"user":true}
  '';
  reformatted = builtins.toFile "reformatted-settings.json" ''
    { "managed": true }
  '';
  mkCleanup =
    name: target: source:
    pkgs.writeShellScript name ''
      set -euo pipefail
      ${config.lib.bash.initHomeManagerLib}
      newGenPath="$TMPDIR/generation"
      ${lib.hm.generators.mkImpureConfigCleanup {
        file = {
          enable = true;
          inherit target source;
        };
      }}
    '';
  cleanup = mkCleanup "cleanup" "config's settings.json" source;
  linkedCleanup = mkCleanup "linked-cleanup" "linked/settings.json" source;
  # The generation holds a copy of the declared source, as it does when the
  # source's executable bit differs from the declaration.
  copiedCleanup =
    mkCleanup "copied-cleanup" "copied/settings.json"
      "/@TMPDIR@/copied-src/settings.json";
  # Collision checking, the cleanup, and link generation as activation runs
  # them, for a real file entry.
  integration = pkgs.writeShellScript "cleanup-integration" ''
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
    ${config.home.activation.checkLinkTargets.data}
    ${lib.hm.generators.mkImpureConfigCleanup {
      file = config.home.file."cleanup-test/settings.json";
    }}
    ${config.home.activation.linkGeneration.data}
  '';
  disabledCleanup = lib.hm.generators.mkImpureConfigCleanup {
    file = {
      enable = false;
      target = "settings.json";
      inherit source;
    };
  };
in
{
  home.file."cleanup-test/settings.json".source = source;

  nmt.script = ''
    ${lib.optionalString (disabledCleanup != "") ''
      fail "A disabled file entry must not produce a cleanup"
    ''}

    export HOME="$TMPDIR/hm-user"
    mkdir -p "$HOME" "$TMPDIR/generation/home-files"
    ln -s ${source} "$TMPDIR/generation/home-files/config's settings.json"
    target="$HOME/config's settings.json"

    install -m600 ${source} "$target"
    DRY_RUN=1 ${cleanup} > "$TMPDIR/dry-output"
    assertFileContent "$target" ${source}
    grep -F "rm -- $target" "$TMPDIR/dry-output"

    VERBOSE=1 ${cleanup} > "$TMPDIR/verbose-output"
    assertPathNotExists "$target"
    grep -F "Removing unchanged config at $target before linking" "$TMPDIR/verbose-output"

    install -m600 ${source} "$target"
    ${cleanup} > "$TMPDIR/quiet-output"
    assertPathNotExists "$target"
    test ! -s "$TMPDIR/quiet-output"

    install -m600 ${changed} "$target"
    ${cleanup}
    assertFileContent "$target" ${changed}

    install -m600 ${reformatted} "$target"
    ${cleanup}
    assertFileContent "$target" ${reformatted}

    rm "$target"
    install -m600 ${source} "$TMPDIR/backing.json"
    ln -s "$TMPDIR/backing.json" "$target"
    ${cleanup}
    test -L "$target"
    assertFileContent "$TMPDIR/backing.json" ${source}

    rm "$TMPDIR/backing.json"
    ${cleanup}
    test -L "$target"

    rm "$target"
    ${cleanup}
    assertPathNotExists "$target"

    mkdir "$target"
    ${cleanup}
    test -d "$target"

    # An out-of-store source reached through a symlinked parent directory is
    # the target itself; removing it would delete the only copy.
    mkdir -p "$TMPDIR/dotfiles" "$TMPDIR/generation/home-files/linked"
    install -m600 ${source} "$TMPDIR/dotfiles/settings.json"
    ln -s "$TMPDIR/dotfiles" "$HOME/linked"
    ln -s "$TMPDIR/dotfiles/settings.json" "$TMPDIR/generation/home-files/linked/settings.json"
    ${linkedCleanup}
    test -f "$TMPDIR/dotfiles/settings.json"
    test ! -L "$TMPDIR/dotfiles/settings.json"
    assertFileContent "$TMPDIR/dotfiles/settings.json" ${source}

    # The same layout where the generation holds a copy instead of a link.
    mkdir -p "$TMPDIR/copied-src" "$TMPDIR/generation/home-files/copied"
    install -m755 ${source} "$TMPDIR/copied-src/settings.json"
    ln -s "$TMPDIR/copied-src" "$HOME/copied"
    install -m644 ${source} "$TMPDIR/generation/home-files/copied/settings.json"
    substitute ${copiedCleanup} "$TMPDIR/copied-cleanup" --subst-var TMPDIR
    chmod +x "$TMPDIR/copied-cleanup"
    "$TMPDIR/copied-cleanup"
    test -f "$TMPDIR/copied-src/settings.json"
    test ! -L "$TMPDIR/copied-src/settings.json"
    assertFileContent "$TMPDIR/copied-src/settings.json" ${source}

    # Collision checking accepts the identical regular file and link
    # generation would skip it; with the cleanup in between it is linked.
    export TESTED HOME_MANAGER_BACKUP_COMMAND= HOME_MANAGER_BACKUP_EXT= HOME_MANAGER_BACKUP_OVERWRITE=
    export HOME="$TMPDIR/integration-home"
    mkdir -p "$HOME/cleanup-test"
    install -m600 ${source} "$HOME/cleanup-test/settings.json"
    ${integration}
    test -L "$HOME/cleanup-test/settings.json"
    assertFileContent "$HOME/cleanup-test/settings.json" ${source}
  '';
}
