{ pkgs, config, lib, ... }:

with lib;

let serviceCfg = config.services.pass-secret-service;
in {
  meta.maintainers = [ maintainers.cab404 ];
  options.services.pass-secret-service = {
    enable = mkEnableOption "Pass libsecret service";
  };
  config = mkIf serviceCfg.enable {
    assertions = [{
      assertion = config.programs.password-store.enable;
      message = "The 'services.pass-secret-service' module requires"
        + " 'programs.password-store.enable = true'.";
    }];

    systemd.user.services.pass-secret-service = {
      Unit = { Description = "Pass libsecret service"; };
      Service = {
        Install = { WantedBy = [ "default.target" ]; };
        # pass-secret-service doesn't use environment variables for some reason.
        ExecStart =
          "${pkgs.pass-secret-service}/bin/pass_secret_service --path ${config.programs.password-store.settings.PASSWORD_STORE_DIR}";
      };
    };
  };
}
