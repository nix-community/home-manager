{ config, ... }:

{
  programs.hyprpanel = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "hyprpanel"; };
    settings.theme.name = "catppuccin_mocha";
  };

  test.asserts.warnings.expected = [
    ''
      Using `programs.hyprpanel.settings.theme.name` as a named theme is deprecated and will be
      removed in a future release. Please use `programs.hyprpanel.settings.theme` instead.

      Named theme loading was removed because it requires import-from-derivation.

      Paste theme contents from:
        https://github.com/Jas-SinghFSU/HyprPanel/blob/2c0c66a/themes/catppuccin_mocha.json

    ''
  ];

  nmt.script = ''
    assertFileExists "home-files/.config/hyprpanel/config.json"
  '';
}
