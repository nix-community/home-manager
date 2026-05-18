{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    getExe
    hm
    mkDefault
    mkEnableOption
    mkIf
    mkPackageOption
    mkOption
    platforms
    types
    ;

  cfg = config.services.sunsetr;

  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with hm.maintainers; [ rodrada ];

  options.services.sunsetr = {

    enable = mkEnableOption ''
      sunsetr, a tool to apply blue light filters in Wayland according to the time of day
    '';

    package = mkPackageOption pkgs "sunsetr" { };

    settings = mkOption {
      type = types.submodule { freeformType = tomlFormat.type; };
      default = { };
      description = ''
        Settings for the `sunsetr` service.
        See <https://psi4j.github.io/sunsetr/configuration/> for details.
      '';
    };

  };

  config = mkIf cfg.enable {

    assertions = [
      (hm.assertions.assertPlatform "services.sunsetr" pkgs platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."sunsetr/sunsetr.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "sunsetr-config.toml" cfg.settings;
    };

    systemd.user.services.sunsetr = {

      Unit = {
        Description = "Automatic blue light filter for Wayland";
        PartOf = [ "graphical-session.target" ];
        BindsTo = [ "graphical-session.target" ];
        # NOTE: We don't need a reload trigger since sunsetr monitors changes to its config file.
      };

      Service = {
        ExecStart = "${getExe cfg.package}";
        Restart = "on-failure";
        TimeoutStopSec = 5;
        Slice = "background.slice";
      };

      Install.WantedBy = mkDefault [ "graphical-session.target" ];

    };

  };

}
