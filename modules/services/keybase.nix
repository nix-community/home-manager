{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.keybase;

in
{
  options.services.keybase = {
    enable = lib.mkEnableOption "Keybase";

    package = lib.mkPackageOption pkgs "keybase" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.keybase" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.keybase = {
      Unit.Description = "Keybase service";

      Service = {
        ExecStart = "${lib.getExe cfg.package} service --auto-forked";
        Restart = "on-failure";
        PrivateTmp = true;
      };

      Install.WantedBy = [ "default.target" ];
    };
  };
}
