{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.quickshell;
in
{
  meta.maintainers = [ lib.maintainers.justdeeevin ];

  options.programs.quickshell = {
    enable = lib.mkEnableOption "quickshell, a flexbile QtQuick-based desktop shell toolkit.";
    package = lib.mkPackageOption pkgs "quickshell" { nullable = true; };
    configs = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        A set of configs to include in the quickshell config directory. The key is the name of the config.

        The configuration that quickshell should use can be specified with the `activeConfig` option.
      '';
    };
    activeConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        The name of the config to use.

        If `null`, quickshell will attempt to use a config located in `$XDG_CONFIG_HOME/quickshell` instead of one of the named sub-directories.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "quickshell systemd service";
      target = lib.mkOption {
        type = lib.types.str;
        default = config.wayland.systemd.target;
        defaultText = lib.literalExpression "config.wayland.systemd.target";
        example = "hyprland-session.target";
        description = ''
          The systemd target that will automatically start quickshell.

          If you set this to a WM-specific target, make sure that systemd integration for that WM is enabled (e.g. `wayland.windowManager.hyprland.systemd.enable`). **This is typically true by default**.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (cfg.configs != { }) {
        xdg.configFile = lib.mapAttrs' (name: path: {
          name = "quickshell/${name}";
          value.source = path;
        }) cfg.configs;
      })
      {
        assertions = [
          (lib.hm.assertions.assertPlatform "programs.quickshell" pkgs lib.platforms.linux)
          {
            assertion = !(builtins.any (name: lib.hasInfix "/" name) (builtins.attrNames cfg.configs));
            message = "The names of configs in `programs.quickshell.configs` must not contain slashes.";
          }
        ];

        home.packages = [ cfg.package ];

      }
      (lib.mkIf cfg.systemd.enable {
        systemd.user.services.quickshell = {
          Unit = {
            Description = "quickshell";
            Documentation = "https://quickshell.outfoxxed.me/docs/";
            After = [ cfg.systemd.target ];
          };

          Service = {
            ExecStart =
              lib.getExe cfg.package + (if cfg.activeConfig == null then "" else " --config ${cfg.activeConfig}");
            Restart = "on-failure";
          };

          Install.WantedBy = [ cfg.systemd.target ];
        };
      })
    ]
  );
}
