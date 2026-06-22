{
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [
        "https://github.com"
        "https://github.example.com"
      ];
    };
  };

  programs.git-credential-oauth.enable = true;

  programs.git = {
    enable = true;
    signing.format = null;
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config \
      ${./git-credential-integrations-expected.conf}
  '';
}
