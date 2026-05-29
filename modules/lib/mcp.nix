{ lib }:

let
  /*
    Checks whether a value is a file reference submodule.

    A file reference has the shape `{ file = "/path/to/file"; }` and is used
    to indicate that an environment variable's value should be read from a file
    at runtime (e.g. via sops-nix or systemd credentials).

    Type: isFileRef :: Value -> Bool
  */
  isFileRef = value: lib.isAttrs value && value ? file;

  /*
    Filters an `env` attrset to contain only literal (non-file-ref) values.

    This is useful when a transform needs to produce two separate outputs:
    one with the literal values and one with the file paths (for wrapping).

    Type: literalEnv :: AttrSet -> AttrSet

    Example:
      literalEnv { API_KEY = "secret"; TOKEN.file = "/run/secrets/token"; }
      => { API_KEY = "secret"; }
  */
  literalEnv = env: lib.filterAttrs (_: value: !isFileRef value) env;

  /*
    Extracts only the file paths from file-ref entries in an `env` attrset.

    Returns a flat `attrsOf str` mapping variable names to their file paths.
    Non-file-ref entries are excluded.

    Type: fileRefEnv :: AttrSet -> AttrSet

    Example:
      fileRefEnv { API_KEY = "secret"; TOKEN.file = "/run/secrets/token"; }
      => { TOKEN = "/run/secrets/token"; }
  */
  fileRefEnv = env: lib.mapAttrs (_: value: value.file) (lib.filterAttrs (_: isFileRef) env);

  /*
    Render an `env` attrset (literals + file refs) as a flat `attrsOf str`
    by mapping file refs through `mkFileRef path` and leaving literals untouched.

    Type: renderEnv :: (String -> String) -> AttrSet -> AttrSet

    Example:
      renderEnv (path: "{file:${path}}") {
        API_KEY = "literal";
        SESSION_TOKEN.file = "/run/secrets/token";
      }
      => { API_KEY = "literal"; SESSION_TOKEN = "{file:/run/secrets/token}"; }
  */
  renderEnv =
    mkFileRef: env:
    lib.mapAttrs (_: value: if isFileRef value then mkFileRef value.file else value) env;

  /*
    Wrap a local MCP server command in a shell script that reads file-backed
    env values into the environment before executing the original process.
    Compatible with file-based secret managers such as sops-nix or systemd
    credentials. Reads file refs from `server.env`.

    Type: mkEnvFilesWrapper :: { pkgs, name, server } -> Derivation
  */
  mkEnvFilesWrapper =
    {
      pkgs,
      name,
      server,
    }:
    let
      files = fileRefEnv (server.env or { });
    in
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
        '') files
      )}
      exec ${lib.escapeShellArgs ([ server.command ] ++ (server.args or [ ]))}
    '';

  /*
    extraTransform factory: when the server has file refs in `env` and a
    local `command`, replace `command` with a wrapper script that reads
    those files at startup, reset `args` to `[ ]`, and drop the file refs
    from `env` (leaving only literal entries).

    When there is nothing to wrap, returns the server unchanged.

    Type: wrapEnvFilesCommand :: { pkgs, name } -> AttrSet -> AttrSet
  */
  wrapEnvFilesCommand =
    { pkgs, name }:
    server:
    let
      files = fileRefEnv (server.env or { });
      needsWrapping = files != { };
    in
    server
    // lib.optionalAttrs needsWrapping {
      command = mkEnvFilesWrapper { inherit pkgs name server; };
      args = [ ];
      env = literalEnv (server.env or { });
    };

  /*
    Resolve the effective `enabled` state from a server config that may
    have either an `enabled` or a `disabled` field (but not both).

    Returns `null` if neither field is present, allowing callers to omit
    the attribute from the output via the empty-value filter.

    Type: resolveEnabled :: AttrSet -> Null | Bool
  */
  resolveEnabled =
    server:
    let
      hasEnabled = server ? enabled && server.enabled != null;
      hasDisabled = server ? disabled && server.disabled != null;
    in
    if hasEnabled then
      server.enabled
    else if hasDisabled then
      !server.disabled
    else
      null;

  /*
    extraTransform that adds `type = "stdio" | "http"` based on whether the
    server has a `url`.

    Type: addType :: AttrSet -> AttrSet
  */
  addType =
    server:
    if server ? type then
      server
    else
      server
      // {
        type = if server ? url && server.url != null then "http" else "stdio";
      };
in
{
  inherit
    renderEnv
    mkEnvFilesWrapper
    wrapEnvFilesCommand
    addType
    ;

  /*
    Normalise an MCP server attribute set for consumption by a client
    program. Performs only universal steps:

    1. Resolve `enabled` from optional `enabled`/`disabled` fields.
    2. Apply each function in `extraTransforms` to the server attrs, in
       order. Transforms run before `mkFileRef`, `exclude` and the
       empty-value filter, so a transform can still read attrs that will
       be excluded and operate on the raw env shape (with file refs).
    3. Render any remaining file refs in `env` through `mkFileRef path`.
       Callers that consume file refs themselves (e.g. via
       `wrapEnvFilesCommand`) will have stripped them in an
       extraTransform, so `mkFileRef` is a no-op for them.
    4. Remove `disabled` and any keys listed in `exclude`.
    5. Filter `null`, `[]`, and `{}` values.

    Type: transformMcpServer ::
      { server, exclude?, extraTransforms?, mkFileRef? }
      -> AttrSet
  */
  transformMcpServer =
    {
      server,
      exclude ? [ ],
      extraTransforms ? [ ],
      mkFileRef ? (path: "{file:${path}}"),
    }:
    let
      enabled = resolveEnabled server;
      normalised = server // {
        inherit enabled;
        url = if (server.url or null) != null then server.url else server.serverUrl or null;
      };
      transformed = lib.foldl' (acc: transform: transform acc) normalised extraTransforms;
      withRenderedEnv =
        transformed
        // lib.optionalAttrs (transformed ? env) {
          env = renderEnv mkFileRef transformed.env;
        };
      cleaned = removeAttrs withRenderedEnv (
        [
          "disabled"
          "serverUrl"
        ]
        ++ exclude
      );
    in
    lib.filterAttrs (_: value: value != null && value != [ ] && value != { }) cleaned;
}
