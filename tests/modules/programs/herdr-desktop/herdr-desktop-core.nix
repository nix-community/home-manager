{
  config,
  lib,
  pkgs,
  ...
}:
{
  xdg.enable = true;

  programs.herdr.core.package = config.lib.test.mkStubPackage { name = "herdr-core"; };

  programs.herdr.desktop = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "herdr-desktop"; };

    settings.core = "custom-core";
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists "home-files/.config/herdr-app/settings.json"
    settings="$TESTED/home-files/.config/herdr-app/settings.json"
    test "$(${lib.getExe pkgs.jaq} -r '.core' "$settings")" = "custom-core"
  '';
}
