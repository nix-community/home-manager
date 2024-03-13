{ config, lib, pkgs, ... }:

let cfg = config.services.eww;

in {
  meta.maintainers = [ lib.hm.maintainers.madnat ];

  options = {
    services.eww = {
      enable = lib.mkEnableOption "ElKowars wacky widgets daemon";

      package = lib.mkPackageOption pkgs "eww" { };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.emacs" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.eww = {
      Unit = {
        Description = "ElKowars wacky widgets daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = let eww = lib.getExe cfg.package;
      in {
        Type = "simple";
        ExecStart = "${eww} daemon --no-daemonize";
        ExecStop = "${eww} kill";
        ExecReload = "${eww} reload";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
