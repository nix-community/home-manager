{ config, lib, pkgs, ... }:

{
  programs.gh = {
    enable = true;
    enableGitCredentialHelper = true;
  };

  programs.git.enable = true;

  test.stubs = {
    gh = { };
    git = { };
  };

  nmt.script = ''
    assertFileExists home-files/.config/git/config
    assertFileContent home-files/.config/git/config \
      ${./credential-helper.git.conf}
  '';
}
