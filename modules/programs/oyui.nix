{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    types
    maintainers
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    mkMerge
    ;

  cfg = config.programs.oyui;
in
{
  options.programs.oyui = {
    enable = mkEnableOption "modern terminal diff editor";

    package = mkPackageOption pkgs "oyui" { nullable = true; };

    enableJujutsuIntegration = mkEnableOption "use oyui as the diff editor for jj" // {
      default = false;
    };

    config = mkOption {
      type = with types; nullOr lines;
      default = null;
      description = ''
        Text written to {file}`$XDG_CONFIG_HOME/oyui/config.rn`.
      '';
    };

    configFile = mkOption {
      type = with types; nullOr path;
      default = null;
      description = ''
        Path of the config file written to {file}`$XDG_CONFIG_HOME/oyui/config.rn`.
        Ignored when {option}`programs.oyui.config.config` is set.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."oyui/config.rn" = mkMerge [
      (mkIf (cfg.config != null) { text = cfg.config; })
      (mkIf (cfg.configFile != null && cfg.config == null) { source = cfg.configFile; })
    ];

    programs.jujutsu.settings = mkIf cfg.enableJujutsuIntegration {
      ui = {
        diff-editor = "oyui";
        diff-instructions = false;
      };

      merge-tools.oyui = {
        program = lib.getExe pkgs.oyui;
        edit-args = [
          "diff"
          "$left"
          "$right"
        ];
      };
    };
  };

  meta.maintainers = with maintainers; [ weathercold ];
}
