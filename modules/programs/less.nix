{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.less;
in
{
  meta.maintainers = [ lib.maintainers.pamplemousse ];

  options = {
    programs.less = {
      enable = lib.mkEnableOption "less, opposite of more";

      package = lib.mkPackageOption pkgs "less" { nullable = true; };

      keys = lib.mkOption {
        type = lib.types.lines;
        default = "";
        example = ''
          s        back-line
          t        forw-line
        '';
        description = ''
          Extra configuration for {command}`less` written to
          {file}`$XDG_CONFIG_HOME/lesskey`.
        '';
      };

      historyFile = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Location of the less history file.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."lesskey".text = cfg.keys;
    home.sessionVariables =
      mkIf (cfg.historyFile != null) { LESSHISTFILE = cfg.historyFile; };
  };
}
