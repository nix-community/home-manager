{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.dbus;
in
{
  meta.maintainers = [ lib.hm.maintainers.rosuavio ];

  options.dbus = {
    packages = lib.mkOption {
      type = with lib.types; types.listOf types.package;
      default = [ ];
      description = ''
        Packages whose D-Bus configuration files should be included in
        the configuration of the D-Bus session-wide message bus. Specifically,
        files in «pkg»/share/dbus-1/services will be included in the user's
        $XDG_DATA_HOME/dbus-1/services directory.
      '';
    };
  };

  config = {
    xdg.dataFile."dbus-1/services" = {
      recursive = true;
      source = pkgs.symlinkJoin {
        name = "user-dbus-services";
        paths = cfg.packages;
        stripPrefix = "/share/dbus-1/services";
      };
    };
  };
}
