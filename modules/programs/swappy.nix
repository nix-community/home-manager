{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.swappy;

  iniFormat = pkgs.formats.ini { };

  iniFile = iniFormat.generate "config" cfg.settings;

in {
  meta.maintainers = [ hm.maintainers.eclairevoyant ];

  options.programs.swappy = {
    enable = mkEnableOption "Swappy, a GTK-based screenshot editor for Wayland";

    package = mkPackageOption pkgs "swappy" { };

    settings = mkOption {
      type = iniFormat.type;
      default = { };
      example = ''
        {
          Default = {
            show_panel = true;
          };
        }'';
      description = ''
        Configuration to use for Swappy. See
        <citerefentry>
          <refentrytitle>swappy</refentrytitle>
          <manvolnum>1</manvolnum>
        </citerefentry>
        for available options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile =
      mkIf (cfg.settings != { }) { "swappy/config".source = iniFile; };
  };
}
