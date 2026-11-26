{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.lazysql;

  formatter = pkgs.formats.toml { };

  homeDir = config.home.homeDirectory;
  xdgConfigHome = config.home.sessionVariables.XDG_CONFIG_HOME or null;
  useDarwinDefault = xdgConfigHome == null || xdgConfigHome == "";
  xdgConfigPath = toString xdgConfigHome;
  knownXdgConfigHome =
    (xdgConfigPath == homeDir || lib.hasPrefix "${homeDir}/" xdgConfigPath)
    && lib.all (marker: !lib.hasInfix marker xdgConfigPath) [
      "$"
      "`"
      "\\"
      "\""
    ]
    && !(lib.elem ".." (lib.splitString "/" xdgConfigPath));
  darwinConfigHome =
    if useDarwinDefault then "${homeDir}/Library/Application Support" else xdgConfigPath;
in
{

  options.programs.lazysql = {
    enable = mkEnableOption "lazysql";
    package = mkPackageOption pkgs "lazysql" { nullable = true; };
    settings = mkOption {
      inherit (formatter) type;
      default = { };
      example = { };
      description = ''
        Configuration settings for lazysql.

        On macOS, the default target is
        {file}`~/Library/Application Support/lazysql/config.toml` when Home
        Manager has no nonempty {env}`XDG_CONFIG_HOME` to export. An absolute
        XDG configuration directory declared under the home directory is
        honored. Relative or shell-expanded values and directories outside
        the home directory retain the normal XDG file target. A value set
        only by the launcher is unavailable to Home Manager during
        evaluation. Declare the same absolute path under the home directory
        in {option}`home.sessionVariables.XDG_CONFIG_HOME` to match it.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."lazysql/config.toml" = mkIf (cfg.settings != { }) {
      source = formatter.generate "lazysql-config" cfg.settings;
      target = mkIf (pkgs.stdenv.hostPlatform.isDarwin && (useDarwinDefault || knownXdgConfigHome)) (
        # Use a priority just above the file type's mkDefault target.
        lib.mkOverride 999 "${darwinConfigHome}/lazysql/config.toml"
      );
    };
  };
}
