{ config, lib, pkgs, ... }:
let
  cfg = config.programs.micro;

  jsonFormat = pkgs.formats.json { };
in {
  meta.maintainers = [ lib.hm.maintainers.mforster ];

  options = {
    programs.micro = {
      enable = lib.mkEnableOption "micro, a terminal-based text editor";

      package = lib.mkPackageOption pkgs "micro" { nullable = true; };

      settings = lib.mkOption {
        type = jsonFormat.type;
        default = { };
        example = lib.literalExpression ''
          {
            autosu = false;
            cursorline = false;
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/micro/settings.json`. See
          <https://github.com/zyedidia/micro/blob/master/runtime/help/options.md>
          for supported values.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."micro/settings.json".source =
      jsonFormat.generate "micro-settings" cfg.settings;
  };
}
