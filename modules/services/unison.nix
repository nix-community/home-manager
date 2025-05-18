{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    ;

  cfg = config.services.unison;

  pairOf =
    t:
    let
      list = types.addCheck (types.listOf t) (l: lib.length l == 2);
    in
    list // { description = list.description + " of length 2"; };

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
        type = with types; attrsOf (either str (listOf str));
        apply = lib.mergeAttrs default;
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
          `unison` program.

          Use a list of strings to declare the same option multiple times.

          See
          {manpage}`unison(1)`
          for a list of available options.
        '';
      };

      roots = mkOption {
        type = pairOf types.str;
        example = lib.literalExpression ''
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

  serialiseArg =
    key: val:
    lib.concatStringsSep " " (
      lib.forEach (lib.toList val) (x: lib.escapeShellArg "-${key}=${lib.escape [ "=" ] x}")
    );

  serialiseArgs = args: lib.concatStringsSep " " (lib.mapAttrsToList serialiseArg args);

  unitName = name: "unison-pair-${name}";

  makeDefs =
    gen: lib.mapAttrs' (name: pairCfg: lib.nameValuePair (unitName name) (gen name pairCfg)) cfg.pairs;

in
{
  meta.maintainers = with lib.maintainers; [ euxane ];

  options.services.unison = {
    enable = lib.mkEnableOption "Unison synchronisation";

    package = lib.mkPackageOption pkgs "unison" {
      example = "pkgs.unison.override { enableX11 = false; }";
    };

    pairs = mkOption {
      type = with types; attrsOf (submodule pairOptions);
      default = { };
      example = lib.literalExpression ''
        {
          "my-documents" = {
            roots = [
              "/home/user/documents"
              "ssh://remote/documents"
            ];
          };
        }
      '';
      description = ''
        Unison root pairs to keep synchronised.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.unison" pkgs lib.platforms.linux)
    ];

    systemd.user.services = makeDefs (
      name: pairCfg: {
        Unit.Description = "Unison pair sync (${name})";
        Service = {
          CPUSchedulingPolicy = "idle";
          IOSchedulingClass = "idle";
          Environment = [ "UNISON='${toString pairCfg.stateDirectory}'" ];
          ExecStart = ''
            ${cfg.package}/bin/unison \
              ${serialiseArgs pairCfg.commandOptions} \
              ${lib.strings.concatMapStringsSep " " lib.escapeShellArg pairCfg.roots}
          '';
        };
      }
    );

    systemd.user.timers = makeDefs (
      name: pairCfg: {
        Unit.Description = "Unison pair sync auto-restart (${name})";
        Install.WantedBy = [ "timers.target" ];
        Timer = {
          Unit = "${unitName name}.service";
          OnActiveSec = 1;
          OnUnitInactiveSec = 60;
        };
      }
    );
  };
}
