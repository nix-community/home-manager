{
  programs.swappy = {
    enable = true;
    settings = {
      Default = {
        save_dir = "$HOME/Desktop";
        save_filename_format = "swappy-%Y%m%d-%H%M%S.png";
        show_panel = false;
        line_size = 5;
        text_size = 20;
        text_font = "sans-serif";
        paint_mode = "brush";
        early_exit = false;
        fill_shape = false;
        auto_save = false;
        custom_color = "rgba(193,125,17,1)";
        transparent = false;
        transparency = 50;
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/swappy/config
    assertFileContent home-files/.config/swappy/config \
    ${./config}
  '';
}
