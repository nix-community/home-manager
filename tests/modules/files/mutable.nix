{
  config,
  lib,
  pkgs,
  extendModules,
  ...
}:
let
  generation =
    files:
    let
      evaluated =
        (extendModules {
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
    in
    {
      inherit package activate;
    };
  first = generation {
    "app/config" = {
      text = "first";
      mutable = true;
    };
    "app/removed" = {
      text = "remove me";
      mutable = true;
    };
  };
  second = generation {
    "app/config" = {
      text = "second";
      mutable = true;
    };
  };
  linked = generation { "app/config".text = "linked"; };
  third = generation {
    "app/config" = {
      text = "third";
      mutable = true;
    };
  };
  adopt = generation {
    "app/adopted" = {
      text = "adopted";
      mutable = true;
    };
  };
  drop = generation {
    "app/kept" = {
      text = "kept";
      mutable = true;
    };
    "app/dropped" = {
      text = "dropped";
      mutable = true;
    };
  };
  nodrop = generation {
    "app/kept" = {
      text = "kept";
      mutable = true;
    };
  };
  disabled = generation {
    "app/config" = {
      text = "disabled";
      mutable = true;
      enable = false;
    };
  };
  empty = generation { };
in
{
  nmt.script = ''
    export HOME="$TMPDIR/mutable-home"

    # The activation code under test shells out to `bash`, which is not on
    # the test PATH (nmt only provides coreutils, diffutils, findutils,
    # gnugrep, and gnused). Reuse the interpreter running this script,
    # falling back to the sandbox /bin/sh (bash on Linux and Darwin).
    mkdir -p "$TMPDIR/test-bin"
    if ! command -v bash >/dev/null 2>&1; then
      ln -s "''${BASH:-/bin/sh}" "$TMPDIR/test-bin/bash"
      export PATH="$TMPDIR/test-bin:$PATH"
    fi
    test -x "$(command -v bash)"
    export PATH="${pkgs.gettext}/bin:$PATH"

    mkdir -p "$HOME/app"
    printf unmanaged > "$HOME/app/unmanaged"

    # An unknown previous generation cannot prove ownership: adoption stays
    # explicit even when contents match.
    printf adopted > "$HOME/app/adopted"
    if out=$(${adopt.activate} /nonexistent 2>&1); then
      fail "Mutable copies adopted a file without generation history"
    fi
    case "$out" in
      *"would be clobbered"*) ;;
      *) fail "Unexpected adoption error: $out" ;;
    esac
    HOME_MANAGER_BACKUP_EXT=backup ${adopt.activate} /nonexistent
    test "$(cat "$HOME/app/adopted")" = adopted
    test "$(cat "$HOME/app/adopted.backup")" = adopted

    # First adoption must refuse even an identical pre-existing regular file.
    printf first > "$HOME/app/config"
    if out=$(${first.activate} ${empty.package} 2>&1); then
      fail "Mutable copies silently adopted an unmanaged file"
    fi
    case "$out" in
      *"would be clobbered"*) ;;
      *) fail "Unexpected adoption error: $out" ;;
    esac
    test "$(cat "$HOME/app/config")" = first
    if out=$(HOME_MANAGER_BACKUP_COMMAND=false ${first.activate} ${empty.package} 2>&1); then
      fail "Mutable installation ignored a failed backup"
    fi
    case "$out" in
      *"failed"*) ;;
      *) fail "Unexpected backup error: $out" ;;
    esac
    test "$(cat "$HOME/app/config")" = first
    HOME_MANAGER_BACKUP_EXT=backup ${first.activate} ${empty.package}
    test "$(cat "$HOME/app/config.backup")" = first
    test ! -L "$HOME/app/config"
    test -w "$HOME/app/config"

    # A foreign symlink left where a removed declaration used to install
    # must survive cleanup along with its referent.
    ${drop.activate} ${empty.package}
    printf referent > "$HOME/real"
    rm "$HOME/app/dropped"
    ln -s "$HOME/real" "$HOME/app/dropped"
    ${nodrop.activate} ${drop.package}
    test -L "$HOME/app/dropped"
    test "$(cat "$HOME/real")" = referent
    test "$(cat "$HOME/app/kept")" = kept

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

    # Retrying after a partially installed generation converges instead of
    # reporting the new copy as an unmanaged collision.
    printf third > "$HOME/app/config"
    ${third.activate} ${first.package}
    test "$(cat "$HOME/app/config")" = third

    # Rolling back to an older declaration restores its contents.
    ${first.activate} ${third.package}
    test "$(cat "$HOME/app/config")" = first
    test "$(cat "$HOME/app/removed")" = "remove me"

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
    if out=$(${second.activate} ${empty.package} 2>&1); then
      fail "Mutable copy followed a parent symlink"
    fi
    case "$out" in
      *"must be a directory"*) ;;
      *) fail "Unexpected parent symlink error: $out" ;;
    esac
    if out=$(${empty.activate} ${second.package} 2>&1); then
      fail "Mutable cleanup followed a parent symlink"
    fi
    case "$out" in
      *"must be a directory"*) ;;
      *) fail "Unexpected parent symlink error: $out" ;;
    esac
    test "$(cat "$HOME/outside/config")" = protected
  '';
}
