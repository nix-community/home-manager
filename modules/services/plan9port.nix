{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.plan9port;

in {
  meta.maintainers = [ maintainers.ehmry ];

  options.services.plan9port = {
    fontsrv.enable =
      mkEnableOption "the Plan 9 file system access to host fonts";
    plumber.enable =
      mkEnableOption "the Plan 9 file system for interprocess messaging";
  };

  config = mkIf (cfg.fontsrv.enable || cfg.plumber.enable) {
    assertions = [
      (hm.assertions.assertPlatform "services.plan9port" pkgs platforms.linux)
    ];

    systemd.user.services.fontsrv = mkIf cfg.fontsrv.enable {
      Unit.Description = "the Plan 9 file system access to host fonts";
      Install.WantedBy = [ "default.target" ];
      Service.ExecStart = "${pkgs.plan9port}/bin/9 fontsrv";
    };

    systemd.user.services.plumber = mkIf cfg.plumber.enable {
      Unit.Description = "file system for interprocess messaging";
      Install.WantedBy = [ "default.target" ];
      Service.ExecStart = "${pkgs.plan9port}/bin/9 plumber -f";
    };

  };

}
