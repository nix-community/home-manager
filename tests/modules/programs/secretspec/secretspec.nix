{
  programs.secretspec = {
    enable = true;
    settings = {
      provider = "keyring";
      profile = "default";
      providers = {
        dotenv = "dotenv://";
        aws = "awssm://";
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/secretspec/config.toml
    assertFileContent home-files/.config/secretspec/config.toml ${./expected.toml}
  '';
}
