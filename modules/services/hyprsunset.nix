{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.hyprsunset;
in
{
  meta.maintainers = with lib.maintainers; [
    khaneliman
  ];

  options.services.hyprsunset = {
    enable = lib.mkEnableOption "Hyprsunset, Hyprland's blue-light filter";

    package = lib.mkPackageOption pkgs "hyprsunset" { };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional command-line arguments to pass to `hyprsunset`.";
      example = [
        "--verbose"
      ];
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        let
          valueType =
            nullOr (oneOf [
              bool
              int
              float
              str
              path
              (attrsOf valueType)
              (listOf valueType)
            ])
            // {
              description = "Hyprsunset configuration value";
            };
        in
        valueType;
      default = { };
      description = ''
        Hyprsunset configuration written in Nix. Entries with the same key
        should be written as lists. Variables' and colors' names should be
        quoted. See <https://wiki.hypr.land/Hypr-Ecosystem/hyprsunset/> for more examples.
      '';
      example = lib.literalExpression ''
        {
          max-gamma = 150;

          profile = [
            {
              time = "7:30";
              identity = true;
            }
            {
              time = "21:00";
              temperature = 5000;
              gamma = 0.8;
            }
          ];
        };
      '';
    };

    importantPrefixes = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ "$" ];
      example = [ "$" ];
      description = ''
        List of prefix of attributes to source at the top of the config.
      '';
    };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = config.wayland.systemd.target;
      defaultText = lib.literalExpression "config.wayland.systemd.target";
      example = "hyprland-session.target";
      description = "Systemd target to bind to.";
    };
  };

  imports = [
    (lib.mkRemovedOptionModule [
      "services"
      "hyprsunset"
      "transitions"
    ] "Use services.hyprsunset.settings instead.")
  ];

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."hypr/hyprsunset.conf" = lib.mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf {
        attrs = cfg.settings;
        inherit (cfg) importantPrefixes;
      };
    };

    systemd.user = {
      services = {
        hyprsunset = {
          Install = {
            WantedBy = [ cfg.systemdTarget ];
          };

          Unit = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "hyprsunset - Hyprland's blue-light filter";
            After = [ config.wayland.systemd.target ];
            PartOf = [ config.wayland.systemd.target ];
            X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [
              "${config.xdg.configFile."hypr/hyprsunset.conf".source}"
            ];
          };

          Service = {
            ExecStart = "${lib.getExe cfg.package}${
              lib.optionalString (cfg.extraArgs != [ ]) " ${lib.escapeShellArgs cfg.extraArgs}"
            }";
            Restart = "always";
            RestartSec = "10";
          };
        };
      };
    };
  };
}
