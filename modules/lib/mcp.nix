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
    Wrap a local MCP server command in a shell script that reads secrets from `envFiles`
    paths into the environment before executing the original process.
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
in
{
  inherit mkEnvFilesWrapper;

  /*
    `mergeEnv` specialised for the `{file:…}` reference syntax, which
    resolves secret paths at runtime without a wrapper script. Use this
    in MCP client integrations that support the syntax natively instead
    of falling back to `mkEnvFilesWrapper`.

    Example:
      mergeEnvFile { env = {}; envFiles = { TOKEN = /run/secrets/token; }; }
      => { TOKEN = "{file:/run/secrets/token}"; }
  */
  mergeEnvFile = mergeEnv (path: "{file:${path}}");

  /*
    Normalise an MCP server attribute set for consumption by a client
    program. Applies the following transformations:

    - Adds `enabled` as the inverse of `disabled`
    - Adds `type` derived from whether `url` is set (`"http"` or `"stdio"`)
    - Wraps `command` via `mkEnvFilesWrapper` when `envFiles` is non-empty
    - Removes `disabled`, `envFiles`, and any attributes listed in `exclude`
    - Removes attributes whose value is `null`

    Type: transformMcpServer :: { exclude?, pkgs, name, server } -> AttrSet
  */
  transformMcpServer =
    {
      exclude ? [ ],
      pkgs,
      name,
      server,
    }:
    lib.filterAttrs (_: v: v != null && v != [ ] && v != { }) (
      lib.removeAttrs
        (
          server
          // {
            enabled = !server.disabled;
            type = if server.url != null then "http" else "stdio";
          }
          // (envFilesOverrides pkgs name server)
        )
        (
          [
            "disabled"
            "envFiles"
          ]
          ++ exclude
        )
    );
}
