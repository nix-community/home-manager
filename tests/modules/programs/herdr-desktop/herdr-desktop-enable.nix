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
  };

  assertions = [
    {
      assertion = lib.elem config.programs.herdr.core.package config.home.packages;
      message = "Enabling Herdr Desktop must install herdr-core.";
    }
    {
      assertion = lib.elem config.programs.herdr.desktop.package config.home.packages;
      message = "Enabling Herdr Desktop must install the app.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists "home-files/.config/herdr-app/settings.json"
    settings="$TESTED/home-files/.config/herdr-app/settings.json"
    test "$(${lib.getExe pkgs.jaq} -r '.core' "$settings")" = "${lib.getExe' config.programs.herdr.core.package "herdr-core"}"
  '';
}
