{
  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://github.com" "https://github.example.com" ];
    };
  };

  programs.git.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config \
      ${./credential-helper.git.conf}
  '';
}
