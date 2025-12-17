{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.programs.hyprpanel;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.PerchunPak ];

  imports = [
    (lib.mkRemovedOptionModule [ "programs" "hyprpanel" "dontAssertNotificationDaemons " ] ''
      The hyprpanel never supported using it alongside other notification
      daemons, so this option never truly worked.
    '')
  ];

  options.programs.hyprpanel = {
    enable = lib.mkEnableOption "HyprPanel";

    package = lib.mkPackageOption pkgs "hyprpanel" { };

    settings = lib.mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''
        bar.battery.label = true;
        bar.bluetooth.label = false;
        bar.clock.format = "%H:%M:%S";
        bar.layouts = {
          "*" = {
            left = [
              "dashboard"
              "workspaces"
              "media"
            ];
            middle = [ "windowtitle" ];
            right = [
              "volume"
              "network"
              "bluetooth"
              "notifications"
            ];
          };
        };
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/hyprpanel/config.json`.

        See <https://hyprpanel.com/configuration/settings.html#home-manager-module>
        for the full list of options.
      '';
    };

    systemd.enable = lib.mkEnableOption "HyprPanel systemd integration" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      let
        notificationDaemons = [
          "swaync"
          "dunst"
          "mako"
        ];
      in
      builtins.map (name: {
        assertion = !config.services.${name}.enable;
        message = ''
          Only one notification daemon can be enabled at once. You have enabled
          ${name} and hyprpanel.
        '';
      }) notificationDaemons;

    home.packages = [ cfg.package ];

    programs.hyprpanel.settings = lib.mkIf config.services.hypridle.enable {
      # fix hypridle module if user uses systemd service
      bar.customModules.hypridle.startCommand = lib.mkDefault "systemctl --user start hypridle.service";
      bar.customModules.hypridle.stopCommand = lib.mkDefault "systemctl --user stop hypridle.service";
      bar.customModules.hypridle.isActiveCommand = lib.mkDefault "systemctl --user status hypridle.service | grep -q 'Active: active (running)' && echo 'yes' || echo 'no'";
    };

    xdg.configFile.hyprpanel = lib.mkIf (cfg.settings != { }) {
      target = "hyprpanel/config.json";
      source = jsonFormat.generate "hyprpanel-config" (
        if cfg.settings ? theme && cfg.settings.theme ? name then
          lib.warn ''
            `settings.theme.name` option has been removed, because the
            hyprpanel module has been ported to downstream home-manager and
            implementing it would require IFD
            (https://nix.dev/manual/nix/2.26/language/import-from-derivation)

            Replace it with:
            ```nix
            programs.hyprpanel = {
              theme = {
                # paste content of https://github.com/Jas-SinghFSU/HyprPanel/blob/2c0c66a/themes/${cfg.settings.theme.name}.json
              };
            };
            ```
          '' cfg.settings
        else
          cfg.settings
      );
      # hyprpanel replaces it with the same file, but without new line in the end
      force = true;
    };

    systemd.user.services.hyprpanel = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Bar/Panel for Hyprland with extensive customizability";
        Documentation = "https://hyprpanel.com/getting_started/hyprpanel.html";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
        X-Restart-Triggers = lib.optional (cfg.settings != { }) "${config.xdg.configFile.hyprpanel.source}";
      };

      Service = {
        ExecStart = "${cfg.package}/bin/hyprpanel";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };

      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };
    };
  };
}
