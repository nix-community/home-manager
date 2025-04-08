{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.services.getmail;

  accounts = filter (a: a.getmail.enable) (attrValues config.accounts.email.accounts);

  # Note: The getmail service does not expect a path, but just the filename!
  renderConfigFilepath = a: if a.primary then "getmailrc" else "getmail${a.name}";
  configFiles = concatMapStringsSep " " (a: " --rcfile ${renderConfigFilepath a}") accounts;
in
{
  options = {
    services.getmail = {
      enable = mkEnableOption "the getmail systemd service to automatically retrieve mail";

      frequency = mkOption {
        type = types.str;
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

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.getmail" pkgs lib.platforms.linux)
    ];

    systemd.user.services.getmail = {
      Unit = {
        Description = "getmail email fetcher";
      };
      Service = {
        ExecStart = "${pkgs.getmail6}/bin/getmail ${configFiles}";
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
