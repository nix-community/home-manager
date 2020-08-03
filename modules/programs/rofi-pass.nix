{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.rofi.pass;

in {
  meta.maintainers = [ maintainers.seylerius ];

  options.programs.rofi.pass = {
    enable = mkEnableOption "rofi integration with password-store";

    stores = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Directory roots of your password-stores.
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''
        URL_field='url'
        USERNAME_field='user'
        AUTOTYPE_field='autotype'
      '';
      description = ''
        Extra configuration to be added at to the rofi-pass config file.
        Additional examples can be found at
        <link xlink:href="https://github.com/carnager/rofi-pass/blob/master/config.example"/>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.rofi-pass ];

    xdg.configFile."rofi-pass/config".text = optionalString (cfg.stores != [ ])
      ("root=" + (concatStringsSep ":" cfg.stores) + "\n") + cfg.extraConfig
      + optionalString (cfg.extraConfig != "") "\n";
  };
}
