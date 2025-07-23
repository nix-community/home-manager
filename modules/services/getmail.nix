{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.getmail;

  accounts = lib.filter (a: a.getmail.enable) (lib.attrValues config.accounts.email.accounts);

  # Note: The getmail service does not expect a path, but just the filename!
  renderConfigFilepath = a: if a.primary then "getmailrc" else "getmail${a.name}";
  configFiles = lib.concatMapStringsSep " " (a: " --rcfile ${renderConfigFilepath a}") accounts;
in
{
  options = {
    services.getmail = {
      enable = lib.mkEnableOption "the getmail systemd service to automatically retrieve mail";

      package = lib.mkPackageOption pkgs "getmail" { default = "getmail6"; };

      frequency = lib.mkOption {
        type = lib.types.str;
        default = "*:0/5";
        example = "hourly";
        description = ''
          The refresh frequency. Check `man systemd.time` for
          more information on the syntax. If you use a gpg-agent in
          combination with the passwordCommand, keep the poll
          frequency below the cache-ttl value (as set by the
          `default`) to avoid pinentry asking
          permanently for a password.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.getmail" pkgs lib.platforms.linux)
    ];

    systemd.user.services.getmail = {
      Unit = {
        Description = "getmail email fetcher";
      };
      Service = {
        ExecStart = "${lib.getExe cfg.package} ${configFiles}";
      };
    };

    systemd.user.timers.getmail = {
      Unit = {
        Description = "getmail email fetcher";
      };
      Timer = {
        OnCalendar = "${cfg.frequency}";
        Unit = "getmail.service";
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };

  };
}
