{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    literalExpression
    maintainers
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.strings) concatStringsSep escapeShellArgs replaceString;
  inherit (lib.types)
    bool
    listOf
    package
    str
    ;

  cfg = config.services.${unitName};

  unitName = "update-flake-inputs";
in
{
  meta.maintainers = [
    maintainers.l0b0
  ];

  options.services.${unitName} = {
    enable = mkEnableOption "Whether to update Nix flake inputs on a schedule";

    directories = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "/home/user/foo"
        "/home/user/my projects/bar"
      ];
      description = "Absolute paths of directories to perform updates in";
    };

    afterUpdateCommands = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "NIX_ABORT_ON_WARN=true nix flake check"
        "nix develop --ignore-env --command pre-commit run --all-files"
      ];
      description = ''
        Commands to run after the update.
        The variable {env}`input` can be referenced in this script to refer to the flake input name,
        and the variable {env}`PWD` to refer to the flake directory.
      '';
    };

    afterUpdateCommandsDependencies = mkOption {
      type = listOf package;
      default = [ ];
      example = [
        literalExpression
        "pkgs.firefox"
      ];
      description = ''
        Packages required by {option}`afterUpdateCommands`.
      '';
    };

    onCalendar = mkOption {
      type = str;
      default = "daily";
      example = "04:40";
      description = ''
        How often or when update occurs.

        The format is described in
        {manpage}`systemd.time(7)`.
      '';
    };

    randomizedDelaySec = mkOption {
      default = "0";
      type = str;
      example = "45 minutes";
      description = ''
        Add a randomized delay before each run.
        The delay will be chosen between zero and this value.
        This value must be a time span in the format specified by
        {manpage}`systemd.time(7)`
      '';
    };

    fixedRandomDelay = mkOption {
      default = false;
      type = bool;
      example = true;
      description = ''
        Make the randomized delay consistent between runs.
        This reduces the jitter between automatic updates.
        See {option}`randomizedDelaySec` for configuring the randomized delay.
      '';
    };

    persistent = mkOption {
      default = true;
      type = bool;
      example = false;
      description = ''
        Takes a boolean argument. If true, the time when the service
        unit was last triggered is stored on disk. When the timer is
        activated, the service unit is triggered immediately if it
        would have been triggered at least once during the time when
        the timer was inactive. Such triggering is nonetheless
        subject to the delay imposed by RandomizedDelaySec=. This is
        useful to catch up on missed runs of the service when the
        system was powered down.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.directories != [ ];
        message = "You must specify some directories to act on.";
      }
    ];

    systemd.user =
      let
        Description = "Update Nix flake inputs";
      in
      {
        services.${unitName} =
          let
            updateFlakeInputs = pkgs.writeShellApplication {
              name = unitName;
              bashOptions = [ ];
              runtimeInputs = [
                pkgs.gitMinimal
                pkgs.jq
              ]
              ++ cfg.afterUpdateCommandsDependencies;
              text =
                let
                  script = builtins.readFile ./update.bash;
                  afterUpdateCommandLine = concatStringsSep " && " (
                    if cfg.afterUpdateCommands == [ ] then [ "true" ] else cfg.afterUpdateCommands
                  );
                in
                replaceString "@afterUpdateCommandLine@" afterUpdateCommandLine script;
            };
          in
          {
            Unit = {
              inherit Description;
              Documentation = [ "man:nix3-flake(1)" ];

              After = [ "network-online.target" ];
              Wants = [ "network-online.target" ];

              X-StopOnRemoval = false;
              X-RestartIfChanged = false;
            };

            Service = {
              ExecStart = ''
                ${getExe updateFlakeInputs} ${escapeShellArgs cfg.directories}
              '';
              Type = "oneshot";
            };
          };

        timers.${unitName} = {
          Install.WantedBy = [ "timers.target" ];

          Timer = {
            FixedRandomDelay = cfg.fixedRandomDelay;
            OnCalendar = cfg.onCalendar;
            Persistent = cfg.persistent;
            RandomizedDelaySec = cfg.randomizedDelaySec;
            Unit = "${unitName}.service";
          };

          Unit = { inherit Description; };
        };
      };
  };

}
