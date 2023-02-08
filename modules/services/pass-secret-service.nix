{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.services.pass-secret-service;

  serviceArgs =
    optionalString (cfg.storePath != null) "--path ${cfg.storePath}";
in {
  meta.maintainers = with maintainers; [ cab404 houstdav000 ];

  options.services.pass-secret-service = {
    enable = mkEnableOption "Pass libsecret service";

    package = mkPackageOption pkgs "pass-secret-service" { };

    storePath = mkOption {
      type = with types; nullOr str;
      default = null;
      defaultText = "~/.password-store";
      example = "/home/user/.local/share/password-store";
      description = "Absolute path to password store.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.pass-secret-service" pkgs
        platforms.linux)
    ];

    systemd.user.services.pass-secret-service = {
      Unit = {
        AssertFileIsExecutable = "${cfg.package}/bin/pass_secret_service";
        Description = "Pass libsecret service";
        Documentation = "https://github.com/mdellweg/pass_secret_service";
        PartOf = [ "default.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/pass_secret_service ${serviceArgs}";
      };

      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}
