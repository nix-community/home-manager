{ config, lib, pkgs, ... }:

with lib;
let cfg = config.programs.vifm;

in {
  meta.maintainers = [ hm.maintainers.aabccd021 ];

  options.programs.vifm = {
    enable = mkEnableOption "vifm";

    package = mkPackageOption pkgs "vifm" { };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra lines added to the <filename>$XDG_CONFIG_HOME/vifm/vifmrc</filename> file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."vifm/vifmrc" =
      mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}
