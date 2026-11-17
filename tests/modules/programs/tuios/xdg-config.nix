{ config, lib, ... }:
{
  imports = [ ./basic-configuration.nix ];

  xdg = {
    enable = true;
    configHome = "${config.home.homeDirectory}/custom-config";
  };

  nmt.script = lib.mkForce ''
    assertFileContent home-files/custom-config/tuios/config.d/10-home-manager.toml \
      ${./expected-config.toml}
    assertPathNotExists home-files/custom-config/tuios/config.toml
    assertPathNotExists home-files/.config/tuios
    assertPathNotExists "home-files/Library/Application Support/tuios"
  '';
}
