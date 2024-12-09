{ config, lib, pkgs, ... }:

let

  inherit (lib) mkIf mkOption types;

  cfg = config.programs.vifm;

in {
  meta.maintainers = [ lib.hm.maintainers.aabccd021 ];

  options.programs.vifm = {
    enable = lib.mkEnableOption "vifm, a Vim-like file manager";

    package = lib.mkPackageOption pkgs "vifm" { };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = "mark h ~/";
      description = ''
        Extra lines added to the {file}`$XDG_CONFIG_HOME/vifm/vifmrc` file.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."vifm/vifmrc" =
      mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}
