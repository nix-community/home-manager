{ pkgs, ... }:
{
  programs.macchina = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-macchina" "";

    settings = {
      theme = "Helium";
    };

    themes = {
      Helium = {
        spacing = 1;
        separator = "-->";
        key_color = "Blue";
      };

      Neon = {
        spacing = 3;
        hide_ascii = true;
        separator = "=>";
        separator_color = "#ff00ff";

        bar = {
          glyph = "#";
          symbol_open = "(";
          symbol_close = ")";
          visible = true;
          hide_delimiters = false;
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/macchina/macchina.toml
    assertFileContent \
      home-files/.config/macchina/macchina.toml \
      ${./multiple-themes-settings-expected.toml}
    assertFileExists home-files/.config/macchina/themes/Helium.toml
    assertFileContent \
      home-files/.config/macchina/themes/Helium.toml \
      ${./multiple-themes-helium-expected.toml}
    assertFileExists home-files/.config/macchina/themes/Neon.toml
    assertFileContent \
      home-files/.config/macchina/themes/Neon.toml \
      ${./multiple-themes-neon-expected.toml}
  '';
}
