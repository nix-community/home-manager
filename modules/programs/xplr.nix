{ config, lib, pkgs, ... }:
let
  inherit (lib)
    concatStringsSep types mkIf mkOption mkEnableOption mkPackageOption
    literalExpression;

  cfg = config.programs.xplr;

  initialConfig = ''
    version = '${cfg.package.version}'
  '';

  # We provide a default version line within the configuration file, which is
  # obtained from the package's attributes. Merge the initial configFile, a
  # mapped list of plugins and then the user defined configuration to obtain the
  # final configuration.
  pluginPath = if cfg.plugins != [ ] then
    (''
      package.path=
    '' + (concatStringsSep " ..\n"
      (map (p: ''"${p}/init.lua;${p}/?.lua;"'') cfg.plugins)) + ''
         ..
        package.path
      '')
  else
    "\n";

  configFile = initialConfig + pluginPath + cfg.extraConfig;
in {
  meta.maintainers = [ lib.maintainers.NotAShelf ];

  options.programs.xplr = {
    enable = mkEnableOption "xplr, terminal UI based file explorer";

    package = mkPackageOption pkgs "xplr" { };

    plugins = mkOption {
      type = with types; nullOr (listOf (either package str));
      default = [ ];
      defaultText = literalExpression "[]";
      description = ''
        Plugins to be added to your configuration file.

        Must be a package, an absolute plugin path, or string to be recognized
        by xplr. Paths will be relative to
        {file}`$XDG_CONFIG_HOME/xplr/init.lua` unless they are absolute.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        require("wl-clipboard").setup {
          copy_command = "wl-copy -t text/uri-list",
          paste_command = "wl-paste",
          keep_selection = true,
        }
      '';
      description = ''
        Extra xplr configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."xplr/init.lua".source =
      pkgs.writeText "init.lua" configFile;
  };
}
