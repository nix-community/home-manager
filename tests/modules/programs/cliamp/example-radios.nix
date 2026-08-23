{
  programs.cliamp = {
    enable = true;
    radios = {
      station = [
        {
          name = "Jazz FM";
          url = "https://jazz.example.com/stream";
        }
        {
          name = "Ambient Radio";
          url = "https://ambient.example.com/stream.m3u";
        }
      ];
    };
  };
  nmt.script = ''
    assertFileContent "home-files/.config/cliamp/radios.toml" ${./expected-radios.toml}
  '';
}
