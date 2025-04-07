{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.havoc;
  iniFormat = pkgs.formats.ini { };
in
{
  meta.maintainers = with lib.maintainers; [ AndersonTorres ];

  options.programs.havoc = {
    enable = lib.mkEnableOption "Havoc terminal";

    package = lib.mkPackageOption pkgs "havoc" { nullable = true; };

    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/havoc.cfg`. See <https://raw.githubusercontent.com/ii8/havoc/master/havoc.cfg>
        for a list of available options.
      '';
      example = lib.literalExpression ''
        {
          child.program = "bash";
          window.opacity = 240;
          window.margin = no;
          terminal = {
            rows = 80;
            columns = 24;
            scrollback = 2000;
          };
          bind = {
            "C-S-c" = "copy";
            "C-S-v" = "paste";
            "C-S-r" = "reset";
            "C-S-Delete" = "hard reset";
            "C-S-j" = "scroll down";
            "C-S-k" = "scroll up";
            "C-S-Page_Down" = "scroll down page";
            "C-S-Page_Up" = "scroll up page";
            "C-S-End" = "scroll to bottom";
            "C-S-Home" = "scroll to top";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.havoc" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."havoc.cfg" = lib.mkIf (cfg.settings != { }) {
      source = iniFormat.generate "havoc.cfg" cfg.settings;
    };
  };
}
