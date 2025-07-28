{ config, lib, ... }:
let
  cfg = config.programs.zsh;
in
rec {
  homeDir = config.home.homeDirectory;

  # escapes for shell and cleans trailing slashes that can mess with test regex
  cleanPathStr = pathStr: lib.escapeShellArg (lib.removeSuffix "/" pathStr);

  # strips home directory prefix from absolute path.
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

  # given a relative (or unknown) path, returns absolute by prepending home dir
  # if path doesn't begin with "/"
  mkAbsPathStr =
    pathStr: cleanPathStr ((lib.optionalString (!lib.hasPrefix "/" pathStr) "${homeDir}/") + pathStr);

  # For shell variable paths like history.path that get expanded at runtime
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

  # If dotDir is default (i.e., the user's home dir) plugins are stored in
  # ~/.zsh/plugins -- otherwise, in `programs.zsh.dotDir`/plugins
  pluginsDir = dotDirAbs + (lib.optionalString (homeDir == dotDirAbs) "/.zsh") + "/plugins";
}
