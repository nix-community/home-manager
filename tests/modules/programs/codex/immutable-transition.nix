{
  config,
  lib,
  pkgs,
  ...
}:
let
  activation = pkgs.writeShellScript "activate-codex-immutable" ''
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
    ${lib.concatStringsSep "\n" (
      map (entry: entry.data) (
        lib.filter (
          entry:
          builtins.elem entry.name [
            "checkLinkTargets"
            "writeBoundary"
            "codexImmutableSettings"
            "linkGeneration"
          ]
        ) (lib.hm.dag.topoSort config.home.activation).result
      )
    )}
  '';
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";
  programs.codex = {
    enable = true;
    package = null;
    settings = {
      model = "declared";
      instructions = "first\nsecond";
      nested = {
        enabled = true;
        values = [
          "one"
          "two"
        ];
      };
    };
  };
  nmt.script = ''
    set -eu
    export TESTED
    source_file="$TESTED/home-files/.codex/config.toml"
    export HOME="$TMPDIR/hm-user"
    mkdir -p "$HOME/.codex"
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activation} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"
    settings="$(${lib.getExe pkgs.jaq} --from toml --to toml '.' "$source_file")"
    printf '%s\n' "$settings" > "$HOME/.codex/config.toml"
    cmp "$HOME/.codex/config.toml" "$source_file"
    "$TMPDIR/activate"
    test -L "$HOME/.codex/config.toml"
    test "$(readlink -e "$HOME/.codex/config.toml")" = "$(readlink -e "$source_file")"
    rm "$HOME/.codex/config.toml"
    printf 'model = "declared"\ninstructions = "first\\nsecond"\nuser_setting = true\n' > "$HOME/.codex/config.toml"
    cp "$HOME/.codex/config.toml" "$TMPDIR/extra-settings"
    if "$TMPDIR/activate" > "$TMPDIR/extra-output" 2>&1; then
      exit 1
    fi
    grep -F 'would be clobbered' "$TMPDIR/extra-output"
    cmp "$HOME/.codex/config.toml" "$TMPDIR/extra-settings"
  '';
}
