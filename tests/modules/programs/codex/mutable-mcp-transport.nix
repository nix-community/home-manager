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
    settings.mcp_servers = {
      to_http = {
        url = "https://new.example.com/mcp";
        http_headers.X-New = "2";
      };
      to_stdio = {
        command = "new-mcp";
        args = [ "--new" ];
        env.NEW_TOKEN = "new-token";
      };
      unchanged_stdio.command = "unchanged-mcp";
      unchanged_http.url = "https://unchanged.example.com/mcp";
      partial.startup_timeout_sec = 60;
    };
  };
  home.preferXdgDirectories = true;
  home.homeDirectory = lib.mkForce "/@TMPDIR@/hm-user";

  nmt.script = ''
    set -eu
    set -o pipefail
    export HOME="$TMPDIR/hm-user"
    mkdir -p "$HOME/.config/codex"
    cat ${./mutable-mcp-transport-before.toml} > ${settingsPath}
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activation} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"
    "$TMPDIR/activate"
    ${lib.getExe pkgs.jaq} --from toml -S '.' ${settingsPath} > "$TMPDIR/actual.json"
    ${lib.getExe pkgs.jaq} --from toml -S '.' ${./mutable-mcp-transport-expected.toml} > "$TMPDIR/expected.json"
    assertFileContent "$TMPDIR/actual.json" "$TMPDIR/expected.json"
    cp ${settingsPath} "$TMPDIR/first-activation.toml"
    "$TMPDIR/activate"
    assertFileContent ${settingsPath} "$TMPDIR/first-activation.toml"
  '';
}
