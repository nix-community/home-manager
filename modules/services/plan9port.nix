{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.plan9port;

in
{
  meta.maintainers = [ lib.maintainers.ehmry ];

  options.services.plan9port = {
    fontsrv.enable = lib.mkEnableOption "the Plan 9 file system access to host fonts";
    plumber.enable = lib.mkEnableOption "the Plan 9 file system for interprocess messaging";
  };

  config = lib.mkIf (cfg.fontsrv.enable || cfg.plumber.enable) {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.plan9port" pkgs lib.platforms.linux)
    ];

    systemd.user.services.fontsrv = lib.mkIf cfg.fontsrv.enable {
      Unit.Description = "the Plan 9 file system access to host fonts";
      Install.WantedBy = [ "default.target" ];
      Service.ExecStart = "${pkgs.plan9port}/bin/9 fontsrv";
    };

    systemd.user.services.plumber = lib.mkIf cfg.plumber.enable {
      Unit.Description = "file system for interprocess messaging";
      Install.WantedBy = [ "default.target" ];
      Service.ExecStart = "${pkgs.plan9port}/bin/9 plumber -f";
    };

  };

}
