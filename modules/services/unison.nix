{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.unison;
  pairOf = t: with types; addCheck (listOf t) (l: length l == 2);
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
        example = literalExample ''
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
in {
  meta.maintainers = with maintainers; [ pacien ];

  options.services.unison = {
    pairs = mkOption {
      type = with types; attrsOf (submodule pairOptions);
      default = { };
      example = literalExample ''
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

  config = let
    serialiseArg = key: val: "-${key}=${escapeShellArg val}";
    serialiseArgs = args: strings.concatStringsSep " " (attrsets.mapAttrsToList serialiseArg args);
    makeDefs = gen: with attrsets; mapAttrs' (name: pairCfg: nameValuePair "unison-pair-${name}" (gen name pairCfg)) cfg.pairs;
  in mkIf (cfg.pairs != { }) {
    systemd.user.services = makeDefs (name: pairCfg: {
      Unit = {
        Description = "Unison pair sync (${name})";
        StartLimitIntervalSec = 0; # retry forever, useful in case of network disruption
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

      Install = {
        WantedBy = [ "default.target" ];
      };
    });
  };
}
