{ config, lib, pkgs, ... }:
let

  cfg = config.programs.tint2;

in {
  meta.maintainers = [ lib.hm.maintainers.CarlosLoboxyz ];

  options.programs.tint2 = {
    enable = lib.mkEnableOption
      "tint2, a simple, unobtrusive and light panel for Xorg";

    package = lib.mkPackageOption pkgs "tint2" { };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Commands for tint2 that will be add to the {file}`tint2rc`
        file.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "tint2/tint2rc" =
        lib.mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
    };
  };
}
