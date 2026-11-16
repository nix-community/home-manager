{
  config,
  lib,
  pkgs,
  ...
}:
let
  previousFiles = pkgs.runCommand "home-manager-files" { } ''
    mkdir -p "$out/.codex"
    printf 'model = "previous"\nfrom_old_generation = true\n' > "$out/.codex/config.toml"
  '';
  previousGeneration = pkgs.runCommand "codex-previous-generation" { } ''
    mkdir -p "$out"
    ln -s ${previousFiles} "$out/home-files"
  '';
  activation = pkgs.writeShellScript "activate-codex-mutable" ''
    set -eu
    set -o pipefail
    PATH="$(dirname "$BASH"):${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.diffutils
        pkgs.findutils
        pkgs.gettext
      ]
    }:$PATH"
    ${config.lib.bash.initHomeManagerLib}
    hmDriverVersion=1
    newGenPath="$TESTED"
    oldGenPath=${previousGeneration}
    ${lib.concatStringsSep "\n" (
      map (entry: entry.data) (
        lib.filter (
          entry:
          builtins.elem entry.name [
            "checkLinkTargets"
            "writeBoundary"
            "codexMutableSettings"
            "linkGeneration"
          ]
        ) (lib.hm.dag.topoSort config.home.activation).result
      )
    )}
  '';
in
{
  programs.codex = {
    enable = true;
    package = null;
    mutableSettings = true;
    settings.model = "declared";
  };
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";
  nmt.script = ''
    set -eu
    export HOME="$TMPDIR/hm-user" TESTED
    mkdir -p "$HOME/.codex"
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activation} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"

    ln -s ${previousFiles}/.codex/config.toml "$HOME/.codex/config.toml"
    "$TMPDIR/activate"
    test ! -L "$HOME/.codex/config.toml"
    ${lib.getExe pkgs.jaq} --from toml -e '.model == "declared" and (has("from_old_generation") | not)' "$HOME/.codex/config.toml"
    test -w "$HOME/.codex/config.toml"
    test "$(stat -c %a "$HOME/.codex/config.toml")" = 600
  '';
}
