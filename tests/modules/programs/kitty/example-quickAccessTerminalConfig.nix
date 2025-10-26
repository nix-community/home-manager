{
  config = {
    programs.kitty = {
      enable = true;

      quickAccessTerminalConfig = {
        start_as_hidden = false;
        hide_on_focus_loss = false;
        background_opacity = 0.85;
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/kitty/quick-access-terminal.conf
      assertFileContent \
        home-files/.config/kitty/quick-access-terminal.conf \
        ${./example-quickAccessTerminalConfig-expected.conf}
    '';
  };
}
