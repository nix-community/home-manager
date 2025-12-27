{ config, lib, ... }:
let
  cfg = config.programs.zsh;

  stripSlash = lib.removeSuffix "/";
in
rec {
  # Raw home directory, no trailing slash.
  homeDir = stripSlash config.home.homeDirectory;

  /*
    Escape a path string for shell usage and remove trailing slashes.

    This function prepares path strings for safe shell usage by escaping
    special characters and removing trailing slashes that can interfere
    with test regex patterns.

    Type: String -> String

    Example:
      cleanPathStr "/path/to/dir/" => "'/path/to/dir'"
      cleanPathStr "path with spaces" => "'path with spaces'"
  */
  cleanPathStr = pathStr: lib.escapeShellArg (stripSlash pathStr);

  /*
    Convert an absolute path to a relative path by stripping the home directory prefix.
    Returns the raw path (unescaped) for use in home.file keys.

    This function converts absolute paths within the home directory to relative paths
    by removing the home directory prefix. Paths already relative are returned as-is.
    Absolute paths outside the home directory cause an error.

    Type: String -> String

    Example:
      mkRelPathStr "/home/user/config" => "config"
      mkRelPathStr "config" => "config"
      mkRelPathStr "/home/user" => "."
      mkRelPathStr "/etc/config" => <error>
  */
  mkRelPathStr =
    pathStr:
    let
      normPath = stripSlash pathStr;
    in
    if (!lib.hasPrefix "/" normPath) then
      normPath
    else if normPath == homeDir then
      "."
    else if (lib.hasPrefix "${homeDir}/" normPath) then
      lib.removePrefix "${homeDir}/" normPath
    else
      throw ''
        Attempted to convert an absolute path not within home directory to a
        home-relative path.
        Conversion attempted on:
          ${pathStr}
        ...which does not start with:
          ${homeDir}
      '';

  /*
    Convert a relative path to an absolute path.
    Returns RAW path (unescaped).

    This function ensures paths are absolute by prepending the home directory
    to relative paths. Already absolute paths are returned unchanged (after cleaning).

    Type: String -> String

    Example:
      mkAbsPathStr "config" => "/home/user/config"
      mkAbsPathStr "/absolute/path" => "/absolute/path"
  */
  mkAbsPathStr =
    pathStr:
    let
      normPath = stripSlash pathStr;
    in
    if lib.hasPrefix "/" normPath then normPath else "${homeDir}/${normPath}";

  /*
    Convert a path to absolute form while preserving shell variables.
    Returns RAW path (unescaped) unless vars are present (then preserves vars).

    This function handles both literal paths and shell variable expressions.
    Shell variables (containing '$') are preserved unescaped to allow runtime expansion.
    Literal paths are made absolute.

    Type: String -> String

    Example:
      mkShellVarPathStr "config" => "/home/user/config"
      mkShellVarPathStr "$HOME/config" => "$HOME/config"
      mkShellVarPathStr "\${XDG_CONFIG_HOME:-$HOME/.config}/app" => "\${XDG_CONFIG_HOME:-$HOME/.config}/app"
  */
  mkShellVarPathStr =
    pathStr:
    let
      normPath = stripSlash pathStr;
      hasShellVars = lib.hasInfix "$" normPath;
    in
    if hasShellVars then normPath else mkAbsPathStr normPath;

  dotDirAbs = mkAbsPathStr cfg.dotDir;
  dotDirRel = mkRelPathStr cfg.dotDir;

  /*
    Determine the plugins directory path based on dotDir configuration.

    If dotDir is the default (user's home directory), plugins are stored in
    ~/.zsh/plugins. Otherwise, they are stored in `dotDir`/plugins.

    Type: String
  */
  pluginsDir = dotDirAbs + (lib.optionalString (mkRelPathStr cfg.dotDir == ".") "/.zsh") + "/plugins";
}
