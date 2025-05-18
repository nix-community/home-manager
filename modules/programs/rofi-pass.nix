{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types;

  cfg = config.programs.rofi.pass;
in
{
  meta.maintainers = with lib.maintainers; [
    seylerius
    robwalt
  ];

  options.programs.rofi.pass = {
    enable = lib.mkEnableOption "rofi integration with password-store";

    package = lib.mkPackageOption pkgs "rofi-pass" {
      nullable = true;
      example = "pkgs.rofi-pass-wayland";
    };

    stores = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Directory roots of your password-stores.
      '';
    };

    extraConfig = lib.mkOption {
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
        <https://github.com/carnager/rofi-pass/blob/master/config.example>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."rofi-pass/config".text =
      lib.optionalString (cfg.stores != [ ]) ("root=" + (lib.concatStringsSep ":" cfg.stores) + "\n")
      + cfg.extraConfig
      + lib.optionalString (cfg.extraConfig != "") "\n";
  };
}
