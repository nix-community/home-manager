{
  programs.secretspec = {
    enable = true;
    settings = {
      defaults = {
        provider = "keyring";
        profile = "default";
        providers = {
          dotenv = "dotenv://";
          aws = "awssm://";
        };
      };
      audit.enabled = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/secretspec/config.toml
    assertFileContent home-files/.config/secretspec/config.toml ${./expected.toml}
  '';
}
