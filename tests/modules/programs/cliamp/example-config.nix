{
  programs.cliamp = {
    enable = true;
    settings = {
      eq = [
        "-2"
        "0"
        "0"
        "0"
        "0"
        "0"
        "0"
        "0"
        "0"
        "0"
      ];
      eq_preset = "Custom";
      theme = "gruvbox";
      visualizer = "Bricks";
      ytmusic = {
        enabled = true;
      };
    };
  };

  nmt.script = ''
    assertFileContent "home-files/.config/cliamp/config.toml" ${./expected-config.toml}
  '';
}
