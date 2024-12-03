{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.wpaperd;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ hm.maintainers.Avimitin ];

  imports = [
    (mkRenamedOptionModule # \
      [ "programs" "wpaperd" "enable" ] # \
      [ "services" "wpaperd" "enable" ])
    (mkRenamedOptionModule # \
      [ "programs" "wpaperd" "package" ] # \
      [ "services" "wpaperd" "package" ])
    (mkRenamedOptionModule # \
      [ "programs" "wpaperd" "settings" ] # \
      [ "services" "wpaperd" "settings" ])
  ];

  options.services.wpaperd = {
    enable = mkEnableOption "wpaperd";

    package = mkPackageOption pkgs "wpaperd" { };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          eDP-1 = {
            path = "/home/foo/Pictures/Wallpaper";
            apply-shadow = true;
          };
          DP-2 = {
            path = "/home/foo/Pictures/Anime";
            sorting = "descending";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/wpaperd/wallpaper.toml`.
        See <https://github.com/danyspin97/wpaperd#wallpaper-configuration>
        for the full list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.wpaperd" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile = {
      "wpaperd/wallpaper.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "wpaperd-wallpaper" cfg.settings;
      };
    };

    systemd.user.services.wpaperd = {
      Install = { WantedBy = [ "graphical-session.target" ]; };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "wpaperd";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers =
          [ "${config.xdg.configFile."wpaperd/wallpaper.toml".source}" ];
      };

      Service = {
        ExecStart = "${getExe cfg.package}";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
