{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.unison;

  pairOf = t:
    let list = types.addCheck (types.listOf t) (l: length l == 2);
    in list // { description = list.description + " of length 2"; };

  pairOptions = {
    options = {
      stateDirectory = mkOption {
        type = types.path;
        default = "${config.xdg.dataHome}/unison";
        defaultText = "$XDG_DATA_HOME/unison";
        description = ''
          Unison state directory to use.
        '';
      };

      commandOptions = mkOption rec {
        type = with types; attrsOf str;
        apply = mergeAttrs default;
        default = {
          repeat = "watch";
          sshcmd = "${pkgs.openssh}/bin/ssh";
          ui = "text";
          auto = "true";
          batch = "true";
          log = "false"; # don't log to file, handled by systemd
        };
        description = ''
          Additional command line options as a dictionary to pass to the
          <literal>unison</literal> program.
          </para><para>
          See
          <citerefentry>
            <refentrytitle>unison</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>
          for a list of available options.
        '';
      };

      roots = mkOption {
        type = pairOf types.str;
        example = literalExpression ''
          [
            "/home/user/documents"
            "ssh://remote/documents"
          ]
        '';
        description = ''
          Pair of roots to synchronise.
        '';
      };
    };
  };

  serialiseArg = key: val: escapeShellArg "-${key}=${escape [ "=" ] val}";

  serialiseArgs = args: concatStringsSep " " (mapAttrsToList serialiseArg args);

  makeDefs = gen:
    mapAttrs'
    (name: pairCfg: nameValuePair "unison-pair-${name}" (gen name pairCfg))
    cfg.pairs;

in {
  meta.maintainers = with maintainers; [ pacien ];

  options.services.unison = {
    enable = mkEnableOption "Unison synchronisation";

    pairs = mkOption {
      type = with types; attrsOf (submodule pairOptions);
      default = { };
      example = literalExpression ''
        {
          roots = [
            "/home/user/documents"
            "ssh://remote/documents"
          ];
        }
      '';
      description = ''
        Unison root pairs to keep synchronised.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.unison" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services = makeDefs (name: pairCfg: {
      Unit = {
        Description = "Unison pair sync (${name})";
        # Retry forever, useful in case of network disruption.
        StartLimitIntervalSec = 0;
      };

      Service = {
        Restart = "always";
        RestartSec = 60;

        CPUSchedulingPolicy = "idle";
        IOSchedulingClass = "idle";

        Environment = [ "UNISON='${toString pairCfg.stateDirectory}'" ];
        ExecStart = ''
          ${pkgs.unison}/bin/unison \
            ${serialiseArgs pairCfg.commandOptions} \
            ${strings.concatMapStringsSep " " escapeShellArg pairCfg.roots}
        '';
      };

      Install = { WantedBy = [ "default.target" ]; };
    });
  };
}
