{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nh;
in
{
  meta.maintainers = with lib.maintainers; [
    johnrtitor
    a-jay98
  ];

  options.programs.nh = {
    enable = lib.mkEnableOption "nh, yet another Nix CLI helper";

    package = lib.mkPackageOption pkgs "nh" { };

    flake = lib.mkOption {
      type = with lib.types; nullOr (either singleLineStr path);
      default = null;
      description = ''
        The path that will be used for the {env}`FLAKE` environment variable.

        {env}`FLAKE` is used by nh as the default flake for performing actions,
        like {command}`nh os switch`.
      '';
    };

    osFlake = lib.mkOption {
      type = with lib.types; nullOr (either singleLineStr path);
      default = null;
      description = ''
        The string that will be used for the {env}`NH_OS_FLAKE` environment variable.

        {env}`NH_OS_FLAKE` is used by nh as the default flake for performing {command}`nh os`
        actions, such as {command}`nh os switch`.
        Setting this will take priority over the `flake` option.
      '';
    };

    homeFlake = lib.mkOption {
      type = with lib.types; nullOr (either singleLineStr path);
      default = null;
      description = ''
        The string that will be used for the {env}`NH_HOME_FLAKE` environment variable.

        {env}`NH_HOME_FLAKE` is used by nh as the default flake for performing {command}`nh home`
        actions, such as {command}`nh home switch`.
        Setting this will take priority over the `flake` option.
      '';
    };

    darwinFlake = lib.mkOption {
      type = with lib.types; nullOr (either singleLineStr path);
      default = null;
      description = ''
        The string that will be used for the {env}`NH_DARWIN_FLAKE` environment variable.

        {env}`NH_DARWIN_FLAKE` is used by nh as the default flake for performing
        {command}`nh darwin` actions, such as {command}`nh darwin switch`.
        Setting this will take priority over the `flake` option.
      '';
    };

    clean = {
      enable = lib.mkEnableOption ''
        periodic garbage collection for user profile and nix store with nh clean
        user'';

      dates = lib.mkOption {
        type = lib.types.singleLineStr;
        default = "weekly";
        description = ''
          How often cleanup is performed.

          On linux the format is described in {manpage}`systemd.time(7)`.

          ${lib.hm.darwin.intervalDocumentation}
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
    warnings =
      lib.optional (cfg.clean.enable && config.nix.gc.automatic)
        "programs.nh.clean.enable and nix.gc.automatic (Home-Manager) are both enabled. Please use one or the other to avoid conflict.";

    assertions = lib.optionals pkgs.stdenv.isDarwin [
      (lib.hm.darwin.assertInterval "programs.nh.clean.dates" cfg.clean.dates pkgs)
    ];

    home = lib.mkIf cfg.enable {
      packages = [ cfg.package ];
      sessionVariables = lib.mkMerge [
        (lib.mkIf (cfg.flake != null) (
          let
            packageVersion = lib.getVersion cfg.package;
            isVersion4OrHigher = lib.versionAtLeast packageVersion "4.0.0";
          in
          if isVersion4OrHigher then { NH_FLAKE = cfg.flake; } else { FLAKE = cfg.flake; }
        ))
        (lib.mkMerge (
          map
            (
              name:
              (lib.mkIf (cfg."${name}Flake" != null) {
                "NH_${lib.toUpper name}_FLAKE" = cfg."${name}Flake";
              })
            )
            [
              "darwin"
              "home"
              "os"
            ]
        ))
      ];
    };

    systemd.user = lib.mkIf (cfg.clean.enable && pkgs.stdenv.isLinux) {
      services.nh-clean = {
        Unit.Description = "Nh clean (user)";

        Service = {
          Type = "oneshot";
          ExecStart = "${lib.getExe cfg.package} clean user ${cfg.clean.extraArgs}";
        };
      };

      timers.nh-clean = {
        Unit.Description = "Run nh clean";

        Timer = {
          OnCalendar = cfg.clean.dates;
          Persistent = true;
        };

        Install.WantedBy = [ "timers.target" ];
      };

    };

    launchd.agents.nh-clean = lib.mkIf (cfg.clean.enable && pkgs.stdenv.isDarwin) {
      enable = true;
      config = {
        ProgramArguments = [
          "${lib.getExe cfg.package}"
          "clean"
          "user"
        ]
        ++ lib.optional (cfg.clean.extraArgs != "") cfg.clean.extraArgs;

        StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.clean.dates;

      };
    };
  };
}
