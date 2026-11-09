{
  config,
  lib,
  pkgs,
  ...
}:
let
  activation = pkgs.writeShellScript "activate-herdr-desktop-immutable" ''
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
            "herdrDesktopImmutableSettings"
            "linkGeneration"
          ]
        ) (lib.hm.dag.topoSort config.home.activation).result
      )
    )}
  '';
in
{
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";
  xdg.enable = true;

  programs.herdr.desktop = {
    enable = true;
    package = null;

    settings = {
      telemetry = false;
      sounds.enabled = true;
      font = "Iosevka Term Slab";
      font_size = 14;
      font_ligatures = true;
      theme = {
        light = "catppuccin-latte";
        dark = "catppuccin-mocha";
      };
    };
  };

  nmt.script = ''
    set -eu
    export TESTED
    source_file="$TESTED/home-files/.config/herdr-app/settings.json"
    export HOME="$TMPDIR/hm-user"
    mkdir -p "$HOME/.config/herdr-app"
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activation} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"

    # The mutable merger writes a pretty-printed file. The immutable source
    # must use the same formatting so the cleanup can remove it and replace it
    # with a store link.
    settings="$(${lib.getExe pkgs.jaq} '.' "$source_file")"
    printf '%s\n' "$settings" > "$HOME/.config/herdr-app/settings.json"
    cmp "$HOME/.config/herdr-app/settings.json" "$source_file"

    "$TMPDIR/activate"
    test -L "$HOME/.config/herdr-app/settings.json"
    test "$(readlink -e "$HOME/.config/herdr-app/settings.json")" = "$(readlink -e "$source_file")"
  '';
}
