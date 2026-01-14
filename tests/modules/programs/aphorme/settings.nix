{
  programs.aphorme = {
    enable = true;
    settings = {
      gui_cfg = {
        icon = true;
        ui_framework = "EGUI";
        font_size = 12;
        window_size = [
          300
          300
        ];
      };
      app_cfg = {
        paths = [ "$HOME/Desktop" ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/aphorme/config.toml
    assertFileContent home-files/.config/aphorme/config.toml \
      ${./config.toml}
  '';
}
