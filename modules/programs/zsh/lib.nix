{ config, lib, ... }:
let
  cfg = config.programs.zsh;
in
rec {
  homeDir = config.home.homeDirectory;

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
  cleanPathStr = pathStr: lib.escapeShellArg (lib.removeSuffix "/" pathStr);

  /*
    Convert an absolute path to a relative path by stripping the home directory prefix.

    This function converts absolute paths within the home directory to relative paths
    by removing the home directory prefix. Paths already relative are returned as-is.
    Absolute paths outside the home directory cause an error.

    Type: String -> String

    Example:
      mkRelPathStr "/home/user/config" => "'config'"
      mkRelPathStr "config" => "'config'"
      mkRelPathStr "/etc/config" => <error>
  */
  mkRelPathStr =
    pathStr:
    # is already a relative path
    if (!lib.hasPrefix "/" pathStr) then
      cleanPathStr pathStr
    # is an absolute path within home dir
    else if (lib.hasPrefix homeDir pathStr) then
      cleanPathStr (lib.removePrefix "${homeDir}/" pathStr)
    # is an absolute path not in home dir
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
    Convert a relative path to an absolute path by prepending the home directory.

    This function ensures paths are absolute by prepending the home directory
    to relative paths. Already absolute paths are returned unchanged (after cleaning).
    This function does NOT support shell variables.

    Type: String -> String

    Example:
      mkAbsPathStr "config" => "'/home/user/config'"
      mkAbsPathStr "/absolute/path" => "'/absolute/path'"
  */
  mkAbsPathStr =
    pathStr: cleanPathStr ((lib.optionalString (!lib.hasPrefix "/" pathStr) "${homeDir}/") + pathStr);

  /*
    Convert a path to absolute form while preserving shell variables for runtime expansion.

    This function handles both literal paths and shell variable expressions.
    Shell variables (containing '$') are preserved unescaped to allow runtime expansion.
    Literal paths are made absolute and properly escaped for shell usage.

    Type: String -> String

    Example:
      mkShellVarPathStr "config" => "'/home/user/config'"
      mkShellVarPathStr "$HOME/config" => "$HOME/config"
      mkShellVarPathStr "\${XDG_CONFIG_HOME:-$HOME/.config}/app" => "\${XDG_CONFIG_HOME:-$HOME/.config}/app"
  */
  mkShellVarPathStr =
    pathStr:
    let
      cleanPath = lib.removeSuffix "/" pathStr;
      hasShellVars = lib.hasInfix "$" cleanPath;
    in
    if hasShellVars then
      # Does not escape shell variables, allowing them to be expanded at runtime
      cleanPath
    else
      # For literal paths, make them absolute if needed and escape them
      cleanPathStr ((lib.optionalString (!lib.hasPrefix "/" cleanPath) "${homeDir}/") + cleanPath);

  dotDirAbs = mkAbsPathStr cfg.dotDir;
  dotDirRel = mkRelPathStr cfg.dotDir;

  /*
    Determine the plugins directory path based on dotDir configuration.

    If dotDir is the default (user's home directory), plugins are stored in
    ~/.zsh/plugins. Otherwise, they are stored in `dotDir`/plugins.

    Type: String
  */
  pluginsDir = dotDirAbs + (lib.optionalString (homeDir == dotDirAbs) "/.zsh") + "/plugins";
}
