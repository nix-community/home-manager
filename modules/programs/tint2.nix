{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.tint2;

in {
  meta.maintainers = [ hm.maintainers.CarlosLoboxyz ];

  options.programs.tint2 = {
    enable =
      mkEnableOption "tint2, a simple, unobtrusive and light panel for Xorg";

    package = lib.mkPackageOption pkgs "tint2" { };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Commands for tint2 that will be add to the {file}`tint2rc`
        file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "tint2/tint2rc" =
        mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
    };
  };
}
