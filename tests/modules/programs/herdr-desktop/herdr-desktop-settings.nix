{ config, ... }:
{
  xdg.enable = true;

  programs.herdr.desktop = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "herdr-desktop"; };

    settings = {
      telemetry = false;
      sounds.enabled = true;
      font = "Iosevka Term Slab";
      font_size = 14;
      font_ligatures = true;
      theme = {
        light = "catppuccin-latte";
        dark = "catppuccin-mocha";
      };
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists "home-files/.config/herdr-app/settings.json"
    assertFileContent \
      "home-files/.config/herdr-app/settings.json" \
      ${./settings-expected.json}
  '';
}
