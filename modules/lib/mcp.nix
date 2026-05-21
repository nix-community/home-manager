{ lib }:

let
  isFileRef = v: lib.isAttrs v && v ? file;

  literalEnv = env: lib.filterAttrs (_: v: !isFileRef v) env;
  fileRefEnv = env: lib.mapAttrs (_: v: v.file) (lib.filterAttrs (_: isFileRef) env);

  /*
    Render an `env` attrset (literals + file refs) as a flat `attrsOf str` by
    mapping file refs through `mkFileRef path` and leaving literals untouched.

    Type: renderEnv :: (String -> String) -> AttrSet -> AttrSet

    Example:
      renderEnv (p: "{file:${p}}") {
        A = "literal";
        B.file = "/run/secrets/token";
      }
      => { A = "literal"; B = "{file:/run/secrets/token}"; }
  */
  renderEnv = mkFileRef: env: lib.mapAttrs (_: v: if isFileRef v then mkFileRef v.file else v) env;

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
      exec ${lib.escapeShellArgs ([ server.command ] ++ server.args)}
    '';

  /*
    extraTransform that adds `type = "stdio" | "http"` based on whether the
    server has a `url`.

    Type: deriveType :: AttrSet -> AttrSet
  */
  deriveType = s: s // { type = if s.url or null != null then "http" else "stdio"; };

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
    s:
    let
      files = fileRefEnv (s.env or { });
    in
    if files == { } || (s.command or null) == null then
      s
    else
      s
      // {
        command = mkEnvFilesWrapper {
          inherit pkgs name;
          server = s;
        };
        args = [ ];
        env = literalEnv (s.env or { });
      };

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
in
{
  inherit
    isFileRef
    literalEnv
    fileRefEnv
    renderEnv
    mkEnvFilesWrapper
    wrapEnvFilesCommand
    deriveType
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
      mkFileRef ? (p: "{file:${p}}"),
    }:
    let
      enabled = resolveEnabled server;
      withEnabled = server // {
        inherit enabled;
      };
      transformed = lib.foldl' (acc: f: f acc) withEnabled extraTransforms;
      withRenderedEnv =
        transformed
        // lib.optionalAttrs (transformed ? env) {
          env = renderEnv mkFileRef transformed.env;
        };
      cleaned = removeAttrs withRenderedEnv ([ "disabled" ] ++ exclude);
    in
    lib.filterAttrs (_: v: v != null && v != [ ] && v != { }) cleaned;
}
