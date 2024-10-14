{ config, lib, pkgs, ... }:

{
  programs.glab = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
      hosts = [ "https://gitlab.com" "https://gitlab.example.com" ];
    };
  };

  programs.git.enable = true;

  test.stubs.glab = { };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config \
      ${./credential-helper.git.conf}
  '';
}
