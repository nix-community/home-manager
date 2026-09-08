{
  config,
  lib,
  pkgs,
  extendModules,
  ...
}:
let
  generation = files:
    let
      evaluated = (extendModules {
        modules = [ { home.file = lib.mkForce files; } ];
      }).config;
      package = pkgs.runCommand "mutable-test-generation" { } ''
        mkdir -p "$out"
        ln -s ${evaluated.home-files} "$out/home-files"
        ${evaluated.home.extraBuilderCommands}
      '';
      activate = pkgs.writeShellScript "mutable-test-activate" ''
        set -euo pipefail
        ${config.lib.bash.initHomeManagerLib}
        export HOME_MANAGER_BACKUP_COMMAND="''${HOME_MANAGER_BACKUP_COMMAND:-}"
        export HOME_MANAGER_BACKUP_EXT="''${HOME_MANAGER_BACKUP_EXT:-}"
        export HOME_MANAGER_BACKUP_OVERWRITE="''${HOME_MANAGER_BACKUP_OVERWRITE:-}"
        export VERBOSE_ARG=""
        newGenPath=${package}
        oldGenPath="$1"
        ${evaluated.home.activation.checkLinkTargets.data}
        ${evaluated.home.activation.linkGeneration.data}
      '';
    in { inherit package activate; };
  first = generation {
    "app/config" = { text = "first"; mutable = true; };
    "app/removed" = { text = "remove me"; mutable = true; };
  };
  second = generation { "app/config" = { text = "second"; mutable = true; }; };
  linked = generation { "app/config".text = "linked"; };
  disabled = generation { "app/config" = { text = "disabled"; mutable = true; enable = false; }; };
  empty = generation { };
in
{
  nmt.script = ''
    export HOME="$TMPDIR/mutable-home"
    mkdir -p "$HOME/app"
    printf unmanaged > "$HOME/app/unmanaged"

    # First adoption must refuse even an identical pre-existing regular file.
    printf first > "$HOME/app/config"
    if ${first.activate} ${empty.package}; then
      fail "Mutable copies silently adopted an unmanaged file"
    fi
    test "$(cat "$HOME/app/config")" = first
    HOME_MANAGER_BACKUP_EXT=backup ${first.activate} ${empty.package}
    test "$(cat "$HOME/app/config.backup")" = first
    test ! -L "$HOME/app/config"
    test -w "$HOME/app/config"

    # Model an application's atomic save replacing the regular file.
    printf edited > "$HOME/app/replacement"
    mv "$HOME/app/replacement" "$HOME/app/config"
    printf edited > "$HOME/app/removed"
    DRY_RUN=1 ${second.activate} ${first.package}
    test "$(cat "$HOME/app/config")" = edited
    test -f "$HOME/app/removed"
    ${second.activate} ${first.package}
    test "$(cat "$HOME/app/config")" = second
    test ! -e "$HOME/app/removed"
    test "$(cat "$HOME/app/unmanaged")" = unmanaged

    # Transition between a copy and the ordinary home.file symlink mode.
    ${linked.activate} ${second.package}
    test -L "$HOME/app/config"
    ${second.activate} ${linked.package}
    test ! -L "$HOME/app/config"
    test "$(cat "$HOME/app/config")" = second

    # A disabled last declaration and an empty generation both clean up.
    ${disabled.activate} ${second.package}
    test ! -e "$HOME/app/config"
    ${second.activate} ${disabled.package}
    ${empty.activate} ${second.package}
    test ! -e "$HOME/app/config"

    # Parent symlinks must not redirect either writes or cleanup.
    mkdir -p "$HOME/outside"
    printf protected > "$HOME/outside/config"
    mv "$HOME/app" "$HOME/saved-app"
    ln -s "$HOME/outside" "$HOME/app"
    if ${second.activate} ${empty.package}; then
      fail "Mutable copy followed a parent symlink"
    fi
    if ${empty.activate} ${second.package}; then
      fail "Mutable cleanup followed a parent symlink"
    fi
    test "$(cat "$HOME/outside/config")" = protected
  '';
}
