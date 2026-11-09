{ config, ... }:
{
  xdg.enable = true;

  programs.herdr.desktop = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "herdr-desktop"; };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertPathNotExists "home-files/.config/herdr-app/settings.json"
  '';
}
