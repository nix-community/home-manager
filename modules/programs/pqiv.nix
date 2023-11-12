{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.pqiv;
  iniFormat = pkgs.formats.ini { };

in {
  meta.maintainers = with lib.maintainers; [ donovanglover ];

  options.programs.pqiv = {
    enable = mkEnableOption "pqiv image viewer";

    package = mkOption {
      type = types.package;
      default = pkgs.pqiv;
      defaultText = literalExpression "pkgs.pqiv";
      description = "The pqiv package to install.";
    };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/pqivrc</filename>. See <link
        xlink:href="https://github.com/phillipberndt/pqiv/blob/master/pqiv.1"/>
        for a list of available options. To set a boolean flag, set the value to 1.
      '';
      example = literalExpression ''
        {
          options = {
            lazy-load = 1;
            hide-info-box = 1;
            background-pattern = "black";
            thumbnail-size = "256x256";
            command-1 = "thunar";
          };
        };
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.pqiv" pkgs platforms.linux) ];

    home.packages = [ cfg.package ];

    xdg.configFile."pqivrc" = mkIf (cfg.settings != { }) {
      source = iniFormat.generate "pqivrc" cfg.settings;
    };
  };
}
