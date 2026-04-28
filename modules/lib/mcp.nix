{ lib }:

let
  /*
    Merge a server's `env` and `envFiles` into a single attribute set,
    converting each `envFiles` path using the provided template function.

    The `mkFileRef` function receives the file path string and returns the
    substitution string for that path.

    Type: mergeEnv :: (String -> String) -> AttrSet -> AttrSet

    Example:
      mergeEnv (path: "{file:${path}}") {
        env = { API_KEY = "literal"; };
        envFiles = { TOKEN = /run/secrets/token; };
      }
      => { API_KEY = "literal"; TOKEN = "{file:/run/secrets/token}"; }
  */
  mergeEnv = mkFileRef: server: server.env // lib.mapAttrs (_: mkFileRef) server.envFiles;

  /*
    Wrap a local MCP server command in a shell script that reads secrets from
    `envFiles` paths into the environment before executing the original process.
    Compatible with file-based secret managers such as sops-nix or systemd credentials.

    Type: mkEnvFilesWrapper :: { pkgs, name, server } -> Derivation
  */
  mkEnvFilesWrapper =
    {
      pkgs,
      name,
      server,
    }:
    pkgs.writeShellScript "mcp-${name}-wrapper" ''
      ${lib.concatStrings (
        lib.mapAttrsToList (var: path: ''
          if ${var}=$(cat ${lib.escapeShellArg path}); then
            export ${var}
          else
            printf '[${name} wrapper ] Failed to read env var %s from %s\n' \
              ${lib.escapeShellArg var} \
              ${lib.escapeShellArg path} >&2
          fi
        '') server.envFiles
      )}
      exec ${lib.escapeShellArgs ([ server.command ] ++ server.args)}
    '';

  /*
    If the server has `envFiles` set and a non-null `command`, return
    attribute overrides that replace `command` with an `mkEnvFilesWrapper`
    wrapper script and reset `args` to `[]`.

    Returns `{}` when no wrapping is needed.

    Type: envFilesOverrides :: Pkgs -> String -> AttrSet -> AttrSet
  */
  envFilesOverrides =
    pkgs: name: server:
    (lib.optionalAttrs (server.envFiles != { } && server.command != null) {
      command = mkEnvFilesWrapper { inherit pkgs name server; };
      args = [ ];
    });

  # Check if mcp server config is remote
  isRemote = server: server.url != null;
in
{
  inherit mkEnvFilesWrapper;

  /*
    Normalise an MCP server attribute set for consumption by a client
    program. Applies the following transformations:

    - Resolves effective `enabled` from optional `enabled`/`disabled`
    - `transformStyle = "wrapping"`:
      - Adds `enabled`
      - Adds `type` derived from whether `url` is set (`"http"` or `"stdio"`)
      - Wraps `command` via `mkEnvFilesWrapper` when `envFiles` is non-empty
      - Removes `disabled`, `envFiles`, and attributes listed in `exclude`
    - `transformStyle = "opencode"`:
      - Produces OpenCode-native shape (`local`/`remote`, command list, environment)

    Type: transformMcpServer :: { exclude?, pkgs, name, server, transformStyle? } -> AttrSet
  */
  transformMcpServer =
    {
      exclude ? [ ],
      pkgs,
      name,
      server,
      transformStyle ? "wrapping",
    }:
    let
      hasEnabled = server ? enabled && server.enabled != null;
      hasDisabled = server ? disabled && server.disabled != null;
      enabled =
        if hasEnabled then
          server.enabled
        else if hasDisabled then
          !server.disabled
        else
          null;
      transformedServer =
        if transformStyle == "wrapping" then
          server
          // {
            inherit enabled;
            type = if isRemote server then "http" else "stdio";
          }
          // (envFilesOverrides pkgs name server)
        else if transformStyle == "opencode" then
          let
            mergedEnvFile = mergeEnv (path: "{file:${path}}") server;
          in
          {
            inherit enabled;
          }
          // (
            if isRemote server then
              {
                type = "remote";
                inherit (server) url;
              }
              // lib.optionalAttrs (server.headers != { }) { inherit (server) headers; }
            else
              {
                type = "local";
                command = [ server.command ] ++ server.args;
              }
              // lib.optionalAttrs (mergedEnvFile != { }) { environment = mergedEnvFile; }
          )
        else
          throw ''
            lib.hm.mcp.transformMcpServer: unknown transformStyle `${transformStyle}`.
            Expected one of: "wrapping", "opencode".
          '';
    in
    lib.filterAttrs (_: v: v != null && v != [ ] && v != { }) (
      lib.removeAttrs transformedServer (
        [
          "disabled"
          "envFiles"
        ]
        ++ exclude
      )
    );
}
