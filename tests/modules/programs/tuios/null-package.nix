{ lib, ... }:
{
  imports = [ ./basic-configuration.nix ];

  programs.tuios.package = null;

  nmt.script = lib.mkForce ''
    assertPathNotExists home-path/bin/tuios
    assertFileContent "home-files/.config/tuios/config.d/10-home-manager.toml" \
      ${./expected-config.toml}
    assertPathNotExists home-files/.config/tuios/config.toml
  '';

  xdg.enable = true;
}
