{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.services.hyprlauncher;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.services.hyprlauncher = {
    enable = mkEnableOption "hyprlauncher";
    package = mkPackageOption pkgs "hyprlauncher" { nullable = true; };
    settings = mkOption {
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
              description = "Hyprland configuration value";
            };
        in
        valueType;
      default = { };
      example = {
        general.grab_focus = true;
        cache.enabled = true;
        ui.window_size = "400 260";
        finders = {
          math_prefix = "=";
          desktop_icons = true;
        };
      };
      description = ''
        Configuration settings for hyprlauncher. All the available options can be found here:
        <https://wiki.hypr.land/Hypr-Ecosystem/hyprlauncher/#config>
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.hyprlauncher" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile."hypr/hyprlauncher.conf" = mkIf (cfg.settings != { }) {
      text = lib.hm.generators.toHyprconf { attrs = cfg.settings; };
    };
    systemd.user.services.hyprlauncher = mkIf (cfg.package != null) {
      Install.WantedBy = [ config.wayland.systemd.target ];
      Unit = {
        Description = "hyprlauncher";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
        X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [
          "${config.xdg.configFile."hypr/hyprlauncher.conf".source}"
        ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package} -d";
        Restart = "on-failure";
        RestartSec = "10";
      };
    };
  };
}
