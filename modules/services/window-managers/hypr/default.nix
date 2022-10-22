{ config, lib, pkgs, ... }:

let

  inherit (lib) hm types mkEnableOption mkIf mkOption mkPackageOption platforms;

  cfg = config.xsession.windowManager.hypr;

in {
  meta.maintainers = with lib.maintainers; [ AndersonTorres ];

  options = import ./options.nix { inherit config lib pkgs; };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "xsession.windowManager.hypr" pkgs
        platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."hypr/hypr.conf" =
      mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };

    xsession.windowManager.command = ''
      "${cfg.package}/bin/Hypr"
    '';
  };
}
