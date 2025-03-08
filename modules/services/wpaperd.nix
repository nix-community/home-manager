{ config, lib, pkgs, ... }:

let
  cfg = config.services.wpaperd;
  tomlFormat = pkgs.formats.toml { };
  inherit (lib) mkRenamedOptionModule mkIf;
in {
  meta.maintainers = [ lib.hm.maintainers."3ulalia" ];

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
    enable = lib.mkEnableOption "wpaperd";

    package = lib.mkPackageOption pkgs "wpaperd" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
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

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "wpaperd/wallpaper.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "wpaperd-wallpaper" cfg.settings;
      };
    };

    systemd.user.services.wpaperd = lib.mkIf (cfg.package != null) {
      Install = { WantedBy = [ config.wayland.systemd.target ]; };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "wpaperd";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        X-Restart-Triggers =
          [ "${config.xdg.configFile."wpaperd/wallpaper.toml".source}" ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "always";
        RestartSec = "10";
      };
    };
  };
}
