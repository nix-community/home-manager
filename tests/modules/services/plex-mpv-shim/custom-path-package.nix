{ config, ... }:
{
  imports = [ ./mutable-settings.nix ];

  xdg.configHome = "${config.home.homeDirectory}/custom-config";
  services.plex-mpv-shim.package = config.lib.test.mkStubPackage {
    outPath = "@custom-plex-mpv-shim@";
  };
}
