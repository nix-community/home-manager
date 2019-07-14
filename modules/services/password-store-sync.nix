{ config, lib, pkgs, ... }:

with lib;

{
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

  config = let
    serviceCfg = config.services.password-store-sync;
    programCfg = config.programs.password-store;

    # from
    # https://github.com/NixOS/nixpkgs/blob/release-19.03/nixos/modules/system/boot/systemd-lib.nix
    # https://github.com/NixOS/nixpkgs/blob/release-19.03/nixos/modules/system/boot/systemd.nix
    makeJobScript = let
      shellEscape = s: (replaceChars [ "\\" ] [ "\\\\" ] s);
      mkScriptName = s: "unit-script-" + (replaceChars [ "\\" "@" ] [ "-" "_" ] (shellEscape s) );
      mkScriptContent = script: ''
        #! ${pkgs.runtimeShell} -e
        ${script}
      '';
    in name: text: toString (pkgs.writeScript (mkScriptName name) (mkScriptContent text));

    makeEnvironmentPairs = mapAttrsToList (key: value: "${key}=${builtins.toJSON value}");
  in mkIf serviceCfg.enable {
    systemd.user.services.password-store-sync = {
      Unit = {
        Description = "Password store sync";
      };
      Service = {
        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";
        Environment = makeEnvironmentPairs programCfg.settings;
        ExecStart = makeJobScript "password-store-sync" ''
          ${pkgs.pass}/bin/pass git pull --rebase && \
          ${pkgs.pass}/bin/pass git push
        '';
      };
    };

    systemd.user.timers.password-store-sync = {
      Unit = {
        Description = "Password store periodic sync";
      };
      Timer = {
        Unit = "password-store-sync.service";
        OnCalendar = serviceCfg.frequency;
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
