{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.hyprscratch;
in
{
  meta.maintainers = [ lib.maintainers.pierreborine ];

  options.services.hyprscratch = {
    enable = lib.mkEnableOption "Hyprscratch, improved scratchpad functionality for Hyprland";

    package = lib.mkPackageOption pkgs "hyprscratch" { nullable = true; };

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
              description = "Hyprscratch configuration value";
            };
        in
        valueType;
      default = { };
      description = ''
        Hyprscratch configuration written in Nix.
      '';
      example = lib.literalExpression ''
        {
          # Optional globals that apply to all scratchpads
          daemon_options = "clean";
          global_options = "special";
          global_rules = "size 90% 90%";

          name = {
              # Mandatory fields
              command = "command";

              # At least one is mandatory, title takes priority
              title = "title";
              class = "class";

              # Optional fields
              options = "option1 option2 option3";
              rules = "rule1;rule2;rule3";
          };
        }
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

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    systemd.user.services.hyprscratch = lib.mkIf (cfg.package != null) {
      Install.WantedBy = [ cfg.systemdTarget ];

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "Hyprscratch: Improved scratchpad functionality for Hyprland";
        After = [ cfg.systemdTarget ];
        PartOf = [ cfg.systemdTarget ];
        X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [
          "${config.xdg.configFile."hypr/hyprscratch.conf".source}"
        ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} init";
        Restart = "always";
        RestartSec = "10";
      };
    };

    xdg.configFile."hypr/hyprscratch.conf" = lib.mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf { attrs = cfg.settings; };
    };
  };
}
