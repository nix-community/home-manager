{
  programs.kickoff = {
    enable = true;
    settings = {
      padding = 100;
      font_size = 32;
      search.show_hidden_files = false;
      history.decrease_interval = 48;

      keybinding = {
        paste = [ "ctrl+v" ];
        execute = [
          "KP_Enter"
          "Return"
        ];
        complete = [ "Tab" ];
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/kickoff/config.toml
    assertFileContent home-files/.config/kickoff/config.toml \
    ${./example-config.toml}
  '';
}
