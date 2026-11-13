{ lib, options, ... }:
{
  services.twmn = {
    enable = true;
    window.alwaysOnTop = true;
    host = "legacy.example";
    settings = lib.mkForce {
      main.port = 2468;
      main.duration = 500;
      gui.always_on_top = false;
    };
    extraConfig = {
      main.port = "4321";
      main.duration = "1000";
    };
  };

  test.asserts.warnings.expected = [
    "The option `services.twmn.window.alwaysOnTop' defined in ${lib.showFiles options.services.twmn.window.alwaysOnTop.files} has been renamed to `services.twmn.settings.gui.always_on_top'."
    "The option `services.twmn.host' defined in ${lib.showFiles options.services.twmn.host.files} has been renamed to `services.twmn.settings.main.host'."
    ''
      The option `services.twmn.extraConfig' is deprecated. Move its values to
      `services.twmn.settings' and resolve duplicate definitions there.
    ''
  ];

  nmt.script = ''
    assertFileContent home-files/.config/twmn/twmn.conf ${./forced-settings.conf}
  '';
}
