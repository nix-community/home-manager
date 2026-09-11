{ lib, ... }:
{
  services.twmn = {
    enable = true;
    settings = lib.mkDefault {
      gui.font_size = 16;
      main.duration = 9000;
    };
    extraConfig.main.port = "4321";
  };

  test.asserts.warnings.expected = [
    ''
      The option `services.twmn.extraConfig' is deprecated. Move its values to
      `services.twmn.settings' and resolve duplicate definitions there.
    ''
  ];

  nmt.script = ''
    assertFileContent home-files/.config/twmn/twmn.conf ${./extra-config-defaults.conf}
  '';
}
