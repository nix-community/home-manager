{ pkgs, ... }:
{
  programs.television = {
    enable = true;
    settings = {
      tick_rate = 50;
      ui = {
        use_nerd_font_icons = false;
        show_preview_panel = true;
        input_bar_position = "top";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/television/config.toml
    assertFileContent home-files/.config/television/config.toml \
      ${pkgs.writeText "settings-expected" ''
        tick_rate = 50

        [ui]
        input_bar_position = "top"
        show_preview_panel = true
        use_nerd_font_icons = false
      ''}
  '';
}
