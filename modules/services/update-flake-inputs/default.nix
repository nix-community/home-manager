{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    maintainers
    mkEnableOption
    mkIf
    mkOption
    ;
  inherit (lib.strings) escapeShellArgs;
  inherit (lib.types)
    bool
    listOf
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
    enable = mkEnableOption ''
      Whether to update Nix flake inputs on a schedule. For each entry in
      {option}`services.${unitName}.directories`, this service will do the
      following:

      1. Check that there are no changes to {file}`flake.lock`. Otherwise it
         will skip the directory and set exit code 80.
      2. Check that there are no staged changes to tracked files in the Git
         repository. Otherwise it will skip the directory and set exit code 81.
      3. If everything is clean, it will do the following for each flake input:
         1. Update the input. If this fails, it will revert {file}`flake.lock`,
            set exit code 82, and skip the input.
         2. Check whether {file}`flake.lock` was actually changed. If not, it
            will skip the input as there's nothing to do.
         3. Run {command}`nix flake check` to make sure the update passes the
            built-in checks in the repository. If this fails, it will revert
            {file}`flake.lock`, set exit code 83, and skip the input.

            If you want to run a stricter check than the basic one you can set
            {option}`systemd.user.services.${unitName}.Service.Environment = ["NIX_ABORT_ON_WARN=true"]`
            or add custom checks.
         4. Build the flake outputs:

            - NixOS configurations
            - Dev shells for the current architecture
            - Packages for the current architecture

            If any of them fail, it will revert {file}`flake.lock`, set exit
            code 84, and skip the input.
         5. Run the Nix formatter. If this fails, it will revert
            {file}`flake.lock`, set exit code 85, and skip the input.
         6. Commit {file}`flake.lock`. If this fails, it will, you guessed it,
            revert {file}`flake.lock`, set exit code 86, and skip the input.

      The script returns the last non-zero exit code, or zero if everything was
      successful.
    '';

    directories = mkOption {
      type = listOf str;
      default = [ ];
      example = [
        "/home/user/foo"
        "/home/user/my projects/bar"
      ];
      description = "Absolute paths of directories with flakes you want to update";
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
        See {option}`services.${unitName}.randomizedDelaySec` for configuring
        the randomized delay.
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
              ];
              text = builtins.readFile ./update.bash;
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
