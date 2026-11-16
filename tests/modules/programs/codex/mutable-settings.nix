{
  config,
  lib,
  pkgs,
  ...
}:
let
  settingsPath = "$HOME/.config/codex/config.toml";
  activation = pkgs.writeShellScript "activate-codex-settings" ''
    set -eu
    set -o pipefail
    ${config.lib.bash.initHomeManagerLib}
    ${config.home.activation.codexMutableSettings.data}
  '';
in
{
  programs.codex = {
    enable = true;
    package = null;
    mutableSettings = true;
    settings.model = "declared";
  };
  home.preferXdgDirectories = true;
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    set -eu
    set -o pipefail
    export HOME="$TMPDIR/hm-user"
    assertPathNotExists home-files/.config/codex/config.toml
    mkdir -p "$HOME/.config/codex"
    printf '%s\n' 'model = "old"' 'extra = true' > ${settingsPath}
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activation} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"
    "$TMPDIR/activate"
    test ! -L ${settingsPath}
    ${lib.getExe pkgs.jaq} --from toml -e '.model == "declared" and .extra == true' ${settingsPath}
    assertPathNotExists "$HOME/.codex/config.toml"
  '';
}
