{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.lieer;

  syncAccounts = lib.filter (a: a.enable && a.lieer.enable && a.lieer.sync.enable) (
    lib.attrValues config.accounts.email.accounts
  );

  escapeUnitName =
    name:
    let
      good = lib.upperChars ++ lib.lowerChars ++ lib.stringToCharacters "0123456789-_";
      subst = c: if lib.any (x: x == c) good then c else "-";
    in
    lib.stringAsChars subst name;

  serviceUnit = account: {
    name = escapeUnitName "lieer-${account.name}";
    value = {
      Unit = {
        Description = "lieer Gmail synchronization for ${account.name}";
        ConditionPathExists = "${account.maildir.absPath}/.gmailieer.json";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${config.programs.lieer.package}/bin/gmi sync";
        WorkingDirectory = account.maildir.absPath;
        Environment = "NOTMUCH_CONFIG=${config.xdg.configHome}/notmuch/default/config";
      };
    };
  };

  timerUnit = account: {
    name = escapeUnitName "lieer-${account.name}";
    value = {
      Unit = {
        Description = "lieer Gmail synchronization for ${account.name}";
      };

      Timer = {
        OnCalendar = account.lieer.sync.frequency;
        RandomizedDelaySec = 30;
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };

in
{
  meta.maintainers = [ lib.maintainers.tadfisher ];

  options.services.lieer.enable = lib.mkEnableOption "lieer Gmail synchronization service";

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.lieer" pkgs lib.platforms.linux)
    ];

    programs.lieer.enable = true;
    systemd.user.services = lib.listToAttrs (map serviceUnit syncAccounts);
    systemd.user.timers = lib.listToAttrs (map timerUnit syncAccounts);
  };
}
