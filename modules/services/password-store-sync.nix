{ config, lib, pkgs, ... }:

with lib;

let

  serviceCfg = config.services.password-store-sync;
  programCfg = config.programs.password-store;

in {
  meta.maintainers = with maintainers; [ pacien ];

  options.services.password-store-sync = {
    enable = mkEnableOption "Password store periodic sync";

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = ''
        How often to synchronise the password store git repository with its
        default upstream.
        </para><para>
        This value is passed to the systemd timer configuration as the
        <literal>onCalendar</literal> option.
        See
        <citerefentry>
          <refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum>
        </citerefentry>
        for more information about the format.
      '';
    };
  };

  config = mkIf serviceCfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.password-store-sync" pkgs
        platforms.linux)

      {
        assertion = programCfg.enable;
        message = "The 'services.password-store-sync' module requires"
          + " 'programs.password-store.enable = true'.";
      }
    ];

    systemd.user.services.password-store-sync = {
      Unit = { Description = "Password store sync"; };

      Service = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Environment = let
          makeEnvironmentPairs =
            mapAttrsToList (key: value: "${key}=${builtins.toJSON value}");
        in makeEnvironmentPairs programCfg.settings;
        ExecStart = toString (pkgs.writeShellScript "password-store-sync" ''
          ${pkgs.pass}/bin/pass git pull --rebase && \
          ${pkgs.pass}/bin/pass git push
        '');
      };
    };

    systemd.user.timers.password-store-sync = {
      Unit = { Description = "Password store periodic sync"; };

      Timer = {
        Unit = "password-store-sync.service";
        OnCalendar = serviceCfg.frequency;
        Persistent = true;
      };

      Install = { WantedBy = [ "timers.target" ]; };
    };
  };
}
