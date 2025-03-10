{
  programs.terminator = {
    enable = true;
    config = {
      global_config.borderless = true;
      profiles.default.background_color = "#002b36";
    };
  };

  nmt.script = ''
    assertFileContent home-files/.config/terminator/config ${
      builtins.toFile "expected" ''
        [global_config]
        borderless = True
        [profiles]
        [[default]]
        background_color = "#002b36"''
    }
  '';
}
