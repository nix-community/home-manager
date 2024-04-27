{ config, osConfig, lib, pkgs, ... }:

let cfg = config.programs.nh;
in {
  meta.maintainers = with lib.maintainers; [ johnrtitor ];

  options.programs.nh = {
    enable = lib.mkEnableOption "nh, yet another Nix CLI helper";

    package = lib.mkPackageOption pkgs "nh" { };

    flake = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        The path that will be used for the `FLAKE` environment variable.

        `FLAKE` is used by nh as the default flake for performing actions, like `nh os switch`.
      '';
    };

    clean = {
      enable = lib.mkEnableOption
        "periodic garbage collection for user profile and nix store with nh clean user";

      dates = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "weekly";
        description = ''
          How often cleanup is performed. Passed to systemd.time

          The format is described in
          {manpage}`systemd.time(7)`.
        '';
      };

      extraArgs = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "";
        example = "--keep 5 --keep-since 3d";
        description = ''
          Options given to nh clean when the service is run automatically.

          See `nh clean all --help` for more information.
        '';
      };
    };
  };

  config = {
    warnings = lib.optionals (!(cfg.clean.enable -> !osConfig.nix.gc.automatic))
      [
        "programs.nh.clean.enable and nix.gc.automatic (system-wide in configuration.nix) are both enabled. Please use one or the other to avoid conflict."
      ];

    assertions = [{
      assertion = (cfg.flake != null) -> !(lib.hasSuffix ".nix" cfg.flake);
      message = "nh.flake must be a directory, not a nix file";
    }];

    home = lib.mkIf cfg.enable {
      packages = [ cfg.package ];
      sessionVariables = lib.mkIf (cfg.flake != null) { FLAKE = cfg.flake; };
    };

    systemd.user = lib.mkIf cfg.clean.enable {
      services.nh-clean = {
        description = "Nh clean (user)";
        script =
          "exec ${lib.getExe cfg.package} clean user ${cfg.clean.extraArgs}";
        startAt = cfg.clean.dates;
        path = [ config.nix.package ];
        serviceConfig.Type = "oneshot";
      };

      timers.nh-clean = { timerConfig = { Persistent = true; }; };
    };
  };
}
