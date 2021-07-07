{ pkgs, config, lib, ... }:

with lib;

let serviceCfg = config.services.pass-secret-service;
in {
  meta.maintainers = [ maintainers.cab404 ];
  options.services.pass-secret-service = {
    enable = mkEnableOption "Pass libsecret service";
  };
  config = mkIf serviceCfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.pass-secret-service" pkgs
        platforms.linux)

      {
        assertion = config.programs.password-store.enable;
        message = "The 'services.pass-secret-service' module requires"
          + " 'programs.password-store.enable = true'.";
      }
    ];

    systemd.user.services.pass-secret-service = {
      Unit = { Description = "Pass libsecret service"; };
      Service = {
        # pass-secret-service doesn't use environment variables for some reason.
        ExecStart =
          "${pkgs.pass-secret-service}/bin/pass_secret_service --path ${config.programs.password-store.settings.PASSWORD_STORE_DIR}";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}
