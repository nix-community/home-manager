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
  existing = builtins.toFile "config.toml" ''
    [mcp_servers.to_http]
    command = "old-mcp"
    args = ["--stdio"]
    env = { TOKEN = "secret" }
    env_vars = ["EXISTING_TOKEN"]
    cwd = "/old-directory"
    startup_timeout_sec = 30
    tool_timeout_sec = 90
    enabled = false
    scopes = ["read"]
    future_setting = "http-value"

    [mcp_servers.to_http.tools.search]
    approval_mode = "approve"

    [mcp_servers.to_stdio]
    url = "https://old.example.com/mcp"
    bearer_token = "old-token"
    bearer_token_env_var = "OLD_TOKEN"
    http_headers = { X-Old = "1" }
    env_http_headers = { X-Token = "OLD_TOKEN" }
    http_headers_helper = "old-headers-helper"
    oauth = { client_id = "old-client" }
    oauth_resource = "https://old.example.com"
    auth = "oauth"
    startup_timeout_sec = 45
    tool_timeout_sec = 120
    enabled = true
    scopes = ["write"]
    future_setting = "stdio-value"

    [mcp_servers.to_stdio.tools.search]
    approval_mode = "approve"

    [mcp_servers.unchanged_stdio]
    command = "unchanged-mcp"
    args = ["--unchanged"]
    env = { KEEP = "yes" }
    env_vars = ["KEEP_TOKEN"]
    cwd = "/unchanged-directory"

    [mcp_servers.unchanged_http]
    url = "https://unchanged.example.com/mcp"
    bearer_token_env_var = "KEEP_TOKEN"
    http_headers = { X-Keep = "yes" }
    env_http_headers = { X-Token = "KEEP_TOKEN" }
    http_headers_helper = "keep-headers-helper"
    oauth = { client_id = "keep-client" }
    oauth_resource = "https://unchanged.example.com"
    auth = "oauth"

    [mcp_servers.undeclared]
    command = "user-mcp"
    args = ["--user"]
    env = { KEEP = "yes" }
    future_setting = "undeclared-value"

    [mcp_servers.undeclared.tools.search]
    approval_mode = "approve"

    [mcp_servers.partial]
    url = "https://partial.example.com/mcp"
    bearer_token_env_var = "PARTIAL_TOKEN"
    http_headers = { X-Partial = "yes" }
    startup_timeout_sec = 10
    future_setting = "partial-value"
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
    cat ${existing} > ${settingsPath}
    ${lib.getExe pkgs.gnused} "s|/@TMPDIR@|$TMPDIR|g" ${activation} > "$TMPDIR/activate"
    chmod +x "$TMPDIR/activate"
    "$TMPDIR/activate"
    ${lib.getExe pkgs.jaq} --from toml -e '.mcp_servers == {
      to_http: {
        url: "https://new.example.com/mcp",
        http_headers: {"X-New": "2"},
        startup_timeout_sec: 30,
        tool_timeout_sec: 90,
        enabled: false,
        scopes: ["read"],
        future_setting: "http-value",
        tools: {search: {approval_mode: "approve"}}
      },
      to_stdio: {
        command: "new-mcp",
        args: ["--new"],
        env: {NEW_TOKEN: "new-token"},
        startup_timeout_sec: 45,
        tool_timeout_sec: 120,
        enabled: true,
        scopes: ["write"],
        future_setting: "stdio-value",
        tools: {search: {approval_mode: "approve"}}
      },
      unchanged_stdio: {
        command: "unchanged-mcp",
        args: ["--unchanged"],
        env: {KEEP: "yes"},
        env_vars: ["KEEP_TOKEN"],
        cwd: "/unchanged-directory"
      },
      unchanged_http: {
        url: "https://unchanged.example.com/mcp",
        bearer_token_env_var: "KEEP_TOKEN",
        http_headers: {"X-Keep": "yes"},
        env_http_headers: {"X-Token": "KEEP_TOKEN"},
        http_headers_helper: "keep-headers-helper",
        oauth: {client_id: "keep-client"},
        oauth_resource: "https://unchanged.example.com",
        auth: "oauth"
      },
      undeclared: {
        command: "user-mcp",
        args: ["--user"],
        env: {KEEP: "yes"},
        future_setting: "undeclared-value",
        tools: {search: {approval_mode: "approve"}}
      },
      partial: {
        url: "https://partial.example.com/mcp",
        bearer_token_env_var: "PARTIAL_TOKEN",
        http_headers: {"X-Partial": "yes"},
        startup_timeout_sec: 60,
        future_setting: "partial-value"
      }
    }' ${settingsPath} > /dev/null || fail "Unexpected servers: $(cat ${settingsPath})"
    cp ${settingsPath} "$TMPDIR/first-activation.toml"
    "$TMPDIR/activate"
    assertFileContent ${settingsPath} "$TMPDIR/first-activation.toml"
  '';
}
